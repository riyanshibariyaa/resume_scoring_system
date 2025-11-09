# Fix NULL date values and add CORS support

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Fixing Database and CORS Issues" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Fix NULL dates in database
Write-Host "Step 1: Fixing NULL UpdatedAt values in Jobs table..." -ForegroundColor Yellow

$sqlFix = @"
USE ResumeScoring;

-- Update NULL UpdatedAt values
UPDATE Jobs
SET UpdatedAt = ISNULL(UpdatedAt, CreatedAt)
WHERE UpdatedAt IS NULL;

-- Verify
SELECT COUNT(*) as FixedRows FROM Jobs WHERE UpdatedAt IS NOT NULL;
"@

try {
    $result = $sqlFix | sqlcmd -S "localhost\SQLEXPRESS" 2>&1
    Write-Host "  [OK] Fixed NULL date values" -ForegroundColor Green
} catch {
    Write-Host "  [WARNING] Could not fix dates: $_" -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Add CORS to Program.cs
Write-Host "Step 2: Adding CORS configuration..." -ForegroundColor Yellow

$programPath = "E:\SK\resume-scoring-system\backend\api-gateway\Program.cs"

if (Test-Path $programPath) {
    $content = Get-Content $programPath -Raw
    
    # Check if CORS is already configured
    if ($content -match "builder\.Services\.AddCors") {
        Write-Host "  [INFO] CORS already configured" -ForegroundColor Gray
    } else {
        # Add CORS configuration after builder creation
        $corsConfig = @"

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowReactApp",
        policy =>
        {
            policy.WithOrigins("http://localhost:3000", "http://127.0.0.1:3000")
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        });
});
"@
        
        # Find where to insert (after CreateBuilder)
        $content = $content -replace "(var builder = WebApplication\.CreateBuilder\(args\);)", "`$1$corsConfig"
        
        # Add app.UseCors before app.UseAuthorization
        $corsMiddleware = "`napp.UseCors(`"AllowReactApp`");`n"
        $content = $content -replace "(app\.UseAuthorization\(\);)", "$corsMiddleware`$1"
        
        Set-Content $programPath $content
        Write-Host "  [OK] Added CORS configuration" -ForegroundColor Green
    }
} else {
    Write-Host "  [WARNING] Program.cs not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Fix Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart your API: dotnet run" -ForegroundColor Cyan
Write-Host "  2. Try loading jobs and resumes" -ForegroundColor Cyan
Write-Host "  3. Upload resume - everything should work!" -ForegroundColor Cyan
Write-Host ""
pause
