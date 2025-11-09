using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using System.Security.Cryptography;
using ResumeScoring.Api.Data;

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

            // Step 1: Read file content
            string rawText = "";
            using (var reader = new StreamReader(file.OpenReadStream()))
            {
                rawText = await reader.ReadToEndAsync();
            }

            // Step 2: Call Parsing Service
            var parsingClient = _clientFactory.CreateClient("ParsingService");
            var content = new MultipartFormDataContent();
            var fileContent = new StreamContent(file.OpenReadStream());
            fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(file.ContentType);
            content.Add(fileContent, "file", file.FileName);

            var parseResponse = await parsingClient.PostAsync("/parse", content);
            
            string candidateName = "Candidate";
            string? candidateEmail = null;
            string? candidatePhone = null;
            
            if (parseResponse.IsSuccessStatusCode)
            {
                var parseResultJson = await parseResponse.Content.ReadAsStringAsync();

                // parse into JsonDocument for safe traversal
                using var doc = JsonDocument.Parse(parseResultJson);
                var root = doc.RootElement;

                // parsed_data object (parser returns parsed_data as a nested object)
                if (root.TryGetProperty("parsed_data", out var parsedDataElement))
                {
                    // Try to extract contact info from parsed_data (parser or NLP may place it under contact_info)
                    if (parsedDataElement.TryGetProperty("metadata", out var metadataEl))
                    {
                        // metadata may contain some fields, but contact likely comes from NLP service.
                    }

                    // Optionally call NLP service to get structured profile (preferred)
                    try
                    {
                        var nlpClient = _clientFactory.CreateClient();
                        nlpClient.BaseAddress = new Uri("http://localhost:5002"); // NLP service
                        var nlpPayload = new StringContent(JsonSerializer.Serialize(new { parsed_data = JsonSerializer.Deserialize<object>(parsedDataElement.GetRawText()) }), System.Text.Encoding.UTF8, "application/json");
                        var nlpResp = await nlpClient.PostAsync("/extract", nlpPayload);
                        if (nlpResp.IsSuccessStatusCode)
                        {
                            var nlpJson = await nlpResp.Content.ReadAsStringAsync();
                            using var nlpDoc = JsonDocument.Parse(nlpJson);
                            var nlpRoot = nlpDoc.RootElement;

                            if (nlpRoot.TryGetProperty("extracted_data", out var extractedData))
                            {
                                // Try to set contact fields from extracted_data.contact_info
                                if (extractedData.TryGetProperty("contact_info", out var contactInfo))
                                {
                                    if (contactInfo.TryGetProperty("name", out var nameEl))
                                        candidateName = nameEl.GetString() ?? candidateName;
                                    if (contactInfo.TryGetProperty("email", out var emailEl))
                                        candidateEmail = emailEl.GetString();
                                    if (contactInfo.TryGetProperty("phone", out var phoneEl))
                                        candidatePhone = phoneEl.GetString();
                                }

                                // Save ParsedData record
                                var parsedEntity = new ParsedData
                                {
                                    ResumeId = null, // we'll attach after saving Resume
                                    Text = parsedDataElement.TryGetProperty("text", out var t) ? t.GetString() : null,
                                    SectionsJson = parsedDataElement.TryGetProperty("sections", out var s) ? s.GetRawText() : null,
                                    MetadataJson = parsedDataElement.TryGetProperty("metadata", out var m) ? m.GetRawText() : null,
                                    ExtractedProfileJson = extractedData.GetRawText(),
                                    FileHash = root.TryGetProperty("file_hash", out var fh) ? fh.GetString() : null,
                                    RawFilePath = root.TryGetProperty("storage", out var sto) && sto.TryGetProperty("raw_file_path", out var rfp) ? rfp.GetString() : null,
                                    ParsedFilePath = root.TryGetProperty("storage", out var sto2) && sto2.TryGetProperty("parsed_file_path", out var pfp) ? pfp.GetString() : null,
                                    ParsedAt = DateTime.UtcNow
                                };

                                // We'll set parsedEntity.ResumeId after saving Resume below
                                // store it temporarily in a local variable to save after resume creation
                                // (see below: after _context.Resumes.Add(resume) and SaveChanges, set parsedEntity.ResumeId = resume.ResumeId)
                                // Save to DB after resume created
                                // (we need to set after resume added, so we'll keep parsedEntity in a variable)
                                // NOTE: we will save after resume is created (see later)
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "NLP service call failed — continuing without structured extracted_data");
                    }
                }
            }


            // if (parseResponse.IsSuccessStatusCode)
            // {
            //     var parseResult = await parseResponse.Content.ReadAsStringAsync();
            //     // Try to extract name/email from parse result if available
            //     try
            //     {
            //         var parsed = JsonSerializer.Deserialize<Dictionary<string, object>>(parseResult);
            //         if (parsed != null)
            //         {
            //             if (parsed.ContainsKey("name")) 
            //                 candidateName = parsed["name"]?.ToString() ?? "Candidate";
            //             if (parsed.ContainsKey("email")) 
            //                 candidateEmail = parsed["email"]?.ToString();
            //             if (parsed.ContainsKey("phone"))
            //                 candidatePhone = parsed["phone"]?.ToString();
            //         }
            //     }
            //     catch { /* Use defaults if parsing fails */ }
            // }

            // Step 3: Store in Resumes table with ACTUAL database columns
            var resume = new Resume
            {
                CandidateName = candidateName,
                Email = candidateEmail,
                Phone = candidatePhone,
                RawText = rawText,
                FileHash = ComputeFileHash(file),
                FileName = file.FileName,
                FileType = Path.GetExtension(file.FileName).TrimStart('.').ToUpper(),
                UploadedAt = DateTime.UtcNow,
                ProcessedAt = DateTime.UtcNow
            };

            _context.Resumes.Add(resume);
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Resume created successfully: ID={resume.ResumeId}");

            return Ok(new
            {
                resumeId = resume.ResumeId,
                candidateName = resume.CandidateName,
                email = resume.Email,
                phone = resume.Phone,
                fileName = resume.FileName,
                fileType = resume.FileType,
                uploadedAt = resume.UploadedAt,
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
                .OrderByDescending(r => r.UploadedAt)
                .Select(r => new
                {
                    r.ResumeId,
                    r.CandidateName,
                    r.Email,
                    r.Phone,
                    r.FileName,
                    r.FileType,
                    r.UploadedAt,
                    r.ProcessedAt
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
                .Where(r => r.ResumeId == id)
                .Select(r => new
                {
                    r.ResumeId,
                    r.CandidateName,
                    r.Email,
                    r.Phone,
                    r.FileName,
                    r.FileType,
                    r.RawText,
                    r.UploadedAt,
                    r.ProcessedAt,
                    parsedData = _context.ParsedData
                        .Where(pd => pd.ResumeId == r.ResumeId)
                        .Select(pd => new
                        {
                            pd.Skills,
                            pd.Experience,
                            pd.Education,
                            pd.Certifications,
                            pd.Summary,
                            pd.ParsedAt
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
    using var sha = System.Security.Cryptography.SHA256.Create();
    using var stream = file.OpenReadStream();
    var hash = sha.ComputeHash(stream);
    return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
}
// private string ComputeFileHash(IFormFile file)
    // {
    //     using var md5 = MD5.Create();
    //     using var stream = file.OpenReadStream();
    //     var hash = md5.ComputeHash(stream);
    //     return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
    // }
}
