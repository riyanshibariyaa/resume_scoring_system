# 🚀 Resume Scoring System - LOCAL DEVELOPMENT EDITION

## ⚡ Optimized for 4GB RAM, No GPU, Windows

This version is **specifically optimized** for running on low-spec machines without Docker overhead!

---

## 🎯 What's Different?

### Docker Version (Original)
- ❌ Takes hours to build
- ❌ Downloads 2GB+ of CUDA/GPU packages you don't need
- ❌ Uses 4-6GB RAM
- ❌ Requires powerful machine

### Local Version (This One!)
- ✅ Setup in 15 minutes
- ✅ Only CPU-optimized packages (~300MB)
- ✅ Uses only ~1.75GB RAM
- ✅ Perfect for 4GB RAM machines
- ✅ Docker only for SQL Server

---

## 🚀 Quick Start (3 Steps)

### Step 1: Install Prerequisites

**Required:**
1. **Python 3.10+** → [Download](https://www.python.org/downloads/)
2. **.NET SDK 8.0** → [Download](https://dotnet.microsoft.com/download)
3. **Node.js 18+** → [Download](https://nodejs.org/)
4. **Docker Desktop** → [Download](https://www.docker.com/products/docker-desktop) (Only for SQL Server)

**Optional but Recommended:**
5. **Git Bash or WSL** → For better terminal experience

### Step 2: Run Setup

```batch
SETUP_LOCAL.bat
```

This will:
- ✅ Start SQL Server in Docker (only database!)
- ✅ Initialize database schema
- ✅ Install CPU-only Python packages
- ✅ Setup .NET API Gateway
- ✅ Install React frontend

**Time: ~15 minutes** (vs hours with full Docker!)

### Step 3: Start Services

```batch
START_LOCAL.bat
```

Opens 6 windows:
- 📄 Parsing Service (Port 5001)
- 🧠 NLP Service (Port 5002)
- 📊 Embedding Service (Port 5003)
- ⚡ Scoring Service (Port 5004)
- 🌐 API Gateway (Port 5000)
- 🎨 Frontend (Port 3000)

**Wait 30-60 seconds, then visit: http://localhost:3000**

---

## 📋 Memory Usage Breakdown

```
Component             Memory
──────────────────────────────
SQL Server (Docker)   ~500 MB
Parsing Service       ~150 MB
NLP Service           ~250 MB
Embedding Service     ~200 MB
Scoring Service       ~100 MB
API Gateway           ~150 MB
React Frontend        ~300 MB
──────────────────────────────
TOTAL                 ~1.65 GB ✅

Your available: 4GB
Headroom:      ~2.35 GB for OS + IDE
```

---

## 🔧 What's Been Optimized

### 1. Python Dependencies (CPU-Only)

**Before (Docker):**
```txt
torch==2.1.1              # 900MB with CUDA!
transformers==4.35.2      # 500MB+
```

**After (Local):**
```txt
sentence-transformers==2.2.2  # Auto-installs CPU PyTorch (~100MB)
spacy==3.7.2                  # Lightweight NLP (~50MB)
```

**Savings: ~1.3GB!**

### 2. No Heavy Transformers

We use lightweight alternatives:
- ✅ spaCy for NER (12MB model)
- ✅ sentence-transformers with tiny model (80MB)
- ✅ Regex patterns for skill matching
- ❌ NO BERT, GPT, or RoBERTa (saves 500MB each!)

### 3. Only Essential Services

You can run services individually:
```batch
# Only need parsing during development?
cd backend\services\parsing
venv\Scripts\activate
python app.py
```

---

## 📁 File Changes from Original

### New Files:
```
SETUP_LOCAL.bat                          ← Automated local setup
START_LOCAL.bat                          ← Start all services locally
STOP_LOCAL.bat                           ← Stop all services
README_LOCAL.md                          ← This file
backend/services/*/requirements-cpu.txt  ← Optimized dependencies
```

### Modified Files:
None! Original files unchanged, so you can still use Docker if needed.

---

## 🎯 Daily Workflow

### Morning (Start Working):
```batch
START_LOCAL.bat
```

### During Development:
- Services auto-reload on code changes (Flask debug mode)
- Edit files directly in your IDE
- Check logs in service windows
- Test at http://localhost:3000

### Evening (Stop Working):
```batch
STOP_LOCAL.bat
```
Or just close the service windows.

---

## 🛠️ Tips for 4GB RAM

### 1. Don't Run Everything at Once

Working on parsing only?
```batch
# Start only SQL Server + Parsing Service
docker start resume-scoring-db
cd backend\services\parsing
venv\Scripts\activate
python app.py
```

### 2. Close Unnecessary Apps

Before starting:
- ✅ Close Chrome (use Edge, lighter)
- ✅ Close Slack/Teams
- ✅ Close other IDEs
- ✅ Keep only VSCode open

### 3. Use Lightweight Tools

- ✅ VS Code (not Visual Studio)
- ✅ Windows Terminal (not cmd)
- ✅ Edge DevTools (lighter than Chrome)

### 4. Monitor Memory

```batch
# Check memory usage
tasklist /FI "STATUS eq running" /FO TABLE
```

### 5. Restart Services Individually

Don't restart all services if only one needs refresh:
```batch
# Just restart NLP service
# Close its window, then:
cd backend\services\nlp
venv\Scripts\activate
set PORT=5002
python app.py
```

---

## 🔍 Troubleshooting

### Issue: "Python not found"
```batch
# Add Python to PATH
setx PATH "%PATH%;C:\Python310"
```

### Issue: "Docker not running"
```batch
# Start Docker Desktop
# Wait for it to fully start (~30 seconds)
```

### Issue: "Port already in use"
```batch
# Find and kill process
netstat -ano | findstr :5000
taskkill /PID <PID> /F
```

### Issue: "Out of memory"
```batch
# Close all services
STOP_LOCAL.bat

# Close other apps
# Restart only what you need
```

### Issue: "SQL Server won't start"
```batch
# Remove old container and recreate
docker stop resume-scoring-db
docker rm resume-scoring-db

# Run SETUP_LOCAL.bat again
```

### Issue: "Dependencies taking too long"
```batch
# Use requirements-cpu.txt files instead of requirements.txt
# These are much smaller and faster
pip install -r requirements-cpu.txt
```

---

## 📊 Performance Comparison

| Metric | Docker (All Services) | Local (This Version) |
|--------|---------------------|-------------------|
| **Setup Time** | 2-4 hours | 15 minutes |
| **Memory Usage** | 4-6 GB | 1.75 GB |
| **Disk Space** | ~8 GB | ~2 GB |
| **Startup Time** | 3-5 minutes | 30 seconds |
| **Dependencies** | 2GB+ downloads | 300MB downloads |
| **Hot Reload** | ❌ (rebuild needed) | ✅ (instant) |
| **Debugging** | ❌ (in container) | ✅ (direct access) |

---

## 🎓 Understanding the Architecture

### What Runs Where:

```
┌─────────────────────────────────────────┐
│         Your Windows Machine            │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │        Docker Container            │ │
│  │     SQL Server (Port 1433)        │ │
│  └───────────────────────────────────┘ │
│                                         │
│  Python Services (venv)                 │
│  ├─ Parsing (5001)                     │
│  ├─ NLP (5002)                         │
│  ├─ Embedding (5003)                   │
│  └─ Scoring (5004)                     │
│                                         │
│  .NET API Gateway (5000)               │
│                                         │
│  React Frontend (3000)                 │
│                                         │
└─────────────────────────────────────────┘
```

**Why SQL Server in Docker?**
- ✅ Easy setup (one command)
- ✅ Clean removal (no system pollution)
- ✅ Version control
- ✅ Can switch to local SQL Server Express anytime

**Why Services Local?**
- ✅ Fast development cycle
- ✅ Direct debugging
- ✅ No Docker overhead
- ✅ Use less RAM

---

## 🎯 Next Steps

### Immediate:
1. ✅ Run `SETUP_LOCAL.bat`
2. ✅ Run `START_LOCAL.bat`
3. ✅ Visit http://localhost:3000
4. ✅ Upload a test resume

### This Week:
1. Customize scoring weights
2. Add your company skills
3. Test with real resumes
4. Adjust to your needs

### Later:
1. Consider upgrading RAM to 8GB
2. Deploy to cloud when ready
3. Add more ML models (if needed)
4. Scale services separately

---

## 💡 Pro Tips

### Tip 1: Use Windows Terminal
Much better than cmd.exe:
```batch
# Install from Microsoft Store
winget install Microsoft.WindowsTerminal
```

### Tip 2: Create Shortcuts
Right-click START_LOCAL.bat → Send to → Desktop (create shortcut)

### Tip 3: Use VS Code Tasks
Add to `.vscode/tasks.json`:
```json
{
  "label": "Start All Services",
  "type": "shell",
  "command": "START_LOCAL.bat"
}
```

### Tip 4: Monitor Logs
All logs are in the service windows. Keep them visible while developing.

### Tip 5: Git Ignore Virtual Environments
```
# .gitignore
**/venv/
**/__pycache__/
**/node_modules/
```

---

## 🆘 Still Having Issues?

### Can't allocate enough RAM?

**Super minimal setup** - Run only what you need:

```batch
# Just parsing + database
docker start resume-scoring-db
cd backend\services\parsing
venv\Scripts\activate
python app.py
```

### SQL Server too heavy?

Install **SQL Server Express** locally instead:
1. Download SQL Server Express (free)
2. Install with default settings
3. Update connection strings
4. Skip Docker entirely

---

## ✅ Verification Checklist

After setup, verify everything works:

```batch
# 1. Check SQL Server
docker ps | findstr resume-scoring-db

# 2. Check each service health
curl http://localhost:5001/health
curl http://localhost:5002/health
curl http://localhost:5003/health
curl http://localhost:5004/health
curl http://localhost:5000/health

# 3. Check frontend
# Open http://localhost:3000 in browser
```

All should return `{"status":"healthy"}`

---

## 🎉 Success!

You now have a **lightweight, fast, development-friendly** version of the Resume Scoring System!

**Total time: 15 minutes**
**Memory usage: 1.75 GB**
**Setup complexity: Low**

Perfect for development on your 4GB RAM Windows machine!

---

## 📞 Quick Reference

| Action | Command |
|--------|---------|
| **Setup** | `SETUP_LOCAL.bat` |
| **Start** | `START_LOCAL.bat` |
| **Stop** | `STOP_LOCAL.bat` |
| **Frontend** | http://localhost:3000 |
| **API Docs** | http://localhost:5000/swagger |
| **Restart DB** | `docker restart resume-scoring-db` |

---

**Version:** 1.0.0 - Local Development Edition
**Optimized for:** 4GB RAM, No GPU, Windows
**Last Updated:** November 2025

🚀 **Happy Coding!**
