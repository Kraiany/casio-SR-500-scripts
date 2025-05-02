# SQL reports

Collection of SQL queries for produccing reports from slite3 DB of Casio POS orders


/* Daily amount */
-- SELECT date, SUM(total_amount) from orders AS daily_total GROUP BY date ORDER BY date;


/*
sum of the products per hour, assuming the "sum of the products"
refers to the sum of the price for each product within each hour
*/

SELECT
    CAST(strftime('%H', timestamp) AS INTEGER) AS hour_of_day,
    product,
    COUNT(*) AS number_of_products,
    SUM(price) AS total_price_per_hour
FROM items
GROUP BY hour_of_day, product
ORDER BY hour_of_day, product;


-- 2
-- Загальна сума за місяць погодинно
---------------------------------
-- >> Години після 17ї - тільки вихідні і п'ятниця

SELECT
    CAST(strftime('%H', timestamp) AS INTEGER) AS hour_of_day,
    SUM(price) AS total_amount_per_hour
FROM items
GROUP BY hour_of_day
ORDER BY  hour_of_day

/****************************************************************************************/
/* Обрахунок середньої погодинної виручки за місяць. З врахуванням
кількості робочих днів, коли є продажі в ці години (тобто з
врахуванням подовжених годин в п'ятницю-неділю) */

SELECT
    CAST(strftime('%H', timestamp) AS INTEGER) AS hour_of_day,
    CAST(SUM(price) * 1.0 / COUNT(DISTINCT strftime('%w', timestamp) || DATE(timestamp)) AS INTEGER) AS average_total_price_int
FROM items
GROUP BY hour_of_day
ORDER BY hour_of_day;
/****************************************************************************************/



-- ******************************************************************
/* Обрахунок середньої погодинної виручки за місяць з розбивкою по
днях тижня. З врахуванням кількості робочих днів, коли є продажі в ці
години (тобто з врахуванням подовжених годин в п'ятницю-неділю) */
----------------------------------------------------------------------------------------
-- TODO Треба перевірити
----------------------------------------------------------------------------------------
SELECT
    hour_of_day,
    CAST(AVG(CASE WHEN day_of_week = '0' THEN total_price END) * 1.0 / COUNT(DISTINCT CASE WHEN day_of_week = '0' THEN order_date END) AS INTEGER) AS sunday,
    CAST(AVG(CASE WHEN day_of_week = '1' THEN total_price END) * 1.0 / COUNT(DISTINCT CASE WHEN day_of_week = '1' THEN order_date END) AS INTEGER) AS monday,
    CAST(AVG(CASE WHEN day_of_week = '2' THEN total_price END) * 1.0 / COUNT(DISTINCT CASE WHEN day_of_week = '2' THEN order_date END) AS INTEGER) AS tuesday,
    CAST(AVG(CASE WHEN day_of_week = '3' THEN total_price END) * 1.0 / COUNT(DISTINCT CASE WHEN day_of_week = '3' THEN order_date END) AS INTEGER) AS wednesday,
    CAST(AVG(CASE WHEN day_of_week = '4' THEN total_price END) * 1.0 / COUNT(DISTINCT CASE WHEN day_of_week = '4' THEN order_date END) AS INTEGER) AS thursday,
    CAST(AVG(CASE WHEN day_of_week = '5' THEN total_price END) * 1.0 / COUNT(DISTINCT CASE WHEN day_of_week = '5' THEN order_date END) AS INTEGER) AS friday,
    CAST(AVG(CASE WHEN day_of_week = '6' THEN total_price END) * 1.0 / COUNT(DISTINCT CASE WHEN day_of_week = '6' THEN order_date END) AS INTEGER) AS saturday
FROM (
    SELECT
        CAST(strftime('%H', timestamp) AS INTEGER) AS hour_of_day,
        strftime('%w', timestamp) AS day_of_week,
        DATE(timestamp) AS order_date,
        SUM(price) AS total_price
    FROM items
    GROUP BY 1, 2, 3
)
GROUP BY hour_of_day
ORDER BY hour_of_day;
-- ******************************************************************


-- ******************************************************************
/* Сума виручки погодинно і по днях тижня за весь місяць */

SELECT
    hour_of_day,
    CAST(AVG(CASE WHEN day_of_week = '0' THEN total_price ELSE NULL END) AS INTEGER) AS sunday,
    CAST(AVG(CASE WHEN day_of_week = '1' THEN total_price ELSE NULL END) AS INTEGER) AS monday,
    CAST(AVG(CASE WHEN day_of_week = '2' THEN total_price ELSE NULL END) AS INTEGER) AS tuesday,
    CAST(AVG(CASE WHEN day_of_week = '3' THEN total_price ELSE NULL END) AS INTEGER) AS wednesday,
    CAST(AVG(CASE WHEN day_of_week = '4' THEN total_price ELSE NULL END) AS INTEGER) AS thursday,
    CAST(AVG(CASE WHEN day_of_week = '5' THEN total_price ELSE NULL END) AS INTEGER) AS friday,
    CAST(AVG(CASE WHEN day_of_week = '6' THEN total_price ELSE NULL END) AS INTEGER) AS saturday
FROM (
    SELECT
        CAST(strftime('%H', timestamp) AS INTEGER) AS hour_of_day,
        strftime('%w', timestamp) AS day_of_week,
        SUM(price) AS total_price
    FROM items
    GROUP BY 1, 2
)
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- ******************************************************************

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

/* with month */
SELECT
    CAST(strftime('%m', timestamp) AS INTEGER) AS month_number,
    CAST(strftime('%H', timestamp) AS INTEGER) AS hour_of_day,
    product,
    COUNT(*) AS number_of_products,
    SUM(price) AS total_price_per_hour
FROM items
GROUP BY hour_of_day, product
ORDER BY hour_of_day, product;





/* subtotals by product*/

SELECT product, sum(price) as sub_total from items group by product order by sub_total desc;

 SELECT product, count(*) AS number_of_purchases, sum(price) AS sub_total
FROM items
GROUP BY product
ORDER BY sub_total DESC;

/* totals by weekday */

SELECT
    CAST(strftime('%w', timestamp) AS INTEGER) hour_of_day AS    product,
    COUNT(*) AS number_of_products,
    SUM(price) AS total_price
FROM items
GROUP hour_of_day, product ORDER BY hour_of_day, product;



/* Number orders per day and DoW */
SELECT timestamp, date, count(timestamp) as orders, strftime("%w",timestamp) as dow from orders group by date


/* Orders count, total per day */
SELECT date,
       COUNT(timestamp) AS orders_count,
       SUM(total_amount) AS total,
       strftime("%w",date) AS dow
       FROM orders GROUP BY date
       ORDER BY date ASC;


-- ****************************************************************************************
SELECT * FROM (
SELECT
    CAST(strftime('%H', timestamp) AS INTEGER) AS hour_of_day,
         strftime('%w', timestamp) AS day_of_week,
         DATE(timestamp) AS order_date,
         SUM(price) AS total_price
     FROM items
     GROUP BY 1, 2, 3
     )
 where day_of_week = '4'
 and hour_of_day = 17;
