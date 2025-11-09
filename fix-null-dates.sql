-- Fix NULL UpdatedAt values in Jobs table

USE ResumeScoring;
GO

-- Update NULL UpdatedAt values to match CreatedAt
UPDATE Jobs
SET UpdatedAt = ISNULL(UpdatedAt, CreatedAt)
WHERE UpdatedAt IS NULL;

-- Verify the fix
SELECT JobId, Title, CreatedAt, UpdatedAt
FROM Jobs;

PRINT 'Fixed NULL UpdatedAt values in Jobs table';
