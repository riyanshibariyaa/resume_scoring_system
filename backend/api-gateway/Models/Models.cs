// Models for Resume Scoring System
// These match the SQL Server database schema exactly

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ResumeScoring.Models
{
    // ========================================
    // Resume Model
    // ========================================
    [Table("Resumes")]
    public class Resume
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ResumeId { get; set; }

        [MaxLength(200)]
        public string? CandidateName { get; set; }

        [MaxLength(200)]
        public string? Email { get; set; }

        [MaxLength(50)]
        public string? Phone { get; set; }

        [Required]
        [MaxLength(500)]
        public string FileName { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? FileType { get; set; }

        [MaxLength(64)]
        public string? FileHash { get; set; }

        [Column(TypeName = "nvarchar(max)")]
        public string? RawText { get; set; }

        [Required]
        public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

        public DateTime? ProcessedAt { get; set; }

        // Navigation properties
        public virtual ICollection<ResumeScore> ResumeScores { get; set; } = new List<ResumeScore>();
        public virtual ICollection<Skill> Skills { get; set; } = new List<Skill>();
        public virtual ICollection<WorkExperience> WorkExperiences { get; set; } = new List<WorkExperience>();
        public virtual ICollection<Education> Educations { get; set; } = new List<Education>();
    }

    // ========================================
    // Job Model
    // ========================================
    [Table("Jobs")]
    public class Job
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int JobId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [Column(TypeName = "nvarchar(max)")]
        public string Description { get; set; } = string.Empty;

        [Column(TypeName = "nvarchar(max)")]
        public string? RequiredSkills { get; set; }

        [Column(TypeName = "nvarchar(max)")]
        public string? WeightConfig { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        // Navigation properties
        public virtual ICollection<ResumeScore> ResumeScores { get; set; } = new List<ResumeScore>();
    }

    // ========================================
    // ResumeScore Model
    // ========================================
    [Table("ResumeScores")]
    public class ResumeScore
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ScoreId { get; set; }

        [Required]
        public int ResumeId { get; set; }

        [Required]
        public int JobId { get; set; }

        [Required]
        [Column(TypeName = "decimal(5,2)")]
        public decimal TotalScore { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal? SkillScore { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal? ExperienceScore { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal? EducationScore { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal? KeywordScore { get; set; }

        [Column(TypeName = "nvarchar(max)")]
        public string? DetailedScores { get; set; }

        [Required]
        public DateTime ScoredAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("ResumeId")]
        public virtual Resume Resume { get; set; } = null!;

        [ForeignKey("JobId")]
        public virtual Job Job { get; set; } = null!;
    }

    // ========================================
    // Skill Model
    // ========================================
    [Table("Skills")]
    public class Skill
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int SkillId { get; set; }

        [Required]
        public int ResumeId { get; set; }

        [Required]
        [MaxLength(200)]
        public string SkillName { get; set; } = string.Empty;

        [MaxLength(100)]
        public string? SkillCategory { get; set; }

        [Column(TypeName = "decimal(4,1)")]
        public decimal? YearsOfExperience { get; set; }

        [MaxLength(50)]
        public string? ProficiencyLevel { get; set; }

        // Navigation properties
        [ForeignKey("ResumeId")]
        public virtual Resume Resume { get; set; } = null!;
    }

    // ========================================
    // WorkExperience Model
    // ========================================
    [Table("WorkExperience")]
    public class WorkExperience
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ExperienceId { get; set; }

        [Required]
        public int ResumeId { get; set; }

        [MaxLength(200)]
        public string? CompanyName { get; set; }

        [MaxLength(200)]
        public string? JobTitle { get; set; }

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        [Required]
        public bool IsCurrent { get; set; } = false;

        [Column(TypeName = "nvarchar(max)")]
        public string? Description { get; set; }

        public int? DurationMonths { get; set; }

        // Navigation properties
        [ForeignKey("ResumeId")]
        public virtual Resume Resume { get; set; } = null!;
    }

    // ========================================
    // Education Model
    // ========================================
    [Table("Education")]
    public class Education
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int EducationId { get; set; }

        [Required]
        public int ResumeId { get; set; }

        [MaxLength(200)]
        public string? InstitutionName { get; set; }

        [MaxLength(200)]
        public string? Degree { get; set; }

        [MaxLength(200)]
        public string? FieldOfStudy { get; set; }

        public DateTime? StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        [Column(TypeName = "decimal(3,2)")]
        public decimal? GPA { get; set; }

        // Navigation properties
        [ForeignKey("ResumeId")]
        public virtual Resume Resume { get; set; } = null!;
    }
}
