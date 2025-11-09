using Microsoft.EntityFrameworkCore;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ResumeScoring.Api.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<Job> Jobs { get; set; }
        public DbSet<Resume> Resumes { get; set; }
        // Add inside ApplicationDbContext class (near other DbSet<>)
        public DbSet<ParsedData> ParsedData { get; set; }

        public DbSet<ResumeScore> ResumeScores { get; set; }


        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure relationships
            modelBuilder.Entity<ResumeScore>()
                .HasOne(rs => rs.Resume)
                .WithMany()
                .HasForeignKey(rs => rs.ResumeId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ResumeScore>()
                .HasOne(rs => rs.Job)
                .WithMany()
                .HasForeignKey(rs => rs.JobId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }

    // Job Entity
    [Table("Jobs")]
    public class Job
    {
        [Key]
        public int JobId { get; set; }

        [Required]
        [StringLength(200)]
        public string Title { get; set; } = string.Empty;

        public string? Description { get; set; }

        public string? RequiredSkills { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public string? WeightConfig { get; set; }
    }

    // Resume Entity
    [Table("Resumes")]
    public class Resume
    {
        [Key]
        public int ResumeId { get; set; }

        [Required]
        [StringLength(255)]
        public string FileName { get; set; } = string.Empty;

        [StringLength(50)]
        public string? FileType { get; set; }

        [StringLength(200)]
        public string? CandidateName { get; set; }

        [StringLength(200)]
        public string? Email { get; set; }

        [StringLength(50)]
        public string? Phone { get; set; }

        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

        public DateTime? ProcessedAt { get; set; }

        public string? RawText { get; set; }

        [StringLength(100)]
        public string? FileHash { get; set; }
    }

    // ResumeScore Entity
    [Table("ResumeScores")]
    public class ResumeScore
    {
        [Key]
        public int ScoreId { get; set; }

        [Required]
        public int ResumeId { get; set; }

        [Required]
        public int JobId { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal TotalScore { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal EducationScore { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal ExperienceScore { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal SkillsScore { get; set; }

        public DateTime ScoredAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("ResumeId")]
        public virtual Resume? Resume { get; set; }

        [ForeignKey("JobId")]
        public virtual Job? Job { get; set; }
    }
        // ParsedData Entity - paste into ApplicationDbContext.cs (below ResumeScore)
    [Table("ParsedData")]
    public class ParsedData
    {
        [Key]
        public int ParsedDataId { get; set; }

        // FK to Resume (nullable if parsing can be done later)
        public int? ResumeId { get; set; }

        // Full extracted text (may be large)
        public string? Text { get; set; }

        // JSON blobs for structured parts from parser/NLP
        public string? SectionsJson { get; set; }
        public string? MetadataJson { get; set; }
        public string? ExtractedProfileJson { get; set; } // from NLP service

        // Common convenience fields (shallow copies for easy queries)
        public string? Skills { get; set; }
        public string? Education { get; set; }
        public string? Experience { get; set; }
        public string? Certifications { get; set; }
        public string? Summary { get; set; }

        public string? FileHash { get; set; }
        public string? RawFilePath { get; set; }
        public string? ParsedFilePath { get; set; }

        public DateTime ParsedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("ResumeId")]
        public virtual Resume? Resume { get; set; }
    }

}
