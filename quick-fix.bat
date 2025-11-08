@echo off
echo ========================================
echo Resume Scoring System - Quick Fix
echo ========================================
echo.

echo Step 1: Stopping any running LocalDB instances...
sqllocaldb stop MSSQLLocalDB
timeout /t 2 /nobreak >nul

echo.
echo Step 2: Deleting corrupted LocalDB instance...
sqllocaldb delete MSSQLLocalDB
timeout /t 2 /nobreak >nul

echo.
echo Step 3: Creating fresh LocalDB instance...
sqllocaldb create MSSQLLocalDB
timeout /t 2 /nobreak >nul

echo.
echo Step 4: Starting LocalDB instance...
sqllocaldb start MSSQLLocalDB
timeout /t 3 /nobreak >nul

echo.
echo Step 5: Verifying LocalDB status...
sqllocaldb info MSSQLLocalDB

echo.
echo Step 6: Dropping existing database...
cd /d E:\SK\resume-scoring-system\backend\api-gateway
dotnet ef database drop --force

echo.
echo Step 7: Applying database migrations...
dotnet ef database update

echo.
echo ========================================
echo Fix Complete!
echo ========================================
echo.
echo You can now run: dotnet run
echo.
pause
