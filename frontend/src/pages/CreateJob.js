import React, { useState } from 'react';
import { Box, TextField, Button, Typography, Alert } from '@mui/material';
import { jobService } from '../services/api';

const CreateJob = () => {
  const [formData, setFormData] = useState({ title: '', description: '' });
  const [message, setMessage] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      await jobService.create(formData);
      setMessage({ type: 'success', text: 'Job created successfully!' });
      setFormData({ title: '', description: '' });
    } catch (error) {
      setMessage({ type: 'error', text: 'Failed to create job: ' + error.message });
    }
  };

  return (
    <Box component="form" onSubmit={handleSubmit}>
      <Typography variant="h4" gutterBottom>Create Job</Typography>
      <TextField fullWidth label="Job Title" value={formData.title}
        onChange={(e) => setFormData({ ...formData, title: e.target.value })}
        margin="normal" required />
      <TextField fullWidth label="Job Description" value={formData.description}
        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
        margin="normal" multiline rows={4} required />
      <Button type="submit" variant="contained" sx={{ mt: 2 }}>Create Job</Button>
      {message && <Alert severity={message.type} sx={{ mt: 2 }}>{message.text}</Alert>}
    </Box>
  );
};

export default CreateJob;
