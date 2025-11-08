"""Embedding Service - Generate and store embeddings"""
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from sentence_transformers import SentenceTransformer
from loguru import logger
import numpy as np

app = Flask(__name__)
CORS(app)

model = None

def load_model():
    global model
    logger.info("Loading sentence transformer model...")
    model = SentenceTransformer('all-MiniLM-L6-v2')  # CPU-friendly
    logger.info("Model loaded successfully")

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'embedding'})

@app.route('/embed', methods=['POST'])
def embed_text():
    try:
        data = request.json
        text = data.get('text', '')
        embeddings = model.encode([text])
        return jsonify({'embedding': embeddings[0].tolist()})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    load_model()
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5003)))
