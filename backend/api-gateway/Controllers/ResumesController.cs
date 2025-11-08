using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ResumeScoring.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public class ResumesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IHttpClientFactory _clientFactory;
    private readonly ILogger<ResumesController> _logger;

    public ResumesController(ApplicationDbContext context, IHttpClientFactory clientFactory, ILogger<ResumesController> logger)
    {
        _context = context;
        _clientFactory = clientFactory;
        _logger = logger;
    }

    [HttpPost]
    public async Task<IActionResult> UploadResume(IFormFile file)
    {
        try
        {
            if (file == null || file.Length == 0)
                return BadRequest("No file uploaded");

            // Call parsing service
            var parsingClient = _clientFactory.CreateClient("ParsingService");
            var content = new MultipartFormDataContent();
            var fileContent = new StreamContent(file.OpenReadStream());
            fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(file.ContentType);
            content.Add(fileContent, "file", file.FileName);

            var response = await parsingClient.PostAsync("/parse", content);
            var result = await response.Content.ReadAsStringAsync();

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading resume");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [HttpGet]
    public async Task<IActionResult> GetResumes()
    {
        var resumes = await _context.Resumes.ToListAsync();
        return Ok(resumes);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetResume(int id)
    {
        var resume = await _context.Resumes.FindAsync(id);
        if (resume == null)
            return NotFound();
        return Ok(resume);
    }
}
