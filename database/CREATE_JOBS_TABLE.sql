-- =====================================================
-- CREATE JOBS TABLE FROM SCRATCH
-- The Jobs table doesn't exist, so we'll create it
-- =====================================================

USE ResumeScoring;
GO

PRINT '========================================';
PRINT 'CREATING JOBS TABLE';
PRINT '========================================';
PRINT '';

-- Check if table already exists (just in case)
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Jobs')
BEGIN
    PRINT '⚠️  Jobs table already exists!';
    PRINT '   If you are seeing this message, something is wrong.';
    PRINT '   Contact support or manually drop the table first.';
    PRINT '';
END
ELSE
BEGIN
    PRINT 'Creating Jobs table...';
    
    CREATE TABLE Jobs (
        JobId INT PRIMARY KEY IDENTITY(1,1),
        Title NVARCHAR(500) NOT NULL,
        Description NVARCHAR(MAX) NOT NULL,
        RequiredSkills NVARCHAR(MAX) NULL,
        WeightConfig NVARCHAR(MAX) NULL,
        CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2 DEFAULT GETUTCDATE()
    );
    
    PRINT '✅ Jobs table created successfully!';
    PRINT '';
    PRINT 'Table structure:';
    PRINT '  - JobId (INT, Primary Key, Auto-increment)';
    PRINT '  - Title (NVARCHAR(500), Required)';
    PRINT '  - Description (NVARCHAR(MAX), Required)';
    PRINT '  - RequiredSkills (NVARCHAR(MAX), Optional)';
    PRINT '  - WeightConfig (NVARCHAR(MAX), Optional)';
    PRINT '  - CreatedAt (DATETIME2, Auto-generated)';
    PRINT '  - UpdatedAt (DATETIME2, Auto-generated)';
    PRINT '';
    
    -- Create foreign key if Scores table exists
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Scores')
    BEGIN
        PRINT 'Creating foreign key constraint with Scores table...';
        
        -- Check if constraint already exists
        IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Scores_Jobs')
        BEGIN
            ALTER TABLE Scores 
            ADD CONSTRAINT FK_Scores_Jobs 
            FOREIGN KEY (JobId) REFERENCES Jobs(JobId);
            PRINT '✅ FK_Scores_Jobs constraint created';
        END
        ELSE
        BEGIN
            PRINT '✅ FK_Scores_Jobs constraint already exists';
        END
    END
    ELSE
    BEGIN
        PRINT 'ℹ️  Scores table not found - foreign key will be created later';
    END
    
    PRINT '';
    PRINT '========================================';
    PRINT '✅ JOBS TABLE SETUP COMPLETE!';
    PRINT '========================================';
    PRINT '';
    PRINT 'Next steps:';
    PRINT '1. Stop your API Gateway (Ctrl+C)';
    PRINT '2. Restart it:';
    PRINT '   cd E:\\SK\\resume-scoring-system\\backend\\api-gateway';
    PRINT '   dotnet run';
    PRINT '';
    PRINT '3. Test by going to http://localhost:3000/jobs';
    PRINT '';
    PRINT '✅ Everything should work now!';
    PRINT '';
END

GO
