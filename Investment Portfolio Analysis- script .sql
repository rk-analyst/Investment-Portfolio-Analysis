USE invest;

-- TEAM 13
-- Authors
-- Marc Zürn
-- Rhea Kapoor
-- Tebatso Nyarambi

-- Create and delte views
-- DROP VIEW team13_12M_19;

-- CREATE VIEW with Customer 19s Portfolio
-- this only contains our clients data
CREATE VIEW team13_12M_19 AS
-- SELECT all interesting DATA
SELECT cd.customer_id, cd.full_name, hc.account_id, sm.id, sm.security_name, sm.ticker, sm.sp500_weight, sm.sec_type, sm.major_asset_class, 
		hc.quantity, pdn.date, pdn.value, 
	-- Use the LAG Function the add the price from 12M, 18M, 24M to the current price
        LAG (pdn.value, 250) OVER (
							PARTITION BY sm.ticker
							ORDER BY date)
                            as lagged_price, 
                            -- clean the database as the major asset classes are names badly sometimes
                            CASE
								WHEN major_asset_class = 'equty' THEN 'equity'
								WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
								WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							ELSE major_asset_class
                            END as n_major_asset_class
	-- JOIN the tables with each other
	FROM security_masterlist as sm
	JOIN pricing_daily_new as pdn
		ON sm.ticker = pdn.ticker
	JOIN holdings_current as hc
		ON hc.ticker = sm.ticker
	JOIN account_dim as ad
		ON ad.account_id = hc.account_id
 	JOIN customer_details as cd
 		ON cd.customer_id = ad.client_id
	-- Filter on the four customers we selected
	WHERE cd.customer_id IN ('19')
    -- Only use the Adjusted price
		AND pdn.price_type = 'Adjusted'
	ORDER BY date DESC;
    

-- CREATE VIEW over all securities
-- This view contains all securities, used to analyze the overall ROI,...
CREATE VIEW team13_12M_allSec AS
-- SELECT all interesting DATA
SELECT sm.id, sm.security_name, sm.ticker, sm.sp500_weight, sm.sec_type, sm.major_asset_class, pdn.date, pdn.value, 
	-- Use the LAG Function the add the price from 12M, 18M, 24M to the current price
        LAG (pdn.value, 250) OVER (
							PARTITION BY sm.ticker
							ORDER BY date)
                            as lagged_price, 
                            -- clean database as asset class naming is not good
                            CASE
								WHEN major_asset_class = 'equty' THEN 'equity'
								WHEN major_asset_class = 'fixed_income' THEN 'fixed income'
								WHEN major_asset_class = 'fixed income corporate' THEN 'fixed income'
							ELSE major_asset_class
                            END as n_major_asset_class
	-- JOIN the tables with each other
	FROM security_masterlist as sm
	JOIN pricing_daily_new as pdn
		ON sm.ticker = pdn.ticker
	WHERE pdn.price_type = 'Adjusted'
	ORDER BY date DESC;
    

-- Question 1 - What is the most recent 12M**, 18M, 24M (months) return for each of the securities?
SELECT customer_id, full_name, account_id, security_name, ticker, sec_type, major_asset_class, date, 
	-- Format the normal price and the lagged_price
	value as price, quantity, lagged_price, 
	-- Calculate the ROI
    (value - lagged_price) / lagged_price as decimalROI,
    -- Calculate the Profit and Loss per Stock
    (value - lagged_price) * quantity as ProfitLoss
	FROM team13_12M_19
    -- Only use the latest date from our view -- later we only use 2022-09-09 as fixed date
    WHERE date = (SELECT date
					FROM team13_12M_19
					ORDER BY date DESC
					LIMIT 1)
		AND lagged_price > 0 and value > 0
	ORDER BY customer_id, account_id;

    SELECT * FROM account_dim WHERE client_id IN ('19');

-- Question 1 - What is the most recent 12M**, 18M, 24M (months) return for each of the entire Portfolio?     
SELECT customer_id, full_name,
	-- Calulate the total Portfolio Value
	FORMAT(SUM(value*quantity),2) as value,  
   	-- Calulate the total Portfolio Value from 12M ago
	FORMAT(SUM(lagged_price*quantity),2) as prevValue, 
    -- Calulate the weighted ROI for the entire Portfolio
	ROUND((SUM(value*quantity) - SUM(lagged_price*quantity)) / SUM(lagged_price*quantity),4) as ROI,
	-- Calulate the differente in value for the entire Portfolio
	FORMAT(SUM(value*quantity) - SUM(lagged_price*quantity),2) as ProfitLoss
	FROM team13_12M_19
    -- Only use the latest date
	WHERE date = '2022-09-09'
	GROUP BY customer_id, full_name;

SELECT * FROM account_dim WHERE client_id IN ('121', '19', '720', '785');
    
-- What is the ROI on Major Asset Classes Overall
SELECT n_major_asset_class, 
	AVG(((value - lagged_price) / lagged_price)) as 'ROI', count(*) as amount
	FROM team13_12M_allSec
    -- Only use the latest date
    WHERE date = '2022-09-09'
		AND lagged_price > 0 and value > 0
GROUP BY n_major_asset_class
    ;    

