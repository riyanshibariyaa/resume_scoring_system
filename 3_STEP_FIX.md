# ⚡ 3-STEP FIX - Ultra Simple

## 🎯 The Real Problem

**PyTorch needs Visual C++ Runtime DLLs** - that's why both NLP and Embedding services are failing!

---

## ✅ 3 Simple Steps (20 minutes)

### Step 1: Install Visual C++ (5 minutes)

1. **Download**: https://aka.ms/vs/17/release/vc_redist.x64.exe
2. **Run** the installer
3. Click **"Install"**
4. **RESTART** your computer (IMPORTANT!)

**Why**: PyTorch's C++ libraries need these DLLs to work on Windows.

---

### Step 2: Fix API Gateway File (2 minutes)

The PowerShell command corrupted this file.

1. **Open** in Notepad:
   ```
   E:\SK\resume-scoring-system-local\backend\api-gateway\Controllers\ScoringController.cs
   ```

2. **Delete all** content

3. **Copy-paste** this code:
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

4. **Save** (Ctrl+S)

---

### Step 3: Run Fix Script (10 minutes)

**After VC++ install and restart**, open **Command Prompt** and run:

```batch
cd E:\SK\resume-scoring-system-local
FIX_AFTER_VCPP.bat
```

**This will:**
- Reinstall PyTorch CPU version (Embedding)
- Reinstall PyTorch + download spaCy model (NLP)
- Rebuild API Gateway
- Test everything

**Time**: 10 minutes (downloads ~110MB)

---

## 🎉 Done! Start Services

```batch
START_LOCAL.bat
```

Open browser: **http://localhost:3000**

---

## 📋 Quick Checklist

- [ ] Step 1: VC++ installed? Computer restarted?
- [ ] Step 2: API Gateway file fixed?
- [ ] Step 3: FIX_AFTER_VCPP.bat completed successfully?
- [ ] All services started?
- [ ] Frontend loads at http://localhost:3000?

**All checked?** You're done! 🎊

---

## 🔍 Verification

After fixes, test each service:

```batch
curl http://localhost:5001/health  # Parsing
curl http://localhost:5002/health  # NLP (should work now!)
curl http://localhost:5003/health  # Embedding (should work now!)
curl http://localhost:5004/health  # Scoring
curl http://localhost:5000/health  # API Gateway (should work now!)
```

**All should return**: `{"status":"healthy"}`

---

## ❓ FAQ

**Q: Why do I need VC++?**
A: PyTorch is written in C++ and needs Microsoft's C++ runtime libraries on Windows.

**Q: Can I skip the restart?**
A: No! DLLs won't load properly without a restart.

**Q: Why did the previous fixes not work?**
A: They didn't install VC++ first. That's the root cause of the PyTorch DLL error.

**Q: Will this slow down my system?**
A: No, VC++ Redistributable is a small (~14MB) system library used by many programs.

---

## 🆘 If It Still Fails

**After VC++ install + restart**, if PyTorch still fails:

1. Check VC++ is installed:
   - Open "Add or Remove Programs"
   - Search for "Visual C++ 2015-2022 Redistributable (x64)"
   - Should be listed

2. Try alternative VC++ version:
   - Download: https://aka.ms/vs/16/release/vc_redist.x64.exe

3. Check Python version:
   ```batch
   python --version
   ```
   Should be 3.10, 3.11, or 3.12

---

## 💡 Summary

**Root cause**: Missing Visual C++ Runtime → PyTorch DLL fails to load

**Solution**:
1. Install VC++ (one-time, system-wide)
2. Fix corrupted API Gateway file
3. Reinstall PyTorch in both services

**Time**: 20 minutes total (including restart)

**Result**: All 6 services working! 🚀

---

## 📞 Quick Commands

```batch
REM 1. Download VC++ from browser, install, restart

REM 2. Fix API Gateway file manually (copy-paste code above)

REM 3. Run automated fix
cd E:\SK\resume-scoring-system-local
FIX_AFTER_VCPP.bat

REM 4. Start services
START_LOCAL.bat

REM 5. Test
start http://localhost:3000
```

---

**The VC++ install is the KEY - everything else is easy!** ✨
