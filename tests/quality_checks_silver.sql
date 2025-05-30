/*
=================================================================================
Quality Checks
=================================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardizaion across the 'silver' schemas. It includes checks for;
    - Null or duplicate Primary Key
    - Unwanted space in string fields
    - Data standardization and consisyency
    - Invalid date range and orders
    - Data consistency between related fields

Usage Note:
    -  Run this checks after loading Silver layer
    - Investigate and resolve any discrepancies found during the checks
=================================================================================
*/

-- Checking for NULL & Duplicates in Primary Key
-- Expectations: No result
select * from silver.crm_prod_info
Select 
prd_id,
COUNT(*)
from silver.crm_prod_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL


-- Check for Unwanted Spaces --
-- Expectation: No Results --
SELECT prd_nm
from silver.crm_prod_info
where prd_nm != TRIM(prd_nm);


--Cheack for NULL or negative numbers
--Expectation: No result
SELECT prd_cost
from silver.crm_prod_info
where prd_cost < 0 OR prd_cost IS NULL

-- Check Data Consistency & Standardization
--Expectation:No Result
SELECT DISTINCT prd_line
from silver.crm_prod_info

-- Check for Invalid Date Order --
SELECT * 
From silver.crm_prod_info
WHERE prd_end_dt < prd_start_dt

--Check for Invalid Date
SELECT
NULLIF (sls_order_dt, 0) sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt <= 0 OR LEN(sls_order_dt) != 8

-- Check for Invalid Date Order --
SELECT 
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

-- Check Data Consistency: Between Sales, Quantity, and Price
-->> Sales = Quantity * Price
-->> Values must not be NULL, zero, or negative

SELECT DISTINCT 
sls_sales as old_sls_sales,
sls_quantity,
sls_price as old_sls_price,
CASE WHEN sls_sales IS NULL or sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <=0
		THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price
END as sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price


--Identify Out of Range Dates in ERP cust table
SELECT DISTINCT
bdate 
FROM silver.erp_cust_az12
where bdate < '1924-01-01' OR bdate > GETDATE()

-- Data Standardization & COnsistency
SELECT distinct
CASE 
	WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	ELSE 'n/a'
END gen
from silver.erp_cust_az12
