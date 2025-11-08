-- =====================================================
-- DATA VERIFICATION SCRIPT (CORRECTED)
-- Resume Scoring System - Check All Data
-- Works with actual database schema
-- =====================================================

USE ResumeScoring;
GO

PRINT '========================================';
PRINT 'RESUME SCORING SYSTEM - DATA CHECK';
PRINT '========================================';
PRINT '';

-- =====================================================
-- 1. CHECK ALL TABLES EXIST
-- =====================================================
PRINT '1. CHECKING TABLES...';
PRINT '';

SELECT 
    TABLE_NAME as [Table],
    (SELECT COUNT(*) 
     FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_NAME = t.TABLE_NAME) as [Columns]
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

PRINT '';
PRINT '========================================';
PRINT '';

-- =====================================================
-- 2. CHECK ACTUAL COLUMNS IN RESUMES TABLE
-- =====================================================
PRINT '2. RESUMES TABLE STRUCTURE';
PRINT '';

SELECT 
    COLUMN_NAME as [Column],
    DATA_TYPE as [Type],
    CHARACTER_MAXIMUM_LENGTH as [MaxLength]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Resumes'
ORDER BY ORDINAL_POSITION;

PRINT '';
PRINT '========================================';
PRINT '';

-- =====================================================
-- 3. CHECK RESUMES DATA
-- =====================================================
PRINT '3. RESUMES (Uploaded Files)';
PRINT '';

-- First, check if IsDeleted column exists
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Resumes' AND COLUMN_NAME = 'IsDeleted')
BEGIN
    SELECT 
        ResumeId as [ID],
        CandidateName as [Name],
        Email,
        ISNULL(Phone, 'N/A') as Phone,
        ISNULL(FileFormat, 'N/A') as [Format],
        ISNULL(ParseStatus, 'N/A') as [Status],
        CONVERT(varchar, CreatedAt, 120) as [Uploaded]
    FROM Resumes
    WHERE IsDeleted = 0
    ORDER BY CreatedAt DESC;
    
    SELECT '   Total Resumes: ' + CAST(COUNT(*) as varchar) as [Summary]
    FROM Resumes WHERE IsDeleted = 0;
END
ELSE
BEGIN
    -- If IsDeleted doesn't exist, just show all resumes
    SELECT 
        ResumeId as [ID],
        CandidateName as [Name],
        Email,
        ISNULL(Phone, 'N/A') as Phone,
        CONVERT(varchar, CreatedAt, 120) as [Uploaded]
    FROM Resumes
    ORDER BY CreatedAt DESC;
    
    SELECT '   Total Resumes: ' + CAST(COUNT(*) as varchar) as [Summary]
    FROM Resumes;
END

PRINT '';
PRINT '========================================';
PRINT '';

-- =====================================================
-- 4. CHECK PARSED DATA (CandidateProfiles)
-- =====================================================
PRINT '4. PARSED DATA (NLP Extraction Results)';
PRINT '';

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CandidateProfiles')
BEGIN
    SELECT 
        cp.ProfileId as [ID],
        r.CandidateName as [Candidate],
        ISNULL(cp.TotalExperienceYears, 0) as [Years Exp],
        ISNULL(cp.SeniorityLevel, 'N/A') as [Level],
        CONVERT(varchar, cp.ExtractedAt, 120) as [Extracted]
    FROM CandidateProfiles cp
    INNER JOIN Resumes r ON cp.ResumeId = r.ResumeId
    ORDER BY cp.ExtractedAt DESC;

    SELECT '   Total Parsed: ' + CAST(COUNT(*) as varchar) as [Summary]
    FROM CandidateProfiles;
    
    -- Show sample skills for first resume
    IF EXISTS (SELECT 1 FROM CandidateProfiles WHERE SkillsJSON IS NOT NULL)
    BEGIN
        PRINT '';
        PRINT 'Sample Skills from Latest Resume:';
        SELECT TOP 1 
            LEFT(ISNULL(SkillsJSON, 'N/A'), 200) + '...' as [Skills JSON Preview]
        FROM CandidateProfiles
        WHERE SkillsJSON IS NOT NULL
        ORDER BY ProfileId DESC;
    END
END
ELSE
BEGIN
    PRINT '   CandidateProfiles table not found or empty';
END

PRINT '';
PRINT '========================================';
PRINT '';

-- =====================================================
-- 5. CHECK EMBEDDINGS
-- =====================================================
PRINT '5. EMBEDDINGS (Semantic Vectors for Matching)';
PRINT '';

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Embeddings')
BEGIN
    SELECT 
        e.EmbeddingId as [ID],
        e.EntityType as [Type],
        e.EntityId as [Entity ID],
        CASE 
            WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Embeddings' AND COLUMN_NAME = 'VectorJSON')
                THEN CASE WHEN LEN(ISNULL(e.VectorJSON, '')) > 0 THEN 'Generated' ELSE 'Missing' END
            ELSE 'N/A'
        END as [Status],
        CONVERT(varchar, e.CreatedAt, 120) as [Created]
    FROM Embeddings e
    ORDER BY e.CreatedAt DESC;

    SELECT '   Total Embeddings: ' + CAST(COUNT(*) as varchar) as [Summary]
    FROM Embeddings;
