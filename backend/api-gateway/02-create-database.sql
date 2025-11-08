-- ========================================
-- Resume Scoring System - Database Setup
-- SQL Server Express
-- ========================================

USE master;
GO

-- Drop database if exists (for clean setup)
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'ResumeScoring')
BEGIN
    ALTER DATABASE ResumeScoring SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ResumeScoring;
    PRINT 'Existing database dropped';
END
GO

-- Create database
CREATE DATABASE ResumeScoring;
GO

PRINT 'Database ResumeScoring created successfully';
GO

USE ResumeScoring;
GO

-- ========================================
-- Table: Resumes
-- ========================================
CREATE TABLE [dbo].[Resumes] (
    [ResumeId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [CandidateName] NVARCHAR(200) NULL,
    [Email] NVARCHAR(200) NULL,
    [Phone] NVARCHAR(50) NULL,
    [FileName] NVARCHAR(500) NOT NULL,
    [FileType] NVARCHAR(50) NULL,
    [FileHash] NVARCHAR(64) NULL,
    [RawText] NVARCHAR(MAX) NULL,
    [UploadedAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    [ProcessedAt] DATETIME2(7) NULL,
    CONSTRAINT [UQ_Resumes_FileHash] UNIQUE ([FileHash])
);
GO

PRINT 'Table Resumes created';
GO

-- ========================================
-- Table: Jobs
-- ========================================
CREATE TABLE [dbo].[Jobs] (
    [JobId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [Title] NVARCHAR(200) NOT NULL,
    [Description] NVARCHAR(MAX) NOT NULL,
    [RequiredSkills] NVARCHAR(MAX) NULL,
    [WeightConfig] NVARCHAR(MAX) NULL,
    [CreatedAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt] DATETIME2(7) NULL
);
GO

PRINT 'Table Jobs created';
GO

-- ========================================
-- Table: ResumeScores
-- ========================================
CREATE TABLE [dbo].[ResumeScores] (
    [ScoreId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [ResumeId] INT NOT NULL,
    [JobId] INT NOT NULL,
    [TotalScore] DECIMAL(5,2) NOT NULL,
    [SkillScore] DECIMAL(5,2) NULL,
    [ExperienceScore] DECIMAL(5,2) NULL,
    [EducationScore] DECIMAL(5,2) NULL,
    [KeywordScore] DECIMAL(5,2) NULL,
    [DetailedScores] NVARCHAR(MAX) NULL,
    [ScoredAt] DATETIME2(7) NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT [FK_ResumeScores_Resumes] FOREIGN KEY ([ResumeId]) REFERENCES [Resumes]([ResumeId]) ON DELETE CASCADE,
    CONSTRAINT [FK_ResumeScores_Jobs] FOREIGN KEY ([JobId]) REFERENCES [Jobs]([JobId]) ON DELETE CASCADE,
    CONSTRAINT [UQ_ResumeScores_ResumeJob] UNIQUE ([ResumeId], [JobId])
);
GO

PRINT 'Table ResumeScores created';
GO

-- ========================================
-- Table: Skills (extracted from resumes)
-- ========================================
CREATE TABLE [dbo].[Skills] (
    [SkillId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [ResumeId] INT NOT NULL,
    [SkillName] NVARCHAR(200) NOT NULL,
    [SkillCategory] NVARCHAR(100) NULL,
    [YearsOfExperience] DECIMAL(4,1) NULL,
    [ProficiencyLevel] NVARCHAR(50) NULL,
    CONSTRAINT [FK_Skills_Resumes] FOREIGN KEY ([ResumeId]) REFERENCES [Resumes]([ResumeId]) ON DELETE CASCADE
);
GO

PRINT 'Table Skills created';
GO

-- ========================================
-- Table: WorkExperience
-- ========================================
CREATE TABLE [dbo].[WorkExperience] (
    [ExperienceId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [ResumeId] INT NOT NULL,
    [CompanyName] NVARCHAR(200) NULL,
    [JobTitle] NVARCHAR(200) NULL,
    [StartDate] DATE NULL,
    [EndDate] DATE NULL,
    [IsCurrent] BIT NOT NULL DEFAULT 0,
    [Description] NVARCHAR(MAX) NULL,
    [DurationMonths] INT NULL,
    CONSTRAINT [FK_WorkExperience_Resumes] FOREIGN KEY ([ResumeId]) REFERENCES [Resumes]([ResumeId]) ON DELETE CASCADE
);
GO

PRINT 'Table WorkExperience created';
GO

-- ========================================
-- Table: Education
-- ========================================
CREATE TABLE [dbo].[Education] (
    [EducationId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [ResumeId] INT NOT NULL,
    [InstitutionName] NVARCHAR(200) NULL,
    [Degree] NVARCHAR(200) NULL,
    [FieldOfStudy] NVARCHAR(200) NULL,
    [StartDate] DATE NULL,
    [EndDate] DATE NULL,
    [GPA] DECIMAL(3,2) NULL,
    CONSTRAINT [FK_Education_Resumes] FOREIGN KEY ([ResumeId]) REFERENCES [Resumes]([ResumeId]) ON DELETE CASCADE
);
GO

PRINT 'Table Education created';
GO

-- ========================================
-- Indexes for Performance
-- ========================================

-- Resumes indexes
CREATE INDEX [IX_Resumes_UploadedAt] ON [Resumes]([UploadedAt] DESC);
CREATE INDEX [IX_Resumes_Email] ON [Resumes]([Email]);
CREATE INDEX [IX_Resumes_ProcessedAt] ON [Resumes]([ProcessedAt]);
GO

-- Jobs indexes
CREATE INDEX [IX_Jobs_CreatedAt] ON [Jobs]([CreatedAt] DESC);
CREATE INDEX [IX_Jobs_Title] ON [Jobs]([Title]);
GO

-- ResumeScores indexes
CREATE INDEX [IX_ResumeScores_ResumeId] ON [ResumeScores]([ResumeId]);
CREATE INDEX [IX_ResumeScores_JobId] ON [ResumeScores]([JobId]);
CREATE INDEX [IX_ResumeScores_TotalScore] ON [ResumeScores]([TotalScore] DESC);
CREATE INDEX [IX_ResumeScores_ScoredAt] ON [ResumeScores]([ScoredAt] DESC);
GO

-- Skills indexes
CREATE INDEX [IX_Skills_ResumeId] ON [Skills]([ResumeId]);
CREATE INDEX [IX_Skills_SkillName] ON [Skills]([SkillName]);
GO

-- WorkExperience indexes
CREATE INDEX [IX_WorkExperience_ResumeId] ON [WorkExperience]([ResumeId]);
GO

-- Education indexes
CREATE INDEX [IX_Education_ResumeId] ON [Education]([ResumeId]);
GO

PRINT 'Indexes created';
GO

-- ========================================
-- Insert Sample Data (Optional - for testing)
-- ========================================

-- Sample Job
INSERT INTO [Jobs] ([Title], [Description], [RequiredSkills], [CreatedAt])
VALUES 
(
    'Senior Software Engineer',
    'Looking for an experienced software engineer with strong backend development skills.',
    'C#, .NET Core, SQL Server, REST APIs, Entity Framework, Azure',
    GETUTCDATE()
);
GO

PRINT 'Sample data inserted';
GO

-- ========================================
-- Table Information Summary
-- ========================================

SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.is_nullable AS IsNullable,
    c.is_identity AS IsIdentity
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('Resumes', 'Jobs', 'ResumeScores', 'Skills', 'WorkExperience', 'Education')
ORDER BY t.name, c.column_id;
GO

-- ========================================
-- Verification
-- ========================================

PRINT '';
PRINT '========================================';
PRINT 'Database Setup Complete!';
PRINT '========================================';
PRINT '';
PRINT 'Tables created:';
PRINT '  - Resumes';
PRINT '  - Jobs';
PRINT '  - ResumeScores';
PRINT '  - Skills';
PRINT '  - WorkExperience';
PRINT '  - Education';
PRINT '';
PRINT 'Database: ResumeScoring';
PRINT 'Status: Ready for use';
PRINT '';
PRINT 'Next steps:';
PRINT '1. Update appsettings.json with connection string';
PRINT '2. Run: dotnet ef dbcontext scaffold (if using code-first)';
PRINT '   OR skip migrations if using this database-first approach';
PRINT '';
GO
