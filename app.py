#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Alfanous Web API Server
Simple Flask wrapper around the alfanous library
"""

import sys
import os
import json

# Add src to path so we can import alfanous
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from flask import Flask, request, jsonify
import alfanous

app = Flask(__name__)

# Enable CORS manually
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE')
    return response

# Initialize alfanous output
try:
    output = alfanous.outputs.Raw()
    print("Alfanous initialized successfully")
except Exception as e:
    print("Error initializing alfanous: %s" % str(e))
    print("Make sure indexes are built. Run 'make build' before deploying.")
    output = None


@app.route('/')
def index():
    """API information"""
    try:
        info = output.do({"action": "show", "query": "information"})
        return jsonify({
            "status": "running",
            "info": info.get("show", {}).get("information", {}),
            "usage": {
                "search": "/api/search?query=الله",
                "suggest": "/api/suggest?query=ماء",
                "info": "/api/info?query=all"
            }
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/search')
def search():
    """Search endpoint"""
    if not output:
        return jsonify({"error": "Alfanous not initialized"}), 500
    
    try:
        # Get query parameters
        params = {
            "action": "search",
            "query": request.args.get('query', ''),
            "unit": request.args.get('unit', 'aya'),
            "sortedby": request.args.get('sortedby', 'score'),
            "page": request.args.get('page', '1'),
            "range": request.args.get('range', '10'),
            "view": request.args.get('view', 'normal'),
            "highlight": request.args.get('highlight', 'css'),
            "script": request.args.get('script', 'standard'),
            "vocalized": request.args.get('vocalized', 'True'),
            "recitation": request.args.get('recitation', '1'),
            "translation": request.args.get('translation', 'None'),
            "romanization": request.args.get('romanization', 'none'),
            "prev_aya": request.args.get('prev_aya', 'True'),
            "next_aya": request.args.get('next_aya', 'True'),
            "sura_info": request.args.get('sura_info', 'True'),
            "word_info": request.args.get('word_info', 'True'),
            "fuzzy": request.args.get('fuzzy', 'False'),
        }
        
        # Convert boolean strings to actual booleans
        for key in ['vocalized', 'prev_aya', 'next_aya', 'sura_info', 'word_info', 'fuzzy']:
            params[key] = params[key].lower() in ['true', '1', 'yes']
        
        # Convert None strings to None
        if params['translation'] == 'None':
            params['translation'] = None
            
        if params['romanization'] == 'none':
            params['romanization'] = None
        
        result = output.do(params)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/suggest')
def suggest():
    """Suggest endpoint"""
    if not output:
        return jsonify({"error": "Alfanous not initialized"}), 500
    
    try:
        params = {
            "action": "suggest",
            "query": request.args.get('query', ''),
            "unit": request.args.get('unit', 'aya'),
        }
        
        result = output.do(params)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/info')
def info():
    """Information endpoint"""
    if not output:
        return jsonify({"error": "Alfanous not initialized"}), 500
    
    try:
        query = request.args.get('query', 'all')
        params = {
            "action": "show",
            "query": query
        }
        
        result = output.do(params)
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/health')
def health():
    """Health check endpoint"""
    if output is None:
        return jsonify({"status": "unhealthy", "error": "Alfanous not initialized"}), 503
    
    try:
        # Test basic functionality
        test_result = output.do({"action": "show", "query": "information"})
        return jsonify({"status": "healthy"})
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 503


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)

