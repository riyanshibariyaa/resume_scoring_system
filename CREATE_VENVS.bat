@echo off
REM ========================================
REM CREATE VIRTUAL ENVIRONMENTS
REM Run this if venv folders are missing
REM ========================================

echo.
echo ========================================
echo Creating Virtual Environments
echo ========================================
echo.

echo [1/4] Creating Parsing Service venv...
cd backend\services\parsing
if exist venv (
    echo Venv already exists, skipping...
) else (
    python -m venv venv
    echo ✓ Created
)
cd ..\..\..

echo [2/4] Creating NLP Service venv...
cd backend\services\nlp
if exist venv (
    echo Venv already exists, skipping...
) else (
    python -m venv venv
    echo ✓ Created
)
cd ..\..\..

echo [3/4] Creating Embedding Service venv...
cd backend\services\embedding
if exist venv (
    echo Venv already exists, skipping...
) else (
    python -m venv venv
    echo ✓ Created
)
cd ..\..\..

echo [4/4] Creating Scoring Service venv...
cd backend\services\scoring
if exist venv (
    echo Venv already exists, skipping...
) else (
    python -m venv venv
    echo ✓ Created
)
cd ..\..\..

echo.
echo ========================================
echo All venvs created!
echo ========================================
echo.
echo Next: Run INSTALL_DEPENDENCIES.bat
echo.
pause
