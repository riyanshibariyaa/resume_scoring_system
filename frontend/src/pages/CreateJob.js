import React, { useState } from 'react';
import {
  Box,
  Button,
  TextField,
  Typography,
  Alert,
  Paper,
  Grid,
  Slider,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Card,
  CardContent,
  Divider,
} from '@mui/material';
import { Add as AddIcon, Work as JobIcon } from '@mui/icons-material';
import { jobService } from '../services/api';
import { useNavigate } from 'react-router-dom';

const DEFAULT_WEIGHTS = {
  skills: 0.30,
  experience: 0.25,
  domain: 0.15,
  education: 0.10,
  certifications: 0.10,
  recency: 0.10,
};

const CreateJob = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    title: '',
    department: '',
    description: '',
    requirements: '',
  });
  const [weights, setWeights] = useState(DEFAULT_WEIGHTS);
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState(null);
  const [createdJob, setCreatedJob] = useState(null);

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
    setMessage(null);
  };

  const handleWeightChange = (criterion, value) => {
    const newWeights = { ...weights, [criterion]: value / 100 };
    
    // Normalize weights to sum to 1.0
    const sum = Object.values(newWeights).reduce((a, b) => a + b, 0);
    const normalized = {};
    Object.keys(newWeights).forEach(key => {
      normalized[key] = newWeights[key] / sum;
    });
    
    setWeights(normalized);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    // Validation
    if (!formData.title.trim()) {
      setMessage({ type: 'error', text: 'Job title is required' });
      return;
    }
    if (!formData.description.trim()) {
      setMessage({ type: 'error', text: 'Job description is required' });
      return;
    }

    setSubmitting(true);
    setMessage(null);

    try {
      const jobData = {
        title: formData.title,
        department: formData.department,
        description: formData.description,
        requirements: formData.requirements || formData.description,
        weights: weights,
      };

      const result = await jobService.create(jobData);
      
      setCreatedJob(result);
      setMessage({ 
        type: 'success', 
        text: `Job created successfully! Job ID: ${result.jobId || result.id}` 
      });

      // Reset form
      setFormData({
        title: '',
        department: '',
        description: '',
        requirements: '',
      });
      setWeights(DEFAULT_WEIGHTS);

    } catch (error) {
      console.error('Job creation error:', error);
      setMessage({ type: 'error', text: 'Failed to create job: ' + error.message });
    } finally {
      setSubmitting(false);
    }
  };

  const weightsSum = Object.values(weights).reduce((a, b) => a + b, 0);

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ mb: 3, fontWeight: 600 }}>
        Create Job Posting
      </Typography>

      <Grid container spacing={3}>
        {/* Job Details Form */}
        <Grid item xs={12} md={7}>
          <Paper sx={{ p: 3 }}>
            <Typography variant="h6" gutterBottom>
              Job Details
            </Typography>
            
            <Box component="form" onSubmit={handleSubmit}>
              <TextField
                fullWidth
                label="Job Title"
                name="title"
                value={formData.title}
                onChange={handleInputChange}
                required
                placeholder="e.g., Senior Python Developer"
                sx={{ mb: 2 }}
              />

              <TextField
                fullWidth
                label="Department"
                name="department"
                value={formData.department}
                onChange={handleInputChange}
                placeholder="e.g., Engineering, Product, Marketing"
                sx={{ mb: 2 }}
              />

              <TextField
                fullWidth
                label="Job Description"
                name="description"
                value={formData.description}
                onChange={handleInputChange}
                required
                multiline
                rows={8}
                placeholder="Describe the role, responsibilities, and what you're looking for..."
                sx={{ mb: 2 }}
              />

              <TextField
                fullWidth
                label="Key Requirements (Optional)"
                name="requirements"
                value={formData.requirements}
                onChange={handleInputChange}
                multiline
                rows={4}
                placeholder="List specific skills, experience level, education requirements..."
                helperText="If not provided, we'll use the job description for matching"
                sx={{ mb: 3 }}
              />
            </Box>
          </Paper>
        </Grid>

        {/* Scoring Weights */}
        <Grid item xs={12} md={5}>
          <Paper sx={{ p: 3, mb: 3 }}>
            <Typography variant="h6" gutterBottom>
              Scoring Weights
            </Typography>
            <Typography variant="body2" color="text.secondary" gutterBottom sx={{ mb: 2 }}>
              Customize how candidates are scored against this job. Total must equal 100%.
            </Typography>

            {Object.entries(weights).map(([criterion, weight]) => (
              <Box key={criterion} sx={{ mb: 2 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                  <Typography variant="body2" sx={{ textTransform: 'capitalize' }}>
                    {criterion.replace('_', ' ')}
                  </Typography>
                  <Typography variant="body2" fontWeight="bold">
                    {(weight * 100).toFixed(0)}%
                  </Typography>
                </Box>
                <Slider
                  value={weight * 100}
                  onChange={(e, value) => handleWeightChange(criterion, value)}
                  min={0}
                  max={100}
                  step={5}
                  valueLabelDisplay="auto"
                  valueLabelFormat={(value) => `${value}%`}
                />
              </Box>
            ))}

            <Divider sx={{ my: 2 }} />
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Typography variant="body1" fontWeight="bold">
                Total:
              </Typography>
              <Typography 
                variant="body1" 
                fontWeight="bold"
                color={Math.abs(weightsSum - 1.0) < 0.01 ? 'success.main' : 'error.main'}
              >
                {(weightsSum * 100).toFixed(0)}%
              </Typography>
            </Box>

            <Button
              fullWidth
              variant="outlined"
              onClick={() => setWeights(DEFAULT_WEIGHTS)}
              sx={{ mt: 2 }}
            >
              Reset to Default
            </Button>
          </Paper>

          <Paper sx={{ p: 3, backgroundColor: 'info.50' }}>
            <Typography variant="subtitle2" color="info.main" gutterBottom>
              💡 Scoring Criteria Explained
            </Typography>
            <Box component="ul" sx={{ pl: 2, fontSize: '0.875rem' }}>
              <li><strong>Skills:</strong> Match of technical & soft skills</li>
              <li><strong>Experience:</strong> Years of relevant experience</li>
              <li><strong>Domain:</strong> Industry knowledge match</li>
              <li><strong>Education:</strong> Degree & certifications</li>
              <li><strong>Certifications:</strong> Professional credentials</li>
              <li><strong>Recency:</strong> How recent the experience is</li>
            </Box>
          </Paper>
        </Grid>

        {/* Submit Button */}
        <Grid item xs={12}>
          <Button
            variant="contained"
            size="large"
            fullWidth
            onClick={handleSubmit}
            disabled={submitting || !formData.title || !formData.description}
            startIcon={<AddIcon />}
          >
            {submitting ? 'Creating Job...' : 'Create Job Posting'}
          </Button>
        </Grid>

        {/* Success/Error Messages */}
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

        {/* Success Card */}
        {createdJob && (
          <Grid item xs={12}>
            <Card sx={{ backgroundColor: 'success.50' }}>
              <CardContent>
                <Typography variant="h6" gutterBottom color="success.main">
                  ✅ Job Created Successfully!
                </Typography>
                <Typography variant="body1" gutterBottom>
                  <strong>Title:</strong> {createdJob.title}
                </Typography>
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  The job has been saved to the database and is ready for candidate matching.
                </Typography>
                <Box sx={{ mt: 2, display: 'flex', gap: 2 }}>
                  <Button
                    variant="contained"
                    color="primary"
                    onClick={() => navigate('/score')}
                  >
                    Score Candidates →
                  </Button>
                  <Button
                    variant="outlined"
                    onClick={() => navigate('/jobs')}
                  >
                    View All Jobs
                  </Button>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        )}
      </Grid>
    </Box>
  );
};

export default CreateJob;
