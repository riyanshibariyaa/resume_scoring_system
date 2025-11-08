-- Save this as: database/migrations/001_initial_schema.sql

USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ResumeScoring')
BEGIN
    CREATE DATABASE ResumeScoring;
END
GO

USE ResumeScoring;
GO

-- Jobs Table (Job Descriptions)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Jobs')
BEGIN
    CREATE TABLE Jobs (
        JobId INT PRIMARY KEY IDENTITY(1,1),
        Title NVARCHAR(500) NOT NULL,
        Description NVARCHAR(MAX) NOT NULL,
        RequiredSkills NVARCHAR(MAX), -- JSON array of skills
        WeightConfig NVARCHAR(MAX), -- JSON object for scoring weights
        CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2 DEFAULT GETUTCDATE()
    );
END
GO

-- Resumes Table (Candidate Resumes)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Resumes')
BEGIN
    CREATE TABLE Resumes (
        ResumeId INT PRIMARY KEY IDENTITY(1,1),
        CandidateName NVARCHAR(500),
        Email NVARCHAR(255),
        Phone NVARCHAR(50),
        RawText NVARCHAR(MAX), -- Full extracted text
        FileHash NVARCHAR(64), -- For deduplication
        FileName NVARCHAR(500),
        FileType NVARCHAR(10), -- PDF, DOCX, TXT
        UploadedAt DATETIME2 DEFAULT GETUTCDATE(),
        ProcessedAt DATETIME2
    );
END
GO

-- Parsed Data Table (Structured extraction from resumes)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ParsedData')
BEGIN
    CREATE TABLE ParsedData (
        ParsedDataId INT PRIMARY KEY IDENTITY(1,1),
        ResumeId INT FOREIGN KEY REFERENCES Resumes(ResumeId),
        ContactInfo NVARCHAR(MAX), -- JSON: email, phone, linkedin
        Skills NVARCHAR(MAX), -- JSON array of extracted skills
        Experience NVARCHAR(MAX), -- JSON array of work experience
        Education NVARCHAR(MAX), -- JSON array of education
        Certifications NVARCHAR(MAX), -- JSON array
        Summary NVARCHAR(MAX),
        ParsedAt DATETIME2 DEFAULT GETUTCDATE()
    );
END
GO

-- Embeddings Table (Vector storage)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Embeddings')
BEGIN
    CREATE TABLE Embeddings (
        EmbeddingId INT PRIMARY KEY IDENTITY(1,1),
        EntityType NVARCHAR(50), -- 'Resume' or 'Job'
        EntityId INT, -- ResumeId or JobId
        EmbeddingVector NVARCHAR(MAX), -- JSON array of floats
        ModelName NVARCHAR(100), -- e.g., 'all-MiniLM-L6-v2'
        CreatedAt DATETIME2 DEFAULT GETUTCDATE()
    );
END
GO

-- Scores Table (Candidate-Job scores)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Scores')
BEGIN
    CREATE TABLE Scores (
        ScoreId INT PRIMARY KEY IDENTITY(1,1),
        ResumeId INT FOREIGN KEY REFERENCES Resumes(ResumeId),
        JobId INT FOREIGN KEY REFERENCES Jobs(JobId),
        OverallScore DECIMAL(5,2), -- 0-100
        SkillsScore DECIMAL(5,2),
        ExperienceScore DECIMAL(5,2),
        EducationScore DECIMAL(5,2),
        CertificationsScore DECIMAL(5,2),
        SemanticScore DECIMAL(5,2), -- Based on embeddings
        Explanation NVARCHAR(MAX), -- JSON with match details
        ComputedAt DATETIME2 DEFAULT GETUTCDATE()
    );
END
GO

-- Match Evidence Table (Explainability)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'MatchEvidence')
BEGIN
    CREATE TABLE MatchEvidence (
        EvidenceId INT PRIMARY KEY IDENTITY(1,1),
        ScoreId INT FOREIGN KEY REFERENCES Scores(ScoreId),
        Category NVARCHAR(100), -- 'Skills', 'Experience', etc.
        MatchedText NVARCHAR(MAX), -- Text span from resume
        JobRequirement NVARCHAR(MAX), -- Corresponding JD requirement
        ConfidenceScore DECIMAL(5,2), -- 0-100
        CreatedAt DATETIME2 DEFAULT GETUTCDATE()
    );
