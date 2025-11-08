import React, { useState } from 'react';
import { Box, Button, Typography, Alert, LinearProgress } from '@mui/material';
import { resumeService } from '../services/api';

const UploadResume = () => {
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [message, setMessage] = useState(null);

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
    setMessage(null);
  };

  const handleUpload = async () => {
    if (!file) {
      setMessage({ type: 'error', text: 'Please select a file' });
      return;
    }

    setUploading(true);
    try {
      await resumeService.upload(file);
      setMessage({ type: 'success', text: 'Resume uploaded successfully!' });
      setFile(null);
    } catch (error) {
      setMessage({ type: 'error', text: 'Upload failed: ' + error.message });
    } finally {
      setUploading(false);
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>Upload Resume</Typography>
      <Box sx={{ mt: 3 }}>
        <input type="file" accept=".pdf,.docx,.txt" onChange={handleFileChange} />
        <Button variant="contained" onClick={handleUpload} disabled={uploading} sx={{ ml: 2 }}>
          Upload
        </Button>
      </Box>
      {uploading && <LinearProgress sx={{ mt: 2 }} />}
      {message && <Alert severity={message.type} sx={{ mt: 2 }}>{message.text}</Alert>}
    </Box>
  );
};

export default UploadResume;
