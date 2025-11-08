# SQL Server Express Detection and Setup
# Run this script as Administrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SQL Server Express - Detection & Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check if SQL Server Express is installed
Write-Host "1. Checking for SQL Server Express installation..." -ForegroundColor Yellow
$sqlServices = Get-Service -Name "*SQL*" -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName -like "*SQL Server*"}

if ($sqlServices) {
    Write-Host "   Found SQL Server services:" -ForegroundColor Green
    $sqlServices | ForEach-Object {
        Write-Host "   - $($_.DisplayName) [$($_.Status)]" -ForegroundColor Green
    }
} else {
    Write-Host "   No SQL Server services found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "   Please install SQL Server Express from:" -ForegroundColor Yellow
    Write-Host "   https://www.microsoft.com/en-us/sql-server/sql-server-downloads" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Download: SQL Server 2022 Express (Free)" -ForegroundColor Yellow
    Write-Host "   During installation, note the instance name (usually SQLEXPRESS)" -ForegroundColor Yellow
    exit
}

Write-Host ""

# 2. Try to find SQL Server instances
Write-Host "2. Detecting SQL Server instances..." -ForegroundColor Yellow

$instances = @()

# Check for SQLEXPRESS
try {
    $result = sqlcmd -S "localhost\SQLEXPRESS" -Q "SELECT @@VERSION" -W 2>&1
    if ($LASTEXITCODE -eq 0) {
        $instances += "localhost\SQLEXPRESS"
        Write-Host "   Found: localhost\SQLEXPRESS" -ForegroundColor Green
    }
} catch {}

# Check for MSSQLSERVER (default instance)
try {
    $result = sqlcmd -S "localhost" -Q "SELECT @@VERSION" -W 2>&1
    if ($LASTEXITCODE -eq 0) {
        $instances += "localhost"
        Write-Host "   Found: localhost (default instance)" -ForegroundColor Green
    }
} catch {}

# Check for other named instances
try {
    $regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server"
    if (Test-Path $regPath) {
        $installedInstances = (Get-ItemProperty "$regPath").InstalledInstances
        foreach ($instance in $installedInstances) {
            if ($instance -ne "SQLEXPRESS" -and $instance -ne "MSSQLSERVER") {
                $serverName = "localhost\$instance"
                $instances += $serverName
                Write-Host "   Found: $serverName" -ForegroundColor Green
            }
        }
    }
} catch {}

if ($instances.Count -eq 0) {
    Write-Host "   No accessible SQL Server instances found!" -ForegroundColor Red
    Write-Host "   Make sure SQL Server Express is running." -ForegroundColor Yellow
    exit
}

Write-Host ""

# 3. Let user choose instance if multiple found
$selectedInstance = ""
if ($instances.Count -eq 1) {
    $selectedInstance = $instances[0]
    Write-Host "3. Using SQL Server instance: $selectedInstance" -ForegroundColor Green
} else {
    Write-Host "3. Multiple instances found. Please select one:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $instances.Count; $i++) {
        Write-Host "   [$($i+1)] $($instances[$i])" -ForegroundColor Cyan
    }
    $selection = Read-Host "   Enter number"
    $selectedInstance = $instances[[int]$selection - 1]
    Write-Host "   Selected: $selectedInstance" -ForegroundColor Green
}

Write-Host ""

# 4. Test connection
Write-Host "4. Testing connection to $selectedInstance..." -ForegroundColor Yellow
try {
    $result = sqlcmd -S $selectedInstance -Q "SELECT @@VERSION" -W
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Connection successful!" -ForegroundColor Green
    } else {
        Write-Host "   Connection failed!" -ForegroundColor Red
        exit
    }
} catch {
    Write-Host "   Connection failed: $_" -ForegroundColor Red
    exit
}

Write-Host ""

# 5. Generate connection string
Write-Host "5. Generating connection string..." -ForegroundColor Yellow
$connectionString = "Server=$selectedInstance;Database=ResumeScoring;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True;Encrypt=False"
Write-Host "   Connection String:" -ForegroundColor Green
Write-Host "   $connectionString" -ForegroundColor Cyan

Write-Host ""

# 6. Save configuration
Write-Host "6. Saving configuration..." -ForegroundColor Yellow
$config = @{
    ServerInstance = $selectedInstance
    ConnectionString = $connectionString
    DatabaseName = "ResumeScoring"
}
$config | ConvertTo-Json | Out-File "sql-server-config.json"
Write-Host "   Configuration saved to: sql-server-config.json" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Detection Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Run: setup-database.ps1 (to create database)" -ForegroundColor White
Write-Host "2. Update your appsettings.json with the connection string above" -ForegroundColor White
Write-Host "3. Run: dotnet ef database update (to apply migrations)" -ForegroundColor White
Write-Host ""
