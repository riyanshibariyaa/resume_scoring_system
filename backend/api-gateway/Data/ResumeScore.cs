using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ResumeScoring.Api.Data
{
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
}
