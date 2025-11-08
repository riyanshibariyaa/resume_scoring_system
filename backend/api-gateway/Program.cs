using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { 
        Title = "Resume Scoring API", 
        Version = "v1",
        Description = "AI-Powered Resume Parsing and Candidate Scoring System"
    });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
});

// Database
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// HTTP Clients for microservices
builder.Services.AddHttpClient("ParsingService", client =>
{
    client.BaseAddress = new Uri(builder.Configuration["Services:ParsingUrl"] ?? "http://localhost:5001");
});

builder.Services.AddHttpClient("NLPService", client =>
{
    client.BaseAddress = new Uri(builder.Configuration["Services:NLPUrl"] ?? "http://localhost:5002");
});

builder.Services.AddHttpClient("EmbeddingService", client =>
{
    client.BaseAddress = new Uri(builder.Configuration["Services:EmbeddingUrl"] ?? "http://localhost:5003");
});

builder.Services.AddHttpClient("ScoringService", client =>
{
    client.BaseAddress = new Uri(builder.Configuration["Services:ScoringUrl"] ?? "http://localhost:5004");
});

var app = builder.Build();

// Configure HTTP pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

// DbContext
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }
    
    public DbSet<Resume> Resumes { get; set; }
    public DbSet<Job> Jobs { get; set; }
    public DbSet<Score> Scores { get; set; }
    public DbSet<CandidateProfile> CandidateProfiles { get; set; }
    public DbSet<Embedding> Embeddings { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Configure decimal precision for Score
        modelBuilder.Entity<Score>()
            .Property(s => s.OverallScore)
            .HasPrecision(5, 4);

        // Configure decimal precision for CandidateProfile
        modelBuilder.Entity<CandidateProfile>()
            .Property(c => c.TotalExperienceYears)
            .HasPrecision(5, 2);
    }
}

// Models matching actual database schema from migration file
public class Resume
{
    public int ResumeId { get; set; }
    public string? CandidateName { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string RawFileUri { get; set; } = string.Empty;
    public string? ParsedJsonUri { get; set; }
    public string FileHash { get; set; } = string.Empty;
    public string? FileFormat { get; set; }
    public string Source { get; set; } = "WebUpload";
    public string ParseStatus { get; set; } = "Pending";
    public string? ParseErrorMessage { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;
}

public class Job
{
    public int JobId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Department { get; set; }
    public string Description { get; set; } = string.Empty;
    public string? RequirementsText { get; set; }
    public string? WeightConfigJSON { get; set; }
    public string Status { get; set; } = "Active";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public string? OwnerId { get; set; }
    public bool IsDeleted { get; set; } = false;
}

public class Score
{
    public int ScoreId { get; set; }
    public int ResumeId { get; set; }
    public int JobId { get; set; }
    public decimal OverallScore { get; set; }
    public string SubscoresJSON { get; set; } = string.Empty;
    public string? EvidenceJSON { get; set; }
    public string ModelVersion { get; set; } = "v1.0";
    public DateTime ComputedAt { get; set; } = DateTime.UtcNow;
    public int? RecruiterRating { get; set; }
    public string? RecruiterNotes { get; set; }
    
    // Navigation properties
    public Resume? Resume { get; set; }
    public Job? Job { get; set; }
}

public class CandidateProfile
{
    public int ProfileId { get; set; }
    public int ResumeId { get; set; }
    public string? SkillsJSON { get; set; }
    public string? WorkHistoryJSON { get; set; }
    public string? EducationJSON { get; set; }
    public string? CertificationsJSON { get; set; }
    public string? SummaryText { get; set; }
    public decimal? TotalExperienceYears { get; set; }
    public string? SeniorityLevel { get; set; }
    public string? Industries { get; set; }
    public string? PreferredLocations { get; set; }
    public DateTime ExtractedAt { get; set; } = DateTime.UtcNow;
    public string? ModelVersion { get; set; }
    
    // Navigation property
    public Resume? Resume { get; set; }
}

public class Embedding
{
    public int EmbeddingId { get; set; }
    public string EntityType { get; set; } = string.Empty;
    public int EntityId { get; set; }
    public string? VectorJSON { get; set; }
    public string? ModelName { get; set; }
    public int? VectorDimension { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}