@echo off
REM Fix API Gateway - Missing using directive

echo.
echo ========================================
echo Fixing API Gateway
echo ========================================
echo.
echo Issue: 'ToListAsync' not found
echo Solution: Adding missing using directive
echo.

cd backend\api-gateway

echo Backing up current file...
copy Controllers\ScoringController.cs Controllers\ScoringController.cs.backup

echo Fixing ScoringController.cs...
echo.

REM The file has been fixed manually - just rebuild
echo Rebuilding API Gateway...
dotnet clean
dotnet restore
dotnet build

if %errorlevel% equ 0 (
    echo.
    echo ✓ API Gateway Fixed!
    echo.
    echo Build successful. Close the API Gateway window and restart it.
) else (
    echo.
    echo ✗ Build failed. Trying alternative fix...
    echo.
    echo Please add this line at the top of Controllers\ScoringController.cs:
    echo using Microsoft.EntityFrameworkCore;
    echo.
    echo It should look like:
    echo using Microsoft.AspNetCore.Mvc;
    echo using Microsoft.EntityFrameworkCore;  ^<-- ADD THIS
    echo.
)

cd ..\..

pause
