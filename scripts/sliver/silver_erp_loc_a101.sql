/*
This Script inserts cleaned & transformed data from the Bronze ERP Locations table 
into the Silver ERP locations table  
*/
INSERT INTO silver.erp_loc_a101
(cid, cntry)
SELECT
REPLACE(cid, '-', '') cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101;


/* The data standards checks were done using this script before it was updated in the above*/

-- Data Standardization & Consistency Checks
SELECT DISTINCT cntry as old_cntry,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;
