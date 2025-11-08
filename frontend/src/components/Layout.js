import React from 'react';
import { 
  AppBar, 
  Toolbar, 
  Typography, 
  Container, 
  Button, 
  Box,
  IconButton,
  Menu,
  MenuItem,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Description as ResumeIcon,
  Work as JobIcon,
  Psychology as ScoreIcon,
  Dashboard as DashboardIcon,
} from '@mui/icons-material';
import { Link, useNavigate } from 'react-router-dom';

const Layout = ({ children }) => {
  const navigate = useNavigate();
  const [anchorEl, setAnchorEl] = React.useState(null);

  const handleMenu = (event) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const menuItems = [
    { label: 'Dashboard', path: '/', icon: <DashboardIcon /> },
    { label: 'Upload Resume', path: '/upload', icon: <ResumeIcon /> },
    { label: 'View Resumes', path: '/resumes', icon: <ResumeIcon /> },
    { label: 'Create Job', path: '/jobs/create', icon: <JobIcon /> },
    { label: 'View Jobs', path: '/jobs', icon: <JobIcon /> },
    { label: 'Score Candidate', path: '/score', icon: <ScoreIcon /> },
  ];

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
      <AppBar position="static" elevation={2}>
        <Toolbar>
          {/* Mobile Menu */}
          <Box sx={{ display: { xs: 'flex', md: 'none' } }}>
            <IconButton
              size="large"
              edge="start"
              color="inherit"
              aria-label="menu"
              onClick={handleMenu}
              sx={{ mr: 2 }}
            >
              <MenuIcon />
            </IconButton>
            <Menu
              id="menu-appbar"
              anchorEl={anchorEl}
              anchorOrigin={{
                vertical: 'top',
                horizontal: 'left',
              }}
              keepMounted
              transformOrigin={{
                vertical: 'top',
                horizontal: 'left',
              }}
              open={Boolean(anchorEl)}
              onClose={handleClose}
            >
              {menuItems.map((item) => (
                <MenuItem
                  key={item.path}
                  onClick={() => {
                    navigate(item.path);
                    handleClose();
                  }}
                >
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    {item.icon}
                    {item.label}
                  </Box>
                </MenuItem>
              ))}
            </Menu>
          </Box>

          {/* Logo/Title */}
          <Box 
            sx={{ 
              display: 'flex', 
              alignItems: 'center', 
              cursor: 'pointer',
              flexGrow: { xs: 1, md: 0 }
            }}
            onClick={() => navigate('/')}
          >
            <ScoreIcon sx={{ mr: 1, fontSize: 32 }} />
            <Typography 
              variant="h6" 
              component="div" 
              sx={{ 
                fontWeight: 600,
                display: { xs: 'none', sm: 'block' }
              }}
            >
              Resume Scoring System
            </Typography>
            <Typography 
              variant="h6" 
              component="div" 
              sx={{ 
                fontWeight: 600,
                display: { xs: 'block', sm: 'none' }
              }}
            >
              RScore
            </Typography>
          </Box>

          {/* Desktop Menu */}
          <Box sx={{ flexGrow: 1, display: { xs: 'none', md: 'flex' }, ml: 4, gap: 1 }}>
            <Button 
              color="inherit" 
              onClick={() => navigate('/')}
              startIcon={<DashboardIcon />}
            >
              Dashboard
            </Button>
            <Button 
              color="inherit" 
              onClick={() => navigate('/upload')}
              startIcon={<ResumeIcon />}
            >
              Upload
            </Button>
            <Button 
              color="inherit" 
              onClick={() => navigate('/resumes')}
              startIcon={<ResumeIcon />}
            >
              Resumes
            </Button>
            <Button 
              color="inherit" 
              onClick={() => navigate('/jobs')}
              startIcon={<JobIcon />}
            >
              Jobs
            </Button>
            <Button 
              color="inherit" 
              onClick={() => navigate('/score')}
              startIcon={<ScoreIcon />}
              sx={{ 
                backgroundColor: 'rgba(255, 255, 255, 0.1)',
                '&:hover': {
                  backgroundColor: 'rgba(255, 255, 255, 0.2)',
                }
              }}
            >
              Score
            </Button>
          </Box>

          {/* Create Job Button (Desktop) */}
          <Box sx={{ display: { xs: 'none', md: 'flex' } }}>
            <Button
              variant="contained"
              color="secondary"
              onClick={() => navigate('/jobs/create')}
              startIcon={<JobIcon />}
              sx={{
                backgroundColor: 'white',
                color: 'primary.main',
                '&:hover': {
                  backgroundColor: 'grey.100',
                },
              }}
            >
              Create Job
            </Button>
          </Box>
        </Toolbar>
      </AppBar>

      {/* Main Content */}
      <Container maxWidth="xl" sx={{ mt: 4, mb: 4, flexGrow: 1 }}>
        {children}
      </Container>

      {/* Footer */}
      <Box
        component="footer"
        sx={{
          py: 3,
          px: 2,
          mt: 'auto',
          backgroundColor: 'grey.100',
          borderTop: '1px solid',
          borderColor: 'divider',
        }}
      >
        <Container maxWidth="xl">
          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap' }}>
            <Typography variant="body2" color="text.secondary">
              © 2024 Resume Scoring System - NextGen Workspace
            </Typography>
            <Box sx={{ display: 'flex', gap: 2 }}>
              <Typography variant="body2" color="text.secondary">
                Version 1.0
              </Typography>
              <Typography variant="body2" color="text.secondary">
                AI-Powered Candidate Matching
              </Typography>
            </Box>
          </Box>
        </Container>
      </Box>
    </Box>
  );
};

export default Layout;
