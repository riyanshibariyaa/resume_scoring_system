"""
NLP Extraction Service
Performs Named Entity Recognition, skill extraction, and experience timeline analysis
"""

import os
import re
import json
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime
from collections import defaultdict

from flask import Flask, request, jsonify
from flask_cors import CORS
import spacy
from transformers import pipeline, AutoTokenizer, AutoModelForTokenClassification
import dateparser
import phonenumbers
from loguru import logger

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configure logger
logger.add("nlp_service.log", rotation="10 MB", retention="30 days", level="INFO")

# Global variables for models
nlp_model = None
ner_pipeline = None


def load_models():
    """Load NLP models (CPU-optimized)"""
    global nlp_model, ner_pipeline
    
    try:
        logger.info("Loading spaCy model...")
        # Load spaCy model for general NLP tasks
        nlp_model = spacy.load("en_core_web_sm")
        
        logger.info("Loading transformer NER model...")
        # Load transformer model for better NER (CPU-optimized)
        tokenizer = AutoTokenizer.from_pretrained("dslim/bert-base-NER")
        model = AutoModelForTokenClassification.from_pretrained("dslim/bert-base-NER")
        ner_pipeline = pipeline("ner", model=model, tokenizer=tokenizer, aggregation_strategy="simple")
        
        logger.info("Models loaded successfully")
        
    except Exception as e:
        logger.error(f"Error loading models: {str(e)}")
        raise


