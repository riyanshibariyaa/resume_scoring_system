-- =====================================================
-- OPTION A: ADD MISSING COLUMNS TO JOBS TABLE
-- Run this if Jobs table exists but is missing columns
-- This preserves any existing data
-- =====================================================

USE ResumeScoring;
GO

PRINT '========================================';
PRINT 'ADDING MISSING COLUMNS TO JOBS TABLE';
PRINT '========================================';
PRINT '';

-- Add RequiredSkills if missing
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'RequiredSkills')
BEGIN
    PRINT 'Adding RequiredSkills column...';
    ALTER TABLE Jobs ADD RequiredSkills NVARCHAR(MAX) NULL;
    PRINT '✅ RequiredSkills added successfully';
END
ELSE
BEGIN
    PRINT '✅ RequiredSkills already exists';
END

PRINT '';

-- Add WeightConfig if missing
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'WeightConfig')
BEGIN
    PRINT 'Adding WeightConfig column...';
    ALTER TABLE Jobs ADD WeightConfig NVARCHAR(MAX) NULL;
    PRINT '✅ WeightConfig added successfully';
END
ELSE
BEGIN
    PRINT '✅ WeightConfig already exists';
END

PRINT '';

-- Add CreatedAt if missing
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'CreatedAt')
BEGIN
    PRINT 'Adding CreatedAt column...';
    ALTER TABLE Jobs ADD CreatedAt DATETIME2 DEFAULT GETUTCDATE();
    PRINT '✅ CreatedAt added successfully';
END
ELSE
BEGIN
    PRINT '✅ CreatedAt already exists';
END

PRINT '';

-- Add UpdatedAt if missing
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'UpdatedAt')
BEGIN
    PRINT 'Adding UpdatedAt column...';
    ALTER TABLE Jobs ADD UpdatedAt DATETIME2 DEFAULT GETUTCDATE();
    PRINT '✅ UpdatedAt added successfully';
END
ELSE
BEGIN
    PRINT '✅ UpdatedAt already exists';
END

PRINT '';
PRINT '========================================';
PRINT '✅ JOBS TABLE FIX COMPLETE!';
PRINT '========================================';
PRINT '';
PRINT 'Now restart your API Gateway:';
PRINT '  cd E:\\SK\\resume-scoring-system\\backend\\api-gateway';
PRINT '  dotnet run';
PRINT '';

GO
