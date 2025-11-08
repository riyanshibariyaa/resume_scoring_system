import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  Chip,
  LinearProgress,
  Divider,
  Alert,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
} from '@mui/material';
import {
  TrendingUp as ScoreIcon,
  CheckCircle as CheckIcon,
  Code as SkillIcon,
  Work as ExperienceIcon,
  School as EducationIcon,
} from '@mui/icons-material';
import { scoringService } from '../services/api';
import { useParams, useNavigate } from 'react-router-dom';

const ScoringResults = () => {
  const { scoreId } = useParams();
  const navigate = useNavigate();
  const [scoreData, setScoreData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadScoreData();
  }, [scoreId]);

  const loadScoreData = async () => {
    try {
      setLoading(true);
      const data = await scoringService.getScoreById(scoreId);
      setScoreData(data);
    } catch (err) {
      console.error('Error loading score data:', err);
      setError('Failed to load scoring results: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const getScoreColor = (score) => {
    if (score >= 0.8) return 'success.main';
    if (score >= 0.6) return 'warning.main';
    return 'error.main';
  };

  const getScoreLabel = (score) => {
    if (score >= 0.8) return 'Excellent Match';
    if (score >= 0.6) return 'Good Match';
    if (score >= 0.4) return 'Fair Match';
    return 'Poor Match';
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
        <LinearProgress sx={{ width: '50%' }} />
      </Box>
    );
  }

  if (error) {
    return (
      <Box>
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
        <Button variant="contained" onClick={() => navigate('/score')}>
          Back to Scoring
        </Button>
      </Box>
    );
  }

  if (!scoreData) {
    return (
      <Box>
        <Alert severity="warning">
          No scoring data found
        </Alert>
      </Box>
    );
  }

  const overallScore = scoreData.overallScore || scoreData.score || 0;
  const subscores = scoreData.subscores || {};
  const evidence = scoreData.evidence || [];

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ mb: 3, fontWeight: 600 }}>
        Candidate Scoring Results
      </Typography>

      {/* Overall Score Card */}
      <Card sx={{ mb: 3, backgroundColor: 'primary.50' }}>
        <CardContent>
          <Grid container spacing={3} alignItems="center">
            <Grid item xs={12} md={4}>
              <Box sx={{ textAlign: 'center' }}>
                <Typography variant="h2" sx={{ color: getScoreColor(overallScore), fontWeight: 'bold' }}>
                  {(overallScore * 100).toFixed(1)}%
                </Typography>
                <Typography variant="h6" color="text.secondary">
                  Overall Match Score
                </Typography>
                <Chip 
                  label={getScoreLabel(overallScore)}
                  color={overallScore >= 0.6 ? 'success' : 'warning'}
                  sx={{ mt: 1 }}
                />
              </Box>
            </Grid>
            <Grid item xs={12} md={8}>
              <Typography variant="body1" gutterBottom>
                <strong>Candidate:</strong> {scoreData.candidateName || 'Unknown'}
              </Typography>
              <Typography variant="body1" gutterBottom>
                <strong>Job Position:</strong> {scoreData.jobTitle || 'Unknown Position'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                <strong>Evaluated:</strong> {new Date(scoreData.computedAt || Date.now()).toLocaleString()}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                <strong>Model Version:</strong> {scoreData.modelVersion || 'v1.0'}
              </Typography>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* Detailed Subscores */}
      <Typography variant="h6" gutterBottom sx={{ mb: 2 }}>
        Detailed Score Breakdown
      </Typography>
      <Grid container spacing={2} sx={{ mb: 3 }}>
        {Object.entries(subscores).map(([criterion, score]) => {
          const percentage = (score * 100).toFixed(1);
          return (
            <Grid item xs={12} sm={6} md={4} key={criterion}>
              <Card>
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                    {criterion.includes('skill') && <SkillIcon sx={{ mr: 1, color: 'primary.main' }} />}
                    {criterion.includes('experience') && <ExperienceIcon sx={{ mr: 1, color: 'primary.main' }} />}
                    {criterion.includes('education') && <EducationIcon sx={{ mr: 1, color: 'primary.main' }} />}
                    <Typography variant="subtitle2" sx={{ textTransform: 'capitalize', flex: 1 }}>
                      {criterion.replace('_', ' ')}
                    </Typography>
                    <Typography variant="h6" sx={{ color: getScoreColor(score) }}>
                      {percentage}%
                    </Typography>
                  </Box>
                  <LinearProgress 
                    variant="determinate" 
                    value={parseFloat(percentage)} 
                    sx={{ 
                      height: 8, 
                      borderRadius: 1,
                      backgroundColor: 'grey.200',
                      '& .MuiLinearProgress-bar': {
                        backgroundColor: getScoreColor(score),
                      }
                    }} 
                  />
                </CardContent>
              </Card>
            </Grid>
          );
        })}
      </Grid>

      {/* Match Evidence */}
      {evidence && evidence.length > 0 && (
        <>
          <Typography variant="h6" gutterBottom sx={{ mb: 2 }}>
            Match Evidence & Explanation
          </Typography>
          <Paper sx={{ p: 3, mb: 3 }}>
            <Typography variant="body2" color="text.secondary" gutterBottom>
              These are specific examples from the resume that match the job requirements:
            </Typography>
            <Divider sx={{ my: 2 }} />
            {evidence.map((ev, index) => (
              <Box key={index} sx={{ mb: 2, display: 'flex', alignItems: 'flex-start' }}>
                <CheckIcon sx={{ color: 'success.main', mr: 1, mt: 0.5, fontSize: 20 }} />
                <Box>
                  <Typography variant="body1">
                    {typeof ev === 'string' ? ev : ev.text || ev.description}
                  </Typography>
                  {ev.category && (
                    <Chip label={ev.category} size="small" sx={{ mt: 0.5 }} />
                  )}
                  {ev.score && (
                    <Typography variant="caption" color="text.secondary" sx={{ ml: 1 }}>
                      Confidence: {(ev.score * 100).toFixed(0)}%
                    </Typography>
                  )}
                </Box>
              </Box>
            ))}
          </Paper>
        </>
      )}

      {/* Recommendations */}
      <Card sx={{ mb: 3, backgroundColor: 'info.50' }}>
        <CardContent>
          <Typography variant="h6" gutterBottom color="info.main">
            💡 Hiring Recommendation
          </Typography>
          {overallScore >= 0.8 ? (
            <Typography variant="body1">
              <strong>Strong Candidate:</strong> This candidate demonstrates excellent alignment with the job requirements.
              Consider moving forward with an interview.
            </Typography>
          ) : overallScore >= 0.6 ? (
            <Typography variant="body1">
              <strong>Good Candidate:</strong> This candidate shows good potential for the role.
              Review the detailed breakdown and consider for further evaluation.
            </Typography>
          ) : (
            <Typography variant="body1">
              <strong>Review Needed:</strong> This candidate may need additional review.
              Check if there are specific skills or experiences that could be developed or if the job requirements could be adjusted.
            </Typography>
          )}
        </CardContent>
      </Card>

      {/* Database Info */}
      <Paper sx={{ p: 3, backgroundColor: 'success.50' }}>
        <Typography variant="subtitle2" color="success.main" gutterBottom>
          ✅ Data Stored in Database
        </Typography>
        <Grid container spacing={2} sx={{ mt: 1 }}>
          <Grid item xs={12} sm={6}>
            <Typography variant="body2">
              <strong>Scores Table:</strong> Overall and subscores saved
            </Typography>
          </Grid>
          <Grid item xs={12} sm={6}>
            <Typography variant="body2">
              <strong>MatchEvidence Table:</strong> All evidence points recorded
            </Typography>
          </Grid>
        </Grid>
      </Paper>

      {/* Action Buttons */}
      <Box sx={{ mt: 3, display: 'flex', gap: 2 }}>
        <Button
          variant="contained"
          onClick={() => navigate('/score')}
        >
          Score Another Candidate
        </Button>
        <Button
          variant="outlined"
          onClick={() => navigate('/resumes')}
        >
          View All Resumes
        </Button>
        <Button
          variant="outlined"
          onClick={() => navigate('/jobs')}
        >
          View All Jobs
        </Button>
      </Box>
    </Box>
  );
};

export default ScoringResults;
