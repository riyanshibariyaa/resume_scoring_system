# 🚀 Resume Scoring System - Ready to Run!

## ⚡ Quick Start (3 Steps - 25 Minutes)

### What You're Getting
- Complete AI Resume Parser & Scoring System
- Optimized for 4GB RAM, CPU-only (no GPU needed)
- All services run locally (fast & easy debugging)
- Docker only for SQL Server database

---

## 📋 Prerequisites (Install These First)

1. **Python 3.10+** → https://www.python.org/downloads/
2. **.NET SDK 8.0** → https://dotnet.microsoft.com/download
3. **Node.js 18+** → https://nodejs.org/
4. **Docker Desktop** → https://www.docker.com/products/docker-desktop
5. **Visual C++ Redistributable** → https://aka.ms/vs/17/release/vc_redist.x64.exe ⭐ **IMPORTANT!**

**⚠️ Critical**: Install **Visual C++ Redistributable** and **restart your computer** before running setup!

---

## 🚀 Step 1: Setup (15 minutes)

Open **Command Prompt** (NOT PowerShell):
1. Press `Win + R`
2. Type: `cmd`
3. Press Enter

Run setup:
```batch
cd path\to\resume-scoring-system-clean
SETUP_LOCAL.bat
```

**What it does:**
- Starts SQL Server in Docker
- Creates Python virtual environments
- Installs all dependencies (CPU-optimized, ~300MB)
- Builds .NET API Gateway
- Installs React frontend

**Time**: 15 minutes

---

## 🔧 Step 2: Fix PyTorch (if needed) (5 minutes)

If you see PyTorch DLL errors, run this **AFTER installing VC++ and restarting**:

```batch
FIX_AFTER_VCPP.bat
```

**What it does:**
- Reinstalls PyTorch CPU version
- Downloads spaCy model
- Tests everything

**Time**: 5 minutes

---

## ▶️ Step 3: Start Services (1 minute)

In Command Prompt:
```batch
START_LOCAL.bat
```

**Opens 6 windows:**
- Parsing Service (5001)
- NLP Service (5002)
- Embedding Service (5003)
- Scoring Service (5004)
- API Gateway (5000)
- Frontend (3000)

**Wait 30-60 seconds**, then open browser:
```
http://localhost:3000
```

---

## ✅ Verification

Test each service health:
```batch
curl http://localhost:5001/health
curl http://localhost:5002/health
curl http://localhost:5003/health
curl http://localhost:5004/health
curl http://localhost:5000/health
```

All should return: `{"status":"healthy"}`

---

## 📁 Project Structure

```
resume-scoring-system-clean/
├── START_LOCAL.bat          ← Start all services
├── SETUP_LOCAL.bat          ← One-time setup
├── FIX_AFTER_VCPP.bat       ← Fix PyTorch (if needed)
├── STOP_LOCAL.bat           ← Stop all services
│
├── backend/
│   ├── api-gateway/         ← .NET Core API (Port 5000)
│   └── services/
│       ├── parsing/         ← PDF/DOCX parser (Port 5001)
│       ├── nlp/             ← NLP extraction (Port 5002)
│       ├── embedding/       ← Text embeddings (Port 5003)
│       └── scoring/         ← Scoring engine (Port 5004)
│
├── frontend/                ← React UI (Port 3000)
├── database/                ← SQL Server schema
└── docker-compose-local.yml ← Database only
```

---

## 🎯 Features

### Resume Parsing
- ✅ PDF, DOCX, TXT support
- ✅ OCR for scanned documents
- ✅ Section detection

### NLP Extraction
- ✅ Contact info (email, phone, LinkedIn)
- ✅ Skills extraction & categorization
- ✅ Experience timeline
- ✅ Education parsing
- ✅ Certifications

### Candidate Scoring
- ✅ Multi-dimensional scoring (6 criteria)
- ✅ Configurable weights
- ✅ Explainable AI results
- ✅ Semantic similarity

---

## 🛑 Stop Services

Close all service windows, or run:
```batch
STOP_LOCAL.bat
```

---

## 🆘 Troubleshooting

### Issue: PyTorch DLL Error

**Error**: `OSError: [WinError 1114] DLL initialization routine failed`

**Solution**:
1. Install VC++ Redistributable: https://aka.ms/vs/17/release/vc_redist.x64.exe
2. **Restart computer**
3. Run: `FIX_AFTER_VCPP.bat`

### Issue: spaCy Model Not Found

**Error**: `Can't find model 'en_core_web_sm'`

**Solution**:
```batch
cd backend\services\nlp
venv\Scripts\activate
python -m spacy download en_core_web_sm
deactivate
```

### Issue: API Gateway Build Error

**Solution**: Check that `Controllers\ScoringController.cs` exists and is correct.

See `3_STEP_FIX.md` for complete code.

### Issue: Port Already in Use

**Solution**:
```batch
netstat -ano | findstr :5000
taskkill /PID <PID> /F
```

---

## 📊 Resource Usage

| Component | Memory | Port |
|-----------|--------|------|
| SQL Server | ~500 MB | 1433 |
| Parsing | ~150 MB | 5001 |
| NLP | ~250 MB | 5002 |
| Embedding | ~200 MB | 5003 |
| Scoring | ~100 MB | 5004 |
| API Gateway | ~150 MB | 5000 |
| Frontend | ~300 MB | 3000 |
| **Total** | **~1.65 GB** | - |

**Perfect for 4GB RAM!** ✅

---

## 📚 Documentation

- **3_STEP_FIX.md** - Simple fix guide for common errors
- **COMPLETE_FIX_GUIDE.md** - Detailed troubleshooting
- **README_LOCAL.md** - Full local development guide
- **PROJECT_COMPLETION.md** - Complete feature list

---

## 🎯 Quick Commands Reference

```batch
REM One-time setup
SETUP_LOCAL.bat

REM Start all services
START_LOCAL.bat

REM Stop all services
STOP_LOCAL.bat

REM Fix PyTorch (if needed, after VC++ install)
FIX_AFTER_VCPP.bat

REM Test health
curl http://localhost:5001/health

REM Open frontend
start http://localhost:3000
```

---

## ⚠️ Important Notes

1. **Always use Command Prompt (cmd), NOT PowerShell** for .bat files
2. **Install Visual C++ Redistributable BEFORE setup** to avoid PyTorch errors
3. **Restart computer after installing VC++** - DLLs won't load otherwise
4. **Wait 30-60 seconds** after starting services before accessing frontend

---

## ✅ Success Checklist

- [ ] Python 3.10+ installed
- [ ] .NET SDK 8.0 installed
- [ ] Node.js 18+ installed
- [ ] Docker Desktop installed
- [ ] VC++ Redistributable installed
- [ ] Computer restarted after VC++
- [ ] SETUP_LOCAL.bat completed
- [ ] All 6 service windows opened
- [ ] Frontend loads at http://localhost:3000
- [ ] Can upload and score resumes

---

## 🎉 You're Ready!

**Total setup time**: 20-25 minutes
**Memory usage**: 1.65 GB
**All CPU-optimized**: No GPU needed

Much faster than 4+ hours of Docker builds! 🚀

---

## 📞 Support

For detailed guides, check the documentation files:
- Common errors → `3_STEP_FIX.md`
- Full troubleshooting → `COMPLETE_FIX_GUIDE.md`
- Local development → `README_LOCAL.md`

---

**Version**: 1.0.0 - Clean Edition
**Optimized for**: 4GB RAM, CPU-only, Windows
**Last Updated**: November 2025
