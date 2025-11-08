@echo off
REM ============================================
REM Stop All Services - LOCAL MODE
REM ============================================

echo.
echo ========================================
echo Stopping Resume Scoring System
echo ========================================
echo.

echo Stopping all Python, .NET, and Node processes...
echo.

REM Stop Python services
taskkill /FI "WindowTitle eq *Parsing Service*" /F >nul 2>&1
taskkill /FI "WindowTitle eq *NLP Service*" /F >nul 2>&1
taskkill /FI "WindowTitle eq *Embedding Service*" /F >nul 2>&1
taskkill /FI "WindowTitle eq *Scoring Service*" /F >nul 2>&1
echo ✓ Python services stopped

REM Stop .NET API Gateway
taskkill /FI "WindowTitle eq *API Gateway*" /F >nul 2>&1
echo ✓ API Gateway stopped

REM Stop Frontend
taskkill /FI "WindowTitle eq *Frontend*" /F >nul 2>&1
echo ✓ Frontend stopped

REM Stop SQL Server container
echo.
echo Stopping SQL Server container...
docker stop resume-scoring-db >nul 2>&1
echo ✓ SQL Server stopped

echo.
echo ========================================
echo ✓ All services stopped!
echo ========================================
echo.
echo To start again: Run START_LOCAL.bat
echo.
pause