END
GO

-- Feedback Table (Recruiter adjustments)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Feedback')
BEGIN
    CREATE TABLE Feedback (
        FeedbackId INT PRIMARY KEY IDENTITY(1,1),
        ScoreId INT FOREIGN KEY REFERENCES Scores(ScoreId),
        RecruiterNotes NVARCHAR(MAX),
        AdjustedScore DECIMAL(5,2), -- Manual override
        WeightAdjustments NVARCHAR(MAX), -- JSON of new weights
        CreatedAt DATETIME2 DEFAULT GETUTCDATE()
    );
END
GO

PRINT 'Database schema created successfully!';
GO
-- -- Migration: 001_initial_schema.sql
-- -- Resume Parsing and Candidate Scoring System - Database Schema
-- -- Target: MS SQL Server 2019+

-- -- Create Database
-- IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'ResumeScoring')
-- BEGIN
--     CREATE DATABASE ResumeScoring;
-- END
-- GO

-- USE ResumeScoring;
-- GO

-- -- =====================================================
-- -- CORE TABLES
-- -- =====================================================

-- -- Jobs Table
-- CREATE TABLE Jobs (
--     JobId INT IDENTITY(1,1) PRIMARY KEY,
--     Title NVARCHAR(200) NOT NULL,
--     Department NVARCHAR(100),
--     Description NVARCHAR(MAX) NOT NULL,
--     RequirementsText NVARCHAR(MAX),
--     WeightConfigJSON NVARCHAR(MAX) DEFAULT '{"skills":0.30,"experience":0.25,"domain":0.15,"education":0.10,"certifications":0.10,"recency":0.10}',
--     Status NVARCHAR(50) DEFAULT 'Active',
--     CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
--     UpdatedAt DATETIME2 DEFAULT GETUTCDATE(),
--     OwnerId NVARCHAR(100),
--     IsDeleted BIT DEFAULT 0,
--     CONSTRAINT CHK_WeightConfigJSON CHECK (ISJSON(WeightConfigJSON) = 1)
-- );

-- CREATE INDEX IDX_Jobs_Status ON Jobs(Status) WHERE IsDeleted = 0;
-- CREATE INDEX IDX_Jobs_CreatedAt ON Jobs(CreatedAt DESC);

-- -- Resumes Table
-- CREATE TABLE Resumes (
--     ResumeId INT IDENTITY(1,1) PRIMARY KEY,
--     CandidateName NVARCHAR(200),
--     Email NVARCHAR(255),
--     Phone NVARCHAR(50),
--     RawFileUri NVARCHAR(500) NOT NULL,
--     ParsedJsonUri NVARCHAR(500),
--     FileHash NVARCHAR(64) NOT NULL,
--     FileFormat NVARCHAR(10),
--     Source NVARCHAR(100) DEFAULT 'WebUpload',
--     ParseStatus NVARCHAR(50) DEFAULT 'Pending',
--     ParseErrorMessage NVARCHAR(MAX),
--     CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
--     UpdatedAt DATETIME2 DEFAULT GETUTCDATE(),
--     IsDeleted BIT DEFAULT 0,
--     CONSTRAINT CHK_FileFormat CHECK (FileFormat IN ('PDF', 'DOCX', 'TXT', 'RTF'))
-- );

-- CREATE UNIQUE INDEX IDX_Resumes_Hash ON Resumes(FileHash) WHERE IsDeleted = 0;
-- CREATE INDEX IDX_Resumes_ParseStatus ON Resumes(ParseStatus);
-- CREATE INDEX IDX_Resumes_CreatedAt ON Resumes(CreatedAt DESC);

