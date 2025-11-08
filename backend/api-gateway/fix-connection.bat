@echo off
echo.
echo ========================================
echo Fixing Connection String
echo ========================================
echo.
echo This will update your connection string
echo from LocalDB to SQL Server Express
echo.
pause

cd E:\SK\resume-scoring-system\backend\api-gateway

echo.
echo Updating connection string...
echo.

PowerShell -ExecutionPolicy Bypass -Command "& { $file = 'appsettings.json'; if (Test-Path $file) { $content = Get-Content $file -Raw | ConvertFrom-Json; if (-not $content.ConnectionStrings) { $content | Add-Member -NotePropertyName 'ConnectionStrings' -NotePropertyValue @{} -Force }; $content.ConnectionStrings.DefaultConnection = 'Server=localhost\\SQLEXPRESS;Database=ResumeScoring;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True;Encrypt=False'; $content | ConvertTo-Json -Depth 10 | Set-Content $file; Write-Host '[OK] Updated appsettings.json' -ForegroundColor Green } }"

PowerShell -ExecutionPolicy Bypass -Command "& { $file = 'appsettings.Development.json'; if (Test-Path $file) { $content = Get-Content $file -Raw | ConvertFrom-Json; if (-not $content.ConnectionStrings) { $content | Add-Member -NotePropertyName 'ConnectionStrings' -NotePropertyValue @{} -Force }; $content.ConnectionStrings.DefaultConnection = 'Server=localhost\\SQLEXPRESS;Database=ResumeScoring;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True;Encrypt=False'; $content | ConvertTo-Json -Depth 10 | Set-Content $file; Write-Host '[OK] Updated appsettings.Development.json' -ForegroundColor Green } }"

echo.
echo ========================================
echo Fix Complete!
echo ========================================
echo.
echo Connection string updated to SQL Server Express
echo.
echo Next steps:
echo   1. Stop your application (Ctrl+C)
echo   2. Run: dotnet run
echo   3. Upload resume again
echo.
pause
