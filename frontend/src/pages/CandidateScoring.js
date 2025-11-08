import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Typography,
  Alert,
  Paper,
  Grid,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Card,
  CardContent,
  LinearProgress,
  Chip,
  Divider,
} from '@mui/material';
import {
  Psychology as ScoreIcon,
  CheckCircle as SuccessIcon,
  TrendingUp as TrendIcon,
} from '@mui/icons-material';
import { resumeService, jobService, scoringService } from '../services/api';
import { useNavigate } from 'react-router-dom';

const CandidateScoring = () => {
  const navigate = useNavigate();
  const [resumes, setResumes] = useState([]);
  const [jobs, setJobs] = useState([]);
  const [selectedResume, setSelectedResume] = useState('');
  const [selectedJob, setSelectedJob] = useState('');
  const [scoring, setScoring] = useState(false);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState(null);
  const [scoreResult, setScoreResult] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      const [resumesData, jobsData] = await Promise.all([
        resumeService.getAll(),
        jobService.getAll(),
      ]);
      
      setResumes(Array.isArray(resumesData) ? resumesData : []);
      setJobs(Array.isArray(jobsData) ? jobsData : []);
      
      if (resumesData.length === 0) {
        setMessage({ 
          type: 'warning', 
          text: 'No resumes found. Please upload a resume first.' 
        });
      }
      if (jobsData.length === 0) {
        setMessage({ 
          type: 'warning', 
          text: 'No jobs found. Please create a job first.' 
        });
      }
    } catch (error) {
      console.error('Error loading data:', error);
      setMessage({ type: 'error', text: 'Failed to load data: ' + error.message });
    } finally {
      setLoading(false);
    }
  };

  const handleScore = async () => {
    if (!selectedResume || !selectedJob) {
      setMessage({ type: 'error', text: 'Please select both a resume and a job' });
      return;
    }

    setScoring(true);
    setMessage(null);
    setScoreResult(null);

    try {
      // This triggers the complete scoring workflow:
      // 1. Fetches parsed resume data from database
      // 2. Fetches job requirements
      // 3. Compares embeddings
      // 4. Calculates multi-dimensional scores
      // 5. Creates Scores and MatchEvidence records
      const result = await scoringService.scoreCandidate(
        parseInt(selectedResume),
        parseInt(selectedJob)
      );

      setScoreResult(result);
      setMessage({ 
        type: 'success', 
        text: 'Candidate scored successfully! Results have been saved to the database.' 
      });

    } catch (error) {
      console.error('Scoring error:', error);
      setMessage({ type: 'error', text: 'Scoring failed: ' + error.message });
    } finally {
      setScoring(false);
    }
  };

  const selectedResumeData = resumes.find(r => r.resumeId === parseInt(selectedResume) || r.id === parseInt(selectedResume));
  const selectedJobData = jobs.find(j => j.jobId === parseInt(selectedJob) || j.id === parseInt(selectedJob));

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
        <LinearProgress sx={{ width: '50%' }} />
      </Box>
    );
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ mb: 3, fontWeight: 600 }}>
        Score Candidate Against Job
      </Typography>

      <Grid container spacing={3}>
        {/* Selection Panel */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Select Candidate
            </Typography>
            
            <FormControl fullWidth sx={{ mb: 3 }}>
              <InputLabel>Resume</InputLabel>
              <Select
                value={selectedResume}
                onChange={(e) => setSelectedResume(e.target.value)}
                label="Resume"
              >
                <MenuItem value="">
                  <em>Select a resume...</em>
                </MenuItem>
                {resumes.map((resume) => (
                  <MenuItem 
                    key={resume.resumeId || resume.id} 
                    value={resume.resumeId || resume.id}
                  >
                    {resume.candidateName || 'Unnamed Candidate'} 
                    {resume.email && ` (${resume.email})`}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            {selectedResumeData && (
              <Card variant="outlined" sx={{ mb: 2 }}>
                <CardContent>
                  <Typography variant="subtitle2" color="text.secondary">
                    Selected Resume
                  </Typography>
                  <Typography variant="body1" fontWeight="bold">
                    {selectedResumeData.candidateName || 'Unnamed'}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {selectedResumeData.email || 'No email'}
                  </Typography>
                  <Box sx={{ mt: 1 }}>
                    <Chip label={selectedResumeData.fileFormat || 'PDF'} size="small" />
                    <Chip 
                      label={selectedResumeData.parseStatus || 'Parsed'} 
                      color="success" 
                      size="small" 
                      sx={{ ml: 1 }} 
                    />
                  </Box>
                </CardContent>
              </Card>
            )}

            <Button
              variant="outlined"
              fullWidth
              onClick={() => navigate('/upload')}
              disabled={scoring}
            >
              Upload New Resume
            </Button>
          </Paper>
        </Grid>

        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Select Job
            </Typography>
            
            <FormControl fullWidth sx={{ mb: 3 }}>
              <InputLabel>Job Position</InputLabel>
              <Select
                value={selectedJob}
                onChange={(e) => setSelectedJob(e.target.value)}
                label="Job Position"
              >
                <MenuItem value="">
                  <em>Select a job...</em>
                </MenuItem>
                {jobs.map((job) => (
                  <MenuItem 
                    key={job.jobId || job.id} 
                    value={job.jobId || job.id}
                  >
                    {job.title}
                    {job.department && ` - ${job.department}`}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            {selectedJobData && (
              <Card variant="outlined" sx={{ mb: 2 }}>
                <CardContent>
                  <Typography variant="subtitle2" color="text.secondary">
                    Selected Job
                  </Typography>
                  <Typography variant="body1" fontWeight="bold">
                    {selectedJobData.title}
                  </Typography>
                  {selectedJobData.department && (
                    <Typography variant="body2" color="text.secondary">
                      {selectedJobData.department}
                    </Typography>
                  )}
                  <Typography 
                    variant="body2" 
                    sx={{ mt: 1 }}
                    color="text.secondary"
                  >
                    {selectedJobData.description?.substring(0, 150)}...
                  </Typography>
                </CardContent>
              </Card>
            )}

            <Button
              variant="outlined"
              fullWidth
              onClick={() => navigate('/jobs/create')}
              disabled={scoring}
            >
              Create New Job
            </Button>
          </Paper>
        </Grid>

        {/* Score Button */}
        <Grid item xs={12}>
          <Button
            variant="contained"
            size="large"
            fullWidth
            onClick={handleScore}
            disabled={!selectedResume || !selectedJob || scoring}
            startIcon={<ScoreIcon />}
            sx={{ py: 2 }}
          >
            {scoring ? 'Calculating Scores...' : 'Score Candidate Against Job'}
          </Button>
        </Grid>

        {/* Progress Indicator */}
        {scoring && (
          <Grid item xs={12}>
            <Paper sx={{ p: 3 }}>
              <Typography variant="body1" gutterBottom textAlign="center">
                Running AI-Powered Candidate Scoring...
              </Typography>
              <LinearProgress sx={{ my: 2 }} />
              <Typography variant="body2" color="text.secondary" textAlign="center">
                Analyzing skills • Comparing experience • Checking education • Calculating match
              </Typography>
            </Paper>
          </Grid>
        )}

        {/* Messages */}
        {message && (
          <Grid item xs={12}>
            <Alert 
              severity={message.type}
              onClose={() => setMessage(null)}
            >
              {message.text}
            </Alert>
          </Grid>
        )}

        {/* Results */}
        {scoreResult && (
          <Grid item xs={12}>
            <Card sx={{ backgroundColor: 'success.50' }}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <SuccessIcon sx={{ fontSize: 40, color: 'success.main', mr: 2 }} />
                  <Box>
                    <Typography variant="h5" color="success.main" fontWeight="bold">
                      Score: {((scoreResult.overallScore || scoreResult.score || 0) * 100).toFixed(1)}%
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Match quality for this position
                    </Typography>
                  </Box>
                </Box>

                <Divider sx={{ my: 2 }} />

                {/* Subscores */}
                {scoreResult.subscores && (
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="subtitle2" gutterBottom>
                      Detailed Breakdown:
                    </Typography>
                    <Grid container spacing={1}>
                      {Object.entries(scoreResult.subscores).map(([key, value]) => (
                        <Grid item xs={6} sm={4} key={key}>
                          <Box sx={{ textAlign: 'center', p: 1, backgroundColor: 'white', borderRadius: 1 }}>
                            <Typography variant="h6" color="primary">
                              {(value * 100).toFixed(0)}%
                            </Typography>
                            <Typography variant="caption" sx={{ textTransform: 'capitalize' }}>
                              {key.replace('_', ' ')}
                            </Typography>
                          </Box>
                        </Grid>
                      ))}
                    </Grid>
                  </Box>
                )}

                {/* Evidence */}
                {scoreResult.evidence && scoreResult.evidence.length > 0 && (
                  <Box sx={{ mb: 2 }}>
                    <Typography variant="subtitle2" gutterBottom>
                      Match Evidence:
                    </Typography>
                    {scoreResult.evidence.slice(0, 3).map((ev, idx) => (
                      <Typography key={idx} variant="body2" sx={{ ml: 2, mb: 0.5 }}>
                        • {ev.text || ev}
                      </Typography>
                    ))}
                  </Box>
                )}

                <Divider sx={{ my: 2 }} />

                <Typography variant="body2" color="text.secondary" gutterBottom>
                  ✅ Score saved to database (Scores table)
                </Typography>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  ✅ Evidence saved (MatchEvidence table)
                </Typography>

                <Box sx={{ mt: 2, display: 'flex', gap: 2 }}>
                  <Button
                    variant="contained"
                    onClick={() => {
                      if (scoreResult.scoreId || scoreResult.id) {
                        navigate(`/results/${scoreResult.scoreId || scoreResult.id}`);
                      }
                    }}
                  >
                    View Detailed Results
                  </Button>
                  <Button
                    variant="outlined"
                    onClick={() => {
                      setSelectedResume('');
                      setSelectedJob('');
                      setScoreResult(null);
                      setMessage(null);
                    }}
                  >
                    Score Another Candidate
                  </Button>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        )}

        {/* Info Box */}
        <Grid item xs={12}>
          <Paper sx={{ p: 3, backgroundColor: 'info.50' }}>
            <Typography variant="h6" gutterBottom color="info.main">
              📊 How Scoring Works
            </Typography>
            <Box component="ol" sx={{ pl: 2 }}>
              <li>
                <strong>Resume Data Fetched:</strong> Parsed text, extracted skills, experience, education from database
              </li>
              <li>
                <strong>Job Requirements Analyzed:</strong> Job description broken down into requirements
              </li>
              <li>
                <strong>Semantic Matching:</strong> Embeddings compared for deep understanding
              </li>
              <li>
                <strong>Multi-Dimensional Scoring:</strong> 6 criteria evaluated (skills, experience, domain, education, certs, recency)
              </li>
              <li>
                <strong>Evidence Generated:</strong> Specific examples of matches saved
              </li>
              <li>
                <strong>Results Stored:</strong> Scores and evidence saved to database for future reference
              </li>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default CandidateScoring;
