# Setup Database for Resume Scoring System
# Run this script as Administrator AFTER running 01-detect-sql-server.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Resume Scoring - Database Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check if configuration exists
if (-not (Test-Path "sql-server-config.json")) {
    Write-Host "ERROR: Configuration file not found!" -ForegroundColor Red
    Write-Host "Please run: 01-detect-sql-server.ps1 first" -ForegroundColor Yellow
    exit
}

# 2. Load configuration
Write-Host "1. Loading SQL Server configuration..." -ForegroundColor Yellow
$config = Get-Content "sql-server-config.json" | ConvertFrom-Json
$serverInstance = $config.ServerInstance
Write-Host "   Server: $serverInstance" -ForegroundColor Green
Write-Host ""

# 3. Check if SQL script exists
if (-not (Test-Path "02-create-database.sql")) {
    Write-Host "ERROR: Database script not found!" -ForegroundColor Red
    Write-Host "Please ensure 02-create-database.sql is in the current directory" -ForegroundColor Yellow
    exit
}

# 4. Execute database creation script
Write-Host "2. Creating database and tables..." -ForegroundColor Yellow
Write-Host "   This may take a minute..." -ForegroundColor Gray
try {
    sqlcmd -S $serverInstance -i "02-create-database.sql" -o "setup-output.log"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Database created successfully!" -ForegroundColor Green
    } else {
        Write-Host "   Error creating database. Check setup-output.log for details." -ForegroundColor Red
        exit
    }
} catch {
    Write-Host "   Error: $_" -ForegroundColor Red
    exit
}
Write-Host ""

# 5. Verify database and tables
Write-Host "3. Verifying database setup..." -ForegroundColor Yellow
$verifyQuery = @"
USE ResumeScoring;
SELECT 
    name AS TableName,
    OBJECT_SCHEMA_NAME(object_id) AS SchemaName
FROM sys.tables
ORDER BY name;
"@

$verifyQuery | Out-File "verify-query.sql"
$tables = sqlcmd -S $serverInstance -i "verify-query.sql" -h -1 -W

if ($tables) {
    Write-Host "   Tables found:" -ForegroundColor Green
    $tables | ForEach-Object { 
        if ($_.Trim() -ne "") {
            Write-Host "   - $($_.Trim())" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "   Warning: Could not verify tables" -ForegroundColor Yellow
}
Write-Host ""

# 6. Update appsettings.json
Write-Host "4. Updating appsettings.json..." -ForegroundColor Yellow

$projectPath = "E:\SK\resume-scoring-system\backend\api-gateway"
$appsettingsPath = Join-Path $projectPath "appsettings.json"
$appsettingsDevPath = Join-Path $projectPath "appsettings.Development.json"

$connectionString = $config.ConnectionString

# Update or create appsettings.Development.json
$appsettingsContent = @{
    "Logging" = @{
        "LogLevel" = @{
            "Default" = "Information"
            "Microsoft.AspNetCore" = "Warning"
            "Microsoft.EntityFrameworkCore" = "Information"
        }
    }
    "ConnectionStrings" = @{
        "DefaultConnection" = $connectionString
    }
    "AllowedHosts" = "*"
}

if (Test-Path $projectPath) {
    $appsettingsContent | ConvertTo-Json -Depth 10 | Out-File $appsettingsDevPath -Encoding UTF8
    Write-Host "   Updated: $appsettingsDevPath" -ForegroundColor Green
    
    # Also create a backup connection string file
    @"
{
  "ConnectionStrings": {
    "DefaultConnection": "$connectionString"
  }
}
"@ | Out-File "appsettings-new-connectionstring.json" -Encoding UTF8
    Write-Host "   Backup saved: appsettings-new-connectionstring.json" -ForegroundColor Green
} else {
    Write-Host "   Project path not found: $projectPath" -ForegroundColor Yellow
    Write-Host "   Please manually update your appsettings.json with:" -ForegroundColor Yellow
    Write-Host "   $connectionString" -ForegroundColor Cyan
}
Write-Host ""

# 7. Clean up temporary files
Remove-Item "verify-query.sql" -ErrorAction SilentlyContinue

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Database Details:" -ForegroundColor Yellow
Write-Host "  Server: $serverInstance" -ForegroundColor White
Write-Host "  Database: ResumeScoring" -ForegroundColor White
Write-Host "  Connection String: (saved in appsettings.Development.json)" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Verify connection string in appsettings.json" -ForegroundColor White
Write-Host "  2. SKIP Entity Framework migrations (database already created)" -ForegroundColor White
Write-Host "  3. Run your application: cd $projectPath && dotnet run" -ForegroundColor White
Write-Host ""
Write-Host "Test your database:" -ForegroundColor Yellow
Write-Host "  sqlcmd -S $serverInstance -d ResumeScoring -Q `"SELECT * FROM Jobs`"" -ForegroundColor Cyan
Write-Host ""
