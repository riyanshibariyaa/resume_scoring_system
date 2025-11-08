# Fix Connection String - Switch from LocalDB to SQL Server Express
# Run this in your api-gateway folder

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fixing Connection String" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectPath = "E:\SK\resume-scoring-system\backend\api-gateway"

# Correct SQL Server Express connection string
$correctConnectionString = "Server=localhost\\SQLEXPRESS;Database=ResumeScoring;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True;Encrypt=False"

Write-Host "1. Updating appsettings.json..." -ForegroundColor Yellow

$appsettingsPath = Join-Path $projectPath "appsettings.json"
if (Test-Path $appsettingsPath) {
    $content = Get-Content $appsettingsPath -Raw | ConvertFrom-Json
    
    if (-not $content.ConnectionStrings) {
        $content | Add-Member -NotePropertyName "ConnectionStrings" -NotePropertyValue @{} -Force
    }
    
    $content.ConnectionStrings.DefaultConnection = $correctConnectionString
    
    $content | ConvertTo-Json -Depth 10 | Set-Content $appsettingsPath
    Write-Host "   [UPDATED] appsettings.json" -ForegroundColor Green
} else {
    Write-Host "   [NOT FOUND] appsettings.json" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "2. Updating appsettings.Development.json..." -ForegroundColor Yellow

$appsettingsDevPath = Join-Path $projectPath "appsettings.Development.json"
if (Test-Path $appsettingsDevPath) {
    $content = Get-Content $appsettingsDevPath -Raw | ConvertFrom-Json
    
    if (-not $content.ConnectionStrings) {
        $content | Add-Member -NotePropertyName "ConnectionStrings" -NotePropertyValue @{} -Force
    }
    
    $content.ConnectionStrings.DefaultConnection = $correctConnectionString
    
    $content | ConvertTo-Json -Depth 10 | Set-Content $appsettingsDevPath
    Write-Host "   [UPDATED] appsettings.Development.json" -ForegroundColor Green
} else {
    Write-Host "   [NOT FOUND] appsettings.Development.json" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "3. Creating backup connection string file..." -ForegroundColor Yellow

$backupContent = @"
{
  "ConnectionStrings": {
    "DefaultConnection": "$correctConnectionString"
  }
}
"@

$backupPath = Join-Path $projectPath "connection-string-CORRECT.json"
$backupContent | Out-File $backupPath -Encoding UTF8
Write-Host "   [CREATED] connection-string-CORRECT.json" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fix Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Updated connection string to:" -ForegroundColor Yellow
Write-Host "  $correctConnectionString" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Stop your application (Ctrl+C)" -ForegroundColor White
Write-Host "  2. Run: dotnet run" -ForegroundColor White
Write-Host "  3. Try uploading resume again" -ForegroundColor White
Write-Host ""
