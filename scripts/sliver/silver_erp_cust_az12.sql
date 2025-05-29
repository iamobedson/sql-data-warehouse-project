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
FROM bronze.erp_cust_az12
