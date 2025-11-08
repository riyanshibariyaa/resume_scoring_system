using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure SQL Server connection
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// CORS Configuration
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"] ?? "YourSuperSecretKeyThatIsAtLeast32CharactersLong";
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "ResumeScoring";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "ResumeScoringUsers";

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    };
});

builder.Services.AddAuthorization();

// HTTP Clients for microservices
builder.Services.AddHttpClient("ParsingService", client =>
{
    client.BaseAddress = new Uri(builder.Configuration["Services:ParsingUrl"] 
        ?? "http://localhost:5001");
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
    public DbSet<ParsedData> ParsedData { get; set; }
    public DbSet<Embedding> Embeddings { get; set; }
    public DbSet<MatchEvidence> MatchEvidence { get; set; }
    public DbSet<Feedback> Feedback { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Configure primary keys
        modelBuilder.Entity<Resume>()
            .HasKey(r => r.ResumeId);

        modelBuilder.Entity<Job>()
            .HasKey(j => j.JobId);

        modelBuilder.Entity<Score>()
            .HasKey(s => s.ScoreId);

        modelBuilder.Entity<ParsedData>()
            .HasKey(p => p.ParsedDataId);

        modelBuilder.Entity<Embedding>()
            .HasKey(e => e.EmbeddingId);

        modelBuilder.Entity<MatchEvidence>()
            .HasKey(m => m.EvidenceId);

        modelBuilder.Entity<Feedback>()
            .HasKey(f => f.FeedbackId);

        // Configure decimal precision
        modelBuilder.Entity<Score>()
            .Property(s => s.OverallScore)
            .HasColumnType("decimal(5,2)");

        modelBuilder.Entity<Score>()
            .Property(s => s.SkillsScore)
            .HasColumnType("decimal(5,2)");

        modelBuilder.Entity<Score>()
            .Property(s => s.ExperienceScore)
            .HasColumnType("decimal(5,2)");

        modelBuilder.Entity<Score>()
            .Property(s => s.EducationScore)
            .HasColumnType("decimal(5,2)");

        modelBuilder.Entity<Score>()
            .Property(s => s.CertificationsScore)
            .HasColumnType("decimal(5,2)");

        modelBuilder.Entity<Score>()
            .Property(s => s.SemanticScore)
            .HasColumnType("decimal(5,2)");

        modelBuilder.Entity<MatchEvidence>()
            .Property(m => m.ConfidenceScore)
            .HasColumnType("decimal(5,2)");

        modelBuilder.Entity<Feedback>()
            .Property(f => f.AdjustedScore)
            .HasColumnType("decimal(5,2)");
    }
}

// Models matching ACTUAL database schema (from active migration)
public class Resume
{
    public int ResumeId { get; set; }
    public string? CandidateName { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? RawText { get; set; }
    public string? FileHash { get; set; }
    public string? FileName { get; set; }
    public string? FileType { get; set; }
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
}

public class Job
{
    public int JobId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? RequiredSkills { get; set; }
    public string? WeightConfig { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class Score
{
    public int ScoreId { get; set; }
    public int ResumeId { get; set; }
    public int JobId { get; set; }
    public decimal? OverallScore { get; set; }
    public decimal? SkillsScore { get; set; }
    public decimal? ExperienceScore { get; set; }
    public decimal? EducationScore { get; set; }
    public decimal? CertificationsScore { get; set; }
    public decimal? SemanticScore { get; set; }
    public string? Explanation { get; set; }
    public DateTime ComputedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public Resume? Resume { get; set; }
    public Job? Job { get; set; }
}

public class ParsedData
{
    public int ParsedDataId { get; set; }
    public int ResumeId { get; set; }
    public string? ContactInfo { get; set; }
    public string? Skills { get; set; }
    public string? Experience { get; set; }
    public string? Education { get; set; }
    public string? Certifications { get; set; }
    public string? Summary { get; set; }
    public DateTime ParsedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation property
    public Resume? Resume { get; set; }
}

public class Embedding
{
    public int EmbeddingId { get; set; }
    public string? EntityType { get; set; }
    public int EntityId { get; set; }
    public string? EmbeddingVector { get; set; }
    public string? ModelName { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class MatchEvidence
{
    public int EvidenceId { get; set; }
    public int ScoreId { get; set; }
    public string? Category { get; set; }
    public string? MatchedText { get; set; }
    public string? JobRequirement { get; set; }
    public decimal? ConfidenceScore { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation property
    public Score? Score { get; set; }
}

public class Feedback
{
    public int FeedbackId { get; set; }
    public int ScoreId { get; set; }
    public string? RecruiterNotes { get; set; }
    public decimal? AdjustedScore { get; set; }
    public string? WeightAdjustments { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation property
    public Score? Score { get; set; }
}
