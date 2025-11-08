using Microsoft.EntityFrameworkCore;
using ResumeScoring.Models;

namespace ResumeScoring.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
            // Set default command timeout to prevent timeout errors
            this.Database.SetCommandTimeout(60);
        }

        // DbSets for all tables
        public DbSet<Resume> Resumes { get; set; } = null!;
        public DbSet<Job> Jobs { get; set; } = null!;
        public DbSet<ResumeScore> ResumeScores { get; set; } = null!;
        public DbSet<Skill> Skills { get; set; } = null!;
        public DbSet<WorkExperience> WorkExperience { get; set; } = null!;
        public DbSet<Education> Education { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // ========================================
            // Resume Configuration
            // ========================================
            modelBuilder.Entity<Resume>(entity =>
            {
                entity.ToTable("Resumes");
                entity.HasKey(e => e.ResumeId);

                entity.Property(e => e.ResumeId)
                    .ValueGeneratedOnAdd();

                entity.Property(e => e.UploadedAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                // Unique constraint on FileHash
                entity.HasIndex(e => e.FileHash)
                    .IsUnique()
                    .HasDatabaseName("UQ_Resumes_FileHash")
                    .HasFilter("[FileHash] IS NOT NULL");

                // Indexes
                entity.HasIndex(e => e.UploadedAt)
                    .HasDatabaseName("IX_Resumes_UploadedAt");

                entity.HasIndex(e => e.Email)
                    .HasDatabaseName("IX_Resumes_Email");

                entity.HasIndex(e => e.ProcessedAt)
                    .HasDatabaseName("IX_Resumes_ProcessedAt");
            });

            // ========================================
            // Job Configuration
            // ========================================
            modelBuilder.Entity<Job>(entity =>
            {
                entity.ToTable("Jobs");
                entity.HasKey(e => e.JobId);

                entity.Property(e => e.JobId)
                    .ValueGeneratedOnAdd();

                entity.Property(e => e.CreatedAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                // Indexes
                entity.HasIndex(e => e.CreatedAt)
                    .HasDatabaseName("IX_Jobs_CreatedAt");

                entity.HasIndex(e => e.Title)
                    .HasDatabaseName("IX_Jobs_Title");
            });

            // ========================================
            // ResumeScore Configuration
            // ========================================
            modelBuilder.Entity<ResumeScore>(entity =>
            {
                entity.ToTable("ResumeScores");
                entity.HasKey(e => e.ScoreId);

                entity.Property(e => e.ScoreId)
                    .ValueGeneratedOnAdd();

                entity.Property(e => e.ScoredAt)
                    .HasDefaultValueSql("GETUTCDATE()");

                // Unique constraint
                entity.HasIndex(e => new { e.ResumeId, e.JobId })
                    .IsUnique()
                    .HasDatabaseName("UQ_ResumeScores_ResumeJob");

                // Indexes
                entity.HasIndex(e => e.ResumeId)
                    .HasDatabaseName("IX_ResumeScores_ResumeId");

                entity.HasIndex(e => e.JobId)
                    .HasDatabaseName("IX_ResumeScores_JobId");

                entity.HasIndex(e => e.TotalScore)
                    .HasDatabaseName("IX_ResumeScores_TotalScore");

                entity.HasIndex(e => e.ScoredAt)
                    .HasDatabaseName("IX_ResumeScores_ScoredAt");

                // Relationships
                entity.HasOne(d => d.Resume)
                    .WithMany(p => p.ResumeScores)
                    .HasForeignKey(d => d.ResumeId)
                    .OnDelete(DeleteBehavior.Cascade)
                    .HasConstraintName("FK_ResumeScores_Resumes");

                entity.HasOne(d => d.Job)
                    .WithMany(p => p.ResumeScores)
                    .HasForeignKey(d => d.JobId)
                    .OnDelete(DeleteBehavior.Cascade)
                    .HasConstraintName("FK_ResumeScores_Jobs");
            });

            // ========================================
            // Skill Configuration
            // ========================================
            modelBuilder.Entity<Skill>(entity =>
            {
                entity.ToTable("Skills");
                entity.HasKey(e => e.SkillId);

                entity.Property(e => e.SkillId)
                    .ValueGeneratedOnAdd();

                // Indexes
                entity.HasIndex(e => e.ResumeId)
                    .HasDatabaseName("IX_Skills_ResumeId");

                entity.HasIndex(e => e.SkillName)
                    .HasDatabaseName("IX_Skills_SkillName");

                // Relationships
                entity.HasOne(d => d.Resume)
                    .WithMany(p => p.Skills)
                    .HasForeignKey(d => d.ResumeId)
                    .OnDelete(DeleteBehavior.Cascade)
                    .HasConstraintName("FK_Skills_Resumes");
            });

            // ========================================
            // WorkExperience Configuration
            // ========================================
            modelBuilder.Entity<WorkExperience>(entity =>
            {
                entity.ToTable("WorkExperience");
                entity.HasKey(e => e.ExperienceId);

                entity.Property(e => e.ExperienceId)
                    .ValueGeneratedOnAdd();

                // Indexes
                entity.HasIndex(e => e.ResumeId)
                    .HasDatabaseName("IX_WorkExperience_ResumeId");

                // Relationships
                entity.HasOne(d => d.Resume)
                    .WithMany(p => p.WorkExperiences)
                    .HasForeignKey(d => d.ResumeId)
                    .OnDelete(DeleteBehavior.Cascade)
                    .HasConstraintName("FK_WorkExperience_Resumes");
            });

            // ========================================
            // Education Configuration
            // ========================================
            modelBuilder.Entity<Education>(entity =>
            {
                entity.ToTable("Education");
                entity.HasKey(e => e.EducationId);

                entity.Property(e => e.EducationId)
                    .ValueGeneratedOnAdd();

                // Indexes
                entity.HasIndex(e => e.ResumeId)
                    .HasDatabaseName("IX_Education_ResumeId");

                // Relationships
                entity.HasOne(d => d.Resume)
                    .WithMany(p => p.Educations)
                    .HasForeignKey(d => d.ResumeId)
                    .OnDelete(DeleteBehavior.Cascade)
                    .HasConstraintName("FK_Education_Resumes");
            });
        }
    }
}
