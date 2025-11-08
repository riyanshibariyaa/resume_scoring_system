import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  LinearProgress,
  Chip,
} from '@mui/material';
import {
  Description as ResumeIcon,
  Work as JobIcon,
  TrendingUp as ScoreIcon,
  CheckCircle as SuccessIcon,
} from '@mui/icons-material';
import { resumeService, jobService, scoringService } from '../services/api';
import { useNavigate } from 'react-router-dom';

const Dashboard = () => {
  const navigate = useNavigate();
  const [stats, setStats] = useState({
    totalResumes: 0,
    totalJobs: 0,
    totalScores: 0,
    recentResumes: [],
    recentJobs: [],
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const [resumes, jobs] = await Promise.all([
        resumeService.getAll(),
        jobService.getAll(),
      ]);

      setStats({
        totalResumes: resumes.length,
        totalJobs: jobs.length,
        totalScores: 0, // Will be populated when we have scores
        recentResumes: resumes.slice(0, 5),
        recentJobs: jobs.slice(0, 5),
      });
    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
        <LinearProgress sx={{ width: '50%' }} />
      </Box>
    );
  }

  const StatCard = ({ title, value, icon: Icon, color, action }) => (
    <Card sx={{ height: '100%', cursor: action ? 'pointer' : 'default' }} onClick={action}>
      <CardContent>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <Box>
            <Typography color="text.secondary" variant="subtitle2" gutterBottom>
              {title}
            </Typography>
            <Typography variant="h3" sx={{ color: color || 'primary.main', fontWeight: 'bold' }}>
              {value}
            </Typography>
          </Box>
          <Icon sx={{ fontSize: 48, color: color || 'primary.main', opacity: 0.3 }} />
        </Box>
      </CardContent>
    </Card>
  );

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ mb: 3, fontWeight: 600 }}>
        Resume Scoring System Dashboard
      </Typography>

      {/* Statistics Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Resumes"
            value={stats.totalResumes}
            icon={ResumeIcon}
            color="#1976d2"
            action={() => navigate('/resumes')}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Total Jobs"
            value={stats.totalJobs}
            icon={JobIcon}
            color="#2e7d32"
            action={() => navigate('/jobs')}
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="Scores Generated"
            value={stats.totalScores}
            icon={ScoreIcon}
            color="#ed6c02"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            title="System Status"
            value={<SuccessIcon sx={{ fontSize: 48 }} />}
            icon={SuccessIcon}
            color="#4caf50"
          />
        </Grid>
      </Grid>

      {/* Quick Actions */}
      <Card sx={{ mb: 4 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Quick Actions
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6} md={3}>
              <Button
                variant="contained"
                fullWidth
                startIcon={<ResumeIcon />}
                onClick={() => navigate('/upload')}
              >
                Upload Resume
              </Button>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Button
                variant="contained"
                fullWidth
                startIcon={<JobIcon />}
                onClick={() => navigate('/jobs/create')}
              >
                Create Job
              </Button>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Button
                variant="contained"
                fullWidth
                startIcon={<ScoreIcon />}
                onClick={() => navigate('/score')}
              >
                Score Candidate
              </Button>
            </Grid>
            <Grid item xs={12} sm={6} md={3}>
              <Button
                variant="outlined"
                fullWidth
                onClick={() => navigate('/resumes')}
              >
                View All Resumes
              </Button>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      <Grid container spacing={3}>
        {/* Recent Resumes */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Recent Resumes
              </Typography>
              {stats.recentResumes.length > 0 ? (
                stats.recentResumes.map((resume, index) => (
                  <Box
                    key={resume.resumeId || resume.id || index}
                    sx={{
                      p: 2,
                      mb: 1,
                      backgroundColor: 'grey.50',
                      borderRadius: 1,
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                    }}
                  >
                    <Box>
                      <Typography variant="body1" fontWeight="bold">
                        {resume.candidateName || 'Unnamed Candidate'}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {resume.email || 'No email'}
                      </Typography>
                    </Box>
                    <Chip 
                      label={resume.parseStatus || 'Parsed'} 
                      color="success" 
                      size="small" 
                    />
                  </Box>
                ))
              ) : (
                <Typography variant="body2" color="text.secondary">
                  No resumes uploaded yet. Upload your first resume to get started!
                </Typography>
              )}
              <Button
                fullWidth
                variant="text"
                onClick={() => navigate('/resumes')}
                sx={{ mt: 2 }}
              >
                View All Resumes
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Recent Jobs */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Recent Jobs
              </Typography>
              {stats.recentJobs.length > 0 ? (
                stats.recentJobs.map((job, index) => (
                  <Box
                    key={job.jobId || job.id || index}
                    sx={{
                      p: 2,
                      mb: 1,
                      backgroundColor: 'grey.50',
                      borderRadius: 1,
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                    }}
                  >
                    <Box>
                      <Typography variant="body1" fontWeight="bold">
                        {job.title}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        {job.department || 'No department'}
                      </Typography>
                    </Box>
                    <Chip 
                      label={job.status || 'Active'} 
                      color="primary" 
                      size="small" 
                    />
                  </Box>
                ))
              ) : (
                <Typography variant="body2" color="text.secondary">
                  No jobs created yet. Create your first job posting!
                </Typography>
              )}
              <Button
                fullWidth
                variant="text"
                onClick={() => navigate('/jobs')}
                sx={{ mt: 2 }}
              >
                View All Jobs
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Workflow Guide */}
      <Card sx={{ mt: 3, backgroundColor: 'primary.50' }}>
        <CardContent>
          <Typography variant="h6" gutterBottom color="primary.main">
            📋 Complete Workflow
          </Typography>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} md={6} lg={2.4}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h6" color="primary.main">1</Typography>
                <Typography variant="body2">Upload Resume</Typography>
                <Typography variant="caption" color="text.secondary">
                  Stored in Resumes table
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} md={6} lg={2.4}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h6" color="primary.main">2</Typography>
                <Typography variant="body2">Parse Text</Typography>
                <Typography variant="caption" color="text.secondary">
                  Stored in ParsedData table
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} md={6} lg={2.4}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h6" color="primary.main">3</Typography>
                <Typography variant="body2">Generate Embeddings</Typography>
                <Typography variant="caption" color="text.secondary">
                  Stored in Embeddings table
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} md={6} lg={2.4}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h6" color="primary.main">4</Typography>
                <Typography variant="body2">Create Job</Typography>
                <Typography variant="caption" color="text.secondary">
                  Stored in Jobs table
                </Typography>
              </Box>
            </Grid>
            <Grid item xs={12} md={12} lg={2.4}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h6" color="primary.main">5</Typography>
                <Typography variant="body2">Score & Match</Typography>
                <Typography variant="caption" color="text.secondary">
                  Creates Scores + MatchEvidence
                </Typography>
              </Box>
            </Grid>
          </Grid>
        </CardContent>
      </Card>
    </Box>
  );
};

export default Dashboard;
