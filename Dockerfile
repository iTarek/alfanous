FROM python:2.7-slim

WORKDIR /app

# Fix Debian Buster repositories (now archived)
RUN sed -i 's|http://deb.debian.org|http://archive.debian.org|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org|http://archive.debian.org|g' /etc/apt/sources.list && \
    sed -i '/buster-updates/d' /etc/apt/sources.list

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    sqlite3 \
    make \
    perl \
    && rm -rf /var/lib/apt/lists/*

# Copy the entire project
COPY . .

# Install Python dependencies
RUN pip install --no-cache-dir pyparsing Flask==1.1.4 gunicorn==19.10.0 Werkzeug==1.0.1

# Build indexes
RUN echo "Building Alfanous indexes..." && \
    chmod +x build_indexes.sh && \
    ./build_indexes.sh && \
    echo "Indexes built successfully!" && \
    ls -la src/alfanous/indexes/

# Expose port
EXPOSE 5000

# Set environment variable for Flask
ENV FLASK_APP=app.py
ENV PYTHONUNBUFFERED=1
ENV PORT=5000

# Run the application via start.sh so PORT is resolved in script
RUN chmod +x start.sh
CMD ["./start.sh"]

