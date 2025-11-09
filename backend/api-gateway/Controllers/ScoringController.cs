using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ResumeScoring.Api.Data;
using System.Text.Json;

namespace ResumeScoring.Api.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class ScoringController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<ScoringController> _logger;

        public ScoringController(ApplicationDbContext context, ILogger<ScoringController> logger)
        {
            _context = context;
            _logger = logger;
        }

        // DTO used for the POST body
        public class ScoreRequest
        {
            public int ResumeId { get; set; }
            public int JobId { get; set; }
        }

        /// <summary>
        /// Accepts POST /api/v1/scoring with body { resumeId, jobId } and runs scoring.
        /// This provides a simple endpoint your frontend can call.
        /// </summary>
        [HttpPost]  // This matches POST api/v1/scoring
        public async Task<IActionResult> CreateScore([FromBody] ScoreRequest request)
        {
            if (request == null)
                return BadRequest(new { error = "Request body is required: { resumeId, jobId }" });

            // Reuse existing action
            return await ScoreResume(request.ResumeId, request.JobId);
        }

        [HttpPost("score-resume/{resumeId}/job/{jobId}")]
        public async Task<IActionResult> ScoreResume(int resumeId, int jobId)
        {
            try
            {
                _logger.LogInformation($"Scoring resume {resumeId} against job {jobId}");

                // Get resume with parsed data
                var resume = await _context.Resumes.FindAsync(resumeId);
                if (resume == null)
                {
                    return NotFound(new { message = "Resume not found" });
                }

                var parsedData = await _context.ParsedData
                    .Where(pd => pd.ResumeId == resumeId)
                    .FirstOrDefaultAsync();

                // Get job
                var job = await _context.Jobs.FindAsync(jobId);
                if (job == null)
                {
                    return NotFound(new { message = "Job not found" });
                }

                // Parse weight config
                var weights = ParseWeightConfig(job.WeightConfig);

                // Calculate scores using ParsedData if available, fallback to RawText
                decimal educationScore;
                decimal experienceScore;
                decimal skillsScore;

                if (parsedData != null && !string.IsNullOrEmpty(parsedData.Skills))
                {
                    // Use structured data for better scoring
                    educationScore = CalculateEducationScoreFromParsedData(parsedData);
                    experienceScore = CalculateExperienceScoreFromParsedData(parsedData);
                    skillsScore = CalculateSkillsScoreFromParsedData(parsedData, job);
                    _logger.LogInformation("Using ParsedData for scoring");
                }
                else
                {
                    // Fallback to basic keyword-based scoring
                    educationScore = CalculateEducationScore(resume);
                    experienceScore = CalculateExperienceScore(resume);
                    skillsScore = CalculateSkillsScore(resume, job);
                    _logger.LogWarning($"No ParsedData found for resume {resumeId}, using fallback scoring");
                }

                // Calculate weighted total
                var totalScore = 
                    (educationScore * weights.Education) +
                    (experienceScore * weights.Experience) +
                    (skillsScore * weights.Skills);

                // Check if score already exists
                var existingScore = await _context.ResumeScores
                    .FirstOrDefaultAsync(s => s.ResumeId == resumeId && s.JobId == jobId);

                if (existingScore != null)
                {
                    // Update existing score
                    existingScore.TotalScore = totalScore;
                    existingScore.EducationScore = educationScore;
                    existingScore.ExperienceScore = experienceScore;
                    existingScore.SkillsScore = skillsScore;
                    existingScore.ScoredAt = DateTime.UtcNow;
                }
                else
                {
                    // Create new score
                    var score = new ResumeScore
                    {
                        ResumeId = resumeId,
                        JobId = jobId,
                        TotalScore = totalScore,
                        EducationScore = educationScore,
                        ExperienceScore = experienceScore,
                        SkillsScore = skillsScore,
                        ScoredAt = DateTime.UtcNow
                    };

                    _context.ResumeScores.Add(score);
                }

                await _context.SaveChangesAsync();

                _logger.LogInformation($"Resume {resumeId} scored: {totalScore:F2}");

                return Ok(new
                {
                    resumeId,
                    jobId,
                    totalScore = Math.Round(totalScore, 2),
                    educationScore = Math.Round(educationScore, 2),
                    experienceScore = Math.Round(experienceScore, 2),
                    skillsScore = Math.Round(skillsScore, 2),
                    usedParsedData = parsedData != null && !string.IsNullOrEmpty(parsedData.Skills),
                    message = "Resume scored successfully"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error scoring resume");
                return StatusCode(500, new { message = "Error scoring resume", error = ex.Message });
            }
        }

        [HttpPost("score-all-resumes/{jobId}")]
        public async Task<IActionResult> ScoreAllResumes(int jobId)
        {
            try
            {
                _logger.LogInformation($"Scoring all resumes against job {jobId}");

                var job = await _context.Jobs.FindAsync(jobId);
                if (job == null)
                {
                    return NotFound(new { message = "Job not found" });
                }

                var resumes = await _context.Resumes.ToListAsync();
                var parsedDataDict = await _context.ParsedData
                    .Where(pd => pd.Skills != null)
                    .ToDictionaryAsync(pd => pd.ResumeId);

                var results = new List<object>();
                var weights = ParseWeightConfig(job.WeightConfig);

                foreach (var resume in resumes)
                {
                    decimal educationScore;
                    decimal experienceScore;
                    decimal skillsScore;

                    if (parsedDataDict.TryGetValue(resume.ResumeId, out var parsedData))
                    {
                        educationScore = CalculateEducationScoreFromParsedData(parsedData);
                        experienceScore = CalculateExperienceScoreFromParsedData(parsedData);
                        skillsScore = CalculateSkillsScoreFromParsedData(parsedData, job);
                    }
                    else
                    {
                        educationScore = CalculateEducationScore(resume);
                        experienceScore = CalculateExperienceScore(resume);
                        skillsScore = CalculateSkillsScore(resume, job);
                    }

                    var totalScore = 
                        (educationScore * weights.Education) +
                        (experienceScore * weights.Experience) +
                        (skillsScore * weights.Skills);

                    var existingScore = await _context.ResumeScores
                        .FirstOrDefaultAsync(s => s.ResumeId == resume.ResumeId && s.JobId == jobId);

                    if (existingScore != null)
                    {
                        existingScore.TotalScore = totalScore;
                        existingScore.EducationScore = educationScore;
                        existingScore.ExperienceScore = experienceScore;
                        existingScore.SkillsScore = skillsScore;
                        existingScore.ScoredAt = DateTime.UtcNow;
                    }
                    else
                    {
                        var score = new ResumeScore
                        {
                            ResumeId = resume.ResumeId,
                            JobId = jobId,
                            TotalScore = totalScore,
                            EducationScore = educationScore,
                            ExperienceScore = experienceScore,
                            SkillsScore = skillsScore,
                            ScoredAt = DateTime.UtcNow
                        };
                        _context.ResumeScores.Add(score);
                    }

                    results.Add(new
                    {
                        resumeId = resume.ResumeId,
                        candidateName = resume.CandidateName,
                        fileName = resume.FileName,
                        totalScore = Math.Round(totalScore, 2),
                        educationScore = Math.Round(educationScore, 2),
                        experienceScore = Math.Round(experienceScore, 2),
                        skillsScore = Math.Round(skillsScore, 2)
                    });
                }

                await _context.SaveChangesAsync();

                _logger.LogInformation($"Scored {results.Count} resumes against job {jobId}");

                return Ok(new
                {
                    jobId,
                    resumesScored = results.Count,
                    scores = results.OrderByDescending(r => ((dynamic)r).totalScore).ToList()
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error scoring all resumes");
                return StatusCode(500, new { message = "Error scoring all resumes", error = ex.Message });
            }
        }

        [HttpGet("scores/job/{jobId}")]
        public async Task<IActionResult> GetScoresByJob(int jobId)
        {
            try
            {
                var scores = await _context.ResumeScores
                    .Include(s => s.Resume)
                    .Include(s => s.Job)
                    .Where(s => s.JobId == jobId)
                    .OrderByDescending(s => s.TotalScore)
                    .Select(s => new
                    {
                        scoreId = s.ScoreId,
                        resumeId = s.ResumeId,
                        candidateName = s.Resume != null ? s.Resume.CandidateName : null,
                        fileName = s.Resume != null ? s.Resume.FileName : null,
                        email = s.Resume != null ? s.Resume.Email : null,
                        phone = s.Resume != null ? s.Resume.Phone : null,
                        totalScore = Math.Round(s.TotalScore, 2),
                        educationScore = Math.Round(s.EducationScore, 2),
                        experienceScore = Math.Round(s.ExperienceScore, 2),
                        skillsScore = Math.Round(s.SkillsScore, 2),
                        scoredAt = s.ScoredAt
                    })
                    .ToListAsync();

                return Ok(scores);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching scores");
                return StatusCode(500, new { message = "Error fetching scores", error = ex.Message });
            }
        }

        // ===== ParsedData-based scoring methods (NEW) =====

        private decimal CalculateEducationScoreFromParsedData(ParsedData parsedData)
        {
            if (string.IsNullOrEmpty(parsedData.Education))
            {
                return 50m; // Default score if no education data
            }

            try
            {
                var educationArray = JsonSerializer.Deserialize<JsonElement>(parsedData.Education);
                
                if (educationArray.ValueKind != JsonValueKind.Array)
                {
                    return 50m;
                }

                decimal score = 50m; // Base score
                bool hasBachelor = false;
                bool hasMaster = false;
                bool hasPhd = false;

                foreach (var edu in educationArray.EnumerateArray())
                {
                    var degreeText = edu.ToString().ToLower();

                    if (degreeText.Contains("bachelor") || degreeText.Contains("b.tech") || 
                        degreeText.Contains("b.e") || degreeText.Contains("bsc") || degreeText.Contains("b.s"))
                    {
                        if (!hasBachelor)
                        {
                            hasBachelor = true;
                            score += 15m;
                        }
                    }
                    else if (degreeText.Contains("master") || degreeText.Contains("m.tech") || 
                             degreeText.Contains("msc") || degreeText.Contains("mba") || degreeText.Contains("m.s"))
                    {
                        if (!hasMaster)
                        {
                            hasMaster = true;
                            score += 20m;
                        }
                    }
                    else if (degreeText.Contains("phd") || degreeText.Contains("doctorate") || degreeText.Contains("ph.d"))
                    {
                        if (!hasPhd)
                        {
                            hasPhd = true;
                            score += 25m;
                        }
                    }
                }

                return Math.Min(score, 100m);
            }
            catch (Exception ex)
            {
                _logger.LogWarning($"Error parsing education data: {ex.Message}");
                return 50m;
            }
        }

        private decimal CalculateExperienceScoreFromParsedData(ParsedData parsedData)
        {
            if (string.IsNullOrEmpty(parsedData.Experience))
            {
                return 40m; // Default score if no experience data
            }

            try
            {
                var experienceArray = JsonSerializer.Deserialize<JsonElement>(parsedData.Experience);
                
                if (experienceArray.ValueKind != JsonValueKind.Array)
                {
                    return 40m;
                }

                decimal score = 40m; // Base score
                int jobCount = experienceArray.GetArrayLength();
                
                // Score based on number of positions
                score += Math.Min(jobCount * 10m, 30m);

                // Analyze experience content
                foreach (var exp in experienceArray.EnumerateArray())
                {
                    var expText = exp.ToString().ToLower();
                    
                    if (expText.Contains("senior") || expText.Contains("lead") || 
                        expText.Contains("principal") || expText.Contains("architect"))
                    {
                        score += 10m;
                    }
                    else if (expText.Contains("manager") || expText.Contains("director"))
                    {
                        score += 8m;
                    }
                }

                return Math.Min(score, 100m);
            }
            catch (Exception ex)
            {
                _logger.LogWarning($"Error parsing experience data: {ex.Message}");
                return 40m;
            }
        }

        private decimal CalculateSkillsScoreFromParsedData(ParsedData parsedData, Job job)
        {
            if (string.IsNullOrEmpty(parsedData.Skills))
            {
                return 30m; // Default score if no skills data
            }

            try
            {
                var skillsObject = JsonSerializer.Deserialize<JsonElement>(parsedData.Skills);
                var requiredSkillsText = (job.RequiredSkills ?? "").ToLower();

                if (string.IsNullOrEmpty(requiredSkillsText))
                {
                    return 50m; // If no required skills specified, give moderate score
                }

                // Extract all skills from the JSON (organized by category)
                var candidateSkills = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

                if (skillsObject.ValueKind == JsonValueKind.Object)
                {
                    foreach (var category in skillsObject.EnumerateObject())
                    {
                        if (category.Value.ValueKind == JsonValueKind.Array)
                        {
                            foreach (var skill in category.Value.EnumerateArray())
                            {
                                var skillName = skill.GetString();
                                if (!string.IsNullOrEmpty(skillName))
                                {
                                    candidateSkills.Add(skillName.ToLower().Trim());
                                }
                            }
                        }
                    }
                }

                // Parse required skills
                var requiredSkills = requiredSkillsText
                    .Split(new[] { ',', ';', '\n', '|' }, StringSplitOptions.RemoveEmptyEntries)
                    .Select(s => s.Trim().ToLower())
                    .Where(s => !string.IsNullOrEmpty(s))
                    .ToList();

                if (requiredSkills.Count == 0)
                {
                    return 50m;
                }

                // Count matching skills with fuzzy matching
                var matchingSkills = requiredSkills.Count(required => 
                    candidateSkills.Any(candidate => 
                        candidate.Contains(required) || required.Contains(candidate)
                    )
                );

                var matchPercentage = (decimal)matchingSkills / requiredSkills.Count;
                var score = matchPercentage * 100m;

                _logger.LogInformation($"Skills match: {matchingSkills}/{requiredSkills.Count} = {score:F2}%");

                return score;
            }
            catch (Exception ex)
            {
                _logger.LogWarning($"Error parsing skills data: {ex.Message}");
                return 30m;
            }
        }

        // ===== FALLBACK: Original keyword-based scoring methods =====

        private (decimal Education, decimal Experience, decimal Skills) ParseWeightConfig(string? weightConfig)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(weightConfig))
                {
                    return (0.25m, 0.35m, 0.40m); // Default weights
                }

                var weights = JsonSerializer.Deserialize<Dictionary<string, decimal>>(weightConfig)
                            ?? new Dictionary<string, decimal>();

                return (
                    weights.GetValueOrDefault("education", 0.25m),
                    weights.GetValueOrDefault("experience", 0.35m),
                    weights.GetValueOrDefault("skills", 0.40m)
                );
            }
            catch
            {
                return (0.25m, 0.35m, 0.40m); // Default weights on error
            }
        }

        private decimal CalculateEducationScore(Resume resume)
        {
            var text = (resume.RawText ?? "").ToLower();
            decimal score = 50m;

            if (text.Contains("bachelor") || text.Contains("b.tech") || text.Contains("b.e") || text.Contains("bsc"))
                score += 15m;
            if (text.Contains("master") || text.Contains("m.tech") || text.Contains("msc") || text.Contains("mba"))
                score += 20m;
            if (text.Contains("phd") || text.Contains("doctorate"))
                score += 25m;
            if (text.Contains("university") || text.Contains("college") || text.Contains("institute"))
                score += 10m;

            return Math.Min(score, 100m);
        }

        private decimal CalculateExperienceScore(Resume resume)
        {
            var text = (resume.RawText ?? "").ToLower();
            decimal score = 40m;

            if (text.Contains("years") || text.Contains("year"))
                score += 20m;
            if (text.Contains("experience"))
                score += 15m;
            if (text.Contains("worked") || text.Contains("working"))
                score += 10m;
            if (text.Contains("senior") || text.Contains("lead") || text.Contains("manager"))
                score += 15m;
            if (text.Contains("project") || text.Contains("projects"))
                score += 10m;

            return Math.Min(score, 100m);
        }

        private decimal CalculateSkillsScore(Resume resume, Job job)
        {
            var resumeText = (resume.RawText ?? "").ToLower();
            var requiredSkills = (job.RequiredSkills ?? "").ToLower();

            if (string.IsNullOrEmpty(requiredSkills))
            {
                return 50m;
            }

            var skillKeywords = requiredSkills
                .Split(new[] { ',', ';', '\n' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(s => s.Trim().ToLower())
                .Where(s => !string.IsNullOrEmpty(s))
                .ToList();

            if (skillKeywords.Count == 0)
            {
                return 50m;
            }

            var matchingSkills = skillKeywords.Count(skill => resumeText.Contains(skill));
            var matchPercentage = (decimal)matchingSkills / skillKeywords.Count;

            return matchPercentage * 100m;
        }
    }
}
