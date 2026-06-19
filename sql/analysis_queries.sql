CREATE TABLE blinkit_customer_feedback (
    feedback_id BIGINT PRIMARY KEY,
    order_id BIGINT,
    customer_id BIGINT,
    rating INT,
    feedback_text TEXT,
    feedback_category VARCHAR(50),
    sentiment VARCHAR(20),
    feedback_date DATE
);

CREATE TABLE blinkit_customers(
    customer_id BIGINT PRIMARY KEY,
    customer_name VARCHAR(50),
    email VARCHAR(50),
    phone  VARCHAR(50),
    address  VARCHAR(100),
    area  VARCHAR(50),
    pincode INT,
    registration_date DATE,
    customer_segment  VARCHAR(10),
    total_orders INT ,
    avg_order_value DECIMAL(10,2)
);

CREATE TABLE blinkit_delivery_performance (
    order_id BIGINT ,
    delivery_partner_id INT PRIMARY KEY ,
    promised_time TIMESTAMP ,
    actual_time TIMESTAMP ,
    delivery_time_minutes DECIMAL(8,2) ,
    distance_km DECIMAL(8,2),
    delivery_status VARCHAR(30),
    Rreasons_if_delayed VARCHAR(50) 
);

CREATE TABLE blinkit_inventory (
    product_id BIGINT, 
    inventory_date DATE ,
    stock_received INT,
    damaged_stock INT
);

CREATE TABLE blinkit_inventoryNew(
    product_id BIGINT ,
    inventory_date VARCHAR(10),
    stock_received INT,
    damaged_stock INT
);

CREATE TABLE blinkit_marketing_performance (
    campaign_id BIGINT PRIMARY KEY,
    campaign_name VARCHAR(50),
    campaign_date DATE,
    target_audience VARCHAR(30),
    channel VARCHAR(30),
    impressions INT,
    clicks INT,
    conversions INT,
    spend DECIMAL(12,2),
    revenue_generated DECIMAL(12,2),
    roas DECIMAL(10,2)
);

CREATE TABLE blinkit_order_items (
    order_id BIGINT,
    product_id BIGINT,
    quantity INT,
    price DECIMAL(10,2),

    PRIMARY KEY(order_id, product_id)
);

CREATE TABLE blinkit_orders (
    order_id BIGINT PRIMARY KEY,
    customer_id BIGINT,
    order_date TIMESTAMP,
    promised_delivery_time TIMESTAMP,
    actual_delivery_time TIMESTAMP,
    delivery_status VARCHAR(30),
    order_total DECIMAL(10,2),
    payment_method VARCHAR(20),
    delivery_partner_id BIGINT,
    store_id BIGINT
);

CREATE TABLE blinkit_products (
    product_id BIGINT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(100),
    brand VARCHAR(100),
    price DECIMAL(10,2),
    mrp DECIMAL(10,2),
    margin_percentage DECIMAL(5,2),
    shelf_life_days INT,
    min_stock_level INT,
    max_stock_level INT
);

--customer orders
SELECT
    c.customer_name,
    o.order_id,
    o.order_total
FROM blinkit_customers c
JOIN blinkit_orders o
ON c.customer_id = o.customer_id;

--customer review analysis
SELECT
    c.customer_name,
    f.rating,
    f.sentiment
FROM blinkit_customers c
JOIN blinkit_customer_feedback f
ON c.customer_id = f.customer_id;

--order details 
SELECT
    o.order_id,
    p.product_name,
    oi.quantity,
    mrp
FROM blinkit_orders o
JOIN blinkit_order_items oi
ON o.order_id = oi.order_id
JOIN blinkit_products p
ON oi.product_id = p.product_id;

--delivery analysis
SELECT
    o.order_id,
    d.delivery_time_minutes,
    d.delivery_status
FROM blinkit_orders o
JOIN blinkit_delivery_performance d
ON o.order_id = d.order_id;

--SALES ANALYSIS 
--Top Revenue Products
SELECT
    p.product_name,
    SUM(oi.quantity * oi.price) AS revenue
FROM blinkit_order_items oi
JOIN blinkit_products p
ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY revenue DESC;

--Best Selling Category
SELECT
    p.category,
    SUM(oi.quantity) AS units_sold
FROM blinkit_order_items oi
JOIN blinkit_products p
ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY units_sold DESC;

--Top Product in each Category 
WITH sales AS
(
SELECT
    p.category,
    p.product_name,
    SUM(oi.quantity) AS units_sold
FROM blinkit_order_items oi
JOIN blinkit_products p
ON oi.product_id = p.product_id
GROUP BY p.category,p.product_name
)

SELECT *
FROM
(
SELECT *,
       ROW_NUMBER() OVER
       (PARTITION BY category
        ORDER BY units_sold DESC) rn
FROM sales
) x
WHERE rn = 1;
--CUSTOMER ANALYSIS
--Top Customers By Spending 
SELECT
    c.customer_name,
    SUM(o.order_total) AS total_spent
FROM blinkit_customers c
JOIN blinkit_orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY total_spent DESC
LIMIT 10;

--DELIVERY ANALYSIS
--Avg Delivery Time
SELECT
    AVG(delivery_time_minutes)
FROM blinkit_delivery_performance;

--Delayed Orders %
SELECT
    ROUND(
    COUNT(*) FILTER
    (WHERE delivery_status='Slightly Delayed')
    *100.0/COUNT(*),
    2
    ) AS delayed_percentage
FROM blinkit_delivery_performance;

--CUSTOMER SATISFACTION 
--Average Rating
SELECT
    ROUND(AVG(rating),2)
FROM blinkit_customer_feedback;

--Sentiment Distribution
SELECT
    sentiment,
    COUNT(*) AS total
FROM blinkit_customer_feedback
GROUP BY sentiment;

--Delivery Delay VS Rating
SELECT
    d.delivery_status,
    ROUND(AVG(f.rating),2) AS avg_rating
FROM blinkit_delivery_performance d
JOIN blinkit_customer_feedback f
ON d.order_id = f.order_id
GROUP BY d.delivery_status;

--INVENTORY ANALYSIS 
--Products with Highest Damanged Stock
SELECT
    p.product_name,
    SUM(i.damaged_stock) AS damaged
FROM blinkit_inventory i
JOIN blinkit_products p
ON i.product_id = p.product_id
GROUP BY p.product_name
ORDER BY damaged DESC
LIMIT 10;

--Stock Health Analysis
SELECT
    product_name,
    min_stock_level,
    max_stock_level
FROM blinkit_products;