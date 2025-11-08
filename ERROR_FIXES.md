# 🔧 ERROR FIXES - Quick Solutions

## Your Current Status

✅ **Working Services:**
- Parsing Service (Port 5001) - ✅ Running
- Scoring Service (Port 5004) - ✅ Running  
- Frontend (Port 3000) - ✅ Running

❌ **Services with Errors:**
- NLP Service (Port 5002) - ❌ spaCy model missing
- Embedding Service (Port 5003) - ❌ PyTorch DLL error
- API Gateway (Port 5000) - ❌ Compilation error

---

## 🚀 Quick Fix (All at Once)

**Run this ONE command:**

```batch
FIX_ALL_ERRORS.bat
```

This fixes all 3 issues automatically!

**Time:** 5-10 minutes (downloads ~150MB)

---

## 🔍 Individual Fixes

If you prefer to fix one at a time:

### Error 1: NLP Service - spaCy Model Missing

**Error:**
```
OSError: [E050] Can't find model 'en_core_web_sm'
```

**Fix:**
```batch
FIX_NLP.bat
```

**Or manually:**
```batch
cd backend\services\nlp
venv\Scripts\activate
python -m spacy download en_core_web_sm
deactivate
```

**Time:** 1 minute (downloads 12MB)

---

### Error 2: Embedding Service - PyTorch DLL Error

**Error:**
```
OSError: [WinError 1114] A dynamic link library (DLL) initialization routine failed
```

**Root Cause:** Wrong PyTorch version installed (with CUDA dependencies)

**Fix:**
```batch
FIX_EMBEDDING.bat
```

**Or manually:**
```batch
cd backend\services\embedding
venv\Scripts\activate
pip uninstall -y torch torchvision torchaudio
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
deactivate
```

**Time:** 3-5 minutes (downloads ~150MB CPU-only PyTorch)

---

### Error 3: API Gateway - Compilation Error

**Error:**
```
error CS1061: 'IOrderedQueryable<Score>' does not contain a definition for 'ToListAsync'
```

**Root Cause:** Missing `using Microsoft.EntityFrameworkCore;`

**Fix:**
```batch
FIX_API_GATEWAY.bat
```

**Or manually:**

1. Open: `backend\api-gateway\Controllers\ScoringController.cs`
2. Add this line after `using Microsoft.AspNetCore.Mvc;`:
   ```csharp
   using Microsoft.EntityFrameworkCore;
   ```
3. Save file
4. Rebuild:
   ```batch
   cd backend\api-gateway
   dotnet build
   ```

**Time:** 30 seconds

---

## 📋 Step-by-Step Fix Process

### Option A: Fix Everything (Recommended)

```batch
1. Close all service windows
2. Run: FIX_ALL_ERRORS.bat
3. Wait 5-10 minutes
4. Run: START_LOCAL.bat
5. All services should work now!
```

### Option B: Fix One by One

```batch
1. Run: FIX_NLP.bat (1 min)
2. Run: FIX_EMBEDDING.bat (5 min)
3. Run: FIX_API_GATEWAY.bat (30 sec)
4. Run: START_LOCAL.bat
```

---

## ⚡ After Running Fixes

### Restart Services:

Close all service windows, then:
```batch
START_LOCAL.bat
```

### Verify Everything Works:

**Test each service health:**
```batch
curl http://localhost:5001/health  # Parsing ✅
curl http://localhost:5002/health  # NLP (should work now)
curl http://localhost:5003/health  # Embedding (should work now)
curl http://localhost:5004/health  # Scoring ✅
curl http://localhost:5000/health  # API Gateway (should work now)
```

**All should return:** `{"status":"healthy"}`

**Open Frontend:**
```
http://localhost:3000
```

Should load without errors!

---

## 🔍 Understanding the Errors

### Why These Errors Happened:

1. **spaCy Model Missing**
   - Cause: Setup script may have skipped download
   - Fix: Manual download with `python -m spacy download`

2. **PyTorch DLL Error**
   - Cause: PyTorch installed wrong variant (possibly CUDA)
   - Fix: Reinstall CPU-only version explicitly
   - Note: This is a Windows-specific issue

3. **API Gateway Compilation**
   - Cause: Missing using directive in source
   - Fix: Add `using Microsoft.EntityFrameworkCore;`

---

## 🎯 Quick Reference

| Error | Service | Fix Script | Time |
|-------|---------|------------|------|
| spaCy model | NLP | FIX_NLP.bat | 1 min |
| PyTorch DLL | Embedding | FIX_EMBEDDING.bat | 5 min |
| ToListAsync | API Gateway | FIX_API_GATEWAY.bat | 30 sec |
| **All** | **All** | **FIX_ALL_ERRORS.bat** | **10 min** |

---

## 🆘 If Fixes Don't Work

### NLP Service Still Fails:

Try larger model:
```batch
cd backend\services\nlp
venv\Scripts\activate
python -m spacy download en_core_web_md
deactivate
```

Then edit `backend\services\nlp\app.py` line 40:
```python
# Change from:
nlp_model = spacy.load("en_core_web_sm")
# To:
nlp_model = spacy.load("en_core_web_md")
```

### Embedding Service Still Fails:

Check your Visual C++ redistributables:

1. Download: [VC++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)
2. Install it
3. Restart computer
4. Run FIX_EMBEDDING.bat again

### API Gateway Still Fails:

Check .NET version:
```batch
dotnet --version
```

Should be 8.0.x. If not, install .NET 8.0 SDK.

---

## 💡 Prevention for Future

### To avoid these errors when setting up again:

1. **For spaCy:**
   ```batch
   # In SETUP_LOCAL.bat, ensure this runs:
   python -m spacy download en_core_web_sm --quiet
   ```

2. **For PyTorch:**
   ```batch
   # Always use explicit CPU index:
   pip install torch --index-url https://download.pytorch.org/whl/cpu
   ```

3. **For API Gateway:**
   - Keep the fixed ScoringController.cs file

---

## 📊 Expected Output After Fixes

### NLP Service (Port 5002):
```
2025-11-08 02:00:00.000 | INFO | Loading spaCy model...
2025-11-08 02:00:01.000 | INFO | Models loaded successfully
* Running on http://127.0.0.1:5002
```

### Embedding Service (Port 5003):
```
Loading sentence transformer model...
Model loaded successfully
* Running on http://127.0.0.1:5003
```

### API Gateway (Port 5000):
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://0.0.0.0:5000
info: Microsoft.Hosting.Lifetime[0]
      Application started.
```

---

## ✅ Final Checklist

After running fixes:

- [ ] FIX_ALL_ERRORS.bat completed successfully
- [ ] All service windows restarted
- [ ] All health checks return "healthy"
- [ ] Frontend loads at http://localhost:3000
- [ ] Can upload a test resume
- [ ] No errors in any window

---

## 🎉 Success!

Once all checks pass, your system is fully operational!

**All 6 services running:**
- ✅ Parsing Service (5001)
- ✅ NLP Service (5002) - Fixed!
- ✅ Embedding Service (5003) - Fixed!
- ✅ Scoring Service (5004)
- ✅ API Gateway (5000) - Fixed!
- ✅ Frontend (3000)

**Time to first working system: ~25 minutes**
(15 min setup + 10 min fixes)

Still faster than 4 hours of Docker builds! 🚀

---

## 📞 Quick Commands

```batch
# Fix everything
FIX_ALL_ERRORS.bat

# Restart services
START_LOCAL.bat

# Test health
curl http://localhost:5001/health
curl http://localhost:5002/health
curl http://localhost:5003/health
curl http://localhost:5004/health
curl http://localhost:5000/health

# Open app
start http://localhost:3000
```

---

**Questions?** Check README_LOCAL.md for more details.

**Working now?** Start uploading resumes and testing! 🎊
