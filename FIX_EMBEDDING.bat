@echo off
REM Fix Embedding Service - PyTorch DLL error

echo.
echo ========================================
echo Fixing Embedding Service
echo ========================================
echo.
echo Issue: PyTorch DLL initialization failed
echo Solution: Reinstalling PyTorch CPU version
echo.

cd backend\services\embedding
call venv\Scripts\activate.bat

echo Uninstalling current PyTorch...
pip uninstall -y torch torchvision torchaudio

echo.
echo Installing PyTorch CPU version (~150MB)...
echo This may take 2-3 minutes...
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

echo.
echo Verifying installation...
python -c "import torch; print(f'PyTorch version: {torch.__version__}'); print(f'CPU available: {torch.cuda.is_available() == False}')"

call deactivate
cd ..\..\..

echo.
echo ✓ Embedding Service Fixed!
echo.
echo PyTorch CPU version is now installed correctly.
echo Close the Embedding Service window and restart it.
echo.
pause
