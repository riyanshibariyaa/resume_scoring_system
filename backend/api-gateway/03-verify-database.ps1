# Database Verification Script
# Run this after setup to verify everything is working

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Database Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load configuration
if (-not (Test-Path "sql-server-config.json")) {
    Write-Host "ERROR: Configuration file not found!" -ForegroundColor Red
    Write-Host "Please run the setup scripts first" -ForegroundColor Yellow
    exit
}

$config = Get-Content "sql-server-config.json" | ConvertFrom-Json
$serverInstance = $config.ServerInstance

Write-Host "Server: $serverInstance" -ForegroundColor Yellow
Write-Host "Database: ResumeScoring" -ForegroundColor Yellow
Write-Host ""

# Test 1: Connection
Write-Host "Test 1: Testing database connection..." -ForegroundColor Yellow
$connectionTest = sqlcmd -S $serverInstance -d ResumeScoring -Q "SELECT 1 AS Connected" -h -1 -W
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Connection successful" -ForegroundColor Green
} else {
    Write-Host "  ✗ Connection failed" -ForegroundColor Red
    exit
}

# Test 2: List all tables
Write-Host ""
Write-Host "Test 2: Checking tables..." -ForegroundColor Yellow
$tableQuery = @"
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE' 
ORDER BY TABLE_NAME;
"@

$tables = sqlcmd -S $serverInstance -d ResumeScoring -Q $tableQuery -h -1 -W
$expectedTables = @("Education", "Jobs", "ResumeScores", "Resumes", "Skills", "WorkExperience")
$foundTables = @()

foreach ($table in $tables) {
    $tableName = $table.Trim()
    if ($tableName -ne "" -and $tableName -ne "TABLE_NAME") {
        $foundTables += $tableName
    }
}

foreach ($expected in $expectedTables) {
    if ($foundTables -contains $expected) {
        Write-Host "  ✓ $expected" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $expected (missing)" -ForegroundColor Red
    }
}

# Test 3: Check table structures
Write-Host ""
Write-Host "Test 3: Verifying table structures..." -ForegroundColor Yellow

$structureQuery = @"
SELECT 
    t.TABLE_NAME,
    COUNT(c.COLUMN_NAME) as ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
LEFT JOIN INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_NAME = c.TABLE_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE'
GROUP BY t.TABLE_NAME
ORDER BY t.TABLE_NAME;
"@

sqlcmd -S $serverInstance -d ResumeScoring -Q $structureQuery -W | ForEach-Object {
    if ($_ -match "^\s*(\w+)\s+(\d+)\s*$") {
        $tableName = $matches[1]
        $columnCount = $matches[2]
        Write-Host "  ✓ $tableName ($columnCount columns)" -ForegroundColor Green
    }
}

# Test 4: Check indexes
Write-Host ""
Write-Host "Test 4: Checking indexes..." -ForegroundColor Yellow
$indexQuery = @"
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    COUNT(*) as IndexCount
FROM sys.indexes i
WHERE i.object_id IN (
    SELECT object_id FROM sys.tables WHERE name IN ('Resumes', 'Jobs', 'ResumeScores', 'Skills', 'WorkExperience', 'Education')
)
AND i.is_primary_key = 0
GROUP BY i.object_id
ORDER BY OBJECT_NAME(i.object_id);
"@

sqlcmd -S $serverInstance -d ResumeScoring -Q $indexQuery -W | ForEach-Object {
    if ($_ -match "^\s*(\w+)\s+(\d+)\s*$") {
        $tableName = $matches[1]
        $indexCount = $matches[2]
        Write-Host "  ✓ $tableName ($indexCount indexes)" -ForegroundColor Green
    }
}

# Test 5: Check foreign keys
Write-Host ""
Write-Host "Test 5: Checking foreign key relationships..." -ForegroundColor Yellow
$fkQuery = @"
SELECT 
    OBJECT_NAME(f.parent_object_id) AS TableName,
    OBJECT_NAME(f.referenced_object_id) AS ReferencedTable
FROM sys.foreign_keys f
WHERE OBJECT_NAME(f.parent_object_id) IN ('ResumeScores', 'Skills', 'WorkExperience', 'Education')
ORDER BY OBJECT_NAME(f.parent_object_id);
"@

sqlcmd -S $serverInstance -d ResumeScoring -Q $fkQuery -W | ForEach-Object {
    if ($_ -match "^\s*(\w+)\s+(\w+)\s*$") {
        $fromTable = $matches[1]
        $toTable = $matches[2]
        Write-Host "  ✓ $fromTable → $toTable" -ForegroundColor Green
    }
}

# Test 6: Check sample data
Write-Host ""
Write-Host "Test 6: Checking for sample data..." -ForegroundColor Yellow
$countQuery = @"
SELECT 
    'Resumes' as TableName, COUNT(*) as RecordCount FROM Resumes
UNION ALL
SELECT 'Jobs', COUNT(*) FROM Jobs
UNION ALL
SELECT 'ResumeScores', COUNT(*) FROM ResumeScores
UNION ALL
SELECT 'Skills', COUNT(*) FROM Skills
UNION ALL
SELECT 'WorkExperience', COUNT(*) FROM WorkExperience
UNION ALL
SELECT 'Education', COUNT(*) FROM Education;
"@

sqlcmd -S $serverInstance -d ResumeScoring -Q $countQuery -W | ForEach-Object {
    if ($_ -match "^\s*(\w+)\s+(\d+)\s*$") {
        $tableName = $matches[1]
        $count = $matches[2]
        if ([int]$count -gt 0) {
            Write-Host "  ✓ $tableName ($count records)" -ForegroundColor Green
        } else {
            Write-Host "  ○ $tableName (empty)" -ForegroundColor Gray
        }
    }
}

# Test 7: Test a query
Write-Host ""
Write-Host "Test 7: Running test queries..." -ForegroundColor Yellow
$testQuery = @"
-- Test join between tables
SELECT TOP 1 
    r.ResumeId, 
    r.CandidateName, 
    r.UploadedAt,
    j.JobId,
    j.Title
FROM Resumes r
CROSS JOIN Jobs j;
"@

$testResult = sqlcmd -S $serverInstance -d ResumeScoring -Q $testQuery -h -1 -W 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Query execution successful" -ForegroundColor Green
} else {
    Write-Host "  ○ No data yet (database is empty)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verification Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Database: ResumeScoring" -ForegroundColor White
Write-Host "  Server: $serverInstance" -ForegroundColor White
Write-Host "  Status: Ready for use" -ForegroundColor Green
Write-Host ""
Write-Host "You can now:" -ForegroundColor Yellow
Write-Host "  1. Run your application: dotnet run" -ForegroundColor White
Write-Host "  2. Upload resumes through the API" -ForegroundColor White
Write-Host "  3. Create jobs and run scoring" -ForegroundColor White
Write-Host ""
Write-Host "Connection string for your application:" -ForegroundColor Yellow
Write-Host "  $($config.ConnectionString)" -ForegroundColor Cyan
Write-Host ""
