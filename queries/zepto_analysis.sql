-- =========================================================
-- ZEPTO INVENTORY ANALYSIS | PostgreSQL
-- Author: Uday Dubey
-- Purpose: Explore pricing, discounts, inventory and stock availability.
--
-- Dataset source:
-- https://github.com/Odongi-s-data-science-projects/Zepto-dataset-SQL
--
-- IMPORTANT:
-- The source prices are stored in paise. The zepto_clean view converts
-- MRP and discounted selling price into INR and excludes zero-price rows.
-- =========================================================

-- =========================================================
-- 0. TABLE SETUP
-- Business question: Can the raw Zepto inventory dataset be stored in a
-- structured table for analysis?
-- =========================================================

CREATE TABLE IF NOT EXISTS zepto (
    sku_id SERIAL PRIMARY KEY,
    category VARCHAR(120),
    name VARCHAR(150) NOT NULL,
    mrp NUMERIC(8,2),
    discountPercent NUMERIC(5,2),
    availableQuantity INTEGER,
    discountedSellingPrice NUMERIC(8,2),
    weightInGms INTEGER,
    outOfStock BOOLEAN,
    quantity INTEGER
);

-- If the table is already populated, import the CSV separately:
-- \copy zepto(category,name,discountpercent,availablequantity,
--             discountedsellingprice,weightingms,outofstock,quantity)
-- FROM 'data/zepto_v2.csv'
-- WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- =========================================================
-- 1. DATA EXPLORATION
-- =========================================================

-- Business question: How large is the dataset?
SELECT COUNT(*) AS total_rows
FROM zepto;

-- Result meaning: Shows the number of SKU-level records available before cleaning.

-- Business question: What does a sample of the raw data look like?
SELECT *
FROM zepto
LIMIT 10;

-- Result meaning: Provides a quick structural check before analysis.

-- Business question: Are there missing values in key analytical columns?
SELECT
    COUNT(*) FILTER (WHERE name IS NULL) AS null_name,
    COUNT(*) FILTER (WHERE category IS NULL) AS null_category,
    COUNT(*) FILTER (WHERE mrp IS NULL) AS null_mrp,
    COUNT(*) FILTER (WHERE discountpercent IS NULL) AS null_discount,
    COUNT(*) FILTER (WHERE availablequantity IS NULL) AS null_available_quantity,
    COUNT(*) FILTER (WHERE discountedsellingprice IS NULL) AS null_selling_price,
    COUNT(*) FILTER (WHERE weightingms IS NULL) AS null_weight,
    COUNT(*) FILTER (WHERE outofstock IS NULL) AS null_stock_status,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS null_quantity
FROM zepto;

-- Result meaning: Confirms whether missing values could affect the analysis.

-- Business question: How many product categories are represented?
SELECT
    COUNT(DISTINCT category) AS category_count
FROM zepto;

-- Result meaning: Gives the breadth of categories covered by the inventory snapshot.

-- Business question: How is inventory split between in-stock and out-of-stock SKUs?
SELECT
    outofstock,
    COUNT(*) AS sku_count
FROM zepto
GROUP BY outofstock
ORDER BY outofstock;

-- Result meaning: Shows the basic stock-availability mix.

-- Business question: Which product names occur across multiple SKU records?
SELECT
    name,
    COUNT(*) AS sku_count
FROM zepto
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY sku_count DESC, name;

-- Result meaning: Highlights repeated product names that may represent multiple SKUs or repeated records.

-- =========================================================
-- 2. DATA CLEANING
-- =========================================================

-- Business question: Are there records with invalid zero pricing?
SELECT *
FROM zepto
WHERE mrp = 0
   OR discountedsellingprice = 0;

-- Result meaning: Identifies rows that should not be used for price/revenue analysis.

-- Create a cleaned analytical view instead of permanently modifying the raw table.
-- This prevents the script from dividing prices by 100 more than once if rerun.
DROP VIEW IF EXISTS zepto_clean;

CREATE VIEW zepto_clean AS
SELECT
    sku_id,
    category,
    name,
    mrp / 100.0 AS mrp,
    discountpercent,
    availablequantity,
    discountedsellingprice / 100.0 AS discountedsellingprice,
    weightingms,
    outofstock,
    quantity
FROM zepto
WHERE mrp > 0
  AND discountedsellingprice > 0;

