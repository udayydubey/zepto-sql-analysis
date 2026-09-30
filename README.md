# Zepto Inventory Analysis — SQL Portfolio Project

A PostgreSQL portfolio project analysing a Zepto-style quick-commerce inventory snapshot across pricing, discounts, stock availability, estimated inventory revenue and inventory weight.

**Goal:** turn SKU-level inventory data into practical business questions a quick-commerce team could use for pricing, replenishment and inventory planning.

> **Data honesty note:** The current GitHub repository contains the SQL script but does not contain the CSV. Numerical findings below were validated against the public `zepto_v2.csv` source whose 3,732-row, 9-column schema matches this project's table structure. Treat these findings as representative of that dataset; if your local CSV differs, rerun the queries before quoting the numbers.

## Problem Statement

Quick-commerce businesses need to balance **availability, pricing, discounts and inventory levels**. This project uses SQL to answer questions such as:

- Which categories carry the most estimated inventory value?
- Where are discounts strongest?
- Which expensive products are unavailable?
- Which products contribute most to category-level value?
- Are heavily discounted products actually available?

## Tech Stack

- **PostgreSQL**
- **SQL**
- pgAdmin / DBeaver
- GitHub

## Dataset

Source: [Zepto v2 inventory dataset](https://github.com/Odongi-s-data-science-projects/Zepto-dataset-SQL/blob/main/zepto_v2.csv)

**Source size:** 3,732 rows × 9 columns.

| Column | Meaning |
|---|---|
| `Category` | Product category |
| `name` | Product name |
| `mrp` | Maximum Retail Price; source values are in paise |
| `discountPercent` | Discount percentage |
| `availableQuantity` | Available inventory quantity |
| `discountedSellingPrice` | Selling price after discount; source values are in paise |
| `weightInGms` | Product/package weight in grams |
| `outOfStock` | Stock availability flag |
| `quantity` | Product quantity/pack quantity field |

## Data Cleaning

The analysis follows these steps:

1. Checked row count, sample records and nulls.
2. Checked distinct categories and stock-status distribution.
3. Identified repeated product names.
4. Identified records where MRP or selling price was zero.
5. Excluded zero-price rows from analytical calculations.
6. Converted MRP and discounted selling price from **paise to INR**.
7. Created a `zepto_clean` SQL view so the raw table is not permanently modified and the script can be rerun safely.

**Validation result:** 3,732 source rows → **3,731 analytical rows** after removing 1 zero-price record. No nulls were found in the nine source columns in the validated dataset.

## Core Business Questions & Findings

| Query | Business question | Finding |
|---|---|---|
| Q1 | Which products have the highest discounts? | The highest discount is **51%**, seen on three Dukes Waffy wafer products. |
| Q2 | Which high-MRP products are out of stock? | **8 SKU records** have MRP above ₹300 and are out of stock. The highest-MRP example is **Patanjali Cow's Ghee at ₹565**. |
| Q3 | Which category has the highest estimated inventory revenue? | **Cooking Essentials and Munchies tie at ₹337,369 each**, calculated as discounted selling price × available quantity. |
| Q4 | Which high-MRP products have discounts below 10%? | **82 SKU records** have MRP above ₹500 and discount below 10%. |
| Q5 | Which category has the highest average discount? | **Fruits & Vegetables: 15.46% average discount**, followed by Meats, Fish & Eggs at 11.03%. |
| Q6 | Which products have the lowest price per gram above 100g? | The lowest calculated value is **Vicks Cough Drops at about ₹0.017/g**. Treat this metric cautiously because the dataset mixes product/package units. |
| Q7 | How is the SKU mix distributed by weight? | **3,392 Low**, **335 Medium**, and **4 Bulk** SKUs under the project's weight bands. |
| Q8 | Which category holds the most inventory weight? | **Cooking Essentials and Munchies tie at 1,404.65 kg each**. |

## Advanced SQL Questions & Findings

| Query | SQL technique | Business question | Finding |
|---|---|---|---|
| Q9 | CTE + RANK() | What are the top 3 products by estimated revenue within each category? | **Borges Extra Light Olive Oil Bottle** ranks #1 in both Cooking Essentials and Munchies at **₹8,394** estimated inventory revenue. Ties are preserved. |
| Q10 | CTE + window SUM() | What share of estimated revenue comes from each category? | Cooking Essentials and Munchies each contribute **15.04%**; together they account for **30.08%** of estimated revenue. |
| Q11 | CTE + running total | How quickly does revenue accumulate across ranked categories? | The top 5 categories accumulate about **64.23%** of the total estimated revenue. |
| Q12 | Aggregation + stock comparison | Do in-stock and out-of-stock SKUs differ in average discount? | In-stock SKUs average **7.90%** discount vs **5.57%** for out-of-stock SKUs — a **2.34 percentage-point difference** in this snapshot. This is descriptive, not causal. |
| Q13 | CTE + DENSE_RANK() | Which categories are important for both value and physical inventory? | Cooking Essentials and Munchies rank at the top for both estimated revenue and inventory weight. |
| Q14 | Filtering | Which discounted products have zero available inventory? | **21 SKU records** have discounts of at least 20% while showing zero available quantity; the highest-discount examples reach **50%**. |
| Q15 | CTE + JOIN | Which products contribute the largest share of their category revenue? | **Godrej Yummiez Chicken Punjabi Tikka** contributes **7.71%** of its category's estimated revenue in the validated snapshot. |
| Q16 | Subquery + JOIN | Which expensive out-of-stock products are also above their category's average MRP? | **8 SKU records** meet the criteria; the highest-MRP example is **Patanjali Cow's Ghee at ₹565**. |

## Business Recommendations

1. **Prioritise replenishment of high-MRP out-of-stock items.** Products such as Patanjali Cow's Ghee and MamyPoko Pants have relatively high ticket values and are unavailable in the snapshot.
2. **Review promotions against stock availability.** 21 SKU records have discounts of at least 20% but zero available quantity. Discounting unavailable items can create a mismatch between promotion and fulfilment.
3. **Use category-level inventory value and weight together.** Cooking Essentials and Munchies appear high on both dimensions, so they deserve attention in inventory planning and storage allocation.
4. **Validate product/category mapping before operational use.** The source snapshot contains repeated product names across multiple category labels, producing identical category-level metrics in places. This may reflect the dataset construction rather than real Zepto category structure, so production decisions should use a deduplicated/validated source.

## Important Dataset Limitation

This is an **inventory snapshot**, not transaction-level order data. Therefore, "estimated revenue" means:

`discountedSellingPrice × availableQuantity`

It is **not actual historical sales revenue**.

Also, repeated product/category combinations appear in the source. The analysis intentionally reports what the dataset contains rather than silently deduplicating records.

## Recommended Repository Structure

```
zepto-sql-analysis/
├── README.md
├── data/
│   └── zepto_v2.csv
├── queries/
│   └── zepto_analysis.sql
└── screenshots/
    ├── q03-category-revenue.png
    ├── q05-category-discount.png
    ├── q09-top-products.png
    ├── q10-revenue-share.png
    ├── q12-discount-stock.png
    ├── q14-discount-zero-stock.png
    └── q16-high-mrp-oos.png
```

The current repo does not commit the CSV; `data/README.md` explains where to get it and how the SQL expects it.

## How to Run

1. Create a PostgreSQL database.
2. Run the table-creation section of `queries/zepto_analysis.sql`.
3. Put the CSV at `data/zepto_v2.csv`.
4. Import it using pgAdmin or the commented PostgreSQL `COPY` command.
5. Run the cleaning view section.
6. Run Q1–Q16.

## Skills Demonstrated

**SQL:** SELECT, WHERE, DISTINCT, GROUP BY, HAVING, ORDER BY, CASE, aggregates, NULLIF, CTEs, subqueries, JOINs, RANK, DENSE_RANK, running totals and window functions.

**Analytics:** data cleaning, KPI-style aggregation, inventory analysis, pricing analysis, stock analysis, category comparison and business recommendations.

## Author

**Uday Dubey**

[GitHub](https://github.com/udayydubey) · [LinkedIn](https://linkedin.com/in/uday-dubey-775777395)