-- -- Candidate Profiles Table
-- CREATE TABLE CandidateProfiles (
--     ProfileId INT IDENTITY(1,1) PRIMARY KEY,
--     ResumeId INT NOT NULL,
--     SkillsJSON NVARCHAR(MAX),
--     WorkHistoryJSON NVARCHAR(MAX),
--     EducationJSON NVARCHAR(MAX),
--     CertificationsJSON NVARCHAR(MAX),
--     SummaryText NVARCHAR(MAX),
--     TotalExperienceYears DECIMAL(5,2),
--     SeniorityLevel NVARCHAR(50),
--     Industries NVARCHAR(500),
--     PreferredLocations NVARCHAR(500),
--     ExtractedAt DATETIME2 DEFAULT GETUTCDATE(),
--     ModelVersion NVARCHAR(50),
--     CONSTRAINT FK_CandidateProfiles_Resumes FOREIGN KEY (ResumeId) REFERENCES Resumes(ResumeId),
--     CONSTRAINT CHK_SkillsJSON CHECK (SkillsJSON IS NULL OR ISJSON(SkillsJSON) = 1),
--     CONSTRAINT CHK_WorkHistoryJSON CHECK (WorkHistoryJSON IS NULL OR ISJSON(WorkHistoryJSON) = 1),
--     CONSTRAINT CHK_EducationJSON CHECK (EducationJSON IS NULL OR ISJSON(EducationJSON) = 1),
--     CONSTRAINT CHK_CertificationsJSON CHECK (CertificationsJSON IS NULL OR ISJSON(CertificationsJSON) = 1)
-- );

-- CREATE UNIQUE INDEX IDX_CandidateProfiles_ResumeId ON CandidateProfiles(ResumeId);
-- CREATE INDEX IDX_CandidateProfiles_SeniorityLevel ON CandidateProfiles(SeniorityLevel);

-- -- Scores Table
-- CREATE TABLE Scores (
--     ScoreId INT IDENTITY(1,1) PRIMARY KEY,
--     ResumeId INT NOT NULL,
--     JobId INT NOT NULL,
--     OverallScore DECIMAL(5,4) NOT NULL,
--     SubscoresJSON NVARCHAR(MAX) NOT NULL,
--     EvidenceJSON NVARCHAR(MAX),
--     ModelVersion NVARCHAR(50) NOT NULL,
--     ComputedAt DATETIME2 DEFAULT GETUTCDATE(),
--     RecruiterRating INT,
--     RecruiterNotes NVARCHAR(MAX),
--     CONSTRAINT FK_Scores_Resumes FOREIGN KEY (ResumeId) REFERENCES Resumes(ResumeId),
--     CONSTRAINT FK_Scores_Jobs FOREIGN KEY (JobId) REFERENCES Jobs(JobId),
--     CONSTRAINT CHK_OverallScore CHECK (OverallScore BETWEEN 0 AND 1),
--     CONSTRAINT CHK_RecruiterRating CHECK (RecruiterRating IS NULL OR RecruiterRating BETWEEN 1 AND 5),
--     CONSTRAINT CHK_SubscoresJSON CHECK (ISJSON(SubscoresJSON) = 1),
--     CONSTRAINT CHK_EvidenceJSON CHECK (EvidenceJSON IS NULL OR ISJSON(EvidenceJSON) = 1)
-- );

-- CREATE INDEX IDX_Scores_ResumeJob ON Scores(ResumeId, JobId);
-- CREATE INDEX IDX_Scores_OverallScore ON Scores(OverallScore DESC);
-- CREATE INDEX IDX_Scores_ComputedAt ON Scores(ComputedAt DESC);

-- -- Audit Log Table
-- CREATE TABLE AuditLog (
--     EventId BIGINT IDENTITY(1,1) PRIMARY KEY,
--     Actor NVARCHAR(200),
--     Action NVARCHAR(100) NOT NULL,
--     EntityType NVARCHAR(50),
--     EntityId INT,
--     PayloadJSON NVARCHAR(MAX),
--     IPAddress NVARCHAR(45),
--     UserAgent NVARCHAR(500),
--     CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
--     CONSTRAINT CHK_AuditPayloadJSON CHECK (PayloadJSON IS NULL OR ISJSON(PayloadJSON) = 1)
-- );

-- CREATE INDEX IDX_AuditLog_Actor ON AuditLog(Actor);
-- CREATE INDEX IDX_AuditLog_Action ON AuditLog(Action);
-- CREATE INDEX IDX_AuditLog_CreatedAt ON AuditLog(CreatedAt DESC);
-- CREATE INDEX IDX_AuditLog_EntityType ON AuditLog(EntityType, EntityId);