class ResumeExtractor:
    """Main class for extracting structured information from resumes"""
    
    def __init__(self):
        self.skills_ontology = self._load_skills_ontology()
        self.section_extractors = {
            'contact': self._extract_contact_info,
            'summary': self._extract_summary,
            'experience': self._extract_experience,
            'education': self._extract_education,
            'skills': self._extract_skills,
            'certifications': self._extract_certifications
        }
    
    def extract(self, parsed_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Main extraction method
        
        Args:
            parsed_data: Output from parsing service
            
        Returns:
            Structured candidate profile
        """
        text = parsed_data.get('text', '')
        sections = parsed_data.get('sections', [])
        
        logger.info(f"Extracting information from {len(text)} characters")
        
        result = {
            'contact_info': self._extract_contact_info(text),
            'summary': self._extract_summary(text, sections),
            'experience': self._extract_experience(text, sections),
            'education': self._extract_education(text, sections),
            'skills': self._extract_skills(text, sections),
            'certifications': self._extract_certifications(text, sections),
            'languages': self._extract_languages(text, sections),
            'metadata': {
                'total_experience_years': 0,
                'seniority_level': 'Unknown',
                'industries': [],
                'job_titles': []
            },
            'extracted_at': datetime.utcnow().isoformat(),
            'model_version': 'nlp-v1.0.0'
        }
        
        # Calculate derived metrics
        result['metadata'] = self._calculate_metadata(result)
        
        return result
    
    def _extract_contact_info(self, text: str) -> Dict[str, Any]:
        """Extract contact information"""
        contact = {
            'name': None,
            'email': None,
            'phone': None,
            'linkedin': None,
            'github': None,
            'location': None
        }
        
        # Extract email
        email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        emails = re.findall(email_pattern, text)
        if emails:
            contact['email'] = emails[0]
        
        # Extract phone number
        try:
            for match in phonenumbers.PhoneNumberMatcher(text, "US"):
                contact['phone'] = phonenumbers.format_number(
                    match.number, 
                    phonenumbers.PhoneNumberFormat.INTERNATIONAL
                )
                break
        except Exception as e:
            logger.debug(f"Phone extraction failed: {str(e)}")
        
        # Extract LinkedIn
        linkedin_pattern = r'(?:linkedin\.com/in/|linkedin\.com/pub/)([a-zA-Z0-9-]+)'
        linkedin_match = re.search(linkedin_pattern, text, re.IGNORECASE)
        if linkedin_match:
            contact['linkedin'] = f"https://linkedin.com/in/{linkedin_match.group(1)}"
        
        # Extract GitHub
        github_pattern = r'(?:github\.com/)([a-zA-Z0-9-]+)'
        github_match = re.search(github_pattern, text, re.IGNORECASE)
        if github_match:
            contact['github'] = f"https://github.com/{github_match.group(1)}"
        
        # Extract name using NER
        if nlp_model:
            doc = nlp_model(text[:500])  # Use first 500 chars
            for ent in doc.ents:
                if ent.label_ == "PERSON" and not contact['name']:
                    contact['name'] = ent.text
                    break
        
        # Extract location
        if nlp_model:
            doc = nlp_model(text[:1000])
            locations = [ent.text for ent in doc.ents if ent.label_ in ["GPE", "LOC"]]
            if locations:
                contact['location'] = locations[0]
        
        return contact
    
    def _extract_summary(self, text: str, sections: List[Dict]) -> Optional[str]:
        """Extract professional summary"""
        # Find summary section
        summary_section = next((s for s in sections if s['type'] == 'summary'), None)
        
        if summary_section:
            # Extract text after summary header
            start_pos = summary_section['position']
            
            # Find next section
            section_positions = sorted([s['position'] for s in sections if s['position'] > start_pos])
            end_pos = section_positions[0] if section_positions else len(text)
            
            summary_text = text[start_pos:end_pos].strip()
            lines = summary_text.split('\n')
            
            # Skip header line, take next few lines
            content_lines = [line.strip() for line in lines[1:] if line.strip()]
            summary = ' '.join(content_lines[:5])  # Take first 5 lines
            
            return summary if len(summary) > 20 else None
        
        return None
        
    

    def _load_skills_ontology(self)-> Dict[str, Dict[str, Any]]:
        
        return {
            # Programming Languages
            'Python': {'aliases': ['python', 'py', 'python3'], 'category': 'programming_languages'},
            'JavaScript': {'aliases': ['javascript', 'js', 'es6', 'es2015'], 'category': 'programming_languages'},
            'TypeScript': {'aliases': ['typescript', 'ts'], 'category': 'programming_languages'},
            'Java': {'aliases': ['java', 'java8', 'java11'], 'category': 'programming_languages'},
            'C++': {'aliases': ['c++', 'cpp'], 'category': 'programming_languages'},
            'C#': {'aliases': ['c#', 'csharp'], 'category': 'programming_languages'},
            'Go': {'aliases': ['go', 'golang'], 'category': 'programming_languages'},
            'Rust': {'aliases': ['rust'], 'category': 'programming_languages'},
            'PHP': {'aliases': ['php'], 'category': 'programming_languages'},
            'Ruby': {'aliases': ['ruby'], 'category': 'programming_languages'},
            'Swift': {'aliases': ['swift', 'ios'], 'category': 'programming_languages'},
            'Kotlin': {'aliases': ['kotlin', 'android'], 'category': 'programming_languages'},
            
            # Frontend
            'React': {'aliases': ['react', 'reactjs', 'react.js'], 'category': 'frameworks'},
            'Next.js': {'aliases': ['next', 'nextjs', 'next.js'], 'category': 'frameworks'},
            'Vue.js': {'aliases': ['vue', 'vuejs', 'vue.js'], 'category': 'frameworks'},
            'Angular': {'aliases': ['angular', 'angularjs'], 'category': 'frameworks'},
            'Svelte': {'aliases': ['svelte'], 'category': 'frameworks'},
            
            # Backend
            'Node.js': {'aliases': ['node', 'nodejs', 'node.js'], 'category': 'frameworks'},
            'Express.js': {'aliases': ['express', 'expressjs'], 'category': 'frameworks'},
            'Django': {'aliases': ['django'], 'category': 'frameworks'},
            'Flask': {'aliases': ['flask'], 'category': 'frameworks'},
            'FastAPI': {'aliases': ['fastapi'], 'category': 'frameworks'},
            'Spring Boot': {'aliases': ['spring', 'spring boot'], 'category': 'frameworks'},
            '.NET': {'aliases': ['dotnet', '.net', 'asp.net'], 'category': 'frameworks'},
            'Laravel': {'aliases': ['laravel'], 'category': 'frameworks'},
            'Rails': {'aliases': ['rails', 'ruby on rails'], 'category': 'frameworks'},
            
            # Databases
            'MongoDB': {'aliases': ['mongodb', 'mongo'], 'category': 'databases'},
            'PostgreSQL': {'aliases': ['postgresql', 'postgres'], 'category': 'databases'},
            'MySQL': {'aliases': ['mysql'], 'category': 'databases'},
            'Redis': {'aliases': ['redis'], 'category': 'databases'},
            'SQL Server': {'aliases': ['sql server', 'mssql'], 'category': 'databases'},
            'Oracle': {'aliases': ['oracle'], 'category': 'databases'},
            'DynamoDB': {'aliases': ['dynamodb'], 'category': 'databases'},
            'Cassandra': {'aliases': ['cassandra'], 'category': 'databases'},
            'SQLite': {'aliases': ['sqlite'], 'category': 'databases'},
            'MariaDB': {'aliases': ['mariadb'], 'category': 'databases'},
            
            # Cloud
            'AWS': {'aliases': ['aws', 'amazon web services'], 'category': 'cloud'},
            'Azure': {'aliases': ['azure', 'microsoft azure'], 'category': 'cloud'},
            'Google Cloud': {'aliases': ['gcp', 'google cloud'], 'category': 'cloud'},
            'Heroku': {'aliases': ['heroku'], 'category': 'cloud'},
            'DigitalOcean': {'aliases': ['digitalocean'], 'category': 'cloud'},
            
            # DevOps
            'Docker': {'aliases': ['docker'], 'category': 'tools'},
            'Kubernetes': {'aliases': ['kubernetes', 'k8s'], 'category': 'tools'},
            'Git': {'aliases': ['git', 'github', 'gitlab'], 'category': 'tools'},
            'Jenkins': {'aliases': ['jenkins'], 'category': 'tools'},
            'CI/CD': {'aliases': ['ci/cd', 'cicd'], 'category': 'tools'},
            'Terraform': {'aliases': ['terraform'], 'category': 'tools'},
            'Ansible': {'aliases': ['ansible'], 'category': 'tools'},
            
            # CSS/UI
            'Tailwind CSS': {'aliases': ['tailwind', 'tailwindcss'], 'category': 'frameworks'},
            'Bootstrap': {'aliases': ['bootstrap'], 'category': 'frameworks'},
            'Material-UI': {'aliases': ['material-ui', 'mui'], 'category': 'frameworks'},
            'Sass': {'aliases': ['sass', 'scss'], 'category': 'frameworks'},
            
            # Testing
            'Jest': {'aliases': ['jest'], 'category': 'tools'},
            'Pytest': {'aliases': ['pytest'], 'category': 'tools'},
            'Selenium': {'aliases': ['selenium'], 'category': 'tools'},
            'Cypress': {'aliases': ['cypress'], 'category': 'tools'},
            'JUnit': {'aliases': ['junit'], 'category': 'tools'},
            
            # APIs
            'REST API': {'aliases': ['rest', 'rest api', 'restful'], 'category': 'other'},
            'GraphQL': {'aliases': ['graphql'], 'category': 'other'},
            'gRPC': {'aliases': ['grpc'], 'category': 'other'},
            
            # ML/AI
            'TensorFlow': {'aliases': ['tensorflow', 'tf'], 'category': 'other'},
            'PyTorch': {'aliases': ['pytorch'], 'category': 'other'},
            'Scikit-learn': {'aliases': ['scikit-learn', 'sklearn'], 'category': 'other'},
            'Pandas': {'aliases': ['pandas'], 'category': 'other'},
            'NumPy': {'aliases': ['numpy'], 'category': 'other'},
            'Keras': {'aliases': ['keras'], 'category': 'other'},
            
            # Mobile
            'React Native': {'aliases': ['react native'], 'category': 'frameworks'},
            'Flutter': {'aliases': ['flutter'], 'category': 'frameworks'},
            
            # Other
            'Machine Learning': {'aliases': ['machine learning', 'ml'], 'category': 'other'},
            'Deep Learning': {'aliases': ['deep learning', 'dl'], 'category': 'other'},
            'NLP': {'aliases': ['nlp', 'natural language processing'], 'category': 'other'},
            'Computer Vision': {'aliases': ['computer vision', 'cv'], 'category': 'other'},
            'Microservices': {'aliases': ['microservices'], 'category': 'other'},
            'Agile': {'aliases': ['agile', 'scrum'], 'category': 'soft_skills'},
            'Linux': {'aliases': ['linux', 'unix'], 'category': 'other'},
        }


    def _extract_experience(self, text: str, sections: List[Dict]) -> List[Dict[str, Any]]:
        """Extract work experience - IMPROVED VERSION with FALLBACK"""
        experiences = []
        
        # Find experience section
        exp_section = next((s for s in sections if s['type'] == 'experience'), None)
        
        if exp_section:
            # Extract text in experience section
            start_pos = exp_section['position']
            section_positions = sorted([s['position'] for s in sections if s['position'] > start_pos])
            end_pos = section_positions[0] if section_positions else len(text)
            exp_text = text[start_pos:end_pos]
        else:
            # FALLBACK: Search for experience section manually
            logger.warning("No experience section found in sections array, searching manually...")
            
            text_lower = text.lower()
            experience_keywords = ['work experience', 'professional experience', 'employment history', 'experience', 'employment']
            
            start_pos = -1
            for keyword in experience_keywords:
                pattern = r'^' + re.escape(keyword) + r'\s*$'
                for match in re.finditer(pattern, text_lower, re.MULTILINE):
                    start_pos = match.start()
                    logger.info(f"Found experience section at position {start_pos}")
                    break
                if start_pos != -1:
                    break
            
            if start_pos == -1:
                logger.warning("Could not find experience section in text")
                return experiences
            
            # Find end position
            end_keywords = ['education', 'skills', 'projects', 'certifications']
            end_pos = len(text)
            for keyword in end_keywords:
                pattern = r'^' + re.escape(keyword) + r'\s*$'
                for match in re.finditer(pattern, text_lower[start_pos:], re.MULTILINE):
                    end_pos = start_pos + match.start()
                    break
                if end_pos != len(text):
                    break
            
            exp_text = text[start_pos:end_pos]
        lines = exp_text.split('\n')
        
        current_exp = None
        
        for line in lines:
            line = line.strip()
            if not line or line.lower() in ['experience', 'work experience', 'employment', 'professional experience']:
                continue
            
            # NEW: More flexible date patterns
            has_date = False
            
            # Pattern 1: Month Year - Month Year (Jan 2020 - Dec 2021)
            pattern1 = r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}\s*[-–]\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}'
            # Pattern 2: Month Year - Present (Jan 2020 - Present)
            pattern2 = r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}\s*[-–]\s*(Present|Current|Now)'
            # Pattern 3: Year - Year (2020 - 2021)
            pattern3 = r'\b(19|20)\d{2}\s*[-–]\s*(19|20)\d{2}\b'
            # Pattern 4: Year - Present (2020 - Present)
            pattern4 = r'\b(19|20)\d{2}\s*[-–]\s*(Present|Current|Now)'
            # Pattern 5: Just year range in parentheses ((2020-2021))
            pattern5 = r'\(?(19|20)\d{2}\s*[-–]\s*((19|20)\d{2}|Present|Current)\)?'
            
            date_patterns = [pattern1, pattern2, pattern3, pattern4, pattern5]
            
            for pattern in date_patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    has_date = True
                    break
            
            if has_date:
                # Save previous experience
                if current_exp:
                    experiences.append(current_exp)
                
                # Extract dates
                dates = self._extract_dates(line)
                
                # Start new experience entry
                current_exp = {
                    'title': '',
                    'company': '',
                    'location': None,
                    'start_date': dates[0] if len(dates) > 0 else None,
                    'end_date': dates[1] if len(dates) > 1 else 'Present',
                    'duration_months': None,
                    'description': [],
                    'technologies': []
                }
                
                # Extract job title and company from line
                # Usually format: "Software Engineer at Company Name | Jan 2020 - Present"
                # or "Software Engineer - Company Name (Jan 2020 - Present)"
                
                # Remove date part
                line_without_date = re.sub(r'\(?(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4}.*', '', line, flags=re.IGNORECASE)
                line_without_date = re.sub(r'\(?(19|20)\d{2}.*', '', line_without_date)
                line_without_date = line_without_date.strip('|-()\t ')
                
                # Try to split by common separators
                if ' at ' in line_without_date.lower():
                    parts = re.split(r'\s+at\s+', line_without_date, maxsplit=1, flags=re.IGNORECASE)
                    current_exp['title'] = parts[0].strip()
                    current_exp['company'] = parts[1].strip() if len(parts) > 1 else ''
                elif ' - ' in line_without_date and '|' not in line_without_date:
                    parts = line_without_date.split(' - ', maxsplit=1)
                    current_exp['title'] = parts[0].strip()
                    current_exp['company'] = parts[1].strip() if len(parts) > 1 else ''
                elif '|' in line_without_date:
                    parts = line_without_date.split('|', maxsplit=1)
                    current_exp['title'] = parts[0].strip()
                    current_exp['company'] = parts[1].strip() if len(parts) > 1 else ''
                else:
                    # Take first line as title
                    current_exp['title'] = line_without_date.strip()
                
            elif current_exp:
                # This is a description line
                if line.startswith(('•', '-', '*', '○', '●')) or re.match(r'^\d+[\.\)]', line):
                    # Bullet point
                    clean_line = line.lstrip('•-*○●0123456789.) \t')
                    if clean_line:
                        current_exp['description'].append(clean_line)
                elif not current_exp['company'] and not current_exp['title']:
                    # Might be title on first line
                    current_exp['title'] = line
                elif not current_exp['company']:
                    # Might be company on second line
                    current_exp['company'] = line
                else:
                    # Continuation of previous description
                    if current_exp['description']:
                        current_exp['description'][-1] += ' ' + line
        
        # Add last experience
        if current_exp:
            experiences.append(current_exp)
        
        # Calculate durations
        for exp in experiences:
            exp['duration_months'] = self._calculate_duration(
                exp['start_date'], 
                exp['end_date']
            )
        
        logger.info(f"Extracted {len(experiences)} experiences")
        return experiences


    def _extract_dates(self, text: str) -> List[str]:
        """Extract dates - IMPROVED VERSION"""
        dates = []
        
        # Pattern 1: Full month name + year (January 2020, Jan 2020)
        month_year_pattern = r'\b(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+(\d{4})\b'
        matches = re.findall(month_year_pattern, text, re.IGNORECASE)
        
        for match in matches:
            month = match[0].capitalize()
            year = match[1]
            dates.append(f"{month} {year}")
        
        # Pattern 2: Year only if no month found
        if not dates:
            year_pattern = r'\b(19|20)\d{2}\b'
            years = re.findall(year_pattern, text)
            dates = years[:2]
        
        # Pattern 3: Check for "Present", "Current", etc.
        if re.search(r'\b(present|current|now|ongoing)\b', text, re.IGNORECASE):
            if len(dates) == 1:
                dates.append('Present')
            elif len(dates) == 0:
                dates = ['Unknown', 'Present']
        
        # Ensure we have at least start date
        if len(dates) == 0:
            dates = ['Unknown']
        
        return dates[:2]  # Return max 2 dates
        
    def _extract_education(self, text: str, sections: List[Dict]) -> List[Dict[str, Any]]:
        """Extract education information"""
        education = []
        
        edu_section = next((s for s in sections if s['type'] == 'education'), None)
        
        if not edu_section:
            return education
        
        start_pos = edu_section['position']
        section_positions = sorted([s['position'] for s in sections if s['position'] > start_pos])
        end_pos = section_positions[0] if section_positions else len(text)
        
        edu_text = text[start_pos:end_pos]
        lines = edu_text.split('\n')
        
        degree_keywords = [
            'bachelor', 'master', 'phd', 'doctorate', 'mba', 'bs', 'ms', 'ba', 'ma',
            'b.s.', 'm.s.', 'b.a.', 'm.a.', 'ph.d.'
        ]
        
        current_edu = None
        
        for line in lines:
            line = line.strip()
            if not line or line.lower() in ['education', 'academic']:
                continue
            
            # Check if line contains degree keyword
            line_lower = line.lower()
            has_degree = any(keyword in line_lower for keyword in degree_keywords)
            
            if has_degree:
                if current_edu:
                    education.append(current_edu)
                
                current_edu = {
                    'degree': '',
                    'field_of_study': '',
                    'institution': '',
                    'location': None,
                    'graduation_year': None,
                    'gpa': None
                }
                
                # Extract degree info
                current_edu['degree'] = self._extract_degree(line)
                
                # Extract year
                years = re.findall(r'\b(19|20)\d{2}\b', line)
                if years:
                    current_edu['graduation_year'] = int(years[-1])
                
                # Extract GPA
                gpa_match = re.search(r'gpa[:\s]+(\d+\.?\d*)', line_lower)
                if gpa_match:
                    current_edu['gpa'] = float(gpa_match.group(1))
                
            elif current_edu and not current_edu['institution']:
                current_edu['institution'] = line
        
        if current_edu:
            education.append(current_edu)
        
        return education
    
    def _extract_skills(self, text: str, sections: List[Dict]) -> Dict[str, List[str]]:
        """Extract and categorize skills"""
        skills = {
            'programming_languages': [],
            'frameworks': [],
            'databases': [],
            'tools': [],
            'cloud': [],
            'soft_skills': [],
            'other': []
        }
        
        # Find skills section
        skills_section = next((s for s in sections if s['type'] == 'skills'), None)
        
        if skills_section:
            start_pos = skills_section['position']
            section_positions = sorted([s['position'] for s in sections if s['position'] > start_pos])
            end_pos = section_positions[0] if section_positions else len(text)
            skills_text = text[start_pos:end_pos]
        else:
            # Search entire document
            skills_text = text
        
        # Extract using ontology
        for canonical_skill, info in self.skills_ontology.items():
            pattern = r'\b(' + '|'.join(re.escape(alias) for alias in info['aliases']) + r')\b'
            if re.search(pattern, skills_text, re.IGNORECASE):
                category = info['category']
                if category in skills:
                    if canonical_skill not in skills[category]:
                        skills[category].append(canonical_skill)
                else:
                    if canonical_skill not in skills['other']:
                        skills['other'].append(canonical_skill)
        
        return skills
    
    def _extract_certifications(self, text: str, sections: List[Dict]) -> List[Dict[str, Any]]:
        """Extract certifications"""
        certifications = []
        
        cert_section = next((s for s in sections if s['type'] == 'certifications'), None)
        
        if cert_section:
            start_pos = cert_section['position']
            section_positions = sorted([s['position'] for s in sections if s['position'] > start_pos])
            end_pos = section_positions[0] if section_positions else len(text)
            cert_text = text[start_pos:end_pos]
            
            lines = cert_text.split('\n')
            
            for line in lines[1:]:  # Skip header
                line = line.strip()
                if line and len(line) > 5:
                    cert = {
                        'name': line.lstrip('•-* '),
                        'issuer': None,
                        'date': None
                    }
                    
                    # Extract year if present
                    years = re.findall(r'\b(19|20)\d{2}\b', line)
                    if years:
                        cert['date'] = int(years[-1])
                    
                    certifications.append(cert)
        
        return certifications
    
    def _extract_languages(self, text: str, sections: List[Dict]) -> List[Dict[str, str]]:
        """Extract language proficiencies"""
        languages = []
        
        lang_section = next((s for s in sections if s['type'] == 'languages'), None)
        
        if lang_section:
            start_pos = lang_section['position']
            section_positions = sorted([s['position'] for s in sections if s['position'] > start_pos])
            end_pos = section_positions[0] if section_positions else len(text)
            lang_text = text[start_pos:end_pos]
            
            common_languages = [
                'english', 'spanish', 'french', 'german', 'chinese', 'japanese',
                'korean', 'arabic', 'hindi', 'portuguese', 'russian', 'italian'
            ]
            
            for language in common_languages:
                if language in lang_text.lower():
                    proficiency = 'Unknown'
                    if 'native' in lang_text.lower() or 'fluent' in lang_text.lower():
                        proficiency = 'Native/Fluent'
                    elif 'professional' in lang_text.lower():
                        proficiency = 'Professional'
                    elif 'basic' in lang_text.lower() or 'elementary' in lang_text.lower():
                        proficiency = 'Basic'
                    
                    languages.append({
                        'language': language.capitalize(),
                        'proficiency': proficiency
                    })
        
        return languages
    
        # def _extract_dates(self, text: str) -> List[str]:
        #     """Extract dates from text with better pattern matching"""
        #     dates = []
            
        #     # Pattern 1: Month Year format (e.g., "Jan 2020", "January 2020")
        #     month_year_pattern = r'\b(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+(\d{4})\b'
        #     matches = re.findall(month_year_pattern, text, re.IGNORECASE)
        #     for match in matches:
        #         dates.append(f"{match[0]} {match[1]}")
            
        #     # Pattern 2: Year only (e.g., "2020")
        #     if not dates:
        #         year_pattern = r'\b(19|20)\d{2}\b'
        #         years = re.findall(year_pattern, text)
        #         dates = years[:2]  # Take first two years
            
        #     # Pattern 3: "Present", "Current", etc.
        #     if re.search(r'\b(present|current|now|ongoing)\b', text, re.IGNORECASE):
        #         if len(dates) == 1:
        #             dates.append('Present')
            
        #     return dates
        
    def _extract_title_company(self, line: str) -> Dict[str, str]:
        """Extract job title and company from line"""
        result = {'title': '', 'company': ''}
        
        # Common patterns: "Title at Company" or "Title | Company" or "Title - Company"
        separators = [' at ', ' | ', ' - ', ', ']
        
        for sep in separators:
            if sep in line:
                parts = line.split(sep, 1)
                if len(parts) == 2:
                    # Remove dates from both parts
                    result['title'] = re.sub(r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{4}\b', '', parts[0], flags=re.IGNORECASE).strip()
                    result['company'] = re.sub(r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{4}\b', '', parts[1], flags=re.IGNORECASE).strip()
                    return result
        
        # Fallback: use entire line as title
        result['title'] = re.sub(r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{4}\b', '', line, flags=re.IGNORECASE).strip()
        return result
    
    def _extract_degree(self, line: str) -> str:
        """Extract degree from line"""
        degree_mapping = {
            'bachelor': "Bachelor's Degree",
            'master': "Master's Degree",
            'phd': 'Ph.D.',
            'doctorate': 'Doctorate',
            'mba': 'MBA',
            'bs': "Bachelor of Science",
            'ms': "Master of Science",
            'ba': "Bachelor of Arts",
            'ma': "Master of Arts"
        }
        
        line_lower = line.lower()
        for key, value in degree_mapping.items():
            if key in line_lower:
                return value
        
        return line.split(',')[0].strip()
        
    def _calculate_duration(self, start_date: str, end_date: str) -> Optional[int]:
        """Calculate duration in months between two dates"""
        try:
            if not start_date:
                return None
            
            start = dateparser.parse(str(start_date))
            
            if end_date and end_date.lower() not in ['present', 'current']:
                end = dateparser.parse(str(end_date))
            else:
                end = datetime.now()
            
            if start and end:
                months = (end.year - start.year) * 12 + (end.month - start.month)
                return max(months, 0)
        except Exception as e:
            logger.debug(f"Duration calculation failed: {str(e)}")
        
        return None
        
    def _calculate_metadata(self, extracted_data: Dict[str, Any]) -> Dict[str, Any]:
        """Calculate derived metadata"""
        metadata = {
            'total_experience_years': 0.0,
            'seniority_level': 'Entry',
            'industries': [],
            'job_titles': []
        }
        
        # Calculate total experience
        total_months = sum(
            exp['duration_months'] or 0 
            for exp in extracted_data['experience']
        )
        metadata['total_experience_years'] = round(total_months / 12, 1)
        
        # Determine seniority
        years = metadata['total_experience_years']
        if years < 2:
            metadata['seniority_level'] = 'Entry'
        elif years < 5:
            metadata['seniority_level'] = 'Mid-Level'
        elif years < 10:
            metadata['seniority_level'] = 'Senior'
        else:
            metadata['seniority_level'] = 'Lead/Principal'
        
        # Extract job titles
        metadata['job_titles'] = [
            exp['title'] 
            for exp in extracted_data['experience'] 
            if exp['title']
        ]
        
        return metadata
        


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'nlp-service',
        'models_loaded': nlp_model is not None,
        'timestamp': datetime.utcnow().isoformat()
    })


@app.route('/extract', methods=['POST'])
def extract_entities():
    """
    Extract structured information from parsed resume
    
    Request:
        - parsed_data: Output from parsing service
        
    Response:
        - extracted_data: Structured candidate profile
    """
    try:
        data = request.get_json()
        
        if not data or 'parsed_data' not in data:
            return jsonify({'error': 'No parsed_data provided'}), 400
        
        parsed_data = data['parsed_data']
        
        # Extract information
        extractor = ResumeExtractor()
        extracted_data = extractor.extract(parsed_data)
        
        logger.info(f"Extraction complete: Found {len(extracted_data['experience'])} experiences, "
                   f"{sum(len(skills) for skills in extracted_data['skills'].values())} skills")
        
        return jsonify({
            'success': True,
            'extracted_data': extracted_data
        }), 200
        
    except Exception as e:
        logger.error(f"Error in extract_entities: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


if __name__ == '__main__':
    # Load models on startup
    load_models()
    
    port = int(os.getenv('PORT', 5002))
    debug = os.getenv('DEBUG', 'False').lower() == 'true'
    
    logger.info(f"Starting NLP Service on port {port}")
    app.run(host='0.0.0.0', port=port, debug=debug)
