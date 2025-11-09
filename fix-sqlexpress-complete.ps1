# SQL Server Express - Complete Diagnostic and Fix
# Run as Administrator

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "SQL Server Express Complete Diagnostic" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Must run as Administrator!" -ForegroundColor Red
    pause
    exit
}

Write-Host "Step 1: Checking SQL Server Services..." -ForegroundColor Yellow
Write-Host ""

# Check SQLEXPRESS service
$sqlService = Get-Service -Name "MSSQL`$SQLEXPRESS" -ErrorAction SilentlyContinue
if ($sqlService) {
    Write-Host "  SQL Server (SQLEXPRESS):" -ForegroundColor White
    Write-Host "    Status: $($sqlService.Status)" -ForegroundColor $(if ($sqlService.Status -eq 'Running') { 'Green' } else { 'Red' })
    Write-Host "    Startup: $($sqlService.StartType)" -ForegroundColor Gray
} else {
    Write-Host "  [ERROR] SQL Server (SQLEXPRESS) not found!" -ForegroundColor Red
    Write-Host "  Please install SQL Server Express" -ForegroundColor Yellow
    pause
    exit
}

# Check SQL Browser service
$browserService = Get-Service -Name "SQLBrowser" -ErrorAction SilentlyContinue
if ($browserService) {
    Write-Host ""
    Write-Host "  SQL Server Browser:" -ForegroundColor White
    Write-Host "    Status: $($browserService.Status)" -ForegroundColor $(if ($browserService.Status -eq 'Running') { 'Green' } else { 'Yellow' })
    Write-Host "    Startup: $($browserService.StartType)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Step 2: Starting/Restarting Services..." -ForegroundColor Yellow
Write-Host ""

# Stop SQLEXPRESS first
try {
    Write-Host "  Stopping SQL Server (SQLEXPRESS)..." -ForegroundColor Gray
    Stop-Service "MSSQL`$SQLEXPRESS" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
} catch {}

# Start SQL Browser if exists
if ($browserService) {
    try {
        Write-Host "  Starting SQL Server Browser..." -ForegroundColor Gray
        Set-Service "SQLBrowser" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service "SQLBrowser" -ErrorAction SilentlyContinue
        Write-Host "    [OK] SQL Server Browser started" -ForegroundColor Green
    } catch {
        Write-Host "    [WARNING] Could not start SQL Browser" -ForegroundColor Yellow
    }
}

# Start SQLEXPRESS
try {
    Write-Host "  Starting SQL Server (SQLEXPRESS)..." -ForegroundColor Gray
    Start-Service "MSSQL`$SQLEXPRESS" -ErrorAction Stop
    Start-Sleep -Seconds 5
    Write-Host "    [OK] SQL Server started" -ForegroundColor Green
} catch {
    Write-Host "    [ERROR] Failed to start: $_" -ForegroundColor Red
    pause
    exit
}

# Set to automatic
try {
    Set-Service "MSSQL`$SQLEXPRESS" -StartupType Automatic -ErrorAction Stop
    Write-Host "    [OK] Set to automatic startup" -ForegroundColor Green
} catch {}

Write-Host ""
Write-Host "Step 3: Enabling SQL Server Protocols..." -ForegroundColor Yellow
Write-Host ""

# Enable TCP/IP and Named Pipes using registry
$regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*\MSSQLServer\SuperSocketNetLib"

try {
    # Find the correct instance path
    $instancePath = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server" | 
        Where-Object { $_.GetValue("") -eq "SQLEXPRESS" } | 
        Select-Object -First 1 -ExpandProperty PSChildName
    
    if ($instancePath) {
        $npPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instancePath\MSSQLServer\SuperSocketNetLib\Np"
        $tcpPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instancePath\MSSQLServer\SuperSocketNetLib\Tcp"
        
        # Enable Named Pipes
        if (Test-Path $npPath) {
            Set-ItemProperty -Path $npPath -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
            Write-Host "  [OK] Named Pipes enabled" -ForegroundColor Green
        }
        
        # Enable TCP/IP
        if (Test-Path $tcpPath) {
            Set-ItemProperty -Path $tcpPath -Name "Enabled" -Value 1 -ErrorAction SilentlyContinue
            Write-Host "  [OK] TCP/IP enabled" -ForegroundColor Green
        }
        
        Write-Host "  [INFO] Restarting SQL Server for protocol changes..." -ForegroundColor Gray
        Restart-Service "MSSQL`$SQLEXPRESS" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    }
} catch {
    Write-Host "  [WARNING] Could not enable protocols via registry" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 4: Testing Connection..." -ForegroundColor Yellow
Write-Host ""

# Test connection
$connectionTests = @(
    @{Name="Named Pipes"; Server="localhost\SQLEXPRESS"},
    @{Name="TCP/IP (dot)"; Server=".\SQLEXPRESS"},
    @{Name="TCP/IP (localhost)"; Server="localhost\SQLEXPRESS"},
    @{Name="TCP/IP (127.0.0.1)"; Server="127.0.0.1\SQLEXPRESS"}
)

$workingConnection = $null

foreach ($test in $connectionTests) {
    try {
        $result = sqlcmd -S "$($test.Server)" -Q "SELECT @@VERSION" -l 2 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] $($test.Name): Connected!" -ForegroundColor Green
            $workingConnection = $test.Server
            break
        } else {
            Write-Host "  [FAIL] $($test.Name): Failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] $($test.Name): Failed" -ForegroundColor Red
    }
}

if (-not $workingConnection) {
    Write-Host ""
    Write-Host "[ERROR] Could not connect to SQL Server!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible solutions:" -ForegroundColor Yellow
    Write-Host "  1. Open SQL Server Configuration Manager" -ForegroundColor White
    Write-Host "     - Search for 'SQL Server Configuration Manager'" -ForegroundColor Gray
    Write-Host "     - Enable TCP/IP and Named Pipes protocols" -ForegroundColor Gray
    Write-Host "     - Restart SQL Server service" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Check Windows Firewall" -ForegroundColor White
    Write-Host "     - Temporarily disable and test" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Reinstall SQL Server Express" -ForegroundColor White
    Write-Host ""
    pause
    exit
}

Write-Host ""
Write-Host "Step 5: Creating/Verifying Database..." -ForegroundColor Yellow
Write-Host ""

# Create database
try {
    sqlcmd -S "$workingConnection" -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ResumeScoring') CREATE DATABASE ResumeScoring" 2>&1 | Out-Null
    Write-Host "  [OK] Database ResumeScoring ready" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Database creation had issues" -ForegroundColor Yellow
}

# Create tables
$sqlScript = @"
USE ResumeScoring;

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Jobs')
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

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Resumes')
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

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Skills')
CREATE TABLE Skills (
    Id INT PRIMARY KEY IDENTITY(1,1),
    ResumeId INT NOT NULL,
    SkillName NVARCHAR(200) NOT NULL,
    YearsOfExperience INT,
    FOREIGN KEY (ResumeId) REFERENCES Resumes(Id) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WorkExperience')
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

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Education')
CREATE TABLE Education (
    Id INT PRIMARY KEY IDENTITY(1,1),
    ResumeId INT NOT NULL,
    Institution NVARCHAR(200),
    Degree NVARCHAR(200),
    FieldOfStudy NVARCHAR(200),
    GraduationDate DATE,
    FOREIGN KEY (ResumeId) REFERENCES Resumes(Id) ON DELETE CASCADE
);

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ResumeScores')
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

IF NOT EXISTS (SELECT * FROM Jobs)
INSERT INTO Jobs (Title, Description, Requirements, EducationWeight, ExperienceWeight, SkillsWeight)
VALUES ('Senior Software Engineer', 'Looking for an experienced software engineer', 'Bachelor degree, 5+ years experience', 0.25, 0.35, 0.40);
"@

try {
    $sqlScript | sqlcmd -S "$workingConnection" -d ResumeScoring 2>&1 | Out-Null
    Write-Host "  [OK] Tables created" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Table creation had issues" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 6: Updating Connection String..." -ForegroundColor Yellow
Write-Host ""

$projectPath = "E:\SK\resume-scoring-system\backend\api-gateway"
$connectionString = "Server=$workingConnection;Database=ResumeScoring;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True;Encrypt=False"

# Update appsettings.json
$appsettingsPath = Join-Path $projectPath "appsettings.json"
if (Test-Path $appsettingsPath) {
    try {
        $content = Get-Content $appsettingsPath -Raw | ConvertFrom-Json
        if (-not $content.ConnectionStrings) {
            $content | Add-Member -NotePropertyName "ConnectionStrings" -NotePropertyValue @{} -Force
        }
        $content.ConnectionStrings.DefaultConnection = $connectionString
        $content | ConvertTo-Json -Depth 10 | Set-Content $appsettingsPath
        Write-Host "  [OK] Updated appsettings.json" -ForegroundColor Green
    } catch {
        Write-Host "  [WARNING] Could not update appsettings.json" -ForegroundColor Yellow
    }
}

# Update appsettings.Development.json
$appsettingsDevPath = Join-Path $projectPath "appsettings.Development.json"
if (Test-Path $appsettingsDevPath) {
    try {
        $content = Get-Content $appsettingsDevPath -Raw | ConvertFrom-Json
        if (-not $content.ConnectionStrings) {
            $content | Add-Member -NotePropertyName "ConnectionStrings" -NotePropertyValue @{} -Force
        }
        $content.ConnectionStrings.DefaultConnection = $connectionString
        $content | ConvertTo-Json -Depth 10 | Set-Content $appsettingsDevPath
        Write-Host "  [OK] Updated appsettings.Development.json" -ForegroundColor Green
    } catch {
        Write-Host "  [WARNING] Could not update appsettings.Development.json" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Working connection: $workingConnection" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. cd E:\SK\resume-scoring-system\backend\api-gateway" -ForegroundColor Cyan
Write-Host "  2. dotnet run" -ForegroundColor Cyan
Write-Host "  3. Upload resume - it should work!" -ForegroundColor Cyan
Write-Host ""
pause
