/*
==============================================================================
Quality Checks
==============================================================================
Script Purpose:
  This script performs quality checks to validate the integrity, consistency,
  and accuracy of the Gold Layer. These checks ensure:
  - uniqueness of surrogate key to dimension tables
  - referential integrity between fact and dimensions tables
  - validation od relationships in the data model for analytic purposes

Usage Notes:
  - Run this checks after data loading Silver Layer
  - Investigate and resolve any discrepancies found during the checks
==============================================================================
*/
--=====================================================================
--Checking gold.dim_customer
--=====================================================================
Select 
  cutomer_key,
  count (*) AS duplicate_count
from gold.dim_customers
  group by customer_key
  having count(*) > 1;


--=====================================================================
--Checking gold.product_key
--=====================================================================
-- Check for uniqueness of Product Key in gold.dim_products
-- Expectations: no results
SELECT 
  product_key,
  count (*) as duplicate_count
from gold.dom_produts
  group by product_key
  having count(*) > 1;

--=====================================================================
--Checking gold.fact_sales
--=====================================================================
-- Check the data model connectivity between facts and dimensions
-- Checking Foreign Key Integrity across Dimensions
select * 
from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key = f.customer_key
left join gold.dim_products p
on p.product_key = f.product_key
where p.product_key IS NULL

select* from gold.dim_products
