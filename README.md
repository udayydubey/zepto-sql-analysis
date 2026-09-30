# Zepto Inventory Analysis — SQL Portfolio Project

A beginner-friendly PostgreSQL data analysis project using a Zepto-style quick-commerce inventory dataset. The project explores pricing, discounts, stock availability, estimated inventory revenue, product weight and category-level inventory.

> **Data note:** The repository's original SQL schema matches the public zepto_v2.csv dataset used for validation. The raw CSV is not committed to this repository yet. The numerical findings below were calculated from that matching dataset after applying the cleaning logic in queries/zepto_analysis.sql.

## Problem Statement

Quick-commerce businesses need to balance availability, pricing, discounts and inventory across a large number of SKUs.

This project uses SQL to answer questions such as:
- Which categories carry the highest estimated inventory value?
- Which categories offer the highest average discounts?
- Which expensive products are out of stock?
- Which products contribute most to category-level estimated revenue?
- How concentrated is estimated revenue across categories?
- Are heavily discounted products unavailable?

## Dataset

The dataset contains **3,732 SKU-level records** across **14 categories**.

| Column | Description |
|---|---|
| category | Product category |
| name | Product/SKU name |
| mrp | Maximum retail price, stored in paise in the source |
| discountPercent | Discount percentage |
| availableQuantity | Currently available inventory quantity |
| discountedSellingPrice | Selling price after discount, stored in paise |
| weightInGms | Product/package weight in grams |
| outOfStock | Whether the SKU is marked out of stock |
| quantity | Quantity field provided by the dataset |

## Data Cleaning

1. Checked row counts and sample records.
2. Checked NULLs in analytical columns.
3. Identified records with zero MRP or zero discounted selling price.
4. Excluded zero-price records from downstream analysis.
5. Converted MRP and discounted selling price from paise to INR using a cleaned SQL view.
6. Used NULLIF when calculating price per gram to avoid division-by-zero errors.

The matching dataset contains **3,732 raw rows**; **1 zero-price row** is excluded, leaving **3,731 rows** for cleaned analysis.

## Business Questions & Findings

| Query | Business question | Finding |
|---|---|---|
| Q1 | Which products have the highest discounts? | Highest observed discount is **51%**, led by three Dukes Waffy wafer products. |
| Q2 | Which high-MRP products are out of stock? | **8 SKU records** meet out-of-stock + MRP above ₹300. Highest-MRP example: **Patanjali Cow's Ghee, ₹565**. |
| Q3 | Which categories have the highest estimated inventory revenue? | **Cooking Essentials and Munchies tie at ₹337,369 each**. |
| Q4 | Which products have MRP above ₹500 and discount below 10%? | **82 SKU records** meet this condition. |
| Q5 | Which categories have the highest average discount? | **Fruits & Vegetables: 15.46% average discount**, the highest category average. |
| Q6 | Which products have the lowest price per gram above 100g? | Lowest observed value: **₹0.0172/g** for Vicks Cough Drops Menthol. Interpret cautiously across product types. |
| Q7 | How is the SKU mix distributed by weight band? | **3,392 Low**, **335 Medium**, **4 Bulk** records under the project's definitions. |
| Q8 | Which categories hold the most inventory weight? | **Cooking Essentials and Munchies tie at 1,404.65 kg** each. |

## Advanced SQL Questions

| Query | Technique | Finding / purpose |
|---|---|---|
| Q9 | CTE + RANK | Returns the top 3 products by estimated inventory revenue within each category, preserving ties. |
| Q10 | CTE + window aggregate | Calculates each category's share of total estimated inventory revenue. |
| Q11 | CTE + running total | Builds cumulative estimated revenue after ranking categories by revenue. |
| Q12 | GROUP BY | In-stock SKUs average **7.90%** discount vs **5.57%** for out-of-stock SKUs. Descriptive association only. |
| Q13 | CTE + DENSE_RANK | Compares category revenue rank with inventory-weight rank. |
| Q14 | Filtering | Finds **21 SKU records** with at least 20% discount and zero available quantity. |
| Q15 | CTE + JOIN | Identifies products with the largest share of their own category's estimated revenue. |
| Q16 | Subquery + JOIN | Finds high-MRP out-of-stock products priced above their category's average MRP. |

## Key Insights

- **Highest average discount:** Fruits & Vegetables — **15.46%**.
- **Highest estimated inventory revenue:** Cooking Essentials and Munchies — **₹337,369 each**.
- **Total estimated inventory revenue:** **₹22.43 lakh**, calculated as discounted selling price × available quantity. This is not actual sales revenue.
- **High-MRP out-of-stock:** 8 SKU records satisfy the existing Q2 threshold; the highest-MRP example is Patanjali Cow's Ghee at **₹565**.
- **Heaviest inventory:** Cooking Essentials and Munchies — **1,404.65 kg each**.
- **Discount vs stock:** in-stock SKUs average **7.90%** discount versus **5.57%** for out-of-stock SKUs. This is an association, not a causal claim.

## Business Recommendations

1. **Review stock availability for high-value unavailable products.** High-MRP out-of-stock SKUs can be candidates for replenishment review.
2. **Investigate discounted-but-unavailable SKUs.** The 21 records with at least 20% discount and zero available quantity are potential missed-sales cases.
3. **Prioritize high-value categories for inventory monitoring.** Cooking Essentials and Munchies have the highest estimated inventory value and inventory weight in this dataset.
4. **Use category-level discount analysis when reviewing promotions.** Fruits & Vegetables has the highest average discount, so promotion depth can be monitored alongside availability.

## SQL Concepts Demonstrated

- SELECT, WHERE, DISTINCT
- GROUP BY, HAVING, ORDER BY, LIMIT
- COUNT, SUM, AVG, ROUND
- CASE WHEN and NULLIF
- CTEs and subqueries
- INNER JOIN
- RANK and DENSE_RANK
- Window functions and running totals
- Business-oriented KPI calculations

## Project Structure

```text
zepto-sql-analysis/
├── README.md
├── data/
│   └── README.md
├── queries/
│   └── zepto_analysis.sql
└── screenshots/
    └── README.md
```

## How to Run

1. Create a PostgreSQL database.
2. Create the zepto table using the setup section in queries/zepto_analysis.sql.
3. Place the source CSV at data/zepto_v2.csv.
4. Import it with PostgreSQL COPY/\copy.
5. Run queries/zepto_analysis.sql.

## Limitations

- This is an inventory snapshot, not transactional sales data.
- Estimated revenue means discounted selling price × available quantity, not realized revenue.
- Repeated product names can occur across multiple category/SKU records.
- Price-per-gram is not equally meaningful for every product type.
- Findings describe this dataset snapshot and should not be generalized to Zepto's current business operations.

## Screenshots to Add

Recommended screenshots for the README:
1. **Q3 — Category estimated revenue**
2. **Q5 — Average discount by category**
3. **Q8 — Inventory weight by category**
4. **Q9 — Top 3 products per category**
5. **Q10 — Revenue share by category**
6. **Q12 — Discount vs stock status**
7. **Q14 — Discounted but unavailable**
8. **Q16 — High-MRP out-of-stock**

For a compact recruiter README, use **Q3, Q5, Q9, Q10 and Q12**.

## Author

**Uday Dubey**

[GitHub](https://github.com/udayydubey) · [LinkedIn](https://linkedin.com/in/uday-dubey-775777395)