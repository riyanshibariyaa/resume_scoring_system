@echo off
REM ========================================
REM INSTALL ALL DEPENDENCIES
REM Run after CREATE_VENVS.bat
REM ========================================

echo.
echo ========================================
echo Installing All Dependencies
echo This will take 10-15 minutes
echo ========================================
echo.

REM Check if VC++ is installed
echo Checking for Visual C++ Redistributable...
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo WARNING: Visual C++ Redistributable may not be installed!
    echo Download: https://aka.ms/vs/17/release/vc_redist.x64.exe
    echo.
    echo Continue anyway? (Y/N)
    set /p continue=
    if /i not "%continue%"=="Y" exit /b 1
)

echo.
echo [1/5] Installing Parsing Service dependencies...
cd backend\services\parsing
call venv\Scripts\activate.bat
pip install --quiet --upgrade pip
pip install -r requirements-cpu.txt
call deactivate
cd ..\..\..
echo ✓ Parsing Service ready

echo.
echo [2/5] Installing NLP Service dependencies...
cd backend\services\nlp
call venv\Scripts\activate.bat
pip install --quiet --upgrade pip
pip install -r requirements-cpu.txt
echo Downloading spaCy model (12MB)...
python -m spacy download en_core_web_sm
call deactivate
cd ..\..\..
echo ✓ NLP Service ready

echo.
echo [3/5] Installing Embedding Service dependencies...
cd backend\services\embedding
call venv\Scripts\activate.bat
pip install --quiet --upgrade pip
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
pip install -r requirements-cpu.txt
call deactivate
cd ..\..\..
echo ✓ Embedding Service ready

echo.
echo [4/5] Installing Scoring Service dependencies...
cd backend\services\scoring
call venv\Scripts\activate.bat
pip install --quiet --upgrade pip
pip install -r requirements-cpu.txt
call deactivate
cd ..\..\..
echo ✓ Scoring Service ready

echo.
echo [5/5] Building API Gateway and Frontend...
cd backend\api-gateway
dotnet restore >nul 2>&1
dotnet build >nul 2>&1
cd ..\..
echo ✓ API Gateway ready

cd frontend
call npm install
cd ..
echo ✓ Frontend ready

echo.
echo ========================================
echo ✓ All dependencies installed!
echo ========================================
echo.
echo Next: Run START_LOCAL.bat
echo.
pause