-- Result meaning: Converts paise to INR and removes zero-price records for downstream analysis.

-- =========================================================
-- 3. BUSINESS ANALYSIS — CORE QUERIES
-- =========================================================

-- Q1. What products have the highest discount percentages?
SELECT DISTINCT
    name,
    mrp,
    discountpercent
FROM zepto_clean
ORDER BY discountpercent DESC, name
LIMIT 10;

-- Result meaning: Surfaces the most heavily discounted products in the snapshot.

-- Q2. Which high-MRP products are currently out of stock?
SELECT DISTINCT
    name,
    category,
    mrp
FROM zepto_clean
WHERE outofstock = TRUE
  AND mrp > 300
ORDER BY mrp DESC, name;

-- Result meaning: Flags relatively expensive products that are unavailable.

-- Q3. Which categories have the highest estimated inventory revenue?
SELECT
    category,
    ROUND(SUM(discountedsellingprice * availablequantity), 2) AS estimated_revenue
FROM zepto_clean
GROUP BY category
ORDER BY estimated_revenue DESC;

-- Result meaning: Estimates the value of sellable inventory by category using current discounted price × available quantity.

-- Q4. Which products have high MRP but relatively low discounts?
SELECT DISTINCT
    name,
    mrp,
    discountpercent
FROM zepto_clean
WHERE mrp > 500
  AND discountpercent < 10
ORDER BY mrp DESC, discountpercent ASC, name;

-- Result meaning: Identifies higher-priced products where customers receive less than a 10% discount.

-- Q5. Which categories offer the highest average discount?
SELECT
    category,
    ROUND(AVG(discountpercent), 2) AS avg_discount_percent
FROM zepto_clean
GROUP BY category
ORDER BY avg_discount_percent DESC
LIMIT 5;

-- Result meaning: Compares discount intensity across product categories.

-- Q6. Which products provide the lowest price per gram among products above 100g?
SELECT
    name,
    weightingms,
    discountedsellingprice,
    ROUND(
        discountedsellingprice / NULLIF(weightingms, 0),
        2
    ) AS price_per_gram
FROM zepto_clean
WHERE weightingms > 100
ORDER BY price_per_gram ASC, name;

-- Result meaning: Finds products that offer lower price relative to their weight.

-- Q7. How does the inventory split across Low, Medium and Bulk weight bands?
SELECT
    CASE
        WHEN weightingms < 1000 THEN 'Low'
        WHEN weightingms <= 5000 THEN 'Medium'
        ELSE 'Bulk'
    END AS weight_category,
    COUNT(*) AS sku_count
FROM zepto_clean
GROUP BY weight_category
ORDER BY sku_count DESC;

-- Result meaning: Shows whether the SKU mix is concentrated in smaller, medium or bulk packs.

-- Q8. Which categories hold the most inventory weight?
SELECT
    category,
    ROUND(
        SUM(weightingms * availablequantity) / 1000.0,
        2
    ) AS total_inventory_weight_kg
FROM zepto_clean
GROUP BY category
ORDER BY total_inventory_weight_kg DESC;

-- Result meaning: Measures the physical inventory load represented by each category.

-- =========================================================
-- 4. ADVANCED SQL — CTEs, WINDOW FUNCTIONS, SUBQUERIES & JOINS
-- =========================================================

-- Q9. What are the top 3 products by estimated inventory revenue within each category?
WITH product_revenue AS (
    SELECT
        category,
        name,
        ROUND(SUM(discountedsellingprice * availablequantity), 2) AS product_revenue
    FROM zepto_clean
    GROUP BY category, name
),
ranked_products AS (
    SELECT
        category,
        name,
        product_revenue,
        RANK() OVER (
            PARTITION BY category
            ORDER BY product_revenue DESC
        ) AS revenue_rank
    FROM product_revenue
)
SELECT
    category,
    name,
    product_revenue,
    revenue_rank
FROM ranked_products
WHERE revenue_rank <= 3
ORDER BY category, revenue_rank, name;

-- Result meaning: Shows the highest-value products inside each category while preserving ties.

-- Q10. What percentage of total estimated revenue comes from each category?
WITH category_revenue AS (
    SELECT
        category,
        SUM(discountedsellingprice * availablequantity) AS revenue
    FROM zepto_clean
    GROUP BY category
)
SELECT
    category,
    ROUND(revenue, 2) AS category_revenue,
    ROUND(
        100.0 * revenue / NULLIF(SUM(revenue) OVER (), 0),
        2
    ) AS revenue_share_percent
