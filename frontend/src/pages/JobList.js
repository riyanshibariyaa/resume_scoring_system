import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Card,
  CardContent,
  CardActions,
  Button,
  Grid,
  Chip,
  LinearProgress,
  Alert,
  IconButton,
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  Psychology as ScoreIcon,
  Visibility as ViewIcon,
} from '@mui/icons-material';
import { jobService } from '../services/api';
import { useNavigate } from 'react-router-dom';

const JobList = () => {
  const navigate = useNavigate();
  const [jobs, setJobs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState(null);

  useEffect(() => {
    loadJobs();
  }, []);

  const loadJobs = async () => {
    try {
      setLoading(true);
      const data = await jobService.getAll();
      setJobs(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error('Error loading jobs:', error);
      setMessage({ type: 'error', text: 'Failed to load jobs: ' + error.message });
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this job?')) {
      return;
    }

    try {
      await jobService.delete(id);
      setMessage({ type: 'success', text: 'Job deleted successfully' });
      loadJobs();
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to delete job: ' + error.message });
    }
  };

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    return new Date(dateString).toLocaleDateString();
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: 400 }}>
        <LinearProgress sx={{ width: '50%' }} />
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" sx={{ fontWeight: 600 }}>
          All Jobs ({jobs.length})
        </Typography>
        <Button
          variant="contained"
          onClick={() => navigate('/jobs/create')}
        >
          Create New Job
        </Button>
      </Box>

      {message && (
        <Alert severity={message.type} onClose={() => setMessage(null)} sx={{ mb: 3 }}>
          {message.text}
        </Alert>
      )}

      {jobs.length === 0 ? (
        <Paper sx={{ p: 4, textAlign: 'center' }}>
          <Typography variant="h6" gutterBottom>
            No Jobs Found
          </Typography>
          <Typography variant="body1" color="text.secondary" gutterBottom>
            Create your first job posting to start matching candidates
          </Typography>
          <Button
            variant="contained"
            onClick={() => navigate('/jobs/create')}
            sx={{ mt: 2 }}
          >
            Create Job
          </Button>
        </Paper>
      ) : (
        <Grid container spacing={3}>
          {jobs.map((job) => (
            <Grid item xs={12} md={6} lg={4} key={job.jobId || job.id}>
              <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
                <CardContent sx={{ flexGrow: 1 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                    <Typography variant="h6" component="div" sx={{ fontWeight: 600 }}>
                      {job.title}
                    </Typography>
                    <Chip 
                      label={job.status || 'Active'} 
                      color="success" 
                      size="small" 
                    />
                  </Box>

                  {job.department && (
                    <Typography variant="body2" color="primary" gutterBottom>
                      {job.department}
                    </Typography>
                  )}

                  <Typography 
                    variant="body2" 
                    color="text.secondary"
                    sx={{ 
                      mb: 2,
                      display: '-webkit-box',
                      WebkitLineClamp: 3,
                      WebkitBoxOrient: 'vertical',
                      overflow: 'hidden',
                    }}
                  >
                    {job.description}
                  </Typography>

                  <Typography variant="caption" color="text.secondary">
                    Created: {formatDate(job.createdAt)}
                  </Typography>

                  {/* Scoring Weights */}
                  {job.weightConfigJSON && (
                    <Box sx={{ mt: 2, pt: 2, borderTop: '1px solid', borderColor: 'divider' }}>
                      <Typography variant="caption" color="text.secondary" gutterBottom>
                        Scoring Weights:
                      </Typography>
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5, mt: 0.5 }}>
                        {(() => {
                          try {
                            const weights = typeof job.weightConfigJSON === 'string' 
                              ? JSON.parse(job.weightConfigJSON) 
                              : job.weightConfigJSON;
                            return Object.entries(weights).map(([key, value]) => (
                              <Chip 
                                key={key}
                                label={`${key}: ${(value * 100).toFixed(0)}%`}
                                size="small"
                                variant="outlined"
                              />
                            ));
                          } catch (e) {
                            return <Typography variant="caption">Default weights</Typography>;
                          }
                        })()}
                      </Box>
                    </Box>
                  )}
                </CardContent>

                <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
                  <Box>
                    <IconButton
                      size="small"
                      color="primary"
                      title="View Details"
                      onClick={() => navigate(`/jobs/${job.jobId || job.id}`)}
                    >
                      <ViewIcon />
                    </IconButton>
                    <IconButton
                      size="small"
                      color="info"
                      title="Edit"
                      onClick={() => navigate(`/jobs/${job.jobId || job.id}/edit`)}
                    >
                      <EditIcon />
                    </IconButton>
                    <IconButton
                      size="small"
                      color="error"
                      title="Delete"
                      onClick={() => handleDelete(job.jobId || job.id)}
                    >
                      <DeleteIcon />
                    </IconButton>
                  </Box>
                  <Button
                    size="small"
                    variant="contained"
                    startIcon={<ScoreIcon />}
                    onClick={() => navigate('/score', { state: { jobId: job.jobId || job.id } })}
                  >
                    Score Candidates
                  </Button>
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {/* Database Info */}
      <Paper sx={{ mt: 3, p: 3, backgroundColor: 'info.50' }}>
        <Typography variant="subtitle2" color="info.main" gutterBottom>
          📊 Database Table: Jobs
        </Typography>
        <Typography variant="body2">
          Stores job postings with title, description, requirements, and custom scoring weights.
          Each job can be matched against multiple candidates using the scoring algorithm.
        </Typography>
      </Paper>
    </Box>
  );
};

export default JobList;
