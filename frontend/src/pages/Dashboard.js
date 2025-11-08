import React, { useState, useEffect } from 'react';
import { Grid, Card, CardContent, Typography, CircularProgress } from '@mui/material';
import { resumeService, jobService } from '../services/api';

const Dashboard = () => {
  const [stats, setStats] = useState({ resumes: 0, jobs: 0, loading: true });

  useEffect(() => {
    Promise.all([resumeService.getAll(), jobService.getAll()])
      .then(([resumesRes, jobsRes]) => {
        setStats({
          resumes: resumesRes.data.length,
          jobs: jobsRes.data.length,
          loading: false
        });
      })
      .catch(err => {
        console.error('Error loading stats:', err);
        setStats(prev => ({ ...prev, loading: false }));
      });
  }, []);

  if (stats.loading) return <CircularProgress />;

  return (
    <Grid container spacing={3}>
      <Grid item xs={12}>
        <Typography variant="h4" gutterBottom>Dashboard</Typography>
      </Grid>
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h5" component="div">{stats.resumes}</Typography>
            <Typography color="text.secondary">Total Resumes</Typography>
          </CardContent>
        </Card>
      </Grid>
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h5" component="div">{stats.jobs}</Typography>
            <Typography color="text.secondary">Active Jobs</Typography>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
};

export default Dashboard;
