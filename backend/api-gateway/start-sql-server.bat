@echo off
echo.
echo ========================================
echo Starting SQL Server Express Service
echo ========================================
echo.

echo Checking SQL Server Express status...
sc query MSSQL$SQLEXPRESS

echo.
echo Starting SQL Server Express...
net start MSSQL$SQLEXPRESS

echo.
echo Checking status again...
sc query MSSQL$SQLEXPRESS

echo.
echo ========================================
echo Done!
echo ========================================
echo.
echo SQL Server Express should now be running.
echo You can now run your application: dotnet run
echo.
pause
