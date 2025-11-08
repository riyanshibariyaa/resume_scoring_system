import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import UploadResume from './pages/UploadResume';
import CreateJob from './pages/CreateJob';
import ScoringResults from './pages/ScoringResults';
import ResumeList from './pages/ResumeList';
import JobList from './pages/JobList';
import CandidateScoring from './pages/CandidateScoring';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
    success: {
      main: '#4caf50',
    },
  },
  typography: {
    fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
  },
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Layout>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/upload" element={<UploadResume />} />
            <Route path="/resumes" element={<ResumeList />} />
            <Route path="/jobs/create" element={<CreateJob />} />
            <Route path="/jobs" element={<JobList />} />
            <Route path="/score" element={<CandidateScoring />} />
            <Route path="/results/:scoreId" element={<ScoringResults />} />
          </Routes>
        </Layout>
      </Router>
    </ThemeProvider>
  );
}

export default App;
