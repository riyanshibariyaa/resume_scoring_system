@echo off
REM ============================================
REM Start All Services - Resume Scoring System
REM ============================================

echo.
echo ========================================
echo Starting Resume Scoring System
echo ========================================
echo.

echo Starting services in separate windows...
echo.

REM Start Parsing Service
start "Parsing Service (5001)" cmd /k "cd backend\services\parsing && venv\Scripts\activate && python app.py"
timeout /t 2 /nobreak >nul

REM Start NLP Service
start "NLP Service (5002)" cmd /k "cd backend\services\nlp && venv\Scripts\activate && python app.py"
timeout /t 2 /nobreak >nul

REM Start Embedding Service
start "Embedding Service (5003)" cmd /k "cd backend\services\embedding && venv\Scripts\activate && python app.py"
timeout /t 2 /nobreak >nul

REM Start Scoring Service
start "Scoring Service (5004)" cmd /k "cd backend\services\scoring && venv\Scripts\activate && python app.py"
timeout /t 2 /nobreak >nul

REM Start API Gateway
start "API Gateway (5000)" cmd /k "cd backend\api-gateway && dotnet run"
timeout /t 3 /nobreak >nul

REM Start Frontend
start "Frontend (3000)" cmd /k "cd frontend && npm start"

echo.
echo ========================================
echo All services started!
echo ========================================
echo.
echo Service Windows Opened:
echo   - Parsing Service (Port 5001)
echo   - NLP Service (Port 5002)
echo   - Embedding Service (Port 5003)
echo   - Scoring Service (Port 5004)
echo   - API Gateway (Port 5000)
echo   - Frontend (Port 3000)
echo.
echo Wait 30-60 seconds for all services to fully start...
echo.
echo Access Points:
echo   Frontend:  http://localhost:3000
echo   API Docs:  http://localhost:5000/swagger
echo.
echo To stop all services:
echo   - Close all opened command windows
echo   - Or run STOP_ALL_SERVICES.bat
echo.
pause
