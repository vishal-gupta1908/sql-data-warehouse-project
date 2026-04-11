/*
================================================================================
DDL SCRIPT: Create Bronze Tables
================================================================================
PURPOSE: Creates tables in the 'bronze' schema for the data warehouse
DESCRIPTION: Drops existing tables and creates 6 new tables (3 CRM, 3 ERP)
PREREQUISITES: SQL Server access with CREATE/DROP TABLE permissions
RUN: Execute this entire script in SQL Server Management Studio
================================================================================
*/

-- Create schema if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
	CREATE SCHEMA bronze;

PRINT 'Creating CRM Tables...';

-- ============================================================================
-- CRM TABLES
-- ============================================================================

IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info(
	cst_id int,
	sct_key nvarchar(50),
	cst_firstname nvarchar(50),
	cst_lastname nvarchar(50),
	cst_material_status nvarchar(50),
	cst_gndr nvarchar(50),
	cst_create_date date
);

IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info(
	prd_id int,
	prd_key nvarchar(50),
	prd_nm nvarchar(50),
	prd_cost int,
	prd_line nvarchar(50),
	prd_start_dt Date,
	prd_end_dt Date
);

IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details(
	sls_ord_num nvarchar(50),
	sls_prd_key nvarchar(50),
	sls_cust_id int,
	sls_order_id int,
	sls_ship_dt Date,
	sls_due_dt Date,
	sls_slaes int,
	sls_quantity int,
	sls_price int
);

PRINT 'Creating ERP Tables...';

-- ============================================================================
-- ERP TABLES
-- ============================================================================

IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
	DROP TABLE bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101 (
	cid NVARCHAR(50),
	cntry NVARCHAR(50)
);

IF OBJECT_ID('bronze.erp_just_az12', 'U') IS NOT NULL
	DROP TABLE bronze.erp_just_az12;
CREATE TABLE bronze.erp_just_az12 (
	cid NVARCHAR(50),
	bdate DATE,
	gen NVARCHAR(50)
);

IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
	DROP TABLE bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2 (
	id NVARCHAR(50),
	cat NVARCHAR(50),
	subcat NVARCHAR(50),
	maintenance NVARCHAR(50)
);

PRINT 'All Bronze tables created successfully!';
