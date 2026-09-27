# Zepto E-commerce Inventory Analysis (SQL)

Analysis of a real-world Zepto (quick-commerce) inventory dataset using PostgreSQL, covering data exploration, data cleaning, and business-driven SQL analysis.

## Tech Stack

- PostgreSQL
- SQL

## Dataset

Zepto e-commerce inventory data containing SKU-level information such as product category, product name, MRP, discount percentage, available quantity, discounted selling price, weight, stock status, and quantity.

## Project Steps

### 1. Table Setup
Created a PostgreSQL table for SKU-level inventory data.

### 2. Data Exploration
- Row count analysis
- Sample data inspection
- NULL-value checks
- Category analysis
- In-stock vs out-of-stock analysis
- Duplicate product-name analysis

### 3. Data Cleaning
- Identified and removed products with zero MRP or selling price
- Converted prices from paise to rupees

### 4. Business Insights
Solved 8 business questions:

1. Top 10 products by discount percentage
2. High-MRP products that are out of stock
3. Estimated revenue by category
4. Products with MRP above ₹500 and discount below 10%
5. Top 5 categories by average discount
6. Price-per-gram analysis for products above 100g
7. Weight-based segmentation into Low / Medium / Bulk
8. Total inventory weight by category

## SQL Concepts Used

- CREATE TABLE
- SELECT, WHERE, DISTINCT
- ORDER BY, GROUP BY, HAVING
- COUNT, SUM, AVG, ROUND
- CASE WHEN
- DELETE, UPDATE
- NULLIF
- Aggregate functions
- Business-oriented SQL analysis

## Key Insights

Run the queries in zepto_analysis.sql to generate the latest numerical findings for the highest average discount category, highest estimated revenue category, largest inventory-weight category, highest-discount products, and high-MRP out-of-stock products.

## Files

- zepto_analysis.sql — complete SQL script containing table creation, data exploration, cleaning, and business queries.

## Author

**Uday Dubey**

[GitHub](https://github.com/udayydubey) · [LinkedIn](https://linkedin.com/in/uday-dubey-775777395)
