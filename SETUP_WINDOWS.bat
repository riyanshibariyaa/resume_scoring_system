@echo off
REM ============================================
REM Resume Scoring System - Windows Setup Script
REM ============================================

echo.
echo ======================================
echo Resume Scoring System - Windows Setup
echo ======================================
echo.

REM Check Python
echo [1/7] Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Python not found. Please install Python 3.10+ from python.org
    pause
    exit /b 1
)
echo ✓ Python found

REM Check .NET
echo [2/7] Checking .NET SDK...
dotnet --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: .NET SDK not found. Please install .NET 8.0 from dotnet.microsoft.com
    pause
    exit /b 1
)
echo ✓ .NET SDK found

REM Check Node.js
echo [3/7] Checking Node.js installation...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js not found. Please install Node.js 18+ from nodejs.org
    pause
    exit /b 1
)
echo ✓ Node.js found

echo.
echo All prerequisites found!
echo.
echo [4/7] Setting up Python services...
echo.

REM Setup Parsing Service
echo Setting up Parsing Service...
cd backend\services\parsing
if not exist venv (
    python -m venv venv
)
call venv\Scripts\activate.bat
pip install -q -r requirements.txt
call deactivate
cd ..\..\..
echo ✓ Parsing Service ready

REM Setup NLP Service
echo Setting up NLP Service...
cd backend\services\nlp
if not exist venv (
    python -m venv venv
)
call venv\Scripts\activate.bat
pip install -q -r requirements.txt
python -m spacy download en_core_web_sm
call deactivate
cd ..\..\..
echo ✓ NLP Service ready

REM Setup Embedding Service
echo Setting up Embedding Service...
cd backend\services\embedding
if not exist venv (
    python -m venv venv
)
call venv\Scripts\activate.bat
pip install -q -r requirements.txt
call deactivate
cd ..\..\..
echo ✓ Embedding Service ready

REM Setup Scoring Service
echo Setting up Scoring Service...
cd backend\services\scoring
if not exist venv (
    python -m venv venv
)
call venv\Scripts\activate.bat
pip install -q -r requirements.txt
call deactivate
cd ..\..\..
echo ✓ Scoring Service ready

echo.
echo [5/7] Setting up .NET API Gateway...
cd backend\api-gateway
dotnet restore
dotnet build
cd ..\..
echo ✓ API Gateway ready

echo.
echo [6/7] Setting up React Frontend...
cd frontend
call npm install
cd ..
echo ✓ Frontend ready

echo.
echo [7/7] Creating environment files...

REM Create .env for API Gateway
if not exist backend\api-gateway\.env (
    (
        echo DATABASE_CONNECTION=Server=localhost;Database=ResumeScoring;User Id=sa;Password=YourStrong@Password123;TrustServerCertificate=True
        echo JWT_SECRET=your-256-bit-secret-key-change-this-in-production
        echo CORS_ORIGINS=http://localhost:3000
        echo PARSING_SERVICE_URL=http://localhost:5001
        echo NLP_SERVICE_URL=http://localhost:5002
        echo EMBEDDING_SERVICE_URL=http://localhost:5003
        echo SCORING_SERVICE_URL=http://localhost:5004
    ) > backend\api-gateway\.env
    echo ✓ Created API Gateway .env
)

REM Create .env for Frontend
if not exist frontend\.env (
    (
        echo REACT_APP_API_URL=http://localhost:5000
        echo REACT_APP_ENV=development
    ) > frontend\.env
    echo ✓ Created Frontend .env
)

REM Create .env for each Python service
for %%s in (parsing nlp embedding scoring) do (
    if not exist backend\services\%%s\.env (
        if "%%s"=="parsing" set PORT=5001
        if "%%s"=="nlp" set PORT=5002
        if "%%s"=="embedding" set PORT=5003
        if "%%s"=="scoring" set PORT=5004
        (
            echo PORT=!PORT!
            echo DEBUG=true
            echo STORAGE_PATH=./storage
            echo API_GATEWAY_URL=http://localhost:5000
        ) > backend\services\%%s\.env
        echo ✓ Created %%s service .env
    )
)

echo.
echo ======================================
echo ✓ Setup Complete!
echo ======================================
echo.
echo Next Steps:
echo.
echo 1. Setup Database:
echo    sqlcmd -S localhost -U sa -P YourStrong@Password123 -i database\migrations\001_initial_schema.sql
echo.
echo 2. Run the application:
echo    - Open 5 terminal windows
echo    - Run START_ALL_SERVICES.bat (or follow manual instructions)
echo.
echo 3. Access:
echo    - Frontend: http://localhost:3000
echo    - API Docs: http://localhost:5000/swagger
echo.
echo For detailed instructions, see QUICKSTART_GUIDE.md
echo.
pause