FROM category_revenue
ORDER BY category_revenue DESC;

-- Result meaning: Quantifies each category's contribution to the estimated inventory-revenue pool.

-- Q11. What is the running cumulative estimated revenue when categories are ranked by revenue?
WITH category_revenue AS (
    SELECT
        category,
        SUM(discountedsellingprice * availablequantity) AS revenue
    FROM zepto_clean
    GROUP BY category
)
SELECT
    category,
    ROUND(revenue, 2) AS category_revenue,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY revenue DESC, category
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_revenue
FROM category_revenue
ORDER BY category_revenue DESC, category;

-- Result meaning: Shows how quickly the largest categories accumulate the overall revenue pool.

-- Q12. Do in-stock and out-of-stock products differ in their average discount?
SELECT
    CASE
        WHEN outofstock THEN 'Out of stock'
        ELSE 'In stock'
    END AS stock_status,
    COUNT(*) AS sku_count,
    ROUND(AVG(discountpercent), 2) AS avg_discount_percent
FROM zepto_clean
GROUP BY outofstock
ORDER BY outofstock;

-- Result meaning: Compares discount intensity between available and unavailable SKUs.

-- Q13. Which categories combine high revenue with high inventory weight?
WITH category_metrics AS (
    SELECT
        category,
        SUM(discountedsellingprice * availablequantity) AS revenue,
        SUM(weightingms * availablequantity) / 1000.0 AS inventory_weight_kg
    FROM zepto_clean
    GROUP BY category
),
category_ranked AS (
    SELECT
        category,
        revenue,
        inventory_weight_kg,
        DENSE_RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
        DENSE_RANK() OVER (ORDER BY inventory_weight_kg DESC) AS weight_rank
    FROM category_metrics
)
SELECT
    category,
    ROUND(revenue, 2) AS estimated_revenue,
    ROUND(inventory_weight_kg, 2) AS inventory_weight_kg,
    revenue_rank,
    weight_rank
FROM category_ranked
WHERE revenue_rank <= 5
   OR weight_rank <= 5
ORDER BY revenue_rank, weight_rank, category;

-- Result meaning: Helps identify categories that matter both financially and operationally.

-- Q14. Which products have discounts of at least 20% but zero available inventory?
SELECT
    name,
    category,
    discountpercent,
    availablequantity
FROM zepto_clean
WHERE discountpercent >= 20
  AND availablequantity = 0
  AND outofstock = TRUE
ORDER BY discountpercent DESC, name;

-- Result meaning: Flags products carrying meaningful discounts but no available stock, which may indicate missed sales opportunities.

-- Q15. Which products contribute the largest share of their own category's estimated revenue?
WITH product_revenue AS (
    SELECT
        category,
        name,
        SUM(discountedsellingprice * availablequantity) AS product_revenue
    FROM zepto_clean
    GROUP BY category, name
),
category_totals AS (
    SELECT
        category,
        SUM(product_revenue) AS category_revenue
    FROM product_revenue
    GROUP BY category
)
SELECT
    p.category,
    p.name,
    ROUND(p.product_revenue, 2) AS product_revenue,
    ROUND(
        100.0 * p.product_revenue / NULLIF(c.category_revenue, 0),
        2
    ) AS category_revenue_share_percent
FROM product_revenue p
JOIN category_totals c
    ON p.category = c.category
ORDER BY category_revenue_share_percent DESC, p.category, p.name
LIMIT 15;

-- Result meaning: Shows products that have an outsized contribution within their category.

-- Q16. Which high-MRP out-of-stock products are above their category's average MRP?
SELECT
    z.category,
    z.name,
    z.mrp,
    ROUND(category_avg.avg_mrp, 2) AS category_avg_mrp
FROM zepto_clean z
JOIN (
    SELECT
        category,
        AVG(mrp) AS avg_mrp
    FROM zepto_clean
    GROUP BY category
) AS category_avg
    ON z.category = category_avg.category
WHERE z.outofstock = TRUE
  AND z.mrp > 300
  AND z.mrp > category_avg.avg_mrp
ORDER BY z.mrp DESC, z.category, z.name;

-- Result meaning: Prioritizes expensive unavailable products that are also expensive relative to their own category.
