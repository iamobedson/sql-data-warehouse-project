/* 
Data transformation & data cleansing of the Silver Customer Table
*/
Print '>> Truncate the Table to avoid duplication'
TRUNCATE TABLE silver.crm_cust_info;
Print '>> Inserting Data into: Silver.crm_cust_info2 Table'
INSERT INTO silver.crm_cust_info(
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_material_status,
cst_gndr,
cst_create_date
)
SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	CASE WHEN UPPER(TRIM(cst_material_status))= 'S' THEN 'Single'
		 WHEN UPPER(TRIM(cst_material_status))= 'M' THEN 'Married'
		 ELSE 'n/a'
	END cst_marital_status,
	CASE WHEN UPPER(TRIM(cst_gndr)) ='F' THEN 'Female'
		 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		 ELSE 'n/a'
	END cst_gndr,
	cst_create_date
	FROM(
		SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
		from bronze.crm_cust_info
		where cst_id IS NOT NULL
)t where flag_last = 1;

/*
This code transforms/cleans and inserts the cleaned date into the Silver CRM Product Table
*/
Print '>> Truncate the Table to avoid duplication'
TRUNCATE TABLE silver.crm_prod_info;
Print '>> Inserting Data into: Silver.crm_prod_info Table'
INSERT INTO silver.crm_prod_info(
	prd_id,
	cat_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line,
	prd_start_dt,
	prd_end_dt
)

SELECT 
prd_id,
REPLACE (SUBSTRING(prd_key,1,5), '-', '_') AS cat_id, --Extract Category ID
SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,       --Extract Product Key
prd_nm,
ISNULL (prd_cost, 0) AS prd_cost, 
CASE UPPER(TRIM(prd_line))							-- Map product line codes to descriptive value
	WHEN 'M' THEN 'Mountain'
	WHEN 'R' THEN 'Road'
	WHEN 'S' THEN 'Other Sales'
	WHEN 'T' THEN 'Touring'
	ELSE 'n/a'
 END AS prd_line,
CAST(prd_start_dt AS DATE) AS prd_start_dt,			-- Calculate the product end date as one day before the product start date
CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
FROM bronze.crm_prod_info
;

/* 
This code transforms/cleans and inserts the cleaned date into the Silver CRM Sales Table
*/
Print '>> Truncate the Table to avoid duplication'
TRUNCATE TABLE silver.crm_sales_details;
Print '>> Inserting Data into: Silver.crm_sales_details Table'
INSERT INTO silver.crm_sales_details (
	sls_ord_num,
	sls_prd_key,
	sls_cst_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cst_id,
CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
END AS sls_order_dt,				-- Cast order Date from String to DATE variable
CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
END AS sls_ship_dt,				-- Cast shipping Date from String to DATE variable
CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
	 ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
END AS sls_due_dt,				-- Cast due Date from String to DATE variable
CASE WHEN sls_sales IS NULL or sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END AS sls_sales, 				-- Recalculate Sales if Original Value is Mission or incorrect
sls_quantity,
CASE WHEN sls_price IS NULL OR sls_price <=0
		THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price
END as sls_price 				-- Derive Price if the original value is invalid
FROM bronze.crm_sales_details
;

/*
This script cleans and inserts data into the ERP Cust table
*/
Print '>> Truncate table to avoid duplication'
TRUNCATE TABLE silver.erp_cust_az12;
Print '>> Insert cleaned data into: Silver.erp_cust_az12'
INSERT INTO silver.erp_cust_az12(
cid,
bdate,
gen
)
SELECT
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Remove 'NAS' prefix if present
	ELSE cid
END cid,
CASE WHEN bdate > GETDATE() THEN NULL
	ELSE bdate
END bdate,						-- Set future birthdate to NULL
CASE 
	WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	ELSE 'n/a'
END gen							-- Normalise gender values and handle unknown cases
FROM bronze.erp_cust_az12;

/*
This Script inserts cleaned & transformed data from the Bronze ERP Locations table 
into the Silver ERP locations table  
*/
Print '>> Truncate table to avoid duplication'
TRUNCATE TABLE silver.erp_loc_a101;
Print '>> Insert cleaned data into: Silver-erp_loc table'
INSERT INTO silver.erp_loc_a101
(cid, cntry)
SELECT
REPLACE(cid, '-', '') cid,				-- Remove the '-' from the cid --
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	ELSE TRIM(cntry)
END AS cntry						-- Normalise and Handle missing or blank country codes
FROM bronze.erp_loc_a101;

/*
First, truncate, then insert the clean data into the Silver ERP PX-CAT table
After checking to ensure the data meets quality checks using the codes from line 23 downwards
*/
Print '>> Truncate the Table to avoid duplication'
TRUNCATE TABLE silver.erp_px_cat_g1v2;
Print '>> Inserting Data into: Silver.erp_px_cat_g1v2 Table'
INSERT INTO silver.erp_px_cat_g1v2(
id,
cat,
subcat,
maintenance
)
SELECT 
id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_g1v2;