END
ELSE
BEGIN
    PRINT '   Embeddings table not found or empty';
END

PRINT '';
PRINT '========================================';
PRINT '';

-- =====================================================
-- 6. CHECK JOBS
-- =====================================================
PRINT '6. JOBS (Job Postings)';
PRINT '';

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Jobs' AND COLUMN_NAME = 'IsDeleted')
BEGIN
    SELECT 
        JobId as [ID],
        Title,
        ISNULL(Department, 'N/A') as Department,
        ISNULL(Status, 'Active') as Status,
        CONVERT(varchar, CreatedAt, 120) as [Created]
    FROM Jobs
    WHERE IsDeleted = 0
    ORDER BY CreatedAt DESC;
    
    SELECT '   Total Jobs: ' + CAST(COUNT(*) as varchar) as [Summary]
    FROM Jobs WHERE IsDeleted = 0;
END
ELSE
BEGIN
    SELECT 
        JobId as [ID],
        Title,
        ISNULL(Department, 'N/A') as Department,
        CONVERT(varchar, CreatedAt, 120) as [Created]
    FROM Jobs
    ORDER BY CreatedAt DESC;
    
    SELECT '   Total Jobs: ' + CAST(COUNT(*) as varchar) as [Summary]
    FROM Jobs;
END

PRINT '';
PRINT '========================================';
PRINT '';

-- =====================================================
-- 7. CHECK SCORES
-- =====================================================
PRINT '7. SCORES (Candidate-Job Matches)';
PRINT '';

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Scores')
BEGIN
    SELECT 
        s.ScoreId as [ID],
        r.CandidateName as [Candidate],
        j.Title as [Job],
        CAST(ROUND(s.OverallScore * 100, 1) as decimal(5,1)) as [Score %],
        CONVERT(varchar, s.ComputedAt, 120) as [Scored]
    FROM Scores s
    INNER JOIN Resumes r ON s.ResumeId = r.ResumeId
    INNER JOIN Jobs j ON s.JobId = j.JobId
    ORDER BY s.ComputedAt DESC;

    SELECT '   Total Scores: ' + CAST(COUNT(*) as varchar) as [Summary]
    FROM Scores;

    -- Show score distribution
    SELECT '   High Scores (80%+): ' + CAST(COUNT(*) as varchar) as [Score Distribution]
    FROM Scores WHERE OverallScore >= 0.8
    UNION ALL
    SELECT '   Good Scores (60-80%): ' + CAST(COUNT(*) as varchar)
    FROM Scores WHERE OverallScore >= 0.6 AND OverallScore < 0.8
    UNION ALL
    SELECT '   Fair Scores (40-60%): ' + CAST(COUNT(*) as varchar)
    FROM Scores WHERE OverallScore >= 0.4 AND OverallScore < 0.6
    UNION ALL
    SELECT '   Low Scores (<40%): ' + CAST(COUNT(*) as varchar)
    FROM Scores WHERE OverallScore < 0.4;
END
ELSE
BEGIN
    PRINT '   Scores table not found or empty';
END

PRINT '';
PRINT '========================================';
PRINT '';

-- =====================================================
-- 8. CHECK MATCH EVIDENCE (if table exists)
-- =====================================================
PRINT '8. MATCH EVIDENCE (Scoring Explanations)';
PRINT '';

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'MatchEvidence')
BEGIN
    SELECT TOP 10
        me.EvidenceId as [ID],
        s.ScoreId as [Score ID],
        r.CandidateName as [Candidate],
        ISNULL(me.Category, 'N/A') as Category,
        CASE 
            WHEN EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MatchEvidence' AND COLUMN_NAME = 'TextSpan')
                THEN LEFT(ISNULL(me.TextSpan, 'N/A'), 50) + '...'
            ELSE 'N/A'
        END as [Evidence Preview],
        CAST(ROUND(ISNULL(me.ConfidenceScore, 0) * 100, 0) as int) as [Confidence %]
    FROM MatchEvidence me
    INNER JOIN Scores s ON me.ScoreId = s.ScoreId
    INNER JOIN Resumes r ON s.ResumeId = r.ResumeId
    ORDER BY s.ComputedAt DESC, me.ConfidenceScore DESC;

    SELECT '   Total Evidence Records: ' + CAST(COUNT(*) as varchar) as [Summary]
    FROM MatchEvidence;
