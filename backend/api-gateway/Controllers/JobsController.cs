using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ResumeScoring.Api.Data;

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
            RequiredSkills = request.RequiredSkills,
            WeightConfig = request.WeightConfig,
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
}

public record JobCreateRequest(
    string Title, 
    string Description, 
    string? RequiredSkills, 
    string? WeightConfig
);
