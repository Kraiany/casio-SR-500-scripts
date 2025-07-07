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
    WHERE timestamp LIKE '2025-02-%'
    GROUP BY 1, 2
)
GROUP BY hour_of_day
ORDER BY hour_of_day;
