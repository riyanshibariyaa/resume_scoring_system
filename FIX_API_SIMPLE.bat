@echo off
REM ========================================
REM SIMPLE FIX - API Gateway Only
REM Run this in Command Prompt (CMD)
REM ========================================

echo.
echo Fixing API Gateway - Rebuilding project...
echo.

cd backend\api-gateway

echo Cleaning previous build...
dotnet clean

echo Restoring packages...
dotnet restore

echo Building project...
dotnet build

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo SUCCESS! API Gateway is now fixed!
    echo ========================================
    echo.
    echo Close the API Gateway window and restart it.
) else (
    echo.
    echo ========================================
    echo ERROR! Build failed.
    echo ========================================
    echo.
    echo The ScoringController.cs file may have been corrupted.
    echo Please check MANUAL_FIX.md for the correct file content.
)

cd ..\..

pause