-- -- Model Registry Table
-- CREATE TABLE ModelRegistry (
--     ModelId INT IDENTITY(1,1) PRIMARY KEY,
--     Name NVARCHAR(100) NOT NULL,
--     Version NVARCHAR(50) NOT NULL,
--     Type NVARCHAR(50) NOT NULL,
--     Description NVARCHAR(500),
--     FilePath NVARCHAR(500),
--     SHA256Hash NVARCHAR(64),
--     ParametersJSON NVARCHAR(MAX),
--     PerformanceMetricsJSON NVARCHAR(MAX),
--     IsActive BIT DEFAULT 0,
--     CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
--     CreatedBy NVARCHAR(100),
--     CONSTRAINT UQ_ModelRegistry_NameVersion UNIQUE (Name, Version),
--     CONSTRAINT CHK_ModelType CHECK (Type IN ('NER', 'Embedding', 'Scoring', 'Classification')),
--     CONSTRAINT CHK_ParametersJSON CHECK (ParametersJSON IS NULL OR ISJSON(ParametersJSON) = 1),
--     CONSTRAINT CHK_PerformanceMetricsJSON CHECK (PerformanceMetricsJSON IS NULL OR ISJSON(PerformanceMetricsJSON) = 1)
-- );

-- CREATE INDEX IDX_ModelRegistry_Active ON ModelRegistry(IsActive, Type);

-- -- Feedback Table
-- CREATE TABLE Feedback (
--     FeedbackId INT IDENTITY(1,1) PRIMARY KEY,
--     ScoreId INT NOT NULL,
--     FeedbackType NVARCHAR(50) NOT NULL,
--     FeedbackData NVARCHAR(MAX),
--     SubmittedBy NVARCHAR(200),
--     SubmittedAt DATETIME2 DEFAULT GETUTCDATE(),
--     IsProcessed BIT DEFAULT 0,
--     ProcessedAt DATETIME2,
--     CONSTRAINT FK_Feedback_Scores FOREIGN KEY (ScoreId) REFERENCES Scores(ScoreId),
--     CONSTRAINT CHK_FeedbackType CHECK (FeedbackType IN ('Correction', 'Rating', 'Mapping', 'Other')),
--     CONSTRAINT CHK_FeedbackData CHECK (FeedbackData IS NULL OR ISJSON(FeedbackData) = 1)
-- );

-- CREATE INDEX IDX_Feedback_ScoreId ON Feedback(ScoreId);
-- CREATE INDEX IDX_Feedback_IsProcessed ON Feedback(IsProcessed);

-- -- Skills Ontology Table (for normalization)
-- CREATE TABLE SkillsOntology (
--     SkillId INT IDENTITY(1,1) PRIMARY KEY,
--     CanonicalName NVARCHAR(200) NOT NULL,
--     Category NVARCHAR(100),
--     Aliases NVARCHAR(MAX),
--     Description NVARCHAR(500),
--     Source NVARCHAR(50) DEFAULT 'Custom',
--     ExternalId NVARCHAR(100),
--     IsActive BIT DEFAULT 1,
--     CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
--     UpdatedAt DATETIME2 DEFAULT GETUTCDATE(),
--     CONSTRAINT UQ_SkillsOntology_CanonicalName UNIQUE (CanonicalName),
--     CONSTRAINT CHK_SkillSource CHECK (Source IN ('ONET', 'ESCO', 'Custom', 'LinkedIn'))
-- );

-- CREATE INDEX IDX_SkillsOntology_Category ON SkillsOntology(Category);
-- CREATE INDEX IDX_SkillsOntology_Active ON SkillsOntology(IsActive);

-- -- Users Table (for authentication and authorization)
-- CREATE TABLE Users (
--     UserId INT IDENTITY(1,1) PRIMARY KEY,
--     Username NVARCHAR(100) NOT NULL,
--     Email NVARCHAR(255) NOT NULL,
--     PasswordHash NVARCHAR(255),
--     FullName NVARCHAR(200),
--     Role NVARCHAR(50) NOT NULL DEFAULT 'Recruiter',
--     IsActive BIT DEFAULT 1,
--     LastLoginAt DATETIME2,
--     CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
--     UpdatedAt DATETIME2 DEFAULT GETUTCDATE(),
--     CONSTRAINT UQ_Users_Username UNIQUE (Username),
--     CONSTRAINT UQ_Users_Email UNIQUE (Email),
--     CONSTRAINT CHK_UserRole CHECK (Role IN ('Admin', 'Recruiter', 'HiringManager', 'Viewer'))
-- );

