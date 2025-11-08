@echo off
REM ========================================
REM SQL Server Express - One-Click Setup
REM Resume Scoring System
REM ========================================

echo.
echo ========================================
echo SQL Server Express - Complete Setup
echo ========================================
echo.
echo This will:
echo   1. Detect SQL Server Express
echo   2. Create ResumeScoring database
echo   3. Create all tables and indexes
echo   4. Update appsettings.json
echo   5. Verify setup
echo.
echo Press Ctrl+C to cancel or
pause

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERROR: This script must be run as Administrator!
    echo.
    echo Right-click on this file and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Step 1: Detecting SQL Server Express
echo ========================================
echo.
PowerShell -ExecutionPolicy Bypass -File "01-detect-sql-server.ps1"
if %errorLevel% neq 0 (
    echo.
    echo ERROR: SQL Server detection failed!
    echo Please ensure SQL Server Express is installed.
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Step 2: Creating Database and Tables
echo ========================================
echo.
PowerShell -ExecutionPolicy Bypass -File "02-setup-database.ps1"
if %errorLevel% neq 0 (
    echo.
    echo ERROR: Database setup failed!
    echo Check setup-output.log for details.
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Step 3: Verifying Setup
echo ========================================
echo.
PowerShell -ExecutionPolicy Bypass -File "03-verify-database.ps1"

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Your database is ready to use!
echo.
echo Next steps:
echo   1. Open your project in Visual Studio or VS Code
echo   2. Verify appsettings.json has the correct connection string
echo   3. Copy Models.cs and ApplicationDbContext.cs to your project
echo   4. Update Program.cs with the configuration
echo   5. Run: dotnet run
echo.
echo For detailed instructions, see: SETUP-GUIDE.md
echo.
pause
