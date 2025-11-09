using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;
using System.Security.Cryptography;
using ResumeScoring.Api.Data;
using static ResumeScoring.Api.Data.ApplicationDbContext;

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
    /// Upload resume - Complete workflow with NLP extraction and ParsedData saving
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> UploadResume(IFormFile file)
    {
        try
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { error = "No file uploaded" });

            _logger.LogInformation($"Processing resume upload: {file.FileName}");

            // Step 1: Read file content for RawText
            string rawText = "";
            using (var reader = new StreamReader(file.OpenReadStream()))
            {
                rawText = await reader.ReadToEndAsync();
            }

            // Step 2: Call Parsing Service
            var parsingClient = _clientFactory.CreateClient("ParsingService");
            var content = new MultipartFormDataContent();
            
            // Reset the stream position before creating new StreamContent
            file.OpenReadStream().Position = 0;
            var fileContent = new StreamContent(file.OpenReadStream());
            fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(file.ContentType);
            content.Add(fileContent, "file", file.FileName);

            var parseResponse = await parsingClient.PostAsync("/parse", content);
            
            string candidateName = "Candidate";
            string? candidateEmail = null;
            string? candidatePhone = null;
            
            // Variables to hold ParsedData fields
            string? parsedText = rawText;
            string? sectionsJson = null;
            string? metadataJson = null;
            string? extractedProfileJson = null;
            string? fileHash = null;
            string? rawFilePath = null;
            string? parsedFilePath = null;
            string? skillsJson = null;
            string? educationJson = null;
            string? experienceJson = null;
            string? certificationsJson = null;
            string? summaryJson = null;

            if (parseResponse.IsSuccessStatusCode)
            {
                var parseResultJson = await parseResponse.Content.ReadAsStringAsync();
                _logger.LogInformation("Parsing service successful");

                // Parse into JsonDocument for safe traversal
                using var doc = JsonDocument.Parse(parseResultJson);
                var root = doc.RootElement;

                // Extract file hash
                if (root.TryGetProperty("file_hash", out var fh))
                {
                    fileHash = fh.GetString();
                }

                // Extract storage paths
                if (root.TryGetProperty("storage", out var sto))
                {
                    if (sto.TryGetProperty("raw_file_path", out var rfp))
                        rawFilePath = rfp.GetString();
                    if (sto.TryGetProperty("parsed_file_path", out var pfp))
                        parsedFilePath = pfp.GetString();
                }

                // Extract parsed_data object
                if (root.TryGetProperty("parsed_data", out var parsedDataElement))
                {
                    // Extract text
                    if (parsedDataElement.TryGetProperty("text", out var t))
                    {
                        parsedText = t.GetString() ?? rawText;
                    }

                    // Extract sections
                    if (parsedDataElement.TryGetProperty("sections", out var s))
                    {
                        sectionsJson = s.GetRawText();
                    }

                    // Extract metadata
                    if (parsedDataElement.TryGetProperty("metadata", out var m))
                    {
                        metadataJson = m.GetRawText();
                    }

                    // Step 3: Call NLP service to get structured profile
                    try
                    {
                        // ✅ FIX: Create HTTP client with explicit BaseAddress
                        var nlpClient = _clientFactory.CreateClient();
                        nlpClient.BaseAddress = new Uri("http://localhost:5002");
                        nlpClient.Timeout = TimeSpan.FromMinutes(2);
                        
                        var nlpPayload = new
                        {
                            parsed_data = new
                            {
                                text = parsedText  // Use parsedText, not rawText
                            }
                        };

                        var nlpContent = new StringContent(
                            JsonSerializer.Serialize(nlpPayload),
                            System.Text.Encoding.UTF8,
                            "application/json"
                        );

                        _logger.LogInformation("Calling NLP service...");
                        var nlpResp = await nlpClient.PostAsync("/extract", nlpContent);
                        
                        if (nlpResp.IsSuccessStatusCode)
                        {
                            var nlpJson = await nlpResp.Content.ReadAsStringAsync();
                            _logger.LogInformation("NLP service successful");
                            
                            using var nlpDoc = JsonDocument.Parse(nlpJson);
                            var nlpRoot = nlpDoc.RootElement;

                            if (nlpRoot.TryGetProperty("extracted_data", out var extractedData))
                            {
                                // Store the entire extracted profile
                                extractedProfileJson = extractedData.GetRawText();

                                // Extract contact info
                                if (extractedData.TryGetProperty("contact_info", out var contactInfo))
                                {
                                    if (contactInfo.TryGetProperty("name", out var nameEl))
                                        candidateName = nameEl.GetString() ?? candidateName;
                                    if (contactInfo.TryGetProperty("email", out var emailEl))
                                        candidateEmail = emailEl.GetString();
                                    if (contactInfo.TryGetProperty("phone", out var phoneEl))
                                        candidatePhone = phoneEl.GetString();
                                }
                                // Also try "contact" (alternative field name)
                                else if (extractedData.TryGetProperty("contact", out var contact))
                                {
                                    if (contact.TryGetProperty("name", out var nameEl))
                                        candidateName = nameEl.GetString() ?? candidateName;
                                    if (contact.TryGetProperty("email", out var emailEl))
                                        candidateEmail = emailEl.GetString();
                                    if (contact.TryGetProperty("phone", out var phoneEl))
                                        candidatePhone = phoneEl.GetString();
                                }

                                // Extract skills
                                if (extractedData.TryGetProperty("skills", out var skills))
                                {
                                    skillsJson = skills.GetRawText();
                                    _logger.LogInformation($"Extracted skills JSON: {skillsJson.Substring(0, Math.Min(100, skillsJson.Length))}...");
                                }

                                // Extract education
                                if (extractedData.TryGetProperty("education", out var education))
                                {
                                    educationJson = education.GetRawText();
                                    _logger.LogInformation($"Extracted education JSON");
                                }

                                // Extract experience
                                if (extractedData.TryGetProperty("experience", out var experience))
                                {
                                    experienceJson = experience.GetRawText();
                                    _logger.LogInformation($"Extracted experience JSON");
                                }

                                // Extract certifications
                                if (extractedData.TryGetProperty("certifications", out var certifications))
                                {
                                    certificationsJson = certifications.GetRawText();
                                }

                                // Extract summary
                                if (extractedData.TryGetProperty("summary", out var summary))
                                {
                                    summaryJson = summary.GetRawText();
                                }

                                _logger.LogInformation($"Extracted: Name={candidateName}, Email={candidateEmail}, Phone={candidatePhone}");
                            }
                        }
                        else
                        {
                            var errorContent = await nlpResp.Content.ReadAsStringAsync();
                            _logger.LogWarning($"NLP service failed with status {nlpResp.StatusCode}: {errorContent}");
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "NLP service call failed – continuing without structured extracted_data");
                    }
                }
            }
            else
            {
                var errorContent = await parseResponse.Content.ReadAsStringAsync();
                _logger.LogWarning($"Parsing service failed: {errorContent}");
            }

            // Step 4: Store in Resumes table
            var resume = new Resume
            {
                CandidateName = candidateName,
                Email = candidateEmail,
                Phone = candidatePhone,
                RawText = parsedText,
                FileHash = fileHash ?? ComputeFileHash(file),
                FileName = file.FileName,
                FileType = Path.GetExtension(file.FileName).TrimStart('.').ToUpper(),
                UploadedAt = DateTime.UtcNow,
                ProcessedAt = DateTime.UtcNow
            };

            _context.Resumes.Add(resume);
            await _context.SaveChangesAsync();

            _logger.LogInformation($"Resume created successfully: ID={resume.ResumeId}");

            // Step 5: Save ParsedData record
            var parsedDataEntity = new ParsedData
            {
                ResumeId = resume.ResumeId,
                Text = parsedText,
                SectionsJson = sectionsJson,
                MetadataJson = metadataJson,
                ExtractedProfileJson = extractedProfileJson,
                Skills = skillsJson,
                Education = educationJson,
                Experience = experienceJson,
                Certifications = certificationsJson,
                Summary = summaryJson,
                FileHash = fileHash,
                RawFilePath = rawFilePath,
                ParsedFilePath = parsedFilePath,
                ParsedAt = DateTime.UtcNow
            };

            _context.ParsedDatas.Add(parsedDataEntity);
            await _context.SaveChangesAsync();

            _logger.LogInformation($"ParsedData created successfully: ID={parsedDataEntity.ParsedDataId}");
            _logger.LogInformation($"ParsedData has Skills: {!string.IsNullOrEmpty(skillsJson)}");
            _logger.LogInformation($"ParsedData has Experience: {!string.IsNullOrEmpty(experienceJson)}");
            _logger.LogInformation($"ParsedData has Education: {!string.IsNullOrEmpty(educationJson)}");

            return Ok(new
            {
                resumeId = resume.ResumeId,
                candidateName = resume.CandidateName,
                email = resume.Email,
                phone = resume.Phone,
                fileName = resume.FileName,
                fileType = resume.FileType,
                uploadedAt = resume.UploadedAt,
                parsedDataId = parsedDataEntity.ParsedDataId,
                hasSkills = !string.IsNullOrEmpty(skillsJson),
                hasExperience = !string.IsNullOrEmpty(experienceJson),
                hasEducation = !string.IsNullOrEmpty(educationJson),
                status = "success",
                message = "Resume uploaded and processed successfully"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading resume");
            return StatusCode(500, new { error = "Failed to process resume", details = ex.Message, stackTrace = ex.StackTrace });
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

    [HttpPost("generate-embeddings")]
    public async Task<IActionResult> GenerateResumeEmbeddings()
    {
        try
        {
            var resumes = await _context.Resumes
                .Where(r => !string.IsNullOrEmpty(r.RawText))
                .ToListAsync();

            _logger.LogInformation($"Generating embeddings for {resumes.Count} resumes");

            var embeddingsServiceUrl = Environment.GetEnvironmentVariable("EMBEDDINGS_SERVICE_URL") ?? "http://localhost:5003";
            using var httpClient = new HttpClient();
            httpClient.Timeout = TimeSpan.FromMinutes(5);

            int successCount = 0;
            foreach (var resume in resumes)
            {
                try
                {
                    // Call embeddings service
                    var requestData = new { text = resume.RawText };
                    var json = JsonSerializer.Serialize(requestData);
                    var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

                    var response = await httpClient.PostAsync($"{embeddingsServiceUrl}/embed", content);

                    if (response.IsSuccessStatusCode)
                    {
                        var responseText = await response.Content.ReadAsStringAsync();
                        using var doc = JsonDocument.Parse(responseText);

                        if (doc.RootElement.TryGetProperty("embedding", out var embeddingElement))
                        {
                            var embeddingVector = embeddingElement.GetRawText();

                            // Check if embedding already exists
                            var existingEmbedding = await _context.Embeddings
                                .FirstOrDefaultAsync(e => e.EntityType == "Resume" && e.EntityId == resume.ResumeId);

                            if (existingEmbedding != null)
                            {
                                existingEmbedding.VectorData = embeddingVector;
                                existingEmbedding.CreatedAt = DateTime.UtcNow;
                            }
                            else
                            {
                                var embedding = new Embedding
                                {
                                    EntityId = resume.ResumeId,
                                    EntityType = "Resume",
                                    VectorData = embeddingVector,
                                    CreatedAt = DateTime.UtcNow
                                };
                                _context.Embeddings.Add(embedding);
                            }

                            successCount++;
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Failed to generate embedding for resume {resume.ResumeId}");
                }
            }

            await _context.SaveChangesAsync();

            return Ok(new
            {
                totalResumes = resumes.Count,
                successCount,
                message = $"Generated embeddings for {successCount} resumes"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating resume embeddings");
            return StatusCode(500, new { message = "Error generating embeddings", error = ex.Message });
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
                    parsedData = _context.ParsedDatas
                        .Where(pd => pd.ResumeId == r.ResumeId)
                        .Select(pd => new
                        {
                            pd.ParsedDataId,
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
        using var sha = SHA256.Create();
        using var stream = file.OpenReadStream();
        var hash = sha.ComputeHash(stream);
        return BitConverter.ToString(hash).Replace("-", "").ToLowerInvariant();
    }
}