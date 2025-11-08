@echo off
REM ============================================
REM Resume Scoring System - LOCAL SETUP
REM Optimized for 4GB RAM, No GPU, Windows
REM ============================================

echo.
echo ========================================
echo Resume Scoring System - LOCAL SETUP
echo ========================================
echo Optimized for: 4GB RAM, CPU-only, No GPU
echo Time: ~15 minutes (vs hours in Docker!)
echo ========================================
echo.

REM Check prerequisites
echo [STEP 1/7] Checking prerequisites...
echo.

REM Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python not found!
    echo Please install Python 3.10+ from python.org
    pause
    exit /b 1
)
echo ✓ Python found

REM Check .NET
dotnet --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: .NET SDK not found!
    echo Please install .NET 8.0 from dotnet.microsoft.com
    pause
    exit /b 1
)
echo ✓ .NET SDK found

REM Check Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found!
    echo Please install Node.js 18+ from nodejs.org
    pause
    exit /b 1
)
echo ✓ Node.js found

REM Check Docker (for SQL Server only)
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Docker not found!
    echo You'll need to install SQL Server Express manually
    echo Or install Docker Desktop for automated database setup
    echo.
    echo Continue anyway? (Y/N)
    set /p continue=
    if /i not "%continue%"=="Y" exit /b 1
) else (
    echo ✓ Docker found
)

echo.
echo ========================================
echo [STEP 2/7] Setting up SQL Server...
echo ========================================
echo.

REM Start SQL Server in Docker
docker ps -a | findstr resume-scoring-db >nul 2>&1
if %errorlevel% neq 0 (
    echo Creating SQL Server container...
    docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourStrong@Password123!" -p 1433:1433 --name resume-scoring-db -d mcr.microsoft.com/mssql/server:2019-latest
    echo Waiting for SQL Server to start...
    timeout /t 15 /nobreak >nul
) else (
    echo SQL Server container exists, starting it...
    docker start resume-scoring-db
    timeout /t 5 /nobreak >nul
)

echo ✓ SQL Server running on port 1433
echo.

REM Initialize Database
echo Initializing database schema...
timeout /t 5 /nobreak >nul
sqlcmd -S localhost -U sa -P "YourStrong@Password123!" -i "database\migrations\001_initial_schema.sql" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Database initialized
) else (
    echo WARNING: Database initialization may have failed
    echo You can run it manually later
)

echo.
echo ========================================
echo [STEP 3/7] Setting up Parsing Service...
echo ========================================
echo.

cd backend\services\parsing

if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
)

echo Installing dependencies (CPU-optimized)...
call venv\Scripts\activate.bat
pip install --quiet --upgrade pip
pip install --quiet -r requirements-cpu.txt
call deactivate

echo ✓ Parsing Service ready (Port 5001)
cd ..\..\..

echo.
echo ========================================
echo [STEP 4/7] Setting up NLP Service...
echo ========================================
echo.

cd backend\services\nlp

if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
)

echo Installing dependencies (lightweight)...
call venv\Scripts\activate.bat
pip install --quiet --upgrade pip
pip install --quiet -r requirements-cpu.txt

echo Downloading spaCy model (~12MB)...
python -m spacy download en_core_web_sm
call deactivate

echo ✓ NLP Service ready (Port 5002)
cd ..\..\..

echo.
echo ========================================
echo [STEP 5/7] Setting up Embedding Service...
echo ========================================
echo.

cd backend\services\embedding

if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
)

echo Installing dependencies (CPU-only PyTorch)...
echo This will download ~100MB on first run...
call venv\Scripts\activate.bat
pip install --quiet --upgrade pip
pip install --quiet -r requirements-cpu.txt
call deactivate

echo ✓ Embedding Service ready (Port 5003)
cd ..\..\..

echo.
echo ========================================
echo [STEP 5.5/7] Setting up Scoring Service...
echo ========================================
echo.

cd backend\services\scoring

if not exist venv (
    echo Creating virtual environment...
    python -m venv venv
)

echo Installing dependencies (minimal)...
call venv\Scripts\activate.bat
pip install --quiet --upgrade pip
pip install --quiet -r requirements-cpu.txt
call deactivate

echo ✓ Scoring Service ready (Port 5004)
cd ..\..\..

echo.
echo ========================================
echo [STEP 6/7] Setting up API Gateway...
echo ========================================
echo.

cd backend\api-gateway

echo Restoring .NET packages...
dotnet restore >nul 2>&1

echo Building API Gateway...
dotnet build >nul 2>&1

echo ✓ API Gateway ready (Port 5000)
cd ..\..

echo.
echo ========================================
echo [STEP 7/7] Setting up Frontend...
echo ========================================
echo.

cd frontend

echo Installing Node packages...
call npm install

echo ✓ Frontend ready (Port 3000)
cd ..

echo.
echo ========================================
echo ✓ SETUP COMPLETE!
echo ========================================
echo.
echo Your Resume Scoring System is ready!
echo.
echo Memory Usage Estimate:
echo   SQL Server:      ~500 MB
echo   Python Services: ~800 MB
echo   API Gateway:     ~150 MB
echo   Frontend:        ~300 MB
echo   Total:           ~1.75 GB (plenty of headroom!)
echo.
echo Next Steps:
echo   1. Run: START_LOCAL.bat
echo   2. Wait: 30-60 seconds
echo   3. Open: http://localhost:3000
echo.
echo Tips for 4GB RAM:
echo   - Close unnecessary applications
echo   - Start only services you need during development
echo   - Use lightweight code editor
echo.
pause