END
ELSE IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Scores')
BEGIN
    -- Check if evidence is stored in Scores table as JSON
    PRINT '   Evidence may be stored in Scores.EvidenceJSON column';
    SELECT TOP 5
        ScoreId,
        LEFT(ISNULL(EvidenceJSON, 'No evidence'), 100) + '...' as [Evidence Preview]
    FROM Scores
    WHERE EvidenceJSON IS NOT NULL
    ORDER BY ComputedAt DESC;
END
ELSE
BEGIN
    PRINT '   Match evidence table not found';
END

PRINT '';
PRINT '========================================';
PRINT '';

-- =====================================================
-- 9. SYSTEM HEALTH CHECK
-- =====================================================
PRINT '9. SYSTEM HEALTH';
PRINT '';

-- Check for any parse errors
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Resumes' AND COLUMN_NAME = 'ParseStatus')
BEGIN
    SELECT 'Resumes with Parse Errors: ' + CAST(COUNT(*) as varchar) as [Health Check]
    FROM Resumes 
    WHERE ParseStatus LIKE '%Error%' OR ParseStatus LIKE '%Failed%';
END

-- Check resumes without parsed data
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CandidateProfiles')
BEGIN
    DECLARE @ResumesWithoutProfiles INT;
    SELECT @ResumesWithoutProfiles = COUNT(*)
    FROM Resumes r
    LEFT JOIN CandidateProfiles cp ON r.ResumeId = cp.ResumeId
    WHERE cp.ProfileId IS NULL;
    
    SELECT 'Resumes without Parsed Data: ' + CAST(@ResumesWithoutProfiles as varchar) as [Health Check];
END

-- Check resumes without embeddings
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Embeddings')
BEGIN
    DECLARE @ResumesWithoutEmbeddings INT;
    SELECT @ResumesWithoutEmbeddings = COUNT(*)
    FROM Resumes r
    LEFT JOIN Embeddings e ON r.ResumeId = e.EntityId AND e.EntityType = 'Resume'
    WHERE e.EmbeddingId IS NULL;
    
    SELECT 'Resumes without Embeddings: ' + CAST(@ResumesWithoutEmbeddings as varchar) as [Health Check];
END

PRINT '';
PRINT '========================================';
PRINT '';

-- =====================================================
-- 10. COMPLETE WORKFLOW STATUS
-- =====================================================
PRINT '10. COMPLETE WORKFLOW STATUS';
PRINT '';

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CandidateProfiles') 
   AND EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Embeddings')
BEGIN
    SELECT 
        r.ResumeId as [Resume ID],
        r.CandidateName as [Name],
        CASE WHEN cp.ProfileId IS NOT NULL THEN '✓' ELSE '✗' END as [Parsed],
        CASE WHEN e.EmbeddingId IS NOT NULL THEN '✓' ELSE '✗' END as [Embedded],
        ISNULL(
            (SELECT COUNT(*) FROM Scores s WHERE s.ResumeId = r.ResumeId),
            0
        ) as [Times Scored],
        CONVERT(varchar, r.CreatedAt, 120) as [Uploaded]
    FROM Resumes r
    LEFT JOIN CandidateProfiles cp ON r.ResumeId = cp.ResumeId
    LEFT JOIN Embeddings e ON r.ResumeId = e.EntityId AND e.EntityType = 'Resume'
    ORDER BY r.CreatedAt DESC;
END
ELSE
BEGIN
    SELECT 
        ResumeId as [Resume ID],
        CandidateName as [Name],
        CONVERT(varchar, CreatedAt, 120) as [Uploaded]
    FROM Resumes
    ORDER BY CreatedAt DESC;
END

PRINT '';
PRINT '========================================';
PRINT 'DATA CHECK COMPLETE';
PRINT '========================================';
GO

-- =====================================================
-- QUICK STATS SUMMARY
-- =====================================================
PRINT '';
PRINT 'QUICK STATS SUMMARY:';
PRINT '';

DECLARE @ResumeCount int = 0, @JobCount int = 0, @ScoreCount int = 0, @EmbeddingCount int = 0;

SELECT @ResumeCount = COUNT(*) FROM Resumes;
SELECT @JobCount = COUNT(*) FROM Jobs;

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Scores')
    SELECT @ScoreCount = COUNT(*) FROM Scores;

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Embeddings')
    SELECT @EmbeddingCount = COUNT(*) FROM Embeddings;

PRINT 'Resumes: ' + CAST(@ResumeCount as varchar);
PRINT 'Jobs: ' + CAST(@JobCount as varchar);
PRINT 'Scores: ' + CAST(@ScoreCount as varchar);
PRINT 'Embeddings: ' + CAST(@EmbeddingCount as varchar);
PRINT '';

PRINT '========================================';
PRINT 'TIP: If any tables are empty, try running';
PRINT 'the workflow in the frontend application!';
PRINT '========================================';
GO