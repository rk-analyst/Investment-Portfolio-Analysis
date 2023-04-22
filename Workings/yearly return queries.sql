USE invest ;

-- Calculating returns
SELECT a.`date`, a.ticker, IFNULL(ROUND((a.value - a.lagged_price)/ a.lagged_price,2),0) AS `returns`
FROM
(SELECT *, LAG(value, 250) OVER(
							PARTITION BY ticker
                            ORDER BY `DATE`) AS lagged_price
FROM pricing_daily_new
WHERE price_type= 'Adjusted'
) AS a
; 

-- Calculating yearly return ticker-wise for 12 months
SELECT ticker, IFNULL(ROUND((`returns`),2),0) AS yearly_return
FROM
(SELECT a.`date`, a.ticker, IFNULL(ROUND((a.value - a.lagged_price)/ a.lagged_price,2),0) AS `returns`
FROM
(SELECT *, LAG(value, 250) OVER(
							PARTITION BY ticker
                            ORDER BY `DATE`) AS lagged_price
FROM pricing_daily_new
WHERE price_type= 'Adjusted'
) AS a)
 AS b
WHERE `date` = '2022-09-09'
GROUP by ticker
ORDER BY yearly_return DESC
; 

-- Calculating yearly return ticker-wise for 12 months for asset classes
SELECT s.ticker, s.major_asset_class, s.minor_asset_class, IFNULL(ROUND((`returns`),2),0) AS yearly_return
FROM
(SELECT a.`date`, a.ticker, IFNULL(ROUND((a.value - a.lagged_price)/ a.lagged_price,2),0) AS `returns`
FROM
(SELECT *, LAG(value, 250) OVER(
							PARTITION BY ticker
                            ORDER BY `DATE`) AS lagged_price
FROM pricing_daily_new
WHERE price_type= 'Adjusted'
) AS a)
 AS b
INNER JOIN security_masterlist AS s USING(ticker)
WHERE `date` = '2022-09-09'
GROUP by s.ticker, s.major_asset_class, s.minor_asset_class
ORDER BY yearly_return DESC
; 

-- Finding distinct major asset classes
SELECT DISTINCT major_asset_class
FROM security_masterlist;

/* ---------------------------------------- */

USE invest;

(SELECT s.ticker, ROUND(AVG(`returns`),2) AS equity_avg_return, '0' AS commodities_avg_return, '0' AS fixed_income_avg_return, 
'0' AS alternatives_avg_return
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
WHERE (major_asset_class= 'equity' OR major_asset_class= 'equty') AND `date` >= '2021-09-09'
GROUP by s.ticker
ORDER BY equity_avg_return DESC)

UNION 

(SELECT s.ticker, '0' AS equity_avg_return, ROUND(AVG(`returns`),2) AS commodities_avg_return, '0' AS fixed_income_avg_return, 
'0' AS alternatives_avg_return
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
WHERE major_asset_class= 'commodities' AND `date` >= '2021-09-09'
GROUP by s.ticker
ORDER BY equity_avg_return DESC)





