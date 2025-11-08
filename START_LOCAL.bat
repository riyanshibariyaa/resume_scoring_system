@echo off
REM ============================================
REM Start All Services - LOCAL MODE
REM Resume Scoring System
REM ============================================

echo.
echo ========================================
echo Starting Resume Scoring System
echo LOCAL MODE (No Docker for Services)
echo ========================================
echo.

REM Check if SQL Server is running
echo Checking SQL Server...
docker ps | findstr resume-scoring-db >nul 2>&1
if %errorlevel% neq 0 (
    echo Starting SQL Server container...
    docker start resume-scoring-db >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: SQL Server container not found!
        echo Please run SETUP_LOCAL.bat first
        pause
        exit /b 1
    )
    echo Waiting for SQL Server to start...
    timeout /t 10 /nobreak >nul
)
echo ✓ SQL Server running

echo.
echo Starting services in separate windows...
echo Please wait for all windows to open...
echo.

REM Start Parsing Service
echo [1/6] Starting Parsing Service (Port 5001)...
start "📄 Parsing Service [5001]" cmd /k "cd /d "%~dp0backend\services\parsing" && venv\Scripts\activate && set PORT=5001 && set DEBUG=true && python app.py"
timeout /t 2 /nobreak >nul

REM Start NLP Service
echo [2/6] Starting NLP Service (Port 5002)...
start "🧠 NLP Service [5002]" cmd /k "cd /d "%~dp0backend\services\nlp" && venv\Scripts\activate && set PORT=5002 && set DEBUG=true && python app.py"
timeout /t 2 /nobreak >nul

REM Start Embedding Service
echo [3/6] Starting Embedding Service (Port 5003)...
start "📊 Embedding Service [5003]" cmd /k "cd /d "%~dp0backend\services\embedding" && venv\Scripts\activate && set PORT=5003 && set DEBUG=true && python app.py"
timeout /t 2 /nobreak >nul

REM Start Scoring Service
echo [4/6] Starting Scoring Service (Port 5004)...
start "⚡ Scoring Service [5004]" cmd /k "cd /d "%~dp0backend\services\scoring" && call venv\Scripts\activate && set PORT=5004 && set DEBUG=true && python app.py"
timeout /t 2 /nobreak >nul

REM Start API Gateway
echo [5/6] Starting API Gateway (Port 5000)...
start "🌐 API Gateway [5000]" cmd /k "cd /d "%~dp0backend\api-gateway" && dotnet run"
timeout /t 3 /nobreak >nul

REM Start Frontend
echo [6/6] Starting Frontend (Port 3000)...
start "🎨 Frontend [3000]" cmd /k "cd /d "%~dp0frontend" && npm start"

echo.
echo ========================================
echo ✓ All services launched!
echo ========================================
echo.
echo 6 windows opened:
echo   📄 Parsing Service    - Port 5001
echo   🧠 NLP Service        - Port 5002
echo   📊 Embedding Service  - Port 5003
echo   ⚡ Scoring Service    - Port 5004
echo   🌐 API Gateway        - Port 5000
echo   🎨 Frontend           - Port 3000
echo.
echo Please wait 30-60 seconds for all services to fully start...
echo.
echo Access Points:
echo   Frontend UI:   http://localhost:3000
echo   API Docs:      http://localhost:5000/swagger
echo   API Base:      http://localhost:5000/api/v1
echo.
echo Health Checks:
echo   curl http://localhost:5001/health
echo   curl http://localhost:5002/health
echo   curl http://localhost:5003/health
echo   curl http://localhost:5004/health
echo   curl http://localhost:5000/health
echo.
echo To STOP all services:
echo   1. Close all opened command windows
echo   2. Stop database: docker stop resume-scoring-db
echo.
echo Memory Usage: ~1.75 GB total
echo.
pause
