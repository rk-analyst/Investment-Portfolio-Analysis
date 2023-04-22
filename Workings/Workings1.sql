USE invest;

-- Selecting all columns from first 3 tables
SELECT *
FROM customer_details AS c
INNER JOIN account_dim AS a on c.customer_id = a.client_id
INNER JOIN holdings_current AS h ON a.account_id = h.account_id;

-- Finding market value
SELECT c.customer_id, c.first_name, c.last_name, a.account_id, h.ticker, h.value, h.quantity, (h.value * h.quantity) AS market_value
FROM customer_details AS c
INNER JOIN account_dim AS a on c.customer_id = a.client_id
INNER JOIN holdings_current AS h ON a.account_id = h.account_id
WHERE h.price_type = 'Adjusted';

-- Picking the sample: Selecting Top 5 clients with highest market value and with only one account id for ease of analysis
SELECT c.customer_id, c.first_name, c.last_name, a.account_id, ROUND(SUM(h.value * h.quantity),2) AS market_value
FROM customer_details AS c
INNER JOIN account_dim AS a on c.customer_id = a.client_id
INNER JOIN holdings_current AS h ON a.account_id = h.account_id
WHERE h.price_type = 'Adjusted'
GROUP BY c.customer_id, c.first_name, c.last_name, a.account_id 
ORDER BY market_value DESC 
;

SELECT *
FROM customer_details
WHERE customer_id IN ('121', 19, 720, 785);

/*
-- Calculating average return ticker-wise for 12 months
WITH cte1 AS(
SELECT ticker, ROUND(AVG(`returns`),2) AS avg_return
FROM
(SELECT a.`date`, a.ticker, ROUND((a.value - a.lagged_price)/ a.lagged_price,2) AS `returns`
FROM
(SELECT *, LAG(value, 250) OVER(
							PARTITION BY ticker
                            ORDER BY `DATE`) AS lagged_price
FROM pricing_daily_new AS p
WHERE price_type= 'Adjusted'
) AS a) AS b
GROUP by ticker
ORDER BY avg_return DESC)
SELECT MAX(avg_return)
FROM cte1;


-- Max avg asset wise
WITH cte2 AS(
SELECT s.ticker, s.major_asset_class, s.minor_asset_class, ROUND(AVG(`returns`),2) AS avg_return
FROM
(SELECT a.`date`, a.ticker, ROUND((a.value - a.lagged_price)/ a.lagged_price,2) AS `returns`
FROM
(SELECT *, LAG(value, 250) OVER(
							PARTITION BY ticker
                            ORDER BY `DATE`) AS lagged_price
FROM pricing_daily_new AS p
WHERE price_type= 'Adjusted'
) AS a) AS b
INNER JOIN security_masterlist AS s USING(ticker)
GROUP by s.ticker, s.major_asset_class, s.minor_asset_class
ORDER BY avg_return DESC
)
SELECT ticker, MAX(avg_return), 'equity_large_cap' AS 'asset_type'
FROM cte2
WHERE major_asset_class= 'equity' AND minor_asset_class = 'large_cap'
GROUP by ticker
UNION
SELECT ticker, MAX(avg_return), 'equity_small_cap' AS 'asset_type'
FROM cte2
WHERE major_asset_class= 'equity' AND minor_asset_class = 'small_cap'
GROUP by ticker
UNION
SELECT ticker, MAX(avg_return), 'equity_emerging_mkts' AS 'asset_type'
FROM cte2
WHERE major_asset_class= 'equity' OR major_asset_class= 'equty'  AND minor_asset_class = 'emerging_markets'
GROUP by ticker
UNION
SELECT ticker, MAX(avg_return), 'equity_emerging_mkts' AS 'asset_type'
FROM cte2
WHERE major_asset_class= 'equity' AND minor_asset_class = 'emerging_markets'
GROUP by ticker
*/

-- Getting price data for asset classes

SELECT YEAR(`date`), AVG(`value`), major_asset_class
FROM pricing_daily_new AS p
INNER JOIN security_masterlist AS s USING(ticker)
WHERE price_type = 'Adjusted'
GROUP BY YEAR(`date`), major_asset_class ;