-- What is the ROI on Major Asset Classes for our Portfolio
-- Calculate the weighted ROI for our portfolio based on the quantity
SELECT n_major_asset_class,  SUM( weightedROI ) / SUM(quantity), SUM(quantity) as ROI FROM (
SELECT n_major_asset_class, ticker, (value - lagged_price)/lagged_price as ROI, ((value - lagged_price)/lagged_price)*quantity as weightedROI, quantity
	FROM team13_12M_19
    -- Only use the latest date
    WHERE date = '2022-09-09'
		AND lagged_price > 0 and value > 0) as val
GROUP BY n_major_asset_class;
    
-- What is the RISK on Major Asset Classes Overall
SELECT n_major_asset_class, AVG(ret) as 12Mmu, STD(ret) as 12Msigma, STD(ret)*15.8113883008 as yearlySigma, AVG(ret)/STD(ret) as 12risk_adj_sigma
	FROM (SELECT ticker, n_major_asset_class, date, (value - lagged_price)/lagged_price AS ret
		FROM team13_12M_allSec
		-- Only use the latest date
		WHERE lagged_price > 0 and value > 0
		-- GROUP BY  n_major_asset_class
			AND date > '2022-09-01') as totSig
    GROUP BY n_major_asset_class
    ;
    
-- What is the RISK on all Asset on our Portfolio
SELECT ticker, AVG(ret) as 12Mmu, STD(ret) as 12Msigma, AVG(ret)/STD(ret) as 12risk_adj_sigma
	FROM (SELECT ticker, n_major_asset_class, date, (value - lagged_price)/lagged_price AS ret
	FROM team13_12M_19
    -- Only use the latest date
    WHERE lagged_price > 0 and value > 0
		AND date > '2021-09-09'
	-- GROUP BY ticker, n_major_asset_class
    ) as totSig
    GROUP BY ticker
    ;
    
-- What is the RISK on Major Asset Classes on our Portfolio
SELECT n_major_asset_class, AVG(12Mmu) as 12Mmu, 
	AVG(12Msigma)*15.8113883008 as yearlySigma, 
    AVG(12Msigma) as 12Msigma, 
    AVG(12risk_adj_sigma) as 12risk_adj_sigma
FROM (SELECT n_major_asset_class, ticker, AVG(ret) as 12Mmu, STD(ret) as 12Msigma, AVG(ret)/STD(ret) as 12risk_adj_sigma
	FROM (SELECT ticker, n_major_asset_class, date, (value - lagged_price)/lagged_price AS ret
	FROM team13_12M_19
    -- Only use the latest date
    WHERE lagged_price > 0 and value > 0
		AND date > '2021-09-09'
	-- GROUP BY ticker, n_major_asset_class
    ) as totSig
    GROUP BY n_major_asset_class, ticker) as tab
GROUP BY n_major_asset_class;

-- What to sell in our Portfolio
SELECT n_major_asset_class, ticker, (value - lagged_price)/lagged_price as ROI, ((value - lagged_price)/lagged_price)*quantity as weightedROI, quantity, value * quantity as MarketValue
	FROM team13_12M_19
    -- Only use the latest date
    WHERE date = '2022-09-09'
		AND lagged_price > 0 and value > 0
        AND n_major_asset_class IN ('equity')
	ORDER BY MarketValue DESC;
    
-- What to buy for our Portfolio
SELECT n_major_asset_class, ticker, (value - lagged_price)/lagged_price as ROI, value, lagged_price
	FROM team13_12M_AllSec
    -- Only use the latest date
    WHERE date = '2022-09-09'
		AND lagged_price > 0 and value > 0
        -- those to asset classes are to buy classes.
        AND n_major_asset_class IN ('fixed_income', 'alternatives')
        ORDER BY ROI DESC;

/* 
--------------------------------
SELECTING SAMPLE OF CUSTOMERS
--------------------------------
*/

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

-- Picking the sample: Selecting Top 4 clients with highest market value
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
--------------------------------
FINDING RETURNS AND CORRELATIONS
--------------------------------
*/

-- Calculating daily returns for all tickers
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


/* 
--------------------------------
MISCELLANEOUS
--------------------------------
*/

-- Getting price data for asset classes

SELECT MONTH(`date`), YEAR(`date`), IFNULL(ROUND(AVG(`value`),2),0), major_asset_class
FROM pricing_daily_new AS p
INNER JOIN security_masterlist AS s USING(ticker)
WHERE price_type = 'Adjusted'
GROUP BY MONTH(`date`), YEAR(`date`), major_asset_class ;


-- Evaluating Georgi's current portfolio

USE invest;

SELECT c.customer_id, c.full_name, s.ticker, s.security_name, quantity, value, h.date, s.sec_type, 
(CASE WHEN s.major_asset_class = 'equity' OR s.major_asset_class = 'equty' THEN 'Equity'
	 WHEN s.major_asset_class = 'fixed_income' OR s.major_asset_class = 'fixed income' THEN 'Fixed Income'	
     ELSE s.major_asset_class END) AS major_asset_class, 
value*quantity AS market_value
FROM  customer_details AS c
INNER JOIN account_dim AS a ON c.customer_id = a.client_id
INNER JOIN holdings_current AS h ON a.account_id = h.account_id
INNER JOIN security_masterlist AS s ON h.ticker = s.ticker
WHERE h.account_id IN (594, 59401, 59402) AND h.price_type = 'Adjusted'
GROUP BY major_asset_class, c.customer_id, s.ticker, s.security_name, quantity, value, h.date, s.sec_type;


        
