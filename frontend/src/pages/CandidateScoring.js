// frontend/src/pages/CandidateScoring.js
// FIXED VERSION - Reads totalScore correctly from backend

import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Button,
  Alert,
  LinearProgress,
  Divider,
} from '@mui/material';
import {
  CheckCircle as SuccessIcon,
  Psychology as ScoreIcon,
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
  const [scoreResult, setScoreResult] = useState(null);
  const [message, setMessage] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const [resumesData, jobsData] = await Promise.all([
        resumeService.getAll(),
        jobService.getAll(),
      ]);
      setResumes(resumesData);
      setJobs(jobsData);
    } catch (err) {
      console.error('Error loading data:', err);
      setMessage({ type: 'error', text: 'Failed to load resumes or jobs' });
    }
  };

  const handleScore = async () => {
    if (!selectedResume || !selectedJob) {
      setMessage({ type: 'warning', text: 'Please select both a resume and a job' });
      return;
    }

    try {
      setScoring(true);
      setScoreResult(null);
      setMessage(null);

      console.log('🚀 Scoring request:', { resumeId: selectedResume, jobId: selectedJob });

      // Call the scoring API
      const result = await scoringService.scoreCandidate(selectedResume, selectedJob);

      console.log('✅ Scoring response:', result);

      // ✅ CRITICAL FIX: Backend returns totalScore (not overallScore or score)
      // Backend sends as 0-100 percentage (not 0-1 decimal)
      setScoreResult({
        totalScore: result.totalScore || 0,  // ← Read totalScore
        skillsScore: result.skillsScore || 0,
        experienceScore: result.experienceScore || 0,
        educationScore: result.educationScore || 0,
        usedParsedData: result.usedParsedData || false,
        message: result.message,
        // Keep compatibility with old field names if they exist
        overallScore: result.overallScore || result.totalScore / 100, // Convert to 0-1 if needed
        subscores: {
          skills: (result.skillsScore || 0) / 100,
          experience: (result.experienceScore || 0) / 100,
          education: (result.educationScore || 0) / 100,
        },
      });

      setMessage({
        type: 'success',
        text: 'Candidate scored successfully! Results have been saved to the database.',
      });
    } catch (err) {
      console.error('❌ Scoring error:', err);
      setMessage({
        type: 'error',
        text: `Failed to score candidate: ${err.message}`,
      });
    } finally {
      setScoring(false);
    }
  };

  const selectedResumeData = resumes.find((r) => r.resumeId === selectedResume);
  const selectedJobData = jobs.find((j) => j.jobId === selectedJob);

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ mb: 3, fontWeight: 600 }}>
        Score Candidate Against Job
      </Typography>

      <Grid container spacing={3}>
        {/* Select Candidate */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Select Candidate
            </Typography>
            <FormControl fullWidth sx={{ mb: 2 }}>
              <InputLabel>Resume</InputLabel>
              <Select
                value={selectedResume}
                label="Resume"
                onChange={(e) => setSelectedResume(e.target.value)}
              >
                {resumes.map((resume) => (
                  <MenuItem key={resume.resumeId} value={resume.resumeId}>
                    {resume.candidateName || 'Candidate'} ({resume.fileName})
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            {selectedResumeData && (
              <Box sx={{ p: 2, backgroundColor: 'grey.50', borderRadius: 1 }}>
                <Typography variant="subtitle2">Selected Resume</Typography>
                <Typography variant="body2">
                  <strong>{selectedResumeData.candidateName || 'Candidate'}</strong>
                </Typography>
                {selectedResumeData.email && (
                  <Typography variant="body2">{selectedResumeData.email}</Typography>
                )}
                <Typography variant="caption" color="text.secondary">
                  {selectedResumeData.fileName} • Parsed ✅
                </Typography>
              </Box>
            )}
          </Paper>
        </Grid>

        {/* Select Job */}
        <Grid item xs={12} md={6}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Select Job
            </Typography>
            <FormControl fullWidth sx={{ mb: 2 }}>
              <InputLabel>Job Position</InputLabel>
              <Select
                value={selectedJob}
                label="Job Position"
                onChange={(e) => setSelectedJob(e.target.value)}
              >
                {jobs.map((job) => (
                  <MenuItem key={job.jobId} value={job.jobId}>
                    {job.title}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            {selectedJobData && (
              <Box sx={{ p: 2, backgroundColor: 'grey.50', borderRadius: 1 }}>
                <Typography variant="subtitle2">Selected Job</Typography>
                <Typography variant="body2">
                  <strong>{selectedJobData.title}</strong>
                </Typography>
                <Typography variant="body2" sx={{ mt: 1 }}>
                  {selectedJobData.description?.substring(0, 150)}...
                </Typography>
              </Box>
            )}
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
            <Alert severity={message.type} onClose={() => setMessage(null)}>
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
                    {/* ✅ FIXED: Display totalScore directly (already 0-100) */}
                    <Typography variant="h5" color="success.main" fontWeight="bold">
                      Score: {scoreResult.totalScore.toFixed(1)}%
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Match quality for this position
                    </Typography>
                    {scoreResult.usedParsedData && (
                      <Typography variant="caption" color="success.dark">
                        ✅ Scored using structured ParsedData
                      </Typography>
                    )}
                    {!scoreResult.usedParsedData && (
                      <Typography variant="caption" color="warning.dark">
                        ⚠️ Used fallback scoring (no ParsedData available)
                      </Typography>
                    )}
                  </Box>
                </Box>

                <Divider sx={{ my: 2 }} />

                {/* Subscores - Display directly (already 0-100) */}
                <Box sx={{ mb: 2 }}>
                  <Typography variant="subtitle2" gutterBottom>
                    Detailed Breakdown:
                  </Typography>
                  <Grid container spacing={1}>
                    <Grid item xs={6} sm={4}>
                      <Box
                        sx={{
                          textAlign: 'center',
                          p: 1,
                          backgroundColor: 'white',
                          borderRadius: 1,
                        }}
                      >
                        <Typography variant="h6" color="primary">
                          {scoreResult.skillsScore.toFixed(0)}%
                        </Typography>
                        <Typography variant="caption">Skills</Typography>
                      </Box>
                    </Grid>
                    <Grid item xs={6} sm={4}>
                      <Box
                        sx={{
                          textAlign: 'center',
                          p: 1,
                          backgroundColor: 'white',
                          borderRadius: 1,
                        }}
                      >
                        <Typography variant="h6" color="primary">
                          {scoreResult.experienceScore.toFixed(0)}%
                        </Typography>
                        <Typography variant="caption">Experience</Typography>
                      </Box>
                    </Grid>
                    <Grid item xs={6} sm={4}>
                      <Box
                        sx={{
                          textAlign: 'center',
                          p: 1,
                          backgroundColor: 'white',
                          borderRadius: 1,
                        }}
                      >
                        <Typography variant="h6" color="primary">
                          {scoreResult.educationScore.toFixed(0)}%
                        </Typography>
                        <Typography variant="caption">Education</Typography>
                      </Box>
                    </Grid>
                  </Grid>
                </Box>

                <Divider sx={{ my: 2 }} />

                <Typography variant="body2" color="text.secondary" gutterBottom>
                  ✅ Score saved to database (ResumeScores table)
                </Typography>

                <Box sx={{ mt: 2, display: 'flex', gap: 2 }}>
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
                <strong>Resume Data Fetched:</strong> Parsed text, extracted skills, experience,
                education from database
              </li>
              <li>
                <strong>Job Requirements Analyzed:</strong> Job description broken down into
                requirements
              </li>
              <li>
                <strong>Multi-Dimensional Scoring:</strong> Skills, experience, and education
                evaluated
              </li>
              <li>
                <strong>Results Stored:</strong> Scores saved to database for future reference
              </li>
            </Box>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
};

export default CandidateScoring;
