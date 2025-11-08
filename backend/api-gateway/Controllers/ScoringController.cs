using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace ResumeScoring.Api.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public class ScoringController : ControllerBase
{
    private readonly IHttpClientFactory _clientFactory;
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ScoringController> _logger;

    public ScoringController(IHttpClientFactory clientFactory, ApplicationDbContext context, ILogger<ScoringController> logger)
    {
        _clientFactory = clientFactory;
        _context = context;
        _logger = logger;
    }

    [HttpPost]
    public async Task<IActionResult> ScoreCandidate([FromBody] ScoreRequest request)
    {
        try
        {
            var scoringClient = _clientFactory.CreateClient("ScoringService");
            var response = await scoringClient.PostAsJsonAsync("/score", request);
            var result = await response.Content.ReadAsStringAsync();
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error scoring candidate");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    [HttpGet("candidates/{resumeId}")]
    public async Task<IActionResult> GetCandidateScores(int resumeId)
    {
        var scores = await _context.Scores
            .Where(s => s.ResumeId == resumeId)
            .OrderByDescending(s => s.ComputedAt)
            .ToListAsync();
        return Ok(scores);
    }
}

public record ScoreRequest(object Candidate, object Job, Dictionary<string, double>? Weights);
