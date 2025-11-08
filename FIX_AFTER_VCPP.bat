@echo off
REM ========================================
REM COMPLETE FIX - Run AFTER VC++ Install
REM ========================================

echo.
echo ========================================
echo Complete Fix - Resume Scoring System
echo ========================================
echo.
echo IMPORTANT: Have you installed Visual C++ Redistributable?
echo Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe
echo.
echo Have you RESTARTED your computer after installing VC++?
echo.
set /p vcinstalled="Type YES if VC++ installed and computer restarted: "

if /i not "%vcinstalled%"=="YES" (
    echo.
    echo Please install VC++ Redistributable first, then restart!
    echo Download: https://aka.ms/vs/17/release/vc_redist.x64.exe
    echo.
    pause
    exit /b 1
)

echo.
echo Great! Proceeding with fixes...
echo.

REM ========================================
echo [1/3] Fixing Embedding Service...
REM ========================================

cd backend\services\embedding
call venv\Scripts\activate.bat

echo Uninstalling old PyTorch...
pip uninstall -y torch torchvision torchaudio >nul 2>&1

echo Installing PyTorch CPU version...
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

echo Testing PyTorch...
python -c "import torch; print('✓ PyTorch works! Version:', torch.__version__)"

if %errorlevel% neq 0 (
    echo ERROR: PyTorch still failing!
    echo Make sure VC++ is installed and computer is restarted.
    pause
    exit /b 1
)

call deactivate
cd ..\..\..

echo ✓ Embedding Service fixed!
echo.

REM ========================================
echo [2/3] Fixing NLP Service...
REM ========================================

cd backend\services\nlp
call venv\Scripts\activate.bat

echo Uninstalling old PyTorch...
pip uninstall -y torch torchvision torchaudio >nul 2>&1

echo Installing PyTorch CPU version...
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

echo Downloading spaCy model...
python -m spacy download en_core_web_sm

echo Testing NLP packages...
python -c "import torch; import spacy; print('✓ Both PyTorch and spaCy work!')"

if %errorlevel% neq 0 (
    echo ERROR: NLP packages still failing!
    pause
    exit /b 1
)

call deactivate
cd ..\..\..

echo ✓ NLP Service fixed!
echo.

REM ========================================
echo [3/3] Rebuilding API Gateway...
REM ========================================

cd backend\api-gateway

echo Cleaning previous build...
dotnet clean >nul 2>&1

echo Building API Gateway...
dotnet build

if %errorlevel% neq 0 (
    echo.
    echo ERROR: API Gateway build failed!
    echo.
    echo Please check that ScoringController.cs is correct.
    echo See COMPLETE_FIX_GUIDE.md for the correct file content.
    pause
    exit /b 1
)

cd ..\..

echo ✓ API Gateway rebuilt!
echo.

REM ========================================
echo SUCCESS!
REM ========================================

echo.
echo ========================================
echo All fixes completed successfully!
echo ========================================
echo.
echo Services fixed:
echo   ✓ Embedding Service - PyTorch working
echo   ✓ NLP Service - PyTorch + spaCy working
echo   ✓ API Gateway - Build successful
echo.
echo Services already working:
echo   ✓ Parsing Service
echo   ✓ Scoring Service
echo   ✓ Frontend
echo.
echo Next: Run START_LOCAL.bat to start all services
echo.
pause
