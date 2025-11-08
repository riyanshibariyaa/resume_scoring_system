# 🚀 Quick Start Guide - Resume Scoring System

## Windows Setup (CPU-Only, No GPU Required)

### Prerequisites Installation

1. **Python 3.10+**
   ```powershell
   # Download from python.org and install
   # Verify installation:
   python --version
   ```

2. **.NET SDK 8.0**
   ```powershell
   # Download from dotnet.microsoft.com
   # Verify:
   dotnet --version
   ```

3. **Node.js 18+**
   ```powershell
   # Download from nodejs.org
   # Verify:
   node --version
   npm --version
   ```

4. **SQL Server Express** (Free)
   ```powershell
   # Download SQL Server 2019 Express from microsoft.com
   # Or use Docker:
   docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourStrong@Password123!" -p 1433:1433 --name sql2019 -d mcr.microsoft.com/mssql/server:2019-latest
   ```

5. **Tesseract OCR** (Optional, for OCR)
   ```powershell
   # Download installer from github.com/UB-Mannheim/tesseract/wiki
   # Add to PATH: C:\Program Files\Tesseract-OCR
   ```

### Step-by-Step Installation

#### 1. Database Setup

```powershell
# Connect to SQL Server and run schema
sqlcmd -S localhost -U sa -P YourStrong@Password123! -i database\migrations\001_initial_schema.sql
```

#### 2. Backend Services Setup

**Parsing Service:**
```powershell
cd backend\services\parsing
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

**NLP Service:**
```powershell
cd ..\nlp
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python -m spacy download en_core_web_sm
```

**Embedding Service:**
```powershell
cd ..\embedding
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

**Scoring Service:**
```powershell
cd ..\scoring
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

#### 3. API Gateway Setup

```powershell
cd ..\..\api-gateway
dotnet restore
dotnet build
```

#### 4. Frontend Setup

```powershell
cd ..\..\frontend
npm install
```

### Configuration

Create `.env` files in each service:

**backend/api-gateway/.env**
```
DATABASE_CONNECTION=Server=localhost;Database=ResumeScoring;User Id=sa;Password=YourStrong@Password123!;TrustServerCertificate=True
JWT_SECRET=your-256-bit-secret-key-change-this-in-production
CORS_ORIGINS=http://localhost:3000
PARSING_SERVICE_URL=http://localhost:5001
NLP_SERVICE_URL=http://localhost:5002
EMBEDDING_SERVICE_URL=http://localhost:5003
SCORING_SERVICE_URL=http://localhost:5004
```

**backend/services/*/. env** (for each Python service)
```
PORT=5001  # 5002, 5003, 5004 for other services
DEBUG=true
STORAGE_PATH=./storage
API_GATEWAY_URL=http://localhost:5000
```

**frontend/.env**
```
REACT_APP_API_URL=http://localhost:5000
REACT_APP_ENV=development
```

### Running the Application

Open **5 separate terminal windows**:

**Terminal 1 - Parsing Service:**
```powershell
cd backend\services\parsing
venv\Scripts\activate
python app.py
```

**Terminal 2 - NLP Service:**
```powershell
cd backend\services\nlp
venv\Scripts\activate
python app.py
```

**Terminal 3 - Embedding & Scoring Services:**
```powershell
cd backend\services\embedding
venv\Scripts\activate
python app.py

# In another terminal:
cd backend\services\scoring
venv\Scripts\activate
python app.py
```

**Terminal 4 - API Gateway:**
```powershell
cd backend\api-gateway
dotnet run
```

**Terminal 5 - Frontend:**
```powershell
cd frontend
npm start
```

### Access the Application

- **Frontend UI**: http://localhost:3000
- **API Gateway**: http://localhost:5000
- **Swagger Docs**: http://localhost:5000/swagger

### Testing the System

1. Navigate to http://localhost:3000
2. Upload a sample resume (PDF/DOCX)
3. Create a job description
4. Click "Score Candidate"
5. View results with explanations

### Troubleshooting

**Issue: Port already in use**
```powershell
# Change port in .env file or kill process:
netstat -ano | findstr :5000
taskkill /PID <PID> /F
```

**Issue: Database connection failed**
```powershell
# Verify SQL Server is running:
sqlcmd -S localhost -U sa -P YourStrong@Password123! -Q "SELECT @@VERSION"
```

**Issue: Python module not found**
```powershell
# Ensure virtual environment is activated:
venv\Scripts\activate
pip install -r requirements.txt
```

**Issue: Models not loading**
```powershell
# Re-download spaCy models:
python -m spacy download en_core_web_sm
python -m spacy download en_core_web_lg  # larger, more accurate
```

### Docker Deployment (Alternative)

```powershell
# Build and run all services:
docker-compose up -d

# View logs:
docker-compose logs -f

# Stop services:
docker-compose down
```

### Sample Data

Sample resumes and job descriptions are in `database/seed/` folder.

### Next Steps

1. Review API documentation at http://localhost:5000/swagger
2. Customize scoring weights in the database
3. Add your own skills ontology
4. Configure Azure deployment (see DEPLOYMENT.md)
5. Set up CI/CD pipelines (see .github/workflows/)

### Support

For issues:
- Check logs in each service directory
- Review README.md for detailed documentation
- Check GitHub issues

---

**System Status**: Ready for Development ✅
**Estimated Setup Time**: 30-45 minutes
**Recommended RAM**: 8GB minimum, 16GB preferred
