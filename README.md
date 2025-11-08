# AI-Powered Resume Parsing & Candidate Scoring System

## 🎯 Overview

A complete AI-driven system for parsing resumes, extracting candidate information, and scoring candidates against job requirements.

## 🏗️ Architecture

```
┌─────────────────┐
│   React UI      │ (Upload, Dashboard, Scoring)
└────────┬────────┘
         │
┌────────▼────────┐
│ .NET Core API   │ (Gateway, Auth, Orchestration)
│    Gateway      │
└────────┬────────┘
         │
    ┌────┴────┬──────────┬──────────┐
    │         │          │          │
┌───▼───┐ ┌──▼──┐  ┌────▼───┐ ┌───▼────┐
│Parsing│ │ NLP │  │Embedding│ │Scoring │
│Service│ │Svc  │  │ Service │ │ Engine │
└───┬───┘ └──┬──┘  └────┬───┘ └───┬────┘
    │        │          │         │
    └────────┴──────────┴─────────┘
                   │
         ┌─────────┴──────────┐
         │                    │
    ┌────▼────┐          ┌───▼────┐
    │ MS SQL  │          │  Blob  │
    │ Server  │          │Storage │
    └─────────┘          └────────┘
```

## 🚀 Tech Stack

### Backend
- **API Gateway**: .NET Core 8.0
- **Microservices**: Python 3.10+
- **NLP**: spaCy, Transformers (HuggingFace)
- **ML**: scikit-learn, sentence-transformers
- **Document Processing**: PyMuPDF, python-docx, pdfminer
- **OCR**: Tesseract (fallback)

### Frontend
- **Framework**: React 18+ with TypeScript
- **State Management**: React Context + Hooks
- **UI Library**: Material-UI / Tailwind CSS
- **HTTP Client**: Axios

### Database & Storage
- **Primary DB**: MS SQL Server 2019+
- **Vector Store**: pgvector or in-memory (for CPU-only setup)
- **Blob Storage**: Local filesystem (MinIO for production)

### Deployment
- **Development**: Docker Compose
- **Production**: Azure PaaS or Kubernetes

## 📦 Project Structure

```
resume-scoring-system/
├── backend/
│   ├── api-gateway/              # .NET Core API Gateway
│   │   ├── Controllers/
│   │   ├── Models/
│   │   ├── Services/
│   │   └── Program.cs
│   └── services/
│       ├── parsing/              # Resume parsing service
│       ├── nlp/                  # NLP extraction service
│       ├── embedding/            # Embedding & similarity service
│       └── scoring/              # Scoring engine
├── frontend/                     # React application
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/
│   │   └── App.tsx
│   └── package.json
├── database/
│   ├── migrations/               # SQL migration scripts
│   └── seed/                     # Sample data
├── models/                       # Pre-trained ML models
├── docs/                         # Documentation
├── deployment/                   # Docker, K8s configs
└── docker-compose.yml
```

## 🔧 Prerequisites

### Required Software
- **Python**: 3.10 or higher
- **.NET SDK**: 8.0 or higher
- **Node.js**: 18.x or higher
- **SQL Server**: 2019+ (or SQL Server Express for development)
- **Docker**: Latest version (optional, for containerized deployment)

### System Requirements
- **OS**: Windows 10/11, Linux, or macOS
- **RAM**: 8GB minimum, 16GB recommended
- **CPU**: Multi-core processor (no GPU required, optimized for CPU)
- **Disk Space**: 10GB for dependencies and models

## 📥 Installation

### 1. Clone and Setup

```bash
cd resume-scoring-system
```

### 2. Backend Setup

#### Python Services

```bash
cd backend/services/parsing
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Download required models (CPU-optimized)
python -m spacy download en_core_web_sm
```

Repeat for each Python service (nlp, embedding, scoring).

#### .NET API Gateway

```bash
cd backend/api-gateway
dotnet restore
dotnet build
```

### 3. Frontend Setup

```bash
cd frontend
npm install
```

### 4. Database Setup

```bash
# Connect to SQL Server and run migrations
cd database/migrations
sqlcmd -S localhost -U sa -P YourPassword -i 001_initial_schema.sql
```

### 5. Configuration

Create `.env` files in each service directory:

**backend/api-gateway/.env**
```
DATABASE_CONNECTION=Server=localhost;Database=ResumeScoring;User Id=sa;Password=YourPassword;
JWT_SECRET=your-secret-key-here
CORS_ORIGINS=http://localhost:3000
```

