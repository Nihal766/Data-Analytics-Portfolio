-- ====================================================================
-- Project: Retail Sales & Customer Retention Analysis
-- Author: Nihal Varma
-- Description: Advanced analytical queries utilizing CTEs, Window Functions,
--              and Cohort segmentation to optimize retail profit margins.
-- ====================================================================

-- 1. Identify Top 3 Best-Selling Products per Category using Window Functions
WITH CategoryProductRankings AS (
    SELECT 
        category_name,
        product_name,
        SUM(quantity_sold) AS total_units_sold,
        SUM(sales_amount) AS total_revenue,
        DENSE_RANK() OVER (
            PARTITION BY category_name 
            ORDER BY SUM(sales_amount) DESC
        ) AS sales_rank
    FROM retail_sales
    WHERE status = 'Completed'
    GROUP BY category_name, product_name
)
SELECT 
    category_name,
    product_name,
    total_units_sold,
    total_revenue
FROM CategoryProductRankings
WHERE sales_rank <= 3;


-- 2. Month-over-Month (MoM) Revenue Growth & Moving Averages
WITH MonthlyRevenue AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS sales_month,
        SUM(sales_amount) AS current_month_sales
    FROM retail_sales
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT 
    sales_month,
    current_month_sales,
    LAG(current_month_sales, 1) OVER (ORDER BY sales_month) AS previous_month_sales,
    ROUND(
        (current_month_sales - LAG(current_month_sales, 1) OVER (ORDER BY sales_month)) 
        / NULLIF(LAG(current_month_sales, 1) OVER (ORDER BY sales_month), 0) * 100, 
        2
    ) AS mom_growth_percentage,
    AVG(current_month_sales) OVER (
        ORDER BY sales_month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3_month_avg
FROM MonthlyRevenue;


-- 3. Customer Churn Risk Flagging (RFM Logic)
SELECT 
    customer_id,
    customer_name,
    MAX(order_date) AS last_purchase_date,
    COUNT(order_id) AS total_orders,
    SUM(sales_amount) AS total_spend,
    CURRENT_DATE - MAX(order_date) AS days_since_last_order,
    CASE 
        WHEN CURRENT_DATE - MAX(order_date) > 90 AND SUM(sales_amount) > 10000 THEN 'High Value - At Risk'
        WHEN CURRENT_DATE - MAX(order_date) > 90 THEN 'Inactive'
        WHEN CURRENT_DATE - MAX(order_date) <= 30 THEN 'Active / Loyal'
        ELSE 'Moderate Risk'
    END AS customer_retention_segment
FROM retail_sales
GROUP BY customer_id, customer_name;
