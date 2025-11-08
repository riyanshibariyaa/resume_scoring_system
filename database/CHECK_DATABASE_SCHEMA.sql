-- =====================================================
-- COMPREHENSIVE DATABASE SCHEMA CHECK AND FIX
-- Run this to see EXACTLY what's in your database
-- and get the EXACT fix needed
-- =====================================================

USE ResumeScoring;
GO

PRINT '========================================';
PRINT 'COMPLETE SCHEMA ANALYSIS';
PRINT '========================================';
PRINT '';

-- =====================================================
-- 1. CHECK ALL TABLES
-- =====================================================
PRINT '1. ALL TABLES IN DATABASE:';
PRINT '';
SELECT TABLE_NAME as [Table Name]
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
PRINT '';

-- =====================================================
-- 2. CHECK JOBS TABLE STRUCTURE
-- =====================================================
PRINT '2. JOBS TABLE COLUMNS (THIS IS THE PROBLEM):';
PRINT '';
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Jobs')
BEGIN
    SELECT 
        ORDINAL_POSITION as [#],
        COLUMN_NAME as [Column Name],
        DATA_TYPE as [Data Type],
        IS_NULLABLE as [Nullable]
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Jobs'
    ORDER BY ORDINAL_POSITION;
END
ELSE
BEGIN
    PRINT '   ❌ Jobs table does NOT exist!';
END
PRINT '';

-- =====================================================
-- 3. CHECK RESUMES TABLE STRUCTURE
-- =====================================================
PRINT '3. RESUMES TABLE COLUMNS (THIS ONE WORKS):';
PRINT '';
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Resumes')
BEGIN
    SELECT 
        ORDINAL_POSITION as [#],
        COLUMN_NAME as [Column Name],
        DATA_TYPE as [Data Type],
        IS_NULLABLE as [Nullable]
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Resumes'
    ORDER BY ORDINAL_POSITION;
END
ELSE
BEGIN
    PRINT '   ❌ Resumes table does NOT exist!';
END
PRINT '';

-- =====================================================
-- 4. CHECK FOR SPECIFIC COLUMNS
-- =====================================================
PRINT '4. CHECKING FOR PROBLEMATIC COLUMNS:';
PRINT '';

-- Check Jobs columns
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'RequiredSkills')
    PRINT '   ✅ Jobs.RequiredSkills EXISTS'
ELSE
    PRINT '   ❌ Jobs.RequiredSkills MISSING (Code expects this!)';

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'WeightConfig')
    PRINT '   ✅ Jobs.WeightConfig EXISTS'
ELSE
    PRINT '   ❌ Jobs.WeightConfig MISSING (Code expects this!)';

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'Title')
    PRINT '   ✅ Jobs.Title EXISTS'
ELSE
    PRINT '   ❌ Jobs.Title MISSING';

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'Description')
    PRINT '   ✅ Jobs.Description EXISTS'
ELSE
    PRINT '   ❌ Jobs.Description MISSING';

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'CreatedAt')
    PRINT '   ✅ Jobs.CreatedAt EXISTS'
ELSE
    PRINT '   ❌ Jobs.CreatedAt MISSING';

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'UpdatedAt')
    PRINT '   ✅ Jobs.UpdatedAt EXISTS'
ELSE
    PRINT '   ❌ Jobs.UpdatedAt MISSING';

PRINT '';

-- =====================================================
-- 5. SHOW WHAT COLUMNS JOBS TABLE ACTUALLY HAS
-- =====================================================
PRINT '5. JOBS TABLE - ALL ACTUAL COLUMNS:';
PRINT '';
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Jobs')
BEGIN
    DECLARE @JobColumns NVARCHAR(MAX) = '';
    SELECT @JobColumns = @JobColumns + COLUMN_NAME + ', '
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Jobs'
    ORDER BY ORDINAL_POSITION;
    
    -- Remove trailing comma
    IF LEN(@JobColumns) > 0
        SET @JobColumns = LEFT(@JobColumns, LEN(@JobColumns) - 1);
    
    PRINT '   ' + @JobColumns;
END
PRINT '';

-- =====================================================
-- 6. DIAGNOSIS AND RECOMMENDED FIX
-- =====================================================
PRINT '========================================';
PRINT 'DIAGNOSIS:';
PRINT '========================================';
PRINT '';

DECLARE @NeedsFix BIT = 0;

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'RequiredSkills')
BEGIN
    SET @NeedsFix = 1;
    PRINT '❌ PROBLEM: Jobs.RequiredSkills column is MISSING';
END

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'WeightConfig')
BEGIN
    SET @NeedsFix = 1;
    PRINT '❌ PROBLEM: Jobs.WeightConfig column is MISSING';
END

PRINT '';
PRINT '========================================';
PRINT 'RECOMMENDED ACTION:';
PRINT '========================================';
PRINT '';

IF @NeedsFix = 1
BEGIN
    PRINT 'YOU NEED TO RUN ONE OF THESE FIXES:';
    PRINT '';
    PRINT 'OPTION A: Add missing columns (if Jobs table exists with some data)';
    PRINT '   Run script: ADD_MISSING_JOB_COLUMNS.sql';
    PRINT '';
    PRINT 'OPTION B: Recreate Jobs table completely (if table is empty or broken)';
    PRINT '   Run script: RECREATE_JOBS_TABLE.sql';
END
ELSE
BEGIN
    PRINT '✅ Your database schema looks correct!';
    PRINT '   The problem might be in your code configuration.';
    PRINT '   Check your connection string and ensure you are connected to the right database.';
END

PRINT '';
PRINT '========================================';
GO
