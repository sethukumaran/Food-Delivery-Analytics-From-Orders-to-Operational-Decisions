-- Food Delivery Analytics | PostgreSQL
-- Source table: food_delivery_orders
-- Import the CSV into this table using your preferred ETL/GUI tool.
-- PostgreSQL COPY example:
-- \copy food_delivery_orders FROM 'Order_delivery.csv' WITH (FORMAT csv, HEADER true);

-- ============================================================
-- 1. DATA QUALITY PROFILE
-- ============================================================
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT "Order_ID") AS unique_orders,
    COUNT(DISTINCT "User_ID") AS unique_customers,
    COUNT(DISTINCT "Restaurant_ID") AS unique_restaurants,
    COUNT(DISTINCT "Driver_ID") AS unique_drivers,
    COUNT(*) FILTER (WHERE "Order_Status" = 'Delivered') AS delivered_orders,
    COUNT(*) FILTER (WHERE "Order_Status" = 'Cancelled') AS cancelled_orders,
    COUNT(*) FILTER (WHERE "Order_Status" = 'In Transit') AS in_transit_orders
FROM food_delivery_orders;

-- ============================================================
-- 2. OVERALL BUSINESS KPI
-- ============================================================
SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE "Order_Status" = 'Delivered') AS delivered_orders,
    COUNT(*) FILTER (WHERE "Order_Status" = 'Cancelled') AS cancelled_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Order_Status" = 'Delivered') / COUNT(*), 2) AS delivery_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Order_Status" = 'Cancelled') / COUNT(*), 2) AS cancellation_rate_pct,
    ROUND(SUM("Total_Price") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS delivered_revenue,
    ROUND(AVG("Total_Price") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS avg_order_value,
    ROUND(AVG("Delivery_Duration_Minutes") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS avg_delivery_minutes
FROM food_delivery_orders;

-- ============================================================
-- 3. PEAK ORDER HOURS
-- Business question: When should operations allocate the most capacity?
-- ============================================================
SELECT
    EXTRACT(HOUR FROM TO_TIMESTAMP("Order_Time", 'DD-MM-YYYY HH24:MI'))::int AS order_hour,
    COUNT(*) AS orders,
    ROUND(SUM("Total_Price")::numeric, 2) AS gross_order_value,
    ROUND(AVG("Total_Price")::numeric, 2) AS avg_order_value
FROM food_delivery_orders
GROUP BY 1
ORDER BY orders DESC;

-- ============================================================
-- 4. DAY-OF-WEEK DEMAND
-- ============================================================
SELECT
    TO_CHAR(TO_TIMESTAMP("Order_Time", 'DD-MM-YYYY HH24:MI'), 'Dy') AS day_of_week,
    EXTRACT(ISODOW FROM TO_TIMESTAMP("Order_Time", 'DD-MM-YYYY HH24:MI'))::int AS day_num,
    COUNT(*) AS orders,
    ROUND(SUM("Total_Price")::numeric, 2) AS gross_order_value
FROM food_delivery_orders
GROUP BY 1, 2
ORDER BY day_num;

-- ============================================================
-- 5. CITY PERFORMANCE
-- Business question: Which markets need operational or commercial attention?
-- ============================================================
SELECT
    "City",
    COUNT(*) AS orders,
    COUNT(*) FILTER (WHERE "Order_Status" = 'Delivered') AS delivered_orders,
    COUNT(*) FILTER (WHERE "Order_Status" = 'Cancelled') AS cancelled_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Order_Status" = 'Cancelled') / COUNT(*), 2) AS cancellation_rate_pct,
    ROUND(AVG("Total_Price") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS avg_order_value,
    ROUND(SUM("Total_Price") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS delivered_revenue,
    ROUND(AVG("Delivery_Duration_Minutes") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS avg_delivery_minutes
FROM food_delivery_orders
GROUP BY "City"
ORDER BY delivered_revenue DESC;

-- ============================================================
-- 6. TRAFFIC VS DELIVERY PERFORMANCE
-- Business question: How strongly does traffic affect delivery time?
-- ============================================================
SELECT
    "Traffic_Level",
    COUNT(*) AS orders,
    ROUND(AVG("Delivery_Duration_Minutes")::numeric, 2) AS avg_delivery_minutes,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "Delivery_Duration_Minutes")::numeric, 2) AS median_delivery_minutes,
    ROUND(AVG("Delivery_Distance_km")::numeric, 2) AS avg_distance_km,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Order_Status" = 'Cancelled') / COUNT(*), 2) AS cancellation_rate_pct
FROM food_delivery_orders
GROUP BY "Traffic_Level"
ORDER BY avg_delivery_minutes DESC;

-- ============================================================
-- 7. DISTANCE BUCKET VS DELIVERY TIME
-- ============================================================
SELECT
    CASE
        WHEN "Delivery_Distance_km" < 1 THEN '<1 km'
        WHEN "Delivery_Distance_km" < 2 THEN '1-2 km'
        WHEN "Delivery_Distance_km" < 3 THEN '2-3 km'
        WHEN "Delivery_Distance_km" < 4 THEN '3-4 km'
        ELSE '4+ km'
    END AS distance_bucket,
    COUNT(*) AS orders,
    ROUND(AVG("Delivery_Duration_Minutes")::numeric, 2) AS avg_delivery_minutes,
    ROUND(AVG("Total_Price")::numeric, 2) AS avg_order_value
FROM food_delivery_orders
GROUP BY 1
ORDER BY MIN("Delivery_Distance_km");

-- ============================================================
-- 8. RESTAURANT PERFORMANCE
-- Business question: Which restaurants combine demand, revenue and service quality?
-- ============================================================
SELECT
    "Restaurant_ID",
    COUNT(*) AS orders,
    COUNT(*) FILTER (WHERE "Order_Status" = 'Delivered') AS delivered_orders,
    ROUND(SUM("Total_Price") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS delivered_revenue,
    ROUND(AVG("Total_Price") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS avg_order_value,
    ROUND(AVG("Delivery_Duration_Minutes") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS avg_delivery_minutes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Order_Status" = 'Cancelled') / COUNT(*), 2) AS cancellation_rate_pct
FROM food_delivery_orders
GROUP BY "Restaurant_ID"
HAVING COUNT(*) >= 20
ORDER BY delivered_revenue DESC
LIMIT 20;

-- ============================================================
-- 9. ITEM / CUISINE PERFORMANCE
-- Business question: Which menu items are demand and revenue drivers?
-- ============================================================
SELECT
    "Item_Name",
    SUM("Quantity") AS units_sold,
    COUNT(*) AS order_lines,
    ROUND(SUM("Total_Price") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS delivered_revenue,
    ROUND(AVG("Total_Price")::numeric, 2) AS avg_order_value,
    ROUND(AVG("Quantity")::numeric, 2) AS avg_quantity
FROM food_delivery_orders
GROUP BY "Item_Name"
ORDER BY delivered_revenue DESC;

-- ============================================================
-- 10. DRIVER PERFORMANCE
-- Business question: Which drivers have high workload and slower deliveries?
-- ============================================================
SELECT
    "Driver_ID",
    "Driver_Vehicle",
    COUNT(*) AS assigned_orders,
    COUNT(*) FILTER (WHERE "Order_Status" = 'Delivered') AS delivered_orders,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Order_Status" = 'Delivered') / NULLIF(COUNT(*), 0), 2) AS delivery_success_pct,
    ROUND(AVG("Delivery_Duration_Minutes") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS avg_delivery_minutes,
    ROUND(AVG("Delivery_Distance_km")::numeric, 2) AS avg_distance_km
FROM food_delivery_orders
GROUP BY "Driver_ID", "Driver_Vehicle"
HAVING COUNT(*) >= 20
ORDER BY avg_delivery_minutes DESC;

-- ============================================================
-- 11. DRIVER VEHICLE COMPARISON
-- ============================================================
SELECT
    "Driver_Vehicle",
    COUNT(*) AS orders,
    ROUND(AVG("Delivery_Duration_Minutes") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS avg_delivery_minutes,
    ROUND(AVG("Delivery_Distance_km")::numeric, 2) AS avg_distance_km,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Order_Status" = 'Cancelled') / COUNT(*), 2) AS cancellation_rate_pct
FROM food_delivery_orders
GROUP BY "Driver_Vehicle"
ORDER BY avg_delivery_minutes;

-- ============================================================
-- 12. DRIVER AVAILABILITY VS OPERATIONS
-- ============================================================
SELECT
    "Driver_Availability",
    COUNT(*) AS orders,
    ROUND(AVG("Delivery_Duration_Minutes") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS avg_delivery_minutes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Order_Status" = 'Cancelled') / COUNT(*), 2) AS cancellation_rate_pct
FROM food_delivery_orders
GROUP BY "Driver_Availability";

-- ============================================================
-- 13. CUSTOMER SPENDING / FREQUENCY
-- Business question: Who are the high-value and repeat customers?
-- ============================================================
WITH customer_metrics AS (
    SELECT
        "User_ID",
        COUNT(*) AS orders,
        COUNT(*) FILTER (WHERE "Order_Status" = 'Delivered') AS delivered_orders,
        SUM("Total_Price") FILTER (WHERE "Order_Status" = 'Delivered') AS revenue
    FROM food_delivery_orders
    GROUP BY "User_ID"
)
SELECT
    "User_ID",
    orders,
    delivered_orders,
    ROUND(COALESCE(revenue, 0)::numeric, 2) AS delivered_revenue,
    ROUND(COALESCE(revenue, 0) / NULLIF(delivered_orders, 0), 2) AS avg_spend_per_delivered_order
FROM customer_metrics
ORDER BY delivered_revenue DESC
LIMIT 25;

-- ============================================================
-- 14. CUSTOMER SEGMENTATION
-- ============================================================
WITH customer_metrics AS (
    SELECT
        "User_ID",
        COUNT(*) AS orders,
        SUM("Total_Price") FILTER (WHERE "Order_Status" = 'Delivered') AS revenue
    FROM food_delivery_orders
    GROUP BY "User_ID"
)
SELECT
    CASE
        WHEN orders >= 15 THEN 'High Frequency'
        WHEN orders >= 8 THEN 'Medium Frequency'
        ELSE 'Low Frequency'
    END AS frequency_segment,
    COUNT(*) AS customers,
    ROUND(AVG(COALESCE(revenue, 0))::numeric, 2) AS avg_customer_revenue,
    ROUND(SUM(COALESCE(revenue, 0))::numeric, 2) AS segment_revenue
FROM customer_metrics
GROUP BY 1
ORDER BY segment_revenue DESC;

-- ============================================================
-- 15. PAYMENT METHOD PERFORMANCE
-- ============================================================
SELECT
    "Payment_Method",
    COUNT(*) AS orders,
    ROUND(AVG("Total_Price")::numeric, 2) AS avg_order_value,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Order_Status" = 'Cancelled') / COUNT(*), 2) AS cancellation_rate_pct,
    ROUND(SUM("Total_Price") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS delivered_revenue
FROM food_delivery_orders
GROUP BY "Payment_Method"
ORDER BY delivered_revenue DESC;

-- ============================================================
-- 16. CANCELLATION HOTSPOTS
-- Business question: Where are cancellations concentrated?
-- ============================================================
SELECT
    "City",
    "Traffic_Level",
    EXTRACT(HOUR FROM TO_TIMESTAMP("Order_Time", 'DD-MM-YYYY HH24:MI'))::int AS order_hour,
    COUNT(*) AS orders,
    COUNT(*) FILTER (WHERE "Order_Status" = 'Cancelled') AS cancellations,
    ROUND(100.0 * COUNT(*) FILTER (WHERE "Order_Status" = 'Cancelled') / COUNT(*), 2) AS cancellation_rate_pct
FROM food_delivery_orders
GROUP BY 1, 2, 3
HAVING COUNT(*) >= 50
ORDER BY cancellation_rate_pct DESC, cancellations DESC;

-- ============================================================
-- 17. TOP CITY x ITEM COMBINATIONS
-- ============================================================
SELECT
    "City",
    "Item_Name",
    SUM("Quantity") AS units_sold,
    ROUND(SUM("Total_Price") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS delivered_revenue
FROM food_delivery_orders
GROUP BY "City", "Item_Name"
ORDER BY delivered_revenue DESC
LIMIT 30;

-- ============================================================
-- 18. DELIVERY BOTTLENECKS
-- Flag unusually slow deliveries using the 75th percentile + 1.5*IQR.
-- ============================================================
WITH stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY "Delivery_Duration_Minutes") AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY "Delivery_Duration_Minutes") AS q3
    FROM food_delivery_orders
),
flagged AS (
    SELECT
        f.*,
        s.q1,
        s.q3,
        s.q3 + 1.5 * (s.q3 - s.q1) AS upper_iqr_limit
    FROM food_delivery_orders f
    CROSS JOIN stats s
)
SELECT
    "City",
    "Traffic_Level",
    "Driver_Vehicle",
    COUNT(*) AS slow_delivery_orders,
    ROUND(AVG("Delivery_Duration_Minutes")::numeric, 2) AS avg_slow_delivery_minutes
FROM flagged
WHERE "Delivery_Duration_Minutes" > upper_iqr_limit
GROUP BY 1, 2, 3
ORDER BY slow_delivery_orders DESC;

-- ============================================================
-- 19. MONTHLY TREND
-- ============================================================
SELECT
    DATE_TRUNC('month', TO_TIMESTAMP("Order_Time", 'DD-MM-YYYY HH24:MI'))::date AS month,
    COUNT(*) AS orders,
    COUNT(*) FILTER (WHERE "Order_Status" = 'Delivered') AS delivered_orders,
    ROUND(SUM("Total_Price") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS delivered_revenue,
    ROUND(AVG("Delivery_Duration_Minutes") FILTER (WHERE "Order_Status" = 'Delivered')::numeric, 2) AS avg_delivery_minutes
FROM food_delivery_orders
GROUP BY 1
ORDER BY 1;

-- ============================================================
-- 20. CORRELATION-STYLE AGGREGATION FOR DELIVERY TIME
-- PostgreSQL corr() can quantify linear relationships.
-- ============================================================
SELECT
    ROUND(CORR("Delivery_Duration_Minutes", "Delivery_Distance_km")::numeric, 4) AS corr_duration_distance,
    ROUND(CORR("Delivery_Duration_Minutes", "Total_Price")::numeric, 4) AS corr_duration_order_value,
    ROUND(CORR("Total_Price", "Quantity")::numeric, 4) AS corr_order_value_quantity
FROM food_delivery_orders;
