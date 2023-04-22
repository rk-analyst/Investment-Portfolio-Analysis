USE invest;

USE invest;

CREATE VIEW t13_eq_ret AS

(SELECT IFNULL(ROUND(AVG(`returns`),2),0) AS equity_avg_return
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
ORDER BY equity_avg_return DESC);

CREATE VIEW t13_commodities_ret AS
(SELECT IFNULL(ROUND(AVG(`returns`),2),0) AS commodities_avg_return
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
ORDER BY commodities_avg_return DESC);

CREATE VIEW t13_fi_ret AS
(SELECT IFNULL(ROUND(AVG(`returns`),2),0) AS fixed_income_avg_return
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
ORDER BY fixed_income_avg_return DESC);

CREATE VIEW t13_alt_ret AS
(SELECT IFNULL(ROUND(AVG(`returns`),2),0) AS alternatives_avg_return
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
ORDER BY alternatives_avg_return DESC);

/* Finding correlation between average returns of different asset classes. 
The formula for Pearson's correlation coefficient is covariance of two variables divided by the product of their standard deviations */
-- First let us define some variables (set1) for inputting into our formula
SELECT 
	
 @avgeq:= (SELECT AVG(`equity_avg_return`) FROM t13_eq_ret),
 @avgcomm:=(SELECT AVG(`commodities_avg_return`) FROM t13_commodities_ret),
 @avgfi:=(SELECT AVG(`fixed_income_avg_return`) FROM t13_fi_ret),
 @avgalt:=(SELECT AVG(`alternatives_avg_return`) FROM t13_alt_ret),
 @divisor1:=((SELECT STDDEV_SAMP(`equity_avg_return`) FROM t13_eq_ret)) * ((SELECT STDDEV_SAMP(`commodities_avg_return`) FROM t13_commodities_ret)),
 @divisor2:=((SELECT STDDEV_SAMP(`equity_avg_return`) FROM t13_eq_ret)) * ((SELECT STDDEV_SAMP(`fixed_income_avg_return`) FROM t13_fi_ret)),
 @divisor3:=((SELECT STDDEV_SAMP(`equity_avg_return`) FROM t13_eq_ret)) * ((SELECT STDDEV_SAMP(`alternatives_avg_return`) FROM t13_alt_ret)),
 @divisor4:=((SELECT STDDEV_SAMP(`commodities_avg_return`) FROM t13_commodities_ret)) * ((SELECT STDDEV_SAMP(`alternatives_avg_return`) FROM t13_alt_ret)),
 @divisor5:=((SELECT STDDEV_SAMP(`commodities_avg_return`) FROM t13_commodities_ret)) * ((SELECT STDDEV_SAMP(`fixed_income_avg_return`) FROM t13_fi_ret)),
 @divisor6:=((SELECT STDDEV_SAMP(`alternatives_avg_return`) FROM t13_alt_ret)) * ((SELECT STDDEV_SAMP(`fixed_income_avg_return`) FROM t13_fi_ret));
    
  SELECT  @eqavgdiff:= (equity_avg_return  - (@avgeq)) FROM t13_eq_ret;
  SELECT  @commavgdiff:= (commodities_avg_return  - (@avgcomm)) FROM t13_commodities_ret;
  SELECT  @fiavgdiff:= (fixed_income_avg_return  - (@avgfi)) FROM t13_fi_ret;
  SELECT  @altavgdiff:= (alternatives_avg_return  - (@avgalt)) FROM t13_alt_ret;

;
-- Calculating correlation coefficient by replacing above variables into the formula

/* EQUITY VS COMMODITIES*/
SELECT 
    ROUND(((SUM(@eqavgdiff) * SUM(@commavgdiff ))
    / 
(((SELECT COUNT(equity_avg_return) FROM t13_eq_ret) - 1) * @divisor1)),
            2) AS corr_coeff_ec

;

/* EQUITY VS FIXED INCOME*/
SELECT 
    ROUND(((SUM(@eqavgdiff) * SUM(@fiavgdiff ))
    / 
(((SELECT COUNT(equity_avg_return) FROM t13_eq_ret) - 1) * @divisor2)),
            2) AS corr_coeff_ef

;

/* EQUITY VS ALTERNATIVES*/
SELECT 
    ROUND(((SUM(@eqavgdiff) * SUM(@altavgdiff ))
    / 
(((SELECT COUNT(equity_avg_return) FROM t13_eq_ret) - 1) * @divisor3)),
            2) AS corr_coeff_ea

;

/* COMMODITIES VS ALTERNATIVES*/
SELECT 
    ROUND(((SUM(@commavgdiff) * SUM(@altavgdiff ))
    / 
(((SELECT COUNT(commodities_avg_return) FROM t13_commodities_ret) - 1) * @divisor4)),
            2) AS corr_coeff_ca

;

/* COMMODITIES VS FIXED INCOME*/
SELECT 
    ROUND(((SUM(@commavgdiff) * SUM(@fiavgdiff ))
    / 
(((SELECT COUNT(commodities_avg_return) FROM t13_commodities_ret) - 1) * @divisor5)),
            2) AS corr_coeff_cf

;

/* ALTERNATIVES VS FIXED INCOME*/
SELECT 
    ROUND(((SUM(@altavgdiff) * SUM(@fiavgdiff ))
    / 
(((SELECT COUNT(alternatives_avg_return) FROM t13_alt_ret) - 1) * @divisor6)),
            2) AS corr_coeff_cf

;

