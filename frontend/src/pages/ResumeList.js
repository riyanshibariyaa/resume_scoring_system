import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Button,
  IconButton,
  LinearProgress,
  Alert,
} from '@mui/material';
import {
  Visibility as ViewIcon,
  Delete as DeleteIcon,
  Psychology as ScoreIcon,
} from '@mui/icons-material';
import { resumeService } from '../services/api';
import { useNavigate } from 'react-router-dom';

const ResumeList = () => {
  const navigate = useNavigate();
  const [resumes, setResumes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState(null);

  useEffect(() => {
    loadResumes();
  }, []);

  const loadResumes = async () => {
    try {
      setLoading(true);
      const data = await resumeService.getAll();
      setResumes(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error('Error loading resumes:', error);
      setMessage({ type: 'error', text: 'Failed to load resumes: ' + error.message });
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this resume?')) {
      return;
    }

    try {
      await resumeService.delete(id);
      setMessage({ type: 'success', text: 'Resume deleted successfully' });
      loadResumes();
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to delete resume: ' + error.message });
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
          All Resumes ({resumes.length})
        </Typography>
        <Button
          variant="contained"
          onClick={() => navigate('/upload')}
        >
          Upload New Resume
        </Button>
      </Box>

      {message && (
        <Alert severity={message.type} onClose={() => setMessage(null)} sx={{ mb: 3 }}>
          {message.text}
        </Alert>
      )}

      {resumes.length === 0 ? (
        <Paper sx={{ p: 4, textAlign: 'center' }}>
          <Typography variant="h6" gutterBottom>
            No Resumes Found
          </Typography>
          <Typography variant="body1" color="text.secondary" gutterBottom>
            Upload your first resume to get started with candidate scoring
          </Typography>
          <Button
            variant="contained"
            onClick={() => navigate('/upload')}
            sx={{ mt: 2 }}
          >
            Upload Resume
          </Button>
        </Paper>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell><strong>Candidate Name</strong></TableCell>
                <TableCell><strong>Email</strong></TableCell>
                <TableCell><strong>Phone</strong></TableCell>
                <TableCell><strong>Format</strong></TableCell>
                <TableCell><strong>Status</strong></TableCell>
                <TableCell><strong>Uploaded</strong></TableCell>
                <TableCell align="right"><strong>Actions</strong></TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {resumes.map((resume) => (
                <TableRow key={resume.resumeId || resume.id}>
                  <TableCell>{resume.candidateName || 'Unnamed'}</TableCell>
                  <TableCell>{resume.email || 'N/A'}</TableCell>
                  <TableCell>{resume.phone || 'N/A'}</TableCell>
                  <TableCell>
                    <Chip label={resume.fileFormat || 'PDF'} size="small" />
                  </TableCell>
                  <TableCell>
                    <Chip 
                      label={resume.parseStatus || 'Parsed'} 
                      color={resume.parseStatus === 'Complete' || resume.parseStatus === 'Parsed' ? 'success' : 'warning'}
                      size="small" 
                    />
                  </TableCell>
                  <TableCell>{formatDate(resume.createdAt)}</TableCell>
                  <TableCell align="right">
                    <IconButton
                      size="small"
                      color="primary"
                      title="View Details"
                      onClick={() => navigate(`/resumes/${resume.resumeId || resume.id}`)}
                    >
                      <ViewIcon />
                    </IconButton>
                    <IconButton
                      size="small"
                      color="secondary"
                      title="Score Candidate"
                      onClick={() => navigate('/score', { state: { resumeId: resume.resumeId || resume.id } })}
                    >
                      <ScoreIcon />
                    </IconButton>
                    <IconButton
                      size="small"
                      color="error"
                      title="Delete"
                      onClick={() => handleDelete(resume.resumeId || resume.id)}
                    >
                      <DeleteIcon />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Database Info */}
      <Paper sx={{ mt: 3, p: 3, backgroundColor: 'info.50' }}>
        <Typography variant="subtitle2" color="info.main" gutterBottom>
          📊 Database Tables Involved
        </Typography>
        <Typography variant="body2">
          <strong>Resumes:</strong> Stores resume files and metadata<br />
          <strong>ParsedData (CandidateProfiles):</strong> Stores extracted text and structured data<br />
          <strong>Embeddings:</strong> Stores semantic vectors for matching
        </Typography>
      </Paper>
    </Box>
  );
};

export default ResumeList;
