import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';

const api = axios.create({
  baseURL: `${API_BASE_URL}/api/v1`,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const resumeService = {
  upload: (file) => {
    const formData = new FormData();
    formData.append('file', file);
    return api.post('/resumes', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },
  getAll: () => api.get('/resumes'),
  getById: (id) => api.get(`/resumes/${id}`),
};

export const jobService = {
  create: (jobData) => api.post('/jobs', jobData),
  getAll: () => api.get('/jobs'),
  getById: (id) => api.get(`/jobs/${id}`),
};

export const scoringService = {
  scoreCandidate: (data) => api.post('/scoring', data),
  getCandidateScores: (resumeId) => api.get(`/scoring/candidates/${resumeId}`),
};

export default api;
