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
}

public class Resume
{
    public int ResumeId { get; set; }
    public string? CandidateName { get; set; }
    public string? Email { get; set; }
    public string RawFileUri { get; set; } = string.Empty;
    public string FileHash { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class Job
{
    public int JobId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? WeightConfigJSON { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class Score
{
    public int ScoreId { get; set; }
    public int ResumeId { get; set; }
    public int JobId { get; set; }
    public decimal OverallScore { get; set; }
    public string? SubscoresJSON { get; set; }
    public DateTime ComputedAt { get; set; }
}
