/*
=====================================================================================
DDL Scripts: Create Gold View
=====================================================================================
Script Purpose:
  This script creates the views for the 'Gold' layer in the data warehouse.
  The Gold layer represents the final dimension and fact table (Star Schema)

  Each view performs transformations and combines data from the Silver layer
  to create a clean, enriched and business-ready dataset.

Usage: This view can be queried directly for analytics and reporting
=====================================================================================
*/

-- =================================================================================
-- Create Dimension: gold.dim_customers
-- =================================================================================
CREATE VIEW gold.dim_customers AS
select 
	ROW_NUMBER () OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS firstname,
	ci.cst_lastname AS lastname,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE when ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master for gender info
	ELSE COALESCE (ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
from silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid
;

-- =================================================================================
-- Create Dimension: gold.dim_products
-- =================================================================================
CREATE VIEW gold.dim_products AS
select 
	ROW_NUMBER () OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id As category_id,
	pc.cat AS category,
	pc.subcat AS sub_category,
	pc.maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date,
	pn.prd_end_dt
from silver.crm_prod_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id 
where prd_end_dt IS NULL  --- Filter out all Historical Data
;

-- =================================================================================
-- Create Dimension: gold.fact_sales
-- =================================================================================
CREATE VIEW gold.fact_sales AS
select 
sd.sls_ord_num AS order_number,
pr.product_key,
cu.customer_key,
sd.sls_order_dt AS order_date,
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS sales_quantity,
sd.sls_price AS sales_price
from silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cst_id = cu.customer_id


-- Checking Foreign Key Integrity across Dimensions
select * 
from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key = f.customer_key
left join gold.dim_products p
on p.product_key = f.product_key
where p.product_key IS NULL

-- Usage Example: select* from gold.dim_products
