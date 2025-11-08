@echo off
REM Fix NLP Service - Download spaCy model

echo.
echo ========================================
echo Fixing NLP Service
echo ========================================
echo.
echo Issue: spaCy model 'en_core_web_sm' not found
echo Solution: Downloading model now...
echo.

cd backend\services\nlp
call venv\Scripts\activate.bat

echo Downloading spaCy model (12MB)...
python -m spacy download en_core_web_sm

call deactivate
cd ..\..\..

echo.
echo ✓ NLP Service Fixed!
echo.
echo The spaCy model is now installed.
echo Close the NLP Service window and restart it.
echo.
pause
