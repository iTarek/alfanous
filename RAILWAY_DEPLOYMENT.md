# Railway Deployment Guide for Alfanous

## Prerequisites

This project uses Python 2.7 for the core library, but Railway requires Python 3. The indexes and resources need to be pre-built before deployment.

## Deployment Steps

### Option 1: Pre-build Indexes (Recommended)

1. **Build the indexes locally:**
   ```bash
   cd /path/to/alfanous
   make build
   ```

2. **Commit the built indexes to git:**
   ```bash
   git add src/alfanous/indexes/
   git commit -m "Add pre-built indexes"
   git push
   ```

3. **Deploy to Railway:**
   - Connect your GitHub repository to Railway
   - Railway will automatically detect the Python project and deploy

### Option 2: Using Docker (For Python 2.7 Support)

If you need Python 2.7 support, create a Dockerfile:

```dockerfile
FROM python:2.7-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application
COPY . .

# Build indexes if not already built
RUN cd src/alfanous && python setup.py build || true

# Expose port
EXPOSE 5000

# Run the app
CMD ["python", "app.py"]
```

Then create a `railway.json` with:
```json
{
  "build": {
    "builder": "DOCKERFILE"
  }
}
```

## Environment Variables

No environment variables are required. The PORT variable is automatically set by Railway.

## API Endpoints

Once deployed, your API will be available at:

- `GET /` - API information
- `GET /api/search?query=الله` - Search Quranic verses
- `GET /api/suggest?query=ماء` - Get search suggestions
- `GET /api/info?query=all` - Get metadata
- `GET /health` - Health check

## Troubleshooting

### Error: Indexes not found
Make sure you've built the indexes before deploying:
```bash
make build
```

### Error: Python version mismatch
The core library uses Python 2.7 syntax. You may need to use Docker deployment or pre-build all resources.

### Indexes are too large
If the indexes directory is too large for your Git repository, consider:
1. Using Git LFS for the indexes
2. Storing indexes in a cloud storage and downloading during deployment
3. Using Railway's persistent storage

## Notes

- The API is a Python 3 wrapper around the Python 2.7 library
- Indexes must be pre-built and committed to the repository
- The application uses Gunicorn with 2 workers for production
- CORS is enabled for all routes

