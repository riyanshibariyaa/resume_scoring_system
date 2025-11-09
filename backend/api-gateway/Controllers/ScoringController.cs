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

        [HttpPost("score-resume/{resumeId}/job/{jobId}")]
        public async Task<IActionResult> ScoreResume(int resumeId, int jobId)
        {
            try
            {
                _logger.LogInformation($"Scoring resume {resumeId} against job {jobId}");

                // Get resume
                var resume = await _context.Resumes.FindAsync(resumeId);
                if (resume == null)
                {
                    return NotFound(new { message = "Resume not found" });
                }

                // Get job
                var job = await _context.Jobs.FindAsync(jobId);
                if (job == null)
                {
                    return NotFound(new { message = "Job not found" });
                }

                // Parse weight config
                var weights = ParseWeightConfig(job.WeightConfig);

                // Calculate scores
                var educationScore = CalculateEducationScore(resume);
                var experienceScore = CalculateExperienceScore(resume);
                var skillsScore = CalculateSkillsScore(resume, job);

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
                var results = new List<object>();

                foreach (var resume in resumes)
                {
                    var weights = ParseWeightConfig(job.WeightConfig);
                    var educationScore = CalculateEducationScore(resume);
                    var experienceScore = CalculateExperienceScore(resume);
                    var skillsScore = CalculateSkillsScore(resume, job);
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
                        candidateName = s.Resume.CandidateName,
                        fileName = s.Resume.FileName,
                        email = s.Resume.Email,
                        phone = s.Resume.Phone,
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

        private (decimal Education, decimal Experience, decimal Skills) ParseWeightConfig(string weightConfig)
        {
            try
            {
                if (string.IsNullOrEmpty(weightConfig))
                {
                    return (0.25m, 0.35m, 0.40m); // Default weights
                }

                var weights = JsonSerializer.Deserialize<Dictionary<string, decimal>>(weightConfig);
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
            // Simple scoring based on education keywords
            var text = (resume.RawText ?? "").ToLower();
            decimal score = 50; // Base score

            // Degree keywords
            if (text.Contains("bachelor") || text.Contains("b.tech") || text.Contains("b.e") || text.Contains("bsc"))
                score += 15;
            if (text.Contains("master") || text.Contains("m.tech") || text.Contains("msc") || text.Contains("mba"))
                score += 20;
            if (text.Contains("phd") || text.Contains("doctorate"))
                score += 25;

            // Institution quality indicators
            if (text.Contains("university") || text.Contains("college") || text.Contains("institute"))
                score += 10;

            return Math.Min(score, 100);
        }

        private decimal CalculateExperienceScore(Resume resume)
        {
            // Simple scoring based on experience keywords
            var text = (resume.RawText ?? "").ToLower();
            decimal score = 40; // Base score

            // Experience indicators
            if (text.Contains("years") || text.Contains("year"))
                score += 20;
            if (text.Contains("experience"))
                score += 15;
            if (text.Contains("worked") || text.Contains("working"))
                score += 10;
            if (text.Contains("senior") || text.Contains("lead") || text.Contains("manager"))
                score += 15;
            if (text.Contains("project") || text.Contains("projects"))
                score += 10;

            return Math.Min(score, 100);
        }

        private decimal CalculateSkillsScore(Resume resume, Job job)
        {
            // Compare resume skills with job requirements
            var resumeText = (resume.RawText ?? "").ToLower();
            var requiredSkills = (job.RequiredSkills ?? "").ToLower();

            if (string.IsNullOrEmpty(requiredSkills))
            {
                return 50; // Default if no skills specified
            }

            // Split required skills
            var skillKeywords = requiredSkills
                .Split(new[] { ',', ';', '\n' }, StringSplitOptions.RemoveEmptyEntries)
                .Select(s => s.Trim().ToLower())
                .Where(s => !string.IsNullOrEmpty(s))
                .ToList();

            if (skillKeywords.Count == 0)
            {
                return 50;
            }

            // Count matching skills
            var matchingSkills = skillKeywords.Count(skill => resumeText.Contains(skill));
            var matchPercentage = (decimal)matchingSkills / skillKeywords.Count;

            return matchPercentage * 100;
        }
    }
}
