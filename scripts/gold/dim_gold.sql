USE [DataWarehouse];
GO
IF OBJECT_ID('gold.dim_customers', 'U') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) customer_key, --surrogate key
	ci.cst_id customer_id,
	ci.cst_key customer_number,
	ci.cst_firstname first_name,
	ci.cst_lastname last_name,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr --CRM is the master for gender info
	ELSE COALESCE(ca.gen,'n/a')
	END gender,
	ca.bdate birthdate,
	ci.cst_marital_status marital_status,
	la.cntry countery,
	ci.cst_create_date create_date
	
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid
GO 
IF OBJECT_ID('gold.dim_products', 'U') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) product_key, --surrogate key
	pn.prd_id product_id,
	pn.prd_key product_number, 
    pn.prd_nm product_name,
	pn.cat_id category_id, 
	pc.cat category,
    pc.subcat subcategory, 
    pc.maintenance maintenance,
	pn.prd_cost cost, 
	pn.prd_line product_line,
	pn.prd_start_dt product_start_date	 		
FROM [silver].[crm_prd_info] pn
LEFT JOIN [silver].[erp_px_cat_g1v2] pc
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL

GO
IF OBJECT_ID('gold.fact_sales', 'U') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO
CREATE VIEW gold.fact_sales AS
SELECT 
    sd.sls_ord_num AS order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt order_date, 
	sd.sls_ship_dt ship_date, 
	sd.sls_due_dt due_date, 
	sd.sls_sales  sales_amount, 
	sd.sls_quantity quantity, 
	sd.sls_price price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id

/* ---------------------------------
SELECT * FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE p.product_key IS NULL
--------------------------------- */
