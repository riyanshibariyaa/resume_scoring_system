import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';

const api = axios.create({
  baseURL: `${API_BASE_URL}/api/v1`,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 120000, // 2 minutes for large file uploads
});

// Add request interceptor for logging
api.interceptors.request.use(
  (config) => {
    console.log(`🚀 API Request: ${config.method.toUpperCase()} ${config.url}`);
    return config;
  },
  (error) => {
    console.error('❌ API Request Error:', error);
    return Promise.reject(error);
  }
);

// Add response interceptor for error handling
api.interceptors.response.use(
  (response) => {
    console.log(`✅ API Response: ${response.config.url}`, response.data);
    return response;
  },
  (error) => {
    console.error('❌ API Response Error:', error.response || error.message);
    const errorMessage = error.response?.data?.message || error.response?.data?.error || error.message;
    return Promise.reject(new Error(errorMessage));
  }
);

// ====================
// RESUME SERVICE
// ====================
export const resumeService = {
  /**
   * Upload resume file - Step 1 of workflow
   * This triggers: Parsing → NLP → Embeddings
   */
  upload: async (file) => {
    const formData = new FormData();
    formData.append('file', file);
    
    const response = await api.post('/resumes', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    
    return response.data;
  },

  /**
   * Get all resumes with their parsed data
   */
  getAll: async () => {
    const response = await api.get('/resumes');
    return response.data;
  },

  /**
   * Get single resume with full details
   */
  getById: async (id) => {
    const response = await api.get(`/resumes/${id}`);
    return response.data;
  },

  /**
   * Get parsed data for a resume
   */
  getParsedData: async (resumeId) => {
    const response = await api.get(`/resumes/${resumeId}/parsed`);
    return response.data;
  },

  /**
   * Delete a resume
   */
  delete: async (id) => {
    const response = await api.delete(`/resumes/${id}`);
    return response.data;
  },
};

// ====================
// JOB SERVICE
// ====================
export const jobService = {
  /**
   * Create a new job posting
   */
  create: async (jobData) => {
    const response = await api.post('/jobs', {
      title: jobData.title,
      department: jobData.department || null,
      description: jobData.description,
      requirementsText: jobData.requirements || jobData.description,
      weightConfigJSON: jobData.weights ? JSON.stringify(jobData.weights) : undefined,
    });
    return response.data;
  },

  /**
   * Get all jobs
   */
  getAll: async () => {
    const response = await api.get('/jobs');
    return response.data;
  },

  /**
   * Get single job by ID
   */
  getById: async (id) => {
    const response = await api.get(`/jobs/${id}`);
    return response.data;
  },

  /**
   * Update job
   */
  update: async (id, jobData) => {
    const response = await api.put(`/jobs/${id}`, jobData);
    return response.data;
  },

  /**
   * Delete job
   */
  delete: async (id) => {
    const response = await api.delete(`/jobs/${id}`);
    return response.data;
  },
};

// ====================
// SCORING SERVICE
// ====================
export const scoringService = {
  /**
   * Score a candidate against a job - Step 4 of workflow
   * This creates Scores + MatchEvidence records
   */
  scoreCandidate: async (resumeId, jobId, customWeights = null) => {
    const response = await api.post('/scoring', {
      resumeId,
      jobId,
      weights: customWeights,
    });
    return response.data;
  },

  /**
   * Get all scores for a specific resume
   */
  getCandidateScores: async (resumeId) => {
    const response = await api.get(`/scoring/candidates/${resumeId}`);
    return response.data;
  },

  /**
   * Get a specific score with evidence
   */
  getScoreById: async (scoreId) => {
    const response = await api.get(`/scoring/${scoreId}`);
    return response.data;
  },

  /**
   * Get top candidates for a job
   */
  getTopCandidates: async (jobId, limit = 10) => {
    const response = await api.get(`/scoring/jobs/${jobId}/top?limit=${limit}`);
    return response.data;
  },

  /**
   * Batch score multiple candidates
   */
  batchScore: async (resumeIds, jobId) => {
    const response = await api.post('/scoring/batch', {
      resumeIds,
      jobId,
    });
    return response.data;
  },
};

// ====================
// ANALYTICS SERVICE
// ====================
export const analyticsService = {
  /**
   * Get dashboard statistics
   */
  getDashboardStats: async () => {
    const response = await api.get('/analytics/dashboard');
    return response.data;
  },

  /**
   * Get job statistics
   */
  getJobStats: async (jobId) => {
    const response = await api.get(`/analytics/jobs/${jobId}`);
    return response.data;
  },
};

// ====================
// HEALTH CHECK
// ====================
export const healthService = {
  /**
   * Check API Gateway health
   */
  checkHealth: async () => {
    const response = await api.get('/health');
    return response.data;
  },

  /**
   * Check all microservices health
   */
  checkAllServices: async () => {
    const services = [
      { name: 'API Gateway', url: `${API_BASE_URL}/health` },
      { name: 'Parsing', url: 'http://localhost:5001/health' },
      { name: 'NLP', url: 'http://localhost:5002/health' },
      { name: 'Embedding', url: 'http://localhost:5003/health' },
      { name: 'Scoring', url: 'http://localhost:5004/health' },
    ];

    const results = await Promise.allSettled(
      services.map(async (service) => {
        try {
          const response = await axios.get(service.url, { timeout: 5000 });
          return { ...service, status: 'healthy', data: response.data };
        } catch (error) {
          return { ...service, status: 'unhealthy', error: error.message };
        }
      })
    );

    return results.map(result => result.value);
  },
};

export default api;
