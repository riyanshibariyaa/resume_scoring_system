USE ResumeScoring;
GO

-- Add RequiredSkills column if it doesn't exist
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'RequiredSkills'
)
BEGIN
    ALTER TABLE Jobs ADD RequiredSkills NVARCHAR(MAX) NULL;
    PRINT '✓ RequiredSkills column added';
END

-- Add WeightConfig column if it doesn't exist
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'WeightConfig'
)
BEGIN
    ALTER TABLE Jobs ADD WeightConfig NVARCHAR(MAX) NULL;
    PRINT '✓ WeightConfig column added';
END

PRINT '✓ Jobs table fixed!';
GO