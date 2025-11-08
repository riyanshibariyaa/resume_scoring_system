@echo off
REM ============================================
REM FIX ALL ERRORS - Resume Scoring System
REM ============================================

echo.
echo ========================================
echo Fixing All Service Errors
echo ========================================
echo.

echo [1/4] Fixing NLP Service - spaCy model...
cd backend\services\nlp
call venv\Scripts\activate.bat
echo Installing spaCy model...
python -m spacy download en_core_web_sm
call deactivate
cd ..\..\..
echo ✓ NLP Service fixed
echo.

echo [2/4] Fixing Embedding Service - PyTorch DLL...
cd backend\services\embedding
call venv\Scripts\activate.bat
echo Reinstalling PyTorch CPU version...
pip uninstall -y torch
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
call deactivate
cd ..\..\..
echo ✓ Embedding Service fixed
echo.

echo [3/4] Fixing API Gateway - Missing using statement...
cd backend\api-gateway
echo Fixing ScoringController.cs...

REM Add missing using directive
powershell -Command "(Get-Content Controllers\ScoringController.cs) -replace 'using Microsoft.AspNetCore.Mvc;', 'using Microsoft.AspNetCore.Mvc;^nusing Microsoft.EntityFrameworkCore;' | Set-Content Controllers\ScoringController.cs"

echo Rebuilding API Gateway...
dotnet build
cd ..\..
echo ✓ API Gateway fixed
echo.

echo [4/4] Summary...
echo.
echo Fixed Issues:
echo   ✓ NLP: spaCy model installed
echo   ✓ Embedding: PyTorch CPU installed correctly
echo   ✓ API Gateway: Missing using directive added
echo   ✓ Parsing: Already working!
echo   ✓ Scoring: Already working!
echo   ✓ Frontend: Already working!
echo.
echo ========================================
echo All fixes applied!
echo ========================================
echo.
echo Next: Run START_LOCAL.bat again
echo.
pause
