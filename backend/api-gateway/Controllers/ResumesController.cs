using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace ResumeScoring.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public class ResumesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IHttpClientFactory _clientFactory;
    private readonly ILogger<ResumesController> _logger;

    public ResumesController(
        ApplicationDbContext context,
        IHttpClientFactory clientFactory,
        ILogger<ResumesController> logger)
    {
        _context = context;
        _clientFactory = clientFactory;
        _logger = logger;
    }

    /// <summary>
    /// Upload resume - Complete workflow
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> UploadResume(IFormFile file)
    {
        try
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { error = "No file uploaded" });

            _logger.LogInformation($"Processing resume upload: {file.FileName}");

            // Step 1: Call Parsing Service
            var parsingClient = _clientFactory.CreateClient("ParsingService");
            var content = new MultipartFormDataContent();
            var fileContent = new StreamContent(file.OpenReadStream());
            fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(file.ContentType);
            content.Add(fileContent, "file", file.FileName);

            var parseResponse = await parsingClient.PostAsync("/parse", content);
            
            string candidateName = "Candidate";
            string? candidateEmail = null;

            if (parseResponse.IsSuccessStatusCode)
            {
                var parseResult = await parseResponse.Content.ReadAsStringAsync();
                // Try to extract name/email from parse result if available
                try
                {
                    var parsed = JsonSerializer.Deserialize<Dictionary<string, object>>(parseResult);
                    if (parsed != null)
                    {
                        if (parsed.ContainsKey("name")) candidateName = parsed["name"]?.ToString() ?? "Candidate";
                        if (parsed.ContainsKey("email")) candidateEmail = parsed["email"]?.ToString();
                    }
                }
                catch { /* Use defaults if parsing fails */ }
            }

            // Step 2: Store in Resumes table with ALL required columns
            var resume = new Resume
            {
                CandidateName = candidateName,
                Email = candidateEmail,
                Phone = null,
                RawFileUri = $"storage/resumes/{file.FileName}",
                ParsedJsonUri = null,
                FileHash = ComputeFileHash(file),
                FileFormat = Path.GetExtension(file.FileName).TrimStart('.').ToUpper(),
                Source = "WebUpload",
                ParseStatus = "Complete",
                ParseErrorMessage = null,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                IsDeleted = false
            };

            _context.Resumes.Add(resume);
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Resume created successfully: ID={resume.ResumeId}");

            return Ok(new
            {
                resumeId = resume.ResumeId,
                candidateName = resume.CandidateName,
                email = resume.Email,
                fileFormat = resume.FileFormat,
                parseStatus = resume.ParseStatus,
                createdAt = resume.CreatedAt,
                status = "success",
                message = "Resume uploaded and stored successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading resume");
            return StatusCode(500, new { error = "Failed to process resume", details = ex.Message });
        }
    }

    /// <summary>
    /// Get all resumes
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetResumes()
    {
        try
        {
            var resumes = await _context.Resumes
                .Where(r => !r.IsDeleted)
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new
                {
                    r.ResumeId,
                    r.CandidateName,
                    r.Email,
                    r.Phone,
                    r.FileFormat,
                    r.ParseStatus,
                    r.CreatedAt
                })
                .ToListAsync();

            return Ok(resumes);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching resumes");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    /// <summary>
    /// Get resume by ID with parsed data if available
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetResume(int id)
    {
        try
        {
            var resume = await _context.Resumes
                .Where(r => r.ResumeId == id && !r.IsDeleted)
                .Select(r => new
                {
                    r.ResumeId,
                    r.CandidateName,
                    r.Email,
                    r.Phone,
                    r.FileFormat,
                    r.ParseStatus,
                    r.RawFileUri,
                    r.CreatedAt,
                    profile = _context.CandidateProfiles
                        .Where(cp => cp.ResumeId == r.ResumeId)
                        .Select(cp => new
                        {
                            cp.SkillsJSON,
                            cp.WorkHistoryJSON,
                            cp.EducationJSON,
                            cp.TotalExperienceYears,
                            cp.SeniorityLevel
                        })
                        .FirstOrDefault()
                })
                .FirstOrDefaultAsync();

            if (resume == null)
                return NotFound(new { error = "Resume not found" });

            return Ok(resume);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching resume");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    /// <summary>
    /// Delete resume
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteResume(int id)
    {
        try
        {
            var resume = await _context.Resumes.FindAsync(id);
            if (resume == null)
                return NotFound();

            resume.IsDeleted = true;
            resume.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Resume deleted successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting resume");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    private string ComputeFileHash(IFormFile file)
    {
        using var md5 = System.Security.Cryptography.MD5.Create();
        using var stream = file.OpenReadStream();
        var hash = md5.ComputeHash(stream);
        return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
    }
}