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

-- select * from silver.erp_px_cat_g1v2;

--check for unwanted spaces
select * from bronze.erp_px_cat_g1v2
where cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- Check Dat Standardisation and Consistency
select distinct 
maintenance
from bronze.erp_px_cat_g1v2

