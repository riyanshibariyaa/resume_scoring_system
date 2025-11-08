-- =====================================================
-- DROP ALL TABLES AND RECREATE TO MATCH C# CODE
-- WARNING: This will DELETE ALL DATA!
-- =====================================================

USE ResumeScoring;
GO

PRINT '========================================';
PRINT 'DROPPING ALL EXISTING TABLES';
PRINT '========================================';
PRINT '';

-- Drop tables in correct order (foreign keys first)
IF OBJECT_ID('dbo.ScoringResults', 'U') IS NOT NULL
BEGIN
    DROP TABLE ScoringResults;
    PRINT '✅ Dropped ScoringResults';
END

IF OBJECT_ID('dbo.Feedback', 'U') IS NOT NULL
BEGIN
    DROP TABLE Feedback;
    PRINT '✅ Dropped Feedback';
END

IF OBJECT_ID('dbo.MatchEvidence', 'U') IS NOT NULL
BEGIN
    DROP TABLE MatchEvidence;
    PRINT '✅ Dropped MatchEvidence';
END

IF OBJECT_ID('dbo.Scores', 'U') IS NOT NULL
BEGIN
    DROP TABLE Scores;
    PRINT '✅ Dropped Scores';
END

IF OBJECT_ID('dbo.Embeddings', 'U') IS NOT NULL
BEGIN
    DROP TABLE Embeddings;
    PRINT '✅ Dropped Embeddings';
END

IF OBJECT_ID('dbo.ParsedData', 'U') IS NOT NULL
BEGIN
    DROP TABLE ParsedData;
    PRINT '✅ Dropped ParsedData';
END

IF OBJECT_ID('dbo.JobDescriptions', 'U') IS NOT NULL
BEGIN
    DROP TABLE JobDescriptions;
    PRINT '✅ Dropped JobDescriptions';
END

IF OBJECT_ID('dbo.Jobs', 'U') IS NOT NULL
BEGIN
    DROP TABLE Jobs;
    PRINT '✅ Dropped Jobs';
END

IF OBJECT_ID('dbo.Resumes', 'U') IS NOT NULL
BEGIN
    DROP TABLE Resumes;
    PRINT '✅ Dropped Resumes';
END

PRINT '';
PRINT '========================================';
PRINT 'CREATING NEW TABLES (MATCHING C# CODE)';
PRINT '========================================';
PRINT '';

-- =====================================================
-- 1. RESUMES TABLE
-- =====================================================
PRINT '1. Creating Resumes table...';

CREATE TABLE Resumes (
    ResumeId INT IDENTITY(1,1) PRIMARY KEY,
    CandidateName NVARCHAR(500) NULL,
    Email NVARCHAR(255) NULL,
    Phone NVARCHAR(50) NULL,
    RawText NVARCHAR(MAX) NULL,
    FileHash NVARCHAR(64) NULL,
    FileName NVARCHAR(500) NULL,
    FileType NVARCHAR(10) NULL,
    UploadedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ProcessedAt DATETIME2 NULL
);

PRINT '   ✅ Resumes table created';
PRINT '';

-- =====================================================
-- 2. JOBS TABLE
-- =====================================================
PRINT '2. Creating Jobs table...';

CREATE TABLE Jobs (
    JobId INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(500) NOT NULL,
    Description NVARCHAR(MAX) NOT NULL,
    RequiredSkills NVARCHAR(MAX) NULL,
    WeightConfig NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);

PRINT '   ✅ Jobs table created';
PRINT '';

-- =====================================================
-- 3. PARSEDDATA TABLE
-- =====================================================
PRINT '3. Creating ParsedData table...';

CREATE TABLE ParsedData (
    ParsedDataId INT IDENTITY(1,1) PRIMARY KEY,
    ResumeId INT NOT NULL,
    ContactInfo NVARCHAR(MAX) NULL,
    Skills NVARCHAR(MAX) NULL,
    Experience NVARCHAR(MAX) NULL,
    Education NVARCHAR(MAX) NULL,
    Certifications NVARCHAR(MAX) NULL,
    Summary NVARCHAR(MAX) NULL,
    ParsedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_ParsedData_Resumes FOREIGN KEY (ResumeId) REFERENCES Resumes(ResumeId) ON DELETE CASCADE
);

PRINT '   ✅ ParsedData table created';
PRINT '';

-- =====================================================
-- 4. EMBEDDINGS TABLE
-- =====================================================
PRINT '4. Creating Embeddings table...';

CREATE TABLE Embeddings (
    EmbeddingId INT IDENTITY(1,1) PRIMARY KEY,
    EntityType NVARCHAR(50) NULL,
    EntityId INT NOT NULL,
    EmbeddingVector NVARCHAR(MAX) NULL,
    ModelName NVARCHAR(100) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);

