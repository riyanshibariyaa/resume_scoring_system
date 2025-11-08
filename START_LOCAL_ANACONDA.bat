@echo off
REM Start services using Anaconda Python (no venv)

echo.
echo Starting all services using Anaconda Python...
echo.

REM Start Parsing Service
echo [1/6] Starting Parsing Service (5001)...
start "Parsing Service [5001]" cmd /k "cd /d "%~dp0backend\services\parsing" && set PORT=5001 && python app.py"
timeout /t 2 /nobreak >nul

REM Start NLP Service  
echo [2/6] Starting NLP Service (5002)...
start "NLP Service [5002]" cmd /k "cd /d "%~dp0backend\services\nlp" && set PORT=5002 && python app.py"
timeout /t 2 /nobreak >nul

REM Start Embedding Service
echo [3/6] Starting Embedding Service (5003)...
start "Embedding Service [5003]" cmd /k "cd /d "%~dp0backend\services\embedding" && set PORT=5003 && python app.py"
timeout /t 2 /nobreak >nul

REM Start Scoring Service
echo [4/6] Starting Scoring Service (5004)...
start "Scoring Service [5004]" cmd /k "cd /d "%~dp0backend\services\scoring" && set PORT=5004 && python app.py"
timeout /t 2 /nobreak >nul

REM Start API Gateway
echo [5/6] Starting API Gateway (5000)...
start "API Gateway [5000]" cmd /k "cd /d "%~dp0backend\api-gateway" && dotnet run"
timeout /t 3 /nobreak >nul

REM Start Frontend
echo [6/6] Starting Frontend (3000)...
start "Frontend [3000]" cmd /k "cd /d "%~dp0frontend" && npm start"

echo.
echo ========================================
echo All services started!
echo ========================================
echo.
echo Wait 30-60 seconds, then open:
echo http://localhost:3000
echo.
pause