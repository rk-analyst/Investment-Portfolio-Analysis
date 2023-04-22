USE invest ;

-- Calculating returns
SELECT a.`date`, a.ticker, ROUND((a.value - a.lagged_price)/ a.lagged_price,2) AS `returns`
FROM
(SELECT *, LAG(value, 1) OVER(
							PARTITION BY ticker
                            ORDER BY `DATE`) AS lagged_price
FROM pricing_daily_new
WHERE price_type= 'Adjusted'
LIMIT 5000
) AS a
; 


-- Calculating average return ticker-wise for 12 months
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
ORDER BY avg_return DESC
; 

-- Calculating average return ticker-wise for 12 months for asset classes
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
; 

-- Finding distinct major asset classes
SELECT DISTINCT major_asset_class
FROM security_masterlist;

-- Creating view for major asset classes to find correlation between asset classes

CREATE VIEW average_return_groups AS

(SELECT s.ticker, IFNULL(ROUND(AVG(`returns`),2),0) AS equity_avg_return, '0' AS commodities_avg_return, '0' AS fixed_income_avg_return, 
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

(SELECT s.ticker, '0' AS equity_avg_return, IFNULL(ROUND(AVG(`returns`),2),0) AS commodities_avg_return, '0' AS fixed_income_avg_return, 
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

UNION 

(SELECT s.ticker, '0' AS equity_avg_return, '0' AS commodities_avg_return, IFNULL(ROUND(AVG(`returns`),2),0) AS fixed_income_avg_return, 
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
WHERE (major_asset_class= 'fixed_income'  OR major_asset_class= 'fixed income' OR major_asset_class= 'fixed income corporate') 
AND `date` >= '2021-09-09'
GROUP by s.ticker
ORDER BY equity_avg_return DESC)

UNION 

(SELECT s.ticker, '0' AS equity_avg_return, '0' AS commodities_avg_return, '0' AS fixed_income_avg_return, 
IFNULL(ROUND(AVG(`returns`),2),0) AS alternatives_avg_return
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
WHERE major_asset_class= 'alternatives'  AND `date` >= '2021-09-09'
GROUP by s.ticker
ORDER BY equity_avg_return DESC);

/* Finding correlation between average returns of different asset classes. 
The formula for Pearson's correlation coefficient is covariance of two variables divided by the product of their standard deviations */
/*Equity vs commodities*/
-- First let us define some variables for inputting into our formula
SELECT 
    @avgeq:=AVG(`equity_avg_return`),
    @avgcomm:=AVG(`commodities_avg_return`),
    @divisor:=STDDEV_SAMP(`equity_avg_return`) * STDDEV_SAMP(`commodities_avg_return`)
FROM
    average_return_groups
;


-- Now let us replace the defined variables in our formula for correlation
SELECT 
    ROUND((SUM((`equity_avg_return` - @avgeq) * (commodities_avg_return - @avgcomm)) / ((COUNT(equity_avg_return) - 1) * @divisor)),
            2) AS corr_coeff
FROM
    average_return_groups;

/*Equity vs fixed income*/
-- First let us define some variables for inputting into our formula
SELECT 
    @avgeq:=AVG(`equity_avg_return`),
    @avgfi:=AVG(`fixed_income_avg_return`),
    @divisor:=STDDEV_SAMP(`equity_avg_return`) * STDDEV_SAMP(`fixed_income_avg_return`)
FROM
    average_return_groups
;


-- Now let us replace the defined variables in our formula for correlation
SELECT 
    ROUND((SUM((`equity_avg_return` - @avgeq) * (fixed_income_avg_return - @avgfi)) / ((COUNT(equity_avg_return) - 1) * @divisor)),
            2) AS corr_coeff
FROM
    average_return_groups;

/*Equity vs alternatives*/
-- First let us define some variables for inputting into our formula
SELECT 
    @avgeq:=AVG(`equity_avg_return`),
    @avgalt:=AVG(`alternatives_avg_return`),
    @divisor:=STDDEV_SAMP(`equity_avg_return`) * STDDEV_SAMP(`alternatives_avg_return`)
FROM
    average_return_groups
;


-- Now let us replace the defined variables in our formula for correlation
SELECT 
    ROUND((SUM((`equity_avg_return` - @avgeq) * (alternatives_avg_return - @avgalt)) / ((COUNT(equity_avg_return) - 1) * @divisor)),
            2) AS corr_coeff
FROM
    average_return_groups;

/*Commodities vs alternatives*/
-- First let us define some variables for inputting into our formula
SELECT 
    @avgcomm:=AVG(`commodities_avg_return`),
    @avgalt:=AVG(`alternatives_avg_return`),
    @divisor:=STDDEV_SAMP(`commodities_avg_return`) * STDDEV_SAMP(`alternatives_avg_return`)
FROM
    average_return_groups
;


-- Now let us replace the defined variables in our formula for correlation
SELECT 
    ROUND((SUM((`commodities_avg_return` - @avgcomm) * (alternatives_avg_return - @avgalt)) / ((COUNT(commodities_avg_return) - 1) * @divisor)),
            2) AS corr_coeff
FROM
    average_return_groups;
    
/*Commodities vs fixed_income*/
-- First let us define some variables for inputting into our formula
SELECT 
    @avgcomm:=AVG(`commodities_avg_return`),
    @avgfi:=AVG(`fixed_income_avg_return`),
    @divisor:=STDDEV_SAMP(`commodities_avg_return`) * STDDEV_SAMP(`fixed_income_avg_return`)
FROM
    average_return_groups
;


-- Now let us replace the defined variables in our formula for correlation
SELECT 
    ROUND((SUM((`commodities_avg_return` - @avgcomm) * (fixed_income_avg_return - @avgfi)) / ((COUNT(commodities_avg_return) - 1) * @divisor)),
            2) AS corr_coeff
FROM
    average_return_groups;
    
/*alternatives vs fixed_income*/
-- First let us define some variables for inputting into our formula
SELECT 
    @avgalt:=AVG(`alternatives_avg_return`),
    @avgfi:=AVG(`fixed_income_avg_return`),
    @divisor:=STDDEV_SAMP(`alternatives_avg_return`) * STDDEV_SAMP(`fixed_income_avg_return`)
FROM
    average_return_groups
;


-- Now let us replace the defined variables in our formula for correlation
SELECT 
    ROUND((SUM((`alternatives_avg_return` - @avgalt) * (fixed_income_avg_return - @avgfi)) / ((COUNT(alternatives_avg_return) - 1) * @divisor)),
            2) AS corr_coeff
FROM
    average_return_groups;