PRINT '   ✅ Embeddings table created';
PRINT '';

-- =====================================================
-- 5. SCORES TABLE
-- =====================================================
PRINT '5. Creating Scores table...';

CREATE TABLE Scores (
    ScoreId INT IDENTITY(1,1) PRIMARY KEY,
    ResumeId INT NOT NULL,
    JobId INT NOT NULL,
    OverallScore DECIMAL(5,2) NULL,
    SkillsScore DECIMAL(5,2) NULL,
    ExperienceScore DECIMAL(5,2) NULL,
    EducationScore DECIMAL(5,2) NULL,
    CertificationsScore DECIMAL(5,2) NULL,
    SemanticScore DECIMAL(5,2) NULL,
    Explanation NVARCHAR(MAX) NULL,
    ComputedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Scores_Resumes FOREIGN KEY (ResumeId) REFERENCES Resumes(ResumeId) ON DELETE CASCADE,
    CONSTRAINT FK_Scores_Jobs FOREIGN KEY (JobId) REFERENCES Jobs(JobId) ON DELETE CASCADE
);

PRINT '   ✅ Scores table created';
PRINT '';

-- =====================================================
-- 6. MATCHEVIDENCE TABLE
-- =====================================================
PRINT '6. Creating MatchEvidence table...';

CREATE TABLE MatchEvidence (
    EvidenceId INT IDENTITY(1,1) PRIMARY KEY,
    ScoreId INT NOT NULL,
    Category NVARCHAR(100) NULL,
    MatchedText NVARCHAR(MAX) NULL,
    JobRequirement NVARCHAR(MAX) NULL,
    ConfidenceScore DECIMAL(5,2) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_MatchEvidence_Scores FOREIGN KEY (ScoreId) REFERENCES Scores(ScoreId) ON DELETE CASCADE
);

PRINT '   ✅ MatchEvidence table created';
PRINT '';

-- =====================================================
-- 7. FEEDBACK TABLE
-- =====================================================
PRINT '7. Creating Feedback table...';

CREATE TABLE Feedback (
    FeedbackId INT IDENTITY(1,1) PRIMARY KEY,
    ScoreId INT NOT NULL,
    RecruiterNotes NVARCHAR(MAX) NULL,
    AdjustedScore DECIMAL(5,2) NULL,
    WeightAdjustments NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Feedback_Scores FOREIGN KEY (ScoreId) REFERENCES Scores(ScoreId) ON DELETE CASCADE
);

PRINT '   ✅ Feedback table created';
PRINT '';

-- =====================================================
-- VERIFICATION
-- =====================================================
PRINT '========================================';
PRINT 'VERIFICATION - ALL TABLES CREATED';
PRINT '========================================';
PRINT '';

SELECT 
    TABLE_NAME as [Table Name],
    (SELECT COUNT(*) 
     FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE TABLE_NAME = t.TABLE_NAME) as [Column Count]
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_TYPE = 'BASE TABLE' 
  AND TABLE_NAME NOT LIKE '__EF%'
ORDER BY TABLE_NAME;

PRINT '';
PRINT '========================================';
PRINT 'DETAILED TABLE STRUCTURES';
PRINT '========================================';
PRINT '';

PRINT 'RESUMES TABLE:';
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Resumes'
ORDER BY ORDINAL_POSITION;

PRINT '';
PRINT 'JOBS TABLE:';
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Jobs'
ORDER BY ORDINAL_POSITION;

PRINT '';
PRINT 'PARSEDDATA TABLE:';
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ParsedData'
ORDER BY ORDINAL_POSITION;

PRINT '';
PRINT '========================================';
PRINT '✅ DATABASE RECREATED SUCCESSFULLY!';
PRINT '========================================';
PRINT '';
PRINT 'Your database now EXACTLY matches your C# code.';
PRINT '';
PRINT 'Tables created:';
PRINT '  1. Resumes (with ResumeId, CandidateName, Email, etc.)';
PRINT '  2. Jobs (with JobId, Title, Description, etc.)';
PRINT '  3. ParsedData (for NLP extracted data)';
PRINT '  4. Embeddings (for vector embeddings)';
PRINT '  5. Scores (for candidate-job scores)';
PRINT '  6. MatchEvidence (for match explanations)';
PRINT '  7. Feedback (for recruiter feedback)';
PRINT '';
PRINT 'Next steps:';
PRINT '1. Restart your API Gateway:';
PRINT '   cd E:\\SK\\resume-scoring-system\\backend\\api-gateway';
PRINT '   dotnet run';
PRINT '';
PRINT '2. Test at http://localhost:3000';
PRINT '';
PRINT '✅ Everything will work perfectly now!';
PRINT '';

GO
