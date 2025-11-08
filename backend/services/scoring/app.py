"""Scoring Service - Calculate candidate-job match scores"""
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from loguru import logger
import numpy as np
from datetime import datetime
from typing import Dict, Any

app = Flask(__name__)
CORS(app)

class CandidateScorer:
    def __init__(self):
        self.default_weights = {
            'skills': 0.30,
            'experience': 0.25,
            'domain': 0.15,
            'education': 0.10,
            'certifications': 0.10,
            'recency': 0.10
        }
    
    def calculate_score(self, candidate: Dict, job: Dict, weights: Dict = None) -> Dict[str, Any]:
        if not weights:
            weights = self.default_weights
        
        subscores = {
            'skills': self._score_skills(candidate, job),
            'experience': self._score_experience(candidate, job),
            'domain': self._score_domain(candidate, job),
            'education': self._score_education(candidate, job),
            'certifications': self._score_certifications(candidate, job),
            'recency': self._score_recency(candidate)
        }
        
        overall = sum(weights[k] * subscores[k] for k in subscores.keys())
        
        return {
            'overallScore': round(overall, 4),
            'subscores': subscores,
            'explanations': self._generate_explanations(candidate, job, subscores),
            'modelVersion': 'scoring-v1.0.0',
            'timestamp': datetime.utcnow().isoformat()
        }
    
    def _score_skills(self, candidate, job):
        cand_skills = set()
        for skill_list in candidate.get('skills', {}).values():
            cand_skills.update([s.lower() for s in skill_list])
        
        job_skills = set([s.lower() for s in job.get('required_skills', [])])
        
        if not job_skills:
            return 0.5
        
        matched = len(cand_skills & job_skills)
        return min(matched / len(job_skills), 1.0)
    
    def _score_experience(self, candidate, job):
        years = candidate.get('metadata', {}).get('total_experience_years', 0)
        required_years = job.get('required_experience_years', 3)
        
        if years >= required_years:
            return 1.0
        elif years >= required_years * 0.7:
            return 0.8
        elif years >= required_years * 0.5:
            return 0.6
        return 0.3
    
    def _score_domain(self, candidate, job):
        # Simplified domain matching
        return 0.75
    
    def _score_education(self, candidate, job):
        edu = candidate.get('education', [])
        if not edu:
            return 0.5
        return 0.7 if len(edu) > 0 else 0.3
    
    def _score_certifications(self, candidate, job):
        certs = candidate.get('certifications', [])
        return min(len(certs) * 0.2, 1.0)
    
    def _score_recency(self, candidate):
        return 0.85  # Simplified
    
    def _generate_explanations(self, candidate, job, subscores):
        return [
            {'criterion': 'skills', 'evidence': ['Skills match analysis']},
            {'criterion': 'experience', 'evidence': [f"{candidate.get('metadata', {}).get('total_experience_years', 0)} years experience"]}
        ]

scorer = CandidateScorer()

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'scoring'})

@app.route('/score', methods=['POST'])
def score_candidate():
    try:
        data = request.json
        candidate = data.get('candidate', {})
        job = data.get('job', {})
        weights = data.get('weights')
        
        result = scorer.calculate_score(candidate, job, weights)
        return jsonify({'success': True, 'score': result})
    except Exception as e:
        logger.error(f"Scoring error: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5004)))