**backend/services/parsing/.env**
```
BLOB_STORAGE_PATH=./storage
API_GATEWAY_URL=http://localhost:5000
```

## 🏃 Running the Application

### Development Mode

#### 1. Start Database
```bash
# If using Docker for SQL Server
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourPassword123!" -p 1433:1433 --name sql_server -d mcr.microsoft.com/mssql/server:2019-latest
```

#### 2. Start Backend Services

**Terminal 1 - API Gateway**
```bash
cd backend/api-gateway
dotnet run
```

**Terminal 2 - Parsing Service**
```bash
cd backend/services/parsing
python app.py
```

**Terminal 3 - NLP Service**
```bash
cd backend/services/nlp
python app.py
```

**Terminal 4 - Embedding Service**
```bash
cd backend/services/embedding
python app.py
```

**Terminal 5 - Scoring Service**
```bash
cd backend/services/scoring
python app.py
```

#### 3. Start Frontend
```bash
cd frontend
npm start
```

### Production Mode

```bash
docker-compose up -d
```

## 🌐 Access Points

- **Frontend UI**: http://localhost:3000
- **API Gateway**: http://localhost:5000
- **API Documentation**: http://localhost:5000/swagger

## 📊 Key Features

### Resume Parsing
- ✅ PDF, DOCX, TXT format support
- ✅ OCR fallback for scanned documents
- ✅ Section detection (Experience, Education, Skills, etc.)
- ✅ Contact information extraction

### NLP Extraction
- ✅ Named Entity Recognition (Skills, Companies, Roles)
- ✅ Skill normalization using O*NET/ESCO ontology
- ✅ Experience timeline extraction
- ✅ Education and certification detection

### Candidate Scoring
- ✅ Weighted scoring algorithm (Skills, Experience, Domain, Education, Certifications, Recency)
- ✅ Semantic similarity matching
- ✅ Explainable AI with evidence spans
- ✅ Configurable job requirements

### API Endpoints

```
POST   /api/v1/resumes           - Upload resume
POST   /api/v1/jobs              - Create/update job description
POST   /api/v1/score             - Generate candidate score
GET    /api/v1/candidates/{id}   - Get candidate profile
GET    /api/v1/candidates/{id}/scores - Get scoring history
POST   /api/v1/feedback          - Submit recruiter feedback
```

## 🧪 Testing

### Unit Tests
```bash
# Python services
cd backend/services/parsing
pytest tests/

# .NET API
cd backend/api-gateway
dotnet test
```

### Integration Tests
```bash
# Run end-to-end tests
cd tests/integration
pytest test_e2e.py
```

### Performance Testing
```bash
# Load testing with sample resumes
python scripts/performance_test.py --resumes 1000
```

## 📈 Model Performance

- **Extraction F1-Score**: ≥ 0.90
- **Ranking Correlation (Kendall τ)**: ≥ 0.8
- **Parse Success Rate**: ≥ 95%
- **Scoring Latency (P95)**: < 30s per resume

## 🔒 Security

- Azure AD / OAuth2 authentication
- JWT-based authorization
- PII field-level encryption
- TLS 1.2+ for data in transit
- RBAC for access control
- Audit logging for all operations

## 🔄 CI/CD

The project includes:
- GitHub Actions / Azure DevOps pipelines
- Automated testing on PR
- Docker image builds
- Terraform/Bicep IaC templates

## 📚 Documentation

Detailed documentation available in `/docs`:
- API Reference
- Architecture Guide
- Model Training Guide
- Deployment Guide
- User Manual

## 🐛 Troubleshooting

### Common Issues

**Issue**: Models not loading
```bash
# Re-download spaCy models
python -m spacy download en_core_web_lg
```

**Issue**: SQL Server connection failed
```bash
# Check connection string in .env
# Verify SQL Server is running
docker ps | grep sql_server
```

**Issue**: Frontend not connecting to API
```bash
# Check CORS settings in api-gateway
# Verify API_GATEWAY_URL in frontend .env
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

Proprietary - NextGen Workspace

## 👥 Team

- **Project Lead**: [Your Name]
- **AI/ML Engineer**: [Team Member]
- **Backend Developer**: [Team Member]
- **Frontend Developer**: [Team Member]

## 📞 Support

For issues and questions:
- Email: support@nextgenworkspace.com
- Slack: #resume-scoring-project

---

**Version**: 1.0.0
**Last Updated**: November 2025
#   r e s u m e _ s c o r i n g _ s y s t e m  
 