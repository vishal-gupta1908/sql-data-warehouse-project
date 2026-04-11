/*
================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
================================================================================

Script Purpose:
	This stored procedure loads data into the 'bronze' schema from external CSV files.
	It performs the following actions:
	- Truncates the bronze tables before loading data.
	- Uses the 'BULK INSERT' command to load data from csv files to bronze tables.
	- Tracks load duration for CRM and ERP tables separately.
	- Provides detailed error handling and logging.

Parameters:
	None.
	This stored procedure does not accept any parameters or return any values.

Usage Example:
	EXEC bronze.load_bronze;

Prerequisites:
	- Bronze schema and tables must exist
	- CSV files must be present at the specified file paths
	- File paths must be accessible to SQL Server service account
	- User must have EXECUTE permission on the procedure

Output:
	- Prints progress messages and load durations to console
	- On error: prints error message, error number, and error state

================================================================================
*/

Create or Alter Procedure bronze.load_bronze as
Begin
	Declare @start_time Datetime, @end_time Datetime, @batch_start_time Datetime, @batch_end_time Datetime;
	
	BEGIN TRY
		set @start_time = GETDATE();
		
		print '=================================================='
		print 'Loading Bronze Layer'
		print '=================================================='
		print ''
		
		-- Load CRM Tables
		print '>> Loading CRM Tables'
		set @batch_start_time = GETDATE();
		
		Truncate Table bronze.crm_cust_info
		Bulk Insert bronze.crm_cust_info
		from 'F:\SQL Practice\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		with(Firstrow = 2, Fieldterminator = ',', tablock);
		
		Truncate Table bronze.crm_prd_info
		Bulk Insert bronze.crm_prd_info
		from 'F:\SQL Practice\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		with(Firstrow = 2, Fieldterminator = ',', tablock);
		
		Truncate Table bronze.crm_sales_details
		Bulk Insert bronze.crm_sales_details
		from 'F:\SQL Practice\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		with(Firstrow = 2, Fieldterminator = ',', tablock);
		
		set @batch_end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR(10)) + ' seconds'
		print '>> ---------------'
		print ''
		
		-- Load ERP Tables
		print '>> Loading ERP Tables'
		set @batch_start_time = GETDATE();
		
		TRUNCATE TABLE bronze.erp_loc_a101;
		Bulk Insert bronze.erp_loc_a101
		from 'F:\SQL Practice\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		with(Firstrow = 2, Fieldterminator = ',', tablock);
		
		TRUNCATE TABLE bronze.erp_just_az12;
		Bulk Insert bronze.erp_just_az12
		from 'F:\SQL Practice\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		with(Firstrow = 2, Fieldterminator = ',', tablock);
		
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		Bulk Insert bronze.erp_px_cat_g1v2
		from 'F:\SQL Practice\dbc9660c89a3480fa5eb9bae464d6c07\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		with(Firstrow = 2, Fieldterminator = ',', tablock);
		
		set @batch_end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR(10)) + ' seconds'
		print '>> ---------------'
		print ''
		
		set @end_time = GETDATE();
		
		print '=================================================='
		print 'Loading Bronze Layer - Completed'
		print '>> Total Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR(10)) + ' seconds'
		print '=================================================='
		
	END TRY
	BEGIN CATCH
		PRINT '======================================================'
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message: ' + ERROR_MESSAGE();
		PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
		PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR(10));
		PRINT '======================================================'
	END CATCH
End
