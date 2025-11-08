# 🔧 MANUAL FIX GUIDE - Final Steps

## Current Status

✅ **Embedding Service** - FIXED! (PyTorch installed correctly)
❌ **NLP Service** - Still needs spaCy model
❌ **API Gateway** - Has syntax error in file

---

## Fix 1: NLP Service - spaCy Model

### Open Command Prompt (NOT PowerShell!)

1. Press `Win + R`
2. Type: `cmd`
3. Press Enter

### Run these commands:

```batch
cd E:\SK\resume-scoring-system-local\backend\services\nlp
venv\Scripts\activate
python -m spacy download en_core_web_sm
```

**Wait for download to complete (~12MB)**

You should see:
```
✔ Download and installation successful
```

---

## Fix 2: API Gateway - Fix Syntax Error

The PowerShell command corrupted the file. Let's fix it manually.

### Step 1: Open the file

Open this file in Notepad or VS Code:
```
E:\SK\resume-scoring-system-local\backend\api-gateway\Controllers\ScoringController.cs
```

### Step 2: Check the first few lines

They should look like this:
```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ResumeScoring.Api.Controllers;
```

**If line 1 looks weird** (has `^n` or extra characters), fix it to look exactly like above.

### Step 3: Save the file

### Step 4: Rebuild

Open Command Prompt:
```batch
cd E:\SK\resume-scoring-system-local\backend\api-gateway
dotnet clean
dotnet build
```

Should build successfully now!

---

## Alternative: Direct File Fix

If the file is corrupted, replace the entire ScoringController.cs with this:

**File: backend\api-gateway\Controllers\ScoringController.cs**

```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ResumeScoring.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public class ScoringController : ControllerBase
{
    private readonly IHttpClientFactory _clientFactory;
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ScoringController> _logger;

    public ScoringController(IHttpClientFactory clientFactory, ApplicationDbContext context, ILogger<ScoringController> logger)
    {
        _clientFactory = clientFactory;
        _context = context;
        _logger = logger;
    }

    [HttpPost]
    public async Task<IActionResult> ScoreCandidate([FromBody] ScoreRequest request)
    {
        try
        {
            var scoringClient = _clientFactory.CreateClient("ScoringService");
            var response = await scoringClient.PostAsJsonAsync("/score", request);
            var result = await response.Content.ReadAsStringAsync();
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error scoring candidate");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [HttpGet("candidates/{resumeId}")]
    public async Task<IActionResult> GetCandidateScores(int resumeId)
    {
        var scores = await _context.Scores
            .Where(s => s.ResumeId == resumeId)
            .OrderByDescending(s => s.ComputedAt)
            .ToListAsync();
        return Ok(scores);
    }
}

public record ScoreRequest(object Candidate, object Job, Dictionary<string, double>? Weights);
```

---

## After Fixes - Restart Services

### Close all service windows

### Open Command Prompt (cmd, not PowerShell)

```batch
cd E:\SK\resume-scoring-system-local
START_LOCAL.bat
```

---

## Why PowerShell Didn't Work

PowerShell treats `.bat` files differently. You need to use:
- **Command Prompt (cmd)** - for .bat files
- **PowerShell** - for .ps1 files

---

## Quick Commands (Use CMD!)

```batch
REM Fix NLP
cd backend\services\nlp
venv\Scripts\activate
python -m spacy download en_core_web_sm
deactivate

REM Rebuild API Gateway
cd ..\..\api-gateway
dotnet clean
dotnet build

REM Restart everything
cd ..\..
START_LOCAL.bat
```

---

## Verification

After fixes, all services should show:

**NLP Service:**
```
INFO | Models loaded successfully
* Running on http://127.0.0.1:5002
```

**API Gateway:**
```
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://0.0.0.0:5000
```

**All health checks:**
```batch
curl http://localhost:5001/health
curl http://localhost:5002/health
curl http://localhost:5003/health
curl http://localhost:5004/health
curl http://localhost:5000/health
```

Should all return: `{"status":"healthy"}`

---

## 🎯 Summary

**What worked:**
✅ Embedding Service - PyTorch installed perfectly!

**What needs manual fix:**
1. NLP - Run spaCy download in CMD
2. API Gateway - Fix file (copy code above) or rebuild

**Time needed:** 5 minutes

---

**Use CMD (not PowerShell) for all .bat files!**
