using System;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ResumeScoring.Api.Data;
using static ResumeScoring.Api.Data.ApplicationDbContext;

namespace ResumeScoring.Api.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class JobsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<JobsController> _logger;

        public JobsController(ApplicationDbContext context, ILogger<JobsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpPost]
        public async Task<IActionResult> CreateJob([FromBody] JobCreateRequest request)
        {
            var jobText = $"{request.Title}\n{request.Description}\n{request.RequiredSkills}";

            // Generate embedding for the job using helper
            var embeddingVector = await GenerateEmbeddingFromText(jobText);

            if (string.IsNullOrEmpty(embeddingVector))
            {
                _logger.LogWarning("Failed to generate job embedding, proceeding without it");
            }

            var job = new Job
            {
                Title = request.Title,
                Description = request.Description,
                RequiredSkills = request.RequiredSkills,
                WeightConfig = request.WeightConfig,
                EmbeddingVector = embeddingVector,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Jobs.Add(job);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetJob), new { id = job.JobId }, job);
        }

        [HttpGet]
        public async Task<IActionResult> GetJobs()
        {
            var jobs = await _context.Jobs
                .OrderByDescending(j => j.CreatedAt)
                .ToListAsync();
            return Ok(jobs);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetJob(int id)
        {
            var job = await _context.Jobs.FindAsync(id);
            if (job == null)
                return NotFound();
            return Ok(job);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateJob(int id, [FromBody] JobCreateRequest request)
        {
            var job = await _context.Jobs.FindAsync(id);
            if (job == null)
                return NotFound();

            job.Title = request.Title;
            job.Description = request.Description;
            job.RequiredSkills = request.RequiredSkills;
            job.WeightConfig = request.WeightConfig;
            job.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return Ok(job);
        }

        // Public endpoint that generates embedding for a specific job by id (keeps existing route)
        [HttpPost("{jobId}/generate-embedding")]
        public async Task<IActionResult> GenerateJobEmbedding(int jobId)
        {
            try
            {
                var job = await _context.Jobs.FindAsync(jobId);
                if (job == null)
                    return NotFound(new { message = "Job not found" });

                var jobText = $"{job.Title}\n{job.Description}\n{job.RequiredSkills}";

                // Reuse the helper to generate the embedding string
                var embeddingVector = await GenerateEmbeddingFromText(jobText);

                if (string.IsNullOrEmpty(embeddingVector))
                {
                    _logger.LogWarning($"Failed to generate embedding for job {jobId}");
                    return StatusCode(500, new { message = "Failed to generate embedding from service" });
                }

                job.EmbeddingVector = embeddingVector;
                job.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                _logger.LogInformation($"Generated embedding for job {jobId}");

                return Ok(new
                {
                    message = "Embedding generated successfully",
                    jobId = job.JobId,
                    hasEmbedding = true,
                    embeddingLength = embeddingVector.Length
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error generating embedding for job {jobId}");
                return StatusCode(500, new { message = "Error generating embedding", error = ex.Message });
            }
        }

        // Bulk generate embeddings for existing jobs that don't have one
        [HttpPost("generate-embeddings")]
        public async Task<IActionResult> GenerateEmbeddingsForExistingJobs()
        {
            try
            {
                var jobs = await _context.Jobs
                    .Where(j => string.IsNullOrEmpty(j.EmbeddingVector))
                    .ToListAsync();

                _logger.LogInformation($"Generating embeddings for {jobs.Count} jobs");

                int successCount = 0;
                foreach (var job in jobs)
                {
                    var jobText = $"{job.Title}\n{job.Description}\n{job.RequiredSkills}";
                    var embedding = await GenerateEmbeddingFromText(jobText);

                    if (!string.IsNullOrEmpty(embedding))
                    {
                        job.EmbeddingVector = embedding;
                        job.UpdatedAt = DateTime.UtcNow;
                        successCount++;
                    }
                }

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    totalJobs = jobs.Count,
                    successCount,
                    message = $"Generated embeddings for {successCount} jobs"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating job embeddings");
                return StatusCode(500, new { message = "Error generating embeddings", error = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteJob(int id)
        {
            var job = await _context.Jobs.FindAsync(id);
            if (job == null)
                return NotFound();

            _context.Jobs.Remove(job);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Job deleted successfully" });
        }

        // -----------------------------
        // Helper: calls embeddings service
        // -----------------------------
        private async Task<string?> GenerateEmbeddingFromText(string text)
        {
            try
            {
                var embeddingsServiceUrl = Environment.GetEnvironmentVariable("EMBEDDINGS_SERVICE_URL") ?? "http://localhost:5003";

                using var httpClient = new HttpClient();
                httpClient.Timeout = TimeSpan.FromSeconds(30);

                var requestData = new { text = text };
                var json = JsonSerializer.Serialize(requestData);
                using var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await httpClient.PostAsync($"{embeddingsServiceUrl}/embed", content);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Embedding service returned non-success status: {StatusCode}", response.StatusCode);
                    return null;
                }

                var responseText = await response.Content.ReadAsStringAsync();

                using var doc = JsonDocument.Parse(responseText);

                if (doc.RootElement.TryGetProperty("embedding", out var embeddingElement))
                {
                    // If embedding is a JSON array/object, return raw JSON text (e.g. "[0.1, 0.2, ...]")
                    if (embeddingElement.ValueKind == JsonValueKind.Array || embeddingElement.ValueKind == JsonValueKind.Object)
                        return embeddingElement.GetRawText();

                    // Otherwise return its string representation
                    return embeddingElement.ToString();
                }

                _logger.LogWarning("Embedding property not found in embeddings service response");
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calling embedding service");
                return null;
            }
        }
    }

    public record JobCreateRequest(
        string Title,
        string Description,
        string? RequiredSkills,
        string? WeightConfig
    );
}