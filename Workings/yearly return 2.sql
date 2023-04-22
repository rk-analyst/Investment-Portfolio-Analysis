USE invest;


CREATE VIEW yearly_returns_assets AS

(SELECT s.ticker, IFNULL(ROUND((`returns`),2),0) AS equity_return, '0' AS commodities_return, '0' AS fixed_income_return, 
'0' AS alternatives_return
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
WHERE (major_asset_class= 'equity' OR major_asset_class= 'equty') AND  `date` = '2022-09-09'
GROUP by s.ticker
ORDER BY equity_return DESC)

UNION 

(SELECT s.ticker, '0' AS equity_return, IFNULL(ROUND((`returns`),2),0) AS commodities_return, '0' AS fixed_income_return, 
'0' AS alternatives_return
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
WHERE major_asset_class= 'commodities' AND  `date` = '2022-09-09'
GROUP by s.ticker
ORDER BY commodities_return DESC)

UNION 

(SELECT s.ticker, '0' AS equity_return, '0' AS commodities_return, IFNULL(ROUND((`returns`),2),0) AS fixed_income_return, 
'0' AS alternatives_return
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
WHERE (major_asset_class= 'fixed_income'  OR major_asset_class= 'fixed income' OR major_asset_class= 'fixed income corporate') AND `date` = '2022-09-09'
GROUP by s.ticker
ORDER BY fixed_income_return DESC)

UNION 

(SELECT s.ticker, '0' AS equity_return, '0' AS commodities_return, '0' AS fixed_income_return, 
IFNULL(ROUND((`returns`),2),0) AS alternatives_return
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
WHERE major_asset_class= 'alternatives'  AND `date` = '2022-09-09'
GROUP by s.ticker
ORDER BY alternatives_return DESC);


/* Finding correlation between average returns of different asset classes. 
The formula for Pearson's correlation coefficient is covariance of two variables divided by the product of their standard deviations */
/*Equity vs commodities*/
-- First let us define some variables for inputting into our formula
SELECT 
    @avgeq:=AVG(`equity_return`),
    @avgcomm:=AVG(`commodities_return`),
    @divisor:=STDDEV_SAMP(`equity_return`) * STDDEV_SAMP(`commodities_return`)
FROM
    yearly_returns_assets
;


-- Now let us replace the defined variables in our formula for correlation
SELECT 
    ROUND((SUM((`equity_return` - @avgeq) * (commodities_return - @avgcomm)) / ((COUNT(equity_return) - 1) * @divisor)),
            2) AS corr_coeff
FROM
    yearly_returns_assets;


