-- ═══════════════════════════════════════════════════════════════════════════════════
-- STORED PROCEDURE: Load Silver Layer (Bronze → Silver)
-- ═══════════════════════════════════════════════════════════════════════════════════
--
-- Purpose:
--    This stored procedure performs the complete ETL (Extract, Transform, Load) process
--    to populate the 'silver' schema tables from the 'bronze' schema with cleansed and
--    transformed data.
--
-- Actions Performed:
--    • Truncates all silver layer tables
--    • Extracts raw data from bronze schema
--    • Applies data transformations and business logic
--    • Loads cleaned data into silver schema
--    • Logs execution time for each table load
--    • Implements error handling with detailed error messages
--
-- Parameters:
--    None - This procedure does not accept parameters or return values
--
-- Execution:
--    EXEC silver.load_silver;

-- ═══════════════════════════════════════════════════════════════════════════════════


CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

    DECLARE @start_time DATETIME;
    DECLARE @end_time DATETIME;
    DECLARE @batch_start_time DATETIME;
    DECLARE @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        
        PRINT '═══════════════════════════════════════════════════════════════';
        PRINT 'SILVER LAYER LOAD PROCESS STARTED';
        PRINT '═══════════════════════════════════════════════════════════════';
        PRINT '';

        -- ───────────────────────────────────────────────────────────────────
        -- SECTION 1: LOAD CRM TABLES
        -- ───────────────────────────────────────────────────────────────────
        PRINT '───────────────────────────────────────────────────────────────';
        PRINT 'SECTION 1: Loading CRM Tables';
        PRINT '───────────────────────────────────────────────────────────────';
        PRINT '';

        -- ─────────────────────────────────────────────────────────────────
        -- TABLE 1.1: silver.crm_cust_info
        -- ─────────────────────────────────────────────────────────────────
        SET @start_time = GETDATE();
        PRINT '  [1.1] Loading Table: silver.crm_cust_info';
        PRINT '        >> Truncating table...';
        
        TRUNCATE TABLE silver.crm_cust_info;
        
        PRINT '        >> Inserting transformed data...';
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE 
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_marital_status,
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT
                *,
                ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL
        ) t
        WHERE flag_last = 1;
        
        SET @end_time = GETDATE();
        PRINT '        >> Completed in: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

        -- ─────────────────────────────────────────────────────────────────
        -- TABLE 1.2: silver.crm_prd_info
        -- ─────────────────────────────────────────────────────────────────
        SET @start_time = GETDATE();
        PRINT '  [1.2] Loading Table: silver.crm_prd_info';
        PRINT '        >> Truncating table...';
        
        TRUNCATE TABLE silver.crm_prd_info;
        
        PRINT '        >> Inserting transformed data...';
        INSERT INTO silver.crm_prd_info (
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
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE 
                WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
                WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(
                LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 
                AS DATE
            ) AS prd_end_dt
        FROM bronze.crm_prd_info;
        
        SET @end_time = GETDATE();
        PRINT '        >> Completed in: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

        -- ─────────────────────────────────────────────────────────────────
        -- TABLE 1.3: silver.crm_sales_details
        -- ─────────────────────────────────────────────────────────────────
        SET @start_time = GETDATE();
        PRINT '  [1.3] Loading Table: silver.crm_sales_details';
        PRINT '        >> Truncating table...';
        
        TRUNCATE TABLE silver.crm_sales_details;
        
        PRINT '        >> Inserting transformed data...';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
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
            sls_cust_id,
            CASE 
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,
            CASE 
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,
            CASE 
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,
            CASE 
                WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,
            sls_quantity,
            CASE 
                WHEN sls_price IS NULL OR sls_price <= 0 
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price
        FROM bronze.crm_sales_details;
        
        SET @end_time = GETDATE();
        PRINT '        >> Completed in: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

        -- ───────────────────────────────────────────────────────────────────
        -- SECTION 2: LOAD ERP TABLES
        -- ───────────────────────────────────────────────────────────────────
        PRINT '───────────────────────────────────────────────────────────────';
        PRINT 'SECTION 2: Loading ERP Tables';
        PRINT '───────────────────────────────────────────────────────────────';
        PRINT '';

        -- ─────────────────────────────────────────────────────────────────
        -- TABLE 2.1: silver.erp_cust_az12
        -- ─────────────────────────────────────────────────────────────────
        SET @start_time = GETDATE();
        PRINT '  [2.1] Loading Table: silver.erp_cust_az12';
        PRINT '        >> Truncating table...';
        
        TRUNCATE TABLE silver.erp_cust_az12;
        
        PRINT '        >> Inserting transformed data...';
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT
            CASE
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,
            CASE
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'n/a'
            END AS gen
        FROM bronze.erp_cust_az12;
        
        SET @end_time = GETDATE();
        PRINT '        >> Completed in: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

        -- ─────────────────────────────────────────────────────────────────
        -- TABLE 2.2: silver.erp_loc_a101
        -- ─────────────────────────────────────────────────────────────────
        SET @start_time = GETDATE();
        PRINT '  [2.2] Loading Table: silver.erp_loc_a101';
        PRINT '        >> Truncating table...';
        
        TRUNCATE TABLE silver.erp_loc_a101;
        
        PRINT '        >> Inserting transformed data...';
        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT
            REPLACE(cid, '-', '') AS cid,
            CASE
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry
        FROM bronze.erp_loc_a101;
        
        SET @end_time = GETDATE();
        PRINT '        >> Completed in: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

        -- ─────────────────────────────────────────────────────────────────
        -- TABLE 2.3: silver.erp_px_cat_g1v2
        -- ─────────────────────────────────────────────────────────────────
        SET @start_time = GETDATE();
        PRINT '  [2.3] Loading Table: silver.erp_px_cat_g1v2';
        PRINT '        >> Truncating table...';
        
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        
        PRINT '        >> Inserting transformed data...';
        INSERT INTO silver.erp_px_cat_g1v2 (
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
        FROM bronze.erp_px_cat_g1v2;
        
        SET @end_time = GETDATE();
        PRINT '        >> Completed in: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '';

        -- ───────────────────────────────────────────────────────────────────
        -- PROCESS COMPLETED SUCCESSFULLY
        -- ───────────────────────────────────────────────────────────────────
        SET @batch_end_time = GETDATE();
        
        PRINT '═══════════════════════════════════════════════════════════════';
        PRINT 'SILVER LAYER LOAD PROCESS COMPLETED SUCCESSFULLY';
        PRINT '═══════════════════════════════════════════════════════════════';
        PRINT '';
        PRINT '  Total Execution Time: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '';
        PRINT '═══════════════════════════════════════════════════════════════';

    END TRY
    BEGIN CATCH
        
        PRINT '';
        PRINT '═══════════════════════════════════════════════════════════════';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOAD PROCESS';
        PRINT '═══════════════════════════════════════════════════════════════';
        PRINT '';
        PRINT '  Error Number:   ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '  Error Message:  ' + ERROR_MESSAGE();
        PRINT '  Error Severity: ' + CAST(ERROR_SEVERITY() AS NVARCHAR);
        PRINT '  Error State:    ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '';
        PRINT '═══════════════════════════════════════════════════════════════';

    END CATCH

END
