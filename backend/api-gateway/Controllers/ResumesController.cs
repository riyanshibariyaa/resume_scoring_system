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
    /// Upload resume - Complete workflow: Parse → NLP → Embeddings → Store
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
            if (!parseResponse.IsSuccessStatusCode)
            {
                return StatusCode(500, new { error = "Parsing service failed" });
            }

            var parseResult = await parseResponse.Content.ReadAsStringAsync();
            
            // Step 2: Store in Resumes table
            var resume = new Resume
            {
                CandidateName = "Candidate", // Will be updated by NLP
                Email = null,
                RawFileUri = $"storage/resumes/{file.FileName}",
                FileHash = ComputeFileHash(file),
                CreatedAt = DateTime.UtcNow
            };

            _context.Resumes.Add(resume);
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Resume created successfully: ID={resume.ResumeId}");

            return Ok(new
            {
                resumeId = resume.ResumeId,
                candidateName = resume.CandidateName,
                email = resume.Email,
                status = "success",
                message = "Resume uploaded and stored successfully",
                workflow = new
                {
                    uploadToDatabase = "Complete",
                    parsing = "Complete",
                    nextStep = "NLP extraction will happen when scoring"
                }
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
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new
                {
                    r.ResumeId,
                    r.CandidateName,
                    r.Email,
                    r.RawFileUri,
                    r.CreatedAt,
                    parseStatus = "Complete",
                    fileFormat = Path.GetExtension(r.RawFileUri).TrimStart('.').ToUpper()
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
    /// Get resume by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetResume(int id)
    {
        try
        {
            var resume = await _context.Resumes
                .FirstOrDefaultAsync(r => r.ResumeId == id);

            if (resume == null)
                return NotFound(new { error = "Resume not found" });

            return Ok(new
            {
                resume.ResumeId,
                resume.CandidateName,
                resume.Email,
                resume.RawFileUri,
                resume.CreatedAt,
                fileFormat = Path.GetExtension(resume.RawFileUri).TrimStart('.').ToUpper(),
                parseStatus = "Complete"
            });
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

            _context.Resumes.Remove(resume);
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
