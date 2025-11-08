@echo off
REM ========================================
REM FIX DEPENDENCY ISSUES
REM This script will fix the TensorFlow and transformers compatibility issues
REM ========================================

echo.
echo ========================================
echo Fixing Dependency Issues
echo ========================================
echo.

REM Step 1: Fix NLP Service
echo [1/2] Fixing NLP Service...
cd backend\services\nlp
if exist venv (
    echo Activating venv...
    call venv\Scripts\activate.bat
    
    echo Uninstalling problematic packages...
    pip uninstall -y tensorflow tensorflow-intel tensorflow-estimator transformers huggingface-hub
    
    echo Installing compatible versions...
    pip install --upgrade pip
    pip install transformers==4.35.2
    pip install torch==2.1.0 --index-url https://download.pytorch.org/whl/cpu
    pip install tokenizers==0.15.0
    pip install huggingface-hub==0.19.4
    pip install numpy==1.24.3
    pip install safetensors==0.4.1
    pip install flask flask-cors
    
    echo âœ" NLP Service fixed!
    call deactivate
) else (
    echo ERROR: venv not found! Run CREATE_VENVS.bat first
    goto :error
)
cd ..\..\..

echo.
REM Step 2: Fix Embedding Service
echo [2/2] Fixing Embedding Service...
cd backend\services\embedding
if exist venv (
    echo Activating venv...
    call venv\Scripts\activate.bat
    
    echo Uninstalling problematic packages...
    pip uninstall -y sentence-transformers transformers huggingface-hub tensorflow tensorflow-intel
    
    echo Installing compatible versions...
    pip install --upgrade pip
    pip install sentence-transformers==2.2.2
    pip install transformers==4.35.2
    pip install torch==2.1.0 --index-url https://download.pytorch.org/whl/cpu
    pip install tokenizers==0.15.0
    pip install huggingface-hub==0.19.4
    pip install numpy==1.24.3
    pip install scikit-learn scipy nltk sentencepiece
    pip install flask flask-cors
    
    echo âœ" Embedding Service fixed!
    call deactivate
) else (
    echo ERROR: venv not found! Run CREATE_VENVS.bat first
    goto :error
)
cd ..\..\..

echo.
echo ========================================
echo âœ" All dependency issues fixed!
echo ========================================
echo.
echo You can now start your services.
echo.
pause
goto :end

:error
echo.
echo ========================================
echo âœ— Error occurred!
echo ========================================
echo.
pause
exit /b 1

:end
