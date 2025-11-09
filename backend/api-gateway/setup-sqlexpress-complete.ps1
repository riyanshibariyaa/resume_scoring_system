# Complete Setup for SQL Server Express
# Run as Administrator

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Setup SQL Server Express" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Must run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell → Run as Administrator" -ForegroundColor Yellow
    pause
    exit
}

# Step 1: Stop Docker SQL Server
Write-Host "Step 1: Stopping Docker SQL Server..." -ForegroundColor Yellow
try {
    docker stop resume-scoring-db 2>$null
    docker rm resume-scoring-db 2>$null
    Write-Host "  [OK] Docker container stopped" -ForegroundColor Green
} catch {
    Write-Host "  [INFO] Docker container not running or doesn't exist" -ForegroundColor Gray
}
Write-Host ""

# Step 2: Start SQLEXPRESS
Write-Host "Step 2: Starting SQL Server Express..." -ForegroundColor Yellow
$service = Get-Service -Name "MSSQL`$SQLEXPRESS" -ErrorAction SilentlyContinue

if (-not $service) {
    Write-Host "  [ERROR] SQL Server Express not installed!" -ForegroundColor Red
    Write-Host "  Please install SQL Server Express first" -ForegroundColor Yellow
    pause
    exit
}

if ($service.Status -ne 'Running') {
    try {
        Start-Service "MSSQL`$SQLEXPRESS" -ErrorAction Stop
        Start-Sleep -Seconds 2
        Write-Host "  [OK] SQL Server Express started" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Could not start SQL Server Express: $_" -ForegroundColor Red
        pause
        exit
    }
} else {
    Write-Host "  [OK] SQL Server Express already running" -ForegroundColor Green
}

# Set to automatic
try {
    Set-Service "MSSQL`$SQLEXPRESS" -StartupType Automatic -ErrorAction Stop
    Write-Host "  [OK] Set to start automatically" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Could not set automatic startup" -ForegroundColor Yellow
}
Write-Host ""

# Step 3: Create Database
Write-Host "Step 3: Creating ResumeScoring database..." -ForegroundColor Yellow
try {
    $result = sqlcmd -S "localhost\SQLEXPRESS" -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ResumeScoring') CREATE DATABASE ResumeScoring" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Database created or already exists" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Database creation had warnings" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [ERROR] Could not create database: $_" -ForegroundColor Red
    pause
    exit
}
Write-Host ""

# Step 4: Create Tables
Write-Host "Step 4: Creating database tables..." -ForegroundColor Yellow

$sqlScript = @"
USE ResumeScoring;

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
END

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
END

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
END

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
END

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
END

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
END

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
END

SELECT 'Setup Complete!' as Result;
"@

try {
    $sqlScript | sqlcmd -S "localhost\SQLEXPRESS" -d ResumeScoring 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Tables created successfully" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Some warnings during table creation" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [ERROR] Could not create tables: $_" -ForegroundColor Red
}
Write-Host ""

# Step 5: Verify Setup
Write-Host "Step 5: Verifying setup..." -ForegroundColor Yellow
try {
    $tableCount = sqlcmd -S "localhost\SQLEXPRESS" -d ResumeScoring -Q "SELECT COUNT(*) FROM sys.tables" -h -1 -W 2>&1
    Write-Host "  [OK] Found $tableCount tables" -ForegroundColor Green
    
    $jobCount = sqlcmd -S "localhost\SQLEXPRESS" -d ResumeScoring -Q "SELECT COUNT(*) FROM Jobs" -h -1 -W 2>&1
    Write-Host "  [OK] Found $jobCount job(s)" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Could not verify setup" -ForegroundColor Yellow
}
Write-Host ""

# Step 6: Update Connection String
Write-Host "Step 6: Updating connection string..." -ForegroundColor Yellow

$projectPath = "E:\SK\resume-scoring-system\backend\api-gateway"
$connectionString = "Server=localhost\\SQLEXPRESS;Database=ResumeScoring;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True;Encrypt=False"

# Update appsettings.json
$appsettingsPath = Join-Path $projectPath "appsettings.json"
if (Test-Path $appsettingsPath) {
    $content = Get-Content $appsettingsPath -Raw | ConvertFrom-Json
    if (-not $content.ConnectionStrings) {
        $content | Add-Member -NotePropertyName "ConnectionStrings" -NotePropertyValue @{} -Force
    }
    $content.ConnectionStrings.DefaultConnection = $connectionString
    $content | ConvertTo-Json -Depth 10 | Set-Content $appsettingsPath
    Write-Host "  [OK] Updated appsettings.json" -ForegroundColor Green
}

# Update appsettings.Development.json
$appsettingsDevPath = Join-Path $projectPath "appsettings.Development.json"
if (Test-Path $appsettingsDevPath) {
    $content = Get-Content $appsettingsDevPath -Raw | ConvertFrom-Json
    if (-not $content.ConnectionStrings) {
        $content | Add-Member -NotePropertyName "ConnectionStrings" -NotePropertyValue @{} -Force
    }
    $content.ConnectionStrings.DefaultConnection = $connectionString
    $content | ConvertTo-Json -Depth 10 | Set-Content $appsettingsDevPath
    Write-Host "  [OK] Updated appsettings.Development.json" -ForegroundColor Green
}
Write-Host ""

# Summary
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  - Docker SQL Server: Stopped" -ForegroundColor White
Write-Host "  - SQL Server Express: Running" -ForegroundColor White
Write-Host "  - Database: ResumeScoring created" -ForegroundColor White
Write-Host "  - Tables: 6 tables created" -ForegroundColor White
Write-Host "  - Sample Data: 1 job inserted" -ForegroundColor White
Write-Host "  - Connection String: Updated" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. cd E:\SK\resume-scoring-system\backend\api-gateway" -ForegroundColor Cyan
Write-Host "  2. dotnet run" -ForegroundColor Cyan
Write-Host "  3. Upload resume - it will work!" -ForegroundColor Cyan
Write-Host ""
Write-Host "You're all set! Press any key to exit..." -ForegroundColor Green
pause