-- CREATE INDEX IDX_Users_Email ON Users(Email);
-- CREATE INDEX IDX_Users_Role ON Users(Role) WHERE IsActive = 1;

-- -- =====================================================
-- -- STORED PROCEDURES
-- -- =====================================================

-- -- Get Candidate Scores for a Job
-- GO
-- CREATE PROCEDURE sp_GetCandidateScoresForJob
--     @JobId INT,
--     @MinScore DECIMAL(5,4) = 0.0,
--     @TopN INT = 100
-- AS
-- BEGIN
--     SET NOCOUNT ON;
    
--     SELECT TOP (@TopN)
--         s.ScoreId,
--         s.ResumeId,
--         r.CandidateName,
--         r.Email,
--         s.OverallScore,
--         s.SubscoresJSON,
--         s.ComputedAt,
--         s.ModelVersion,
--         cp.SeniorityLevel,
--         cp.TotalExperienceYears
--     FROM Scores s
--     INNER JOIN Resumes r ON s.ResumeId = r.ResumeId
--     LEFT JOIN CandidateProfiles cp ON r.ResumeId = cp.ResumeId
--     WHERE s.JobId = @JobId
--         AND s.OverallScore >= @MinScore
--         AND r.IsDeleted = 0
--     ORDER BY s.OverallScore DESC, s.ComputedAt DESC;
-- END;
-- GO

-- -- Get Candidate Profile with Latest Score
-- GO
-- CREATE PROCEDURE sp_GetCandidateProfileWithScore
--     @ResumeId INT,
--     @JobId INT = NULL
-- AS
-- BEGIN
--     SET NOCOUNT ON;
    
--     SELECT 
--         r.ResumeId,
--         r.CandidateName,
--         r.Email,
--         r.Phone,
--         r.RawFileUri,
--         r.CreatedAt,
--         cp.SkillsJSON,
--         cp.WorkHistoryJSON,
--         cp.EducationJSON,
--         cp.CertificationsJSON,
--         cp.SummaryText,
--         cp.TotalExperienceYears,
--         cp.SeniorityLevel,
--         cp.Industries,
--         s.ScoreId,
--         s.JobId,
--         s.OverallScore,
--         s.SubscoresJSON,
--         s.EvidenceJSON,
--         s.ComputedAt,
--         j.Title AS JobTitle
--     FROM Resumes r
--     LEFT JOIN CandidateProfiles cp ON r.ResumeId = cp.ResumeId
--     LEFT JOIN Scores s ON r.ResumeId = s.ResumeId 
--         AND (@JobId IS NULL OR s.JobId = @JobId)
--         AND s.ScoreId = (
--             SELECT TOP 1 ScoreId 
--             FROM Scores 
--             WHERE ResumeId = r.ResumeId 
--                 AND (@JobId IS NULL OR JobId = @JobId)
--             ORDER BY ComputedAt DESC
--         )
--     LEFT JOIN Jobs j ON s.JobId = j.JobId
--     WHERE r.ResumeId = @ResumeId
--         AND r.IsDeleted = 0;
-- END;
-- GO

-- -- Insert Audit Log Entry
-- GO
-- CREATE PROCEDURE sp_InsertAuditLog
--     @Actor NVARCHAR(200),
--     @Action NVARCHAR(100),
--     @EntityType NVARCHAR(50) = NULL,
--     @EntityId INT = NULL,
--     @PayloadJSON NVARCHAR(MAX) = NULL,
--     @IPAddress NVARCHAR(45) = NULL,
--     @UserAgent NVARCHAR(500) = NULL
-- AS
-- BEGIN
--     SET NOCOUNT ON;
    
--     INSERT INTO AuditLog (Actor, Action, EntityType, EntityId, PayloadJSON, IPAddress, UserAgent)
--     VALUES (@Actor, @Action, @EntityType, @EntityId, @PayloadJSON, @IPAddress, @UserAgent);
-- END;
-- GO

-- -- =====================================================
-- -- VIEWS
-- -- =====================================================

