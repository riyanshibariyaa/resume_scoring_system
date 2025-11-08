@echo off
REM ========================================
REM SIMPLE FIX - NLP Service Only
REM Run this in Command Prompt (CMD)
REM ========================================

echo.
echo Fixing NLP Service - Installing spaCy model...
echo.

cd backend\services\nlp
call venv\Scripts\activate.bat

echo Downloading spaCy model (en_core_web_sm)...
python -m spacy download en_core_web_sm

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo SUCCESS! NLP Service is now fixed!
    echo ========================================
    echo.
    echo Close the NLP Service window and restart it.
) else (
    echo.
    echo ========================================
    echo ERROR! spaCy download failed.
    echo ========================================
    echo.
    echo Try manually:
    echo 1. cd backend\services\nlp
    echo 2. venv\Scripts\activate
    echo 3. python -m spacy download en_core_web_sm
)

call deactivate
cd ..\..\..

pause
