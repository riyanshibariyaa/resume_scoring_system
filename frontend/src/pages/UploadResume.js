import React, { useState } from 'react';
import {
  Box,
  Button,
  Typography,
  Alert,
  LinearProgress,
  Paper,
  Card,
  CardContent,
  Chip,
  Stepper,
  Step,
  StepLabel,
} from '@mui/material';
import {
  CloudUpload as UploadIcon,
  CheckCircle as SuccessIcon,
  Error as ErrorIcon,
} from '@mui/icons-material';
import { resumeService } from '../services/api';
import { useNavigate } from 'react-router-dom';

const WORKFLOW_STEPS = [
  'Upload Resume',
  'Parse Document',
  'Extract Data (NLP)',
  'Generate Embeddings',
  'Ready for Scoring',
];

const UploadResume = () => {
  const navigate = useNavigate();
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [activeStep, setActiveStep] = useState(0);
  const [message, setMessage] = useState(null);
  const [uploadedResume, setUploadedResume] = useState(null);

  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0];
    if (selectedFile) {
      const validTypes = ['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/plain'];
      if (!validTypes.includes(selectedFile.type)) {
        setMessage({ type: 'error', text: 'Please upload PDF, DOCX, or TXT files only' });
        return;
      }
      if (selectedFile.size > 10 * 1024 * 1024) {
        setMessage({ type: 'error', text: 'File size must be less than 10MB' });
        return;
      }
      setFile(selectedFile);
      setMessage(null);
      setActiveStep(0);
    }
  };

  const handleUpload = async () => {
    if (!file) {
      setMessage({ type: 'error', text: 'Please select a file' });
      return;
    }

    setUploading(true);
    setMessage(null);
    setActiveStep(0);

    try {
      // Step 1: Upload file
      setUploadProgress(20);
      setActiveStep(0);
      await new Promise(resolve => setTimeout(resolve, 500));

      // Step 2: Parse document
      setUploadProgress(40);
      setActiveStep(1);
      const uploadResult = await resumeService.upload(file);
      
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Step 3: NLP Extraction
      setUploadProgress(60);
      setActiveStep(2);
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Step 4: Generate embeddings
      setUploadProgress(80);
      setActiveStep(3);
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Step 5: Complete
      setUploadProgress(100);
      setActiveStep(4);
      
      setUploadedResume(uploadResult);
      setMessage({ 
        type: 'success', 
        text: `Resume uploaded successfully! Resume ID: ${uploadResult.resumeId || uploadResult.id}` 
      });
      setFile(null);
      
      // Reset file input
      document.getElementById('file-input').value = '';
      
    } catch (error) {
      console.error('Upload error:', error);
      setMessage({ type: 'error', text: 'Upload failed: ' + error.message });
      setUploadProgress(0);
      setActiveStep(0);
    } finally {
      setUploading(false);
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    const droppedFile = e.dataTransfer.files[0];
    if (droppedFile) {
      handleFileChange({ target: { files: [droppedFile] } });
    }
  };

  const handleDragOver = (e) => {
    e.preventDefault();
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom sx={{ mb: 3, fontWeight: 600 }}>
        Upload Resume
      </Typography>

      {/* Workflow Stepper */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom>
          Upload Workflow
        </Typography>
        <Stepper activeStep={activeStep} alternativeLabel>
          {WORKFLOW_STEPS.map((label, index) => (
            <Step key={label} completed={activeStep > index}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>
      </Paper>

      {/* Upload Area */}
      <Paper
        sx={{
          p: 4,
          mb: 3,
          border: '2px dashed',
          borderColor: file ? 'primary.main' : 'grey.400',
          backgroundColor: file ? 'primary.50' : 'grey.50',
          textAlign: 'center',
          cursor: 'pointer',
          transition: 'all 0.3s',
          '&:hover': {
            borderColor: 'primary.main',
            backgroundColor: 'primary.50',
          },
        }}
        onDrop={handleDrop}
        onDragOver={handleDragOver}
        onClick={() => document.getElementById('file-input').click()}
      >
        <UploadIcon sx={{ fontSize: 64, color: file ? 'primary.main' : 'grey.400', mb: 2 }} />
        <Typography variant="h6" gutterBottom>
          {file ? file.name : 'Click or drag to upload resume'}
        </Typography>
        <Typography variant="body2" color="text.secondary" gutterBottom>
          Supported formats: PDF, DOCX, TXT (Max 10MB)
        </Typography>
        {file && (
          <Box sx={{ mt: 2 }}>
            <Chip 
              label={`${(file.size / 1024 / 1024).toFixed(2)} MB`} 
              color="primary" 
              size="small" 
            />
          </Box>
        )}
        <input
          id="file-input"
          type="file"
          accept=".pdf,.docx,.txt"
          onChange={handleFileChange}
          style={{ display: 'none' }}
        />
      </Paper>

      {/* Upload Button */}
      <Box sx={{ mb: 3 }}>
        <Button
          variant="contained"
          size="large"
          onClick={handleUpload}
          disabled={!file || uploading}
          startIcon={<UploadIcon />}
          fullWidth
        >
          {uploading ? 'Processing...' : 'Upload and Process Resume'}
        </Button>
      </Box>

      {/* Progress Bar */}
      {uploading && (
        <Box sx={{ mb: 3 }}>
          <LinearProgress variant="determinate" value={uploadProgress} />
          <Typography variant="body2" color="text.secondary" sx={{ mt: 1, textAlign: 'center' }}>
            {uploadProgress}% Complete - {WORKFLOW_STEPS[activeStep]}
          </Typography>
        </Box>
      )}

      {/* Success/Error Messages */}
      {message && (
        <Alert 
          severity={message.type} 
          icon={message.type === 'success' ? <SuccessIcon /> : <ErrorIcon />}
          sx={{ mb: 3 }}
          onClose={() => setMessage(null)}
        >
          {message.text}
        </Alert>
      )}

      {/* Next Steps Card */}
      {uploadedResume && (
        <Card sx={{ mb: 3, backgroundColor: 'success.50' }}>
          <CardContent>
            <Typography variant="h6" gutterBottom color="success.main">
              ✅ Resume Successfully Processed!
            </Typography>
            <Typography variant="body1" gutterBottom>
              Your resume has been:
            </Typography>
            <Box component="ul" sx={{ pl: 2 }}>
              <li>✅ Uploaded to storage</li>
              <li>✅ Parsed and text extracted</li>
              <li>✅ Analyzed with NLP (skills, experience, education)</li>
              <li>✅ Embeddings generated for semantic matching</li>
            </Box>
            <Box sx={{ mt: 2, display: 'flex', gap: 2 }}>
              <Button
                variant="contained"
                color="primary"
                onClick={() => navigate('/score')}
              >
                Score Against Job →
              </Button>
              <Button
                variant="outlined"
                onClick={() => navigate('/resumes')}
              >
                View All Resumes
              </Button>
            </Box>
          </CardContent>
        </Card>
      )}

      {/* Info Box */}
      <Paper sx={{ p: 3, backgroundColor: 'info.50' }}>
        <Typography variant="h6" gutterBottom color="info.main">
          📋 What Happens After Upload?
        </Typography>
        <Box component="ol" sx={{ pl: 2 }}>
          <li><strong>Parsing:</strong> We extract text from your PDF/DOCX file</li>
          <li><strong>NLP Analysis:</strong> AI identifies skills, experience, education, and certifications</li>
          <li><strong>Embeddings:</strong> Creates semantic vectors for intelligent matching</li>
          <li><strong>Storage:</strong> All data saved to database (Resumes, ParsedData, Embeddings tables)</li>
          <li><strong>Ready to Score:</strong> Can now be matched against any job posting!</li>
        </Box>
      </Paper>
    </Box>
  );
};

export default UploadResume;
