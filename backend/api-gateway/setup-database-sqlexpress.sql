-- Create ResumeScoring Database and Tables for SQLEXPRESS

USE ResumeScoring;
GO

-- Jobs Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Jobs')
BEGIN
    CREATE TABLE Jobs (
        Id INT PRIMARY KEY IDENTITY(1,1),
        Title NVARCHAR(200) NOT NULL,
        Description NVARCHAR(MAX),
        Requirements NVARCHAR(MAX),
        EducationWeight DECIMAL(5,2) DEFAULT 0.25,
        ExperienceWeight DECIMAL(5,2) DEFAULT 0.35,
        SkillsWeight DECIMAL(5,2) DEFAULT 0.40,
        CreatedAt DATETIME2 DEFAULT GETDATE(),
        UpdatedAt DATETIME2 DEFAULT GETDATE()
    );
    PRINT 'Created Jobs table';
END
GO

-- Resumes Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Resumes')
BEGIN
    CREATE TABLE Resumes (
        Id INT PRIMARY KEY IDENTITY(1,1),
        FileName NVARCHAR(255) NOT NULL,
        UploadedAt DATETIME2 DEFAULT GETDATE(),
        ParsedData NVARCHAR(MAX),
        Name NVARCHAR(200),
        Email NVARCHAR(200),
        Phone NVARCHAR(50),
        RawText NVARCHAR(MAX)
    );
    PRINT 'Created Resumes table';
END
GO

-- Skills Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Skills')
BEGIN
    CREATE TABLE Skills (
        Id INT PRIMARY KEY IDENTITY(1,1),
        ResumeId INT NOT NULL,
        SkillName NVARCHAR(200) NOT NULL,
        YearsOfExperience INT,
        FOREIGN KEY (ResumeId) REFERENCES Resumes(Id) ON DELETE CASCADE
    );
    PRINT 'Created Skills table';
END
GO

-- WorkExperience Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WorkExperience')
BEGIN
    CREATE TABLE WorkExperience (
        Id INT PRIMARY KEY IDENTITY(1,1),
        ResumeId INT NOT NULL,
        Company NVARCHAR(200),
        Position NVARCHAR(200),
        StartDate DATE,
        EndDate DATE,
        Description NVARCHAR(MAX),
        FOREIGN KEY (ResumeId) REFERENCES Resumes(Id) ON DELETE CASCADE
    );
    PRINT 'Created WorkExperience table';
END
GO

-- Education Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Education')
BEGIN
    CREATE TABLE Education (
        Id INT PRIMARY KEY IDENTITY(1,1),
        ResumeId INT NOT NULL,
        Institution NVARCHAR(200),
        Degree NVARCHAR(200),
        FieldOfStudy NVARCHAR(200),
        GraduationDate DATE,
        FOREIGN KEY (ResumeId) REFERENCES Resumes(Id) ON DELETE CASCADE
    );
    PRINT 'Created Education table';
END
GO

-- ResumeScores Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ResumeScores')
BEGIN
    CREATE TABLE ResumeScores (
        Id INT PRIMARY KEY IDENTITY(1,1),
        ResumeId INT NOT NULL,
        JobId INT NOT NULL,
        TotalScore DECIMAL(5,2),
        EducationScore DECIMAL(5,2),
        ExperienceScore DECIMAL(5,2),
        SkillsScore DECIMAL(5,2),
        ScoredAt DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (ResumeId) REFERENCES Resumes(Id) ON DELETE CASCADE,
        FOREIGN KEY (JobId) REFERENCES Jobs(Id) ON DELETE CASCADE
    );
    PRINT 'Created ResumeScores table';
END
GO

-- Insert sample job
IF NOT EXISTS (SELECT * FROM Jobs WHERE Title = 'Senior Software Engineer')
BEGIN
    INSERT INTO Jobs (Title, Description, Requirements, EducationWeight, ExperienceWeight, SkillsWeight)
    VALUES (
        'Senior Software Engineer',
        'Looking for an experienced software engineer to join our team',
        'Bachelor''s degree in Computer Science, 5+ years experience, proficiency in C#, .NET, SQL Server, React',
        0.25,
        0.35,
        0.40
    );
    PRINT 'Inserted sample job';
END
GO

PRINT 'Database setup complete!';
GO
