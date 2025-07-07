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
        COALESCE(SUM(price),0) AS total_price
    FROM items
    where timestamp like '2025-03-%'
    GROUP BY 1, 2, 3
)
GROUP BY hour_of_day
ORDER BY hour_of_day;