-- -- View: Recent Candidates
-- GO
-- CREATE VIEW vw_RecentCandidates AS
-- SELECT 
--     r.ResumeId,
--     r.CandidateName,
--     r.Email,
--     r.Phone,
--     r.FileFormat,
--     r.Source,
--     r.ParseStatus,
--     r.CreatedAt,
--     cp.TotalExperienceYears,
--     cp.SeniorityLevel,
--     cp.Industries,
--     (SELECT COUNT(*) FROM Scores WHERE ResumeId = r.ResumeId) AS TotalScores
-- FROM Resumes r
-- LEFT JOIN CandidateProfiles cp ON r.ResumeId = cp.ResumeId
-- WHERE r.IsDeleted = 0;
-- GO

-- -- View: Job Statistics
-- GO
-- CREATE VIEW vw_JobStatistics AS
-- SELECT 
--     j.JobId,
--     j.Title,
--     j.Department,
--     j.Status,
--     j.CreatedAt,
--     COUNT(DISTINCT s.ResumeId) AS TotalCandidates,
--     AVG(s.OverallScore) AS AverageScore,
--     MAX(s.OverallScore) AS TopScore,
--     COUNT(CASE WHEN s.OverallScore >= 0.8 THEN 1 END) AS HighQualityCandidates
-- FROM Jobs j
-- LEFT JOIN Scores s ON j.JobId = s.JobId
-- WHERE j.IsDeleted = 0
-- GROUP BY j.JobId, j.Title, j.Department, j.Status, j.CreatedAt;
-- GO

-- -- =====================================================
-- -- SAMPLE DATA (Optional - for testing)
-- -- =====================================================

-- -- Insert default admin user
-- INSERT INTO Users (Username, Email, PasswordHash, FullName, Role)
-- VALUES ('admin', 'admin@nextgenworkspace.com', 'HASHED_PASSWORD_HERE', 'System Administrator', 'Admin');

-- -- Insert sample skills ontology
-- INSERT INTO SkillsOntology (CanonicalName, Category, Aliases, Source) VALUES
-- ('Python', 'Programming', '["Python3", "Python 3", "Python Programming"]', 'Custom'),
-- ('JavaScript', 'Programming', '["JS", "Javascript", "ECMAScript"]', 'Custom'),
-- ('.NET Core', 'Framework', '[".NET", "DotNet Core", "ASP.NET Core"]', 'Custom'),
-- ('React', 'Framework', '["ReactJS", "React.js", "React JS"]', 'Custom'),
-- ('SQL', 'Database', '["SQL Server", "T-SQL", "Transact-SQL", "MS SQL"]', 'Custom'),
-- ('Machine Learning', 'Data Science', '["ML", "Machine Learning", "ML Engineering"]', 'Custom'),
-- ('NLP', 'Data Science', '["Natural Language Processing", "Text Analytics"]', 'Custom'),
-- ('Docker', 'DevOps', '["Docker Container", "Containerization"]', 'Custom'),
-- ('Azure', 'Cloud', '["Microsoft Azure", "Azure Cloud"]', 'Custom'),
-- ('Git', 'Version Control', '["GitHub", "GitLab", "Version Control"]', 'Custom');

-- -- Insert sample job
-- INSERT INTO Jobs (Title, Department, Description, RequirementsText, WeightConfigJSON, OwnerId)
-- VALUES (
--     'Senior AI Engineer',
--     'Engineering',
--     'We are seeking an experienced AI Engineer to build resume parsing systems.',
--     'Required: Python, NLP, Machine Learning, .NET Core, SQL. Preferred: Azure, Docker, React',
--     '{"skills":0.35,"experience":0.25,"domain":0.15,"education":0.10,"certifications":0.10,"recency":0.05}',
--     'admin'
-- );

-- -- =====================================================
-- -- INDEXES FOR PERFORMANCE
-- -- =====================================================

-- -- Additional covering indexes for common queries
-- CREATE INDEX IDX_Scores_JobOverall ON Scores(JobId, OverallScore DESC) INCLUDE (ResumeId, ComputedAt);
-- CREATE INDEX IDX_CandidateProfiles_Experience ON CandidateProfiles(TotalExperienceYears, SeniorityLevel);

-- -- =====================================================
-- -- MAINTENANCE
-- -- =====================================================

-- -- Enable Query Store for performance monitoring
-- ALTER DATABASE ResumeScoring SET QUERY_STORE = ON;

-- PRINT 'Database schema created successfully!';
-- PRINT 'Total Tables: 11';
-- PRINT 'Total Stored Procedures: 3';
-- PRINT 'Total Views: 2';
-- GO
