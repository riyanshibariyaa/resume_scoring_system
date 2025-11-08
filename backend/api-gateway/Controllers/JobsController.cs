using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ResumeScoring.Api.Controllers;

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
        var job = new Job
        {
            Title = request.Title,
            Description = request.Description,
            WeightConfigJSON = request.WeightConfigJSON,
            CreatedAt = DateTime.UtcNow
        };

        _context.Jobs.Add(job);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetJob), new { id = job.JobId }, job);
    }

    [HttpGet]
    public async Task<IActionResult> GetJobs()
    {
        var jobs = await _context.Jobs.ToListAsync();
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
}

public record JobCreateRequest(string Title, string Description, string? WeightConfigJSON);
