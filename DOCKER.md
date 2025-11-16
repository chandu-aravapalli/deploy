# Docker Setup for FastAPI Backend

This guide explains how to build and run the FastAPI backend using Docker.

## 📦 Files Overview

- `api/Dockerfile` - Docker configuration for the FastAPI app
- `api/.dockerignore` - Files to exclude from Docker image
- `docker-compose.yml` - Docker Compose configuration for easy orchestration
- `api/docker-build.sh` - Build script

## 🚀 Quick Start

### Option 1: Using Docker directly

**Build the image:**
```bash
cd api
docker build -t feedback-api:latest .
```

**Run the container:**
```bash
docker run -d -p 8000:8000 --name feedback-api feedback-api:latest
```

**Test the API:**
```bash
curl http://localhost:8000/api/feedback
```

**View logs:**
```bash
docker logs feedback-api
```

**Stop the container:**
```bash
docker stop feedback-api
docker rm feedback-api
```

### Option 2: Using Docker Compose (Recommended)

**Start the service:**
```bash
docker-compose up -d
```

**View logs:**
```bash
docker-compose logs -f api
```

**Stop the service:**
```bash
docker-compose down
```

**Rebuild and restart:**
```bash
docker-compose up --build -d
```

### Option 3: Using the build script

```bash
cd api
chmod +x docker-build.sh
./docker-build.sh
```

## 🔧 Docker Image Details

- **Base Image:** Python 3.11 slim
- **Port:** 8000
- **Working Directory:** /app
- **Health Check:** Enabled (checks every 30s)
- **Auto-restart:** Enabled in docker-compose

## 📊 Image Size Optimization

The image uses:
- Python 3.11-slim (smaller base image)
- Multi-stage build potential
- .dockerignore to exclude unnecessary files
- No cache for pip installs

Expected image size: ~150-200MB

## 🌐 API Endpoints (in container)

- `GET http://localhost:8000/api/feedback` - List all feedback
- `POST http://localhost:8000/api/feedback` - Create new feedback
- `POST http://localhost:8000/api/feedback/{id}/upvote` - Upvote feedback

## 🔍 Testing the Container

**Test from host machine:**
```bash
# Get all feedback
curl http://localhost:8000/api/feedback

# Create feedback
curl -X POST http://localhost:8000/api/feedback \
  -H "Content-Type: application/json" \
  -d '{"text": "Great app!"}'

# Upvote feedback (ID 1)
curl -X POST http://localhost:8000/api/feedback/1/upvote
```

## 🐛 Troubleshooting

**Check if container is running:**
```bash
docker ps
```

**Check container logs:**
```bash
docker logs feedback-api
# or with docker-compose
docker-compose logs api
```

**Enter container shell:**
```bash
docker exec -it feedback-api sh
```

**Check health status:**
```bash
docker inspect --format='{{.State.Health.Status}}' feedback-api
```

## 🚢 Deployment Options

### Deploy to Docker Hub

```bash
# Tag the image
docker tag feedback-api:latest yourusername/feedback-api:latest

# Login to Docker Hub
docker login

# Push to Docker Hub
docker push yourusername/feedback-api:latest
```

### Deploy to AWS ECS

1. Push image to Amazon ECR
2. Create ECS task definition
3. Create ECS service with the task

### Deploy to Google Cloud Run

```bash
# Tag for GCR
docker tag feedback-api:latest gcr.io/PROJECT_ID/feedback-api:latest

# Push to GCR
docker push gcr.io/PROJECT_ID/feedback-api:latest

# Deploy to Cloud Run
gcloud run deploy feedback-api \
  --image gcr.io/PROJECT_ID/feedback-api:latest \
  --platform managed \
  --port 8000
```

### Deploy to Azure Container Instances

```bash
# Create resource group
az group create --name feedback-rg --location eastus

# Create container
az container create \
  --resource-group feedback-rg \
  --name feedback-api \
  --image feedback-api:latest \
  --ports 8000 \
  --dns-name-label feedback-api-unique
```

## 🔐 Environment Variables

To add environment variables (for future Postgres integration):

**Docker run:**
```bash
docker run -d -p 8000:8000 \
  -e DATABASE_URL="your-db-url" \
  --name feedback-api \
  feedback-api:latest
```

**Docker Compose:**
```yaml
services:
  api:
    environment:
      - DATABASE_URL=your-db-url
      - API_KEY=your-api-key
```

## 📈 Performance Tips

1. **Use multi-stage builds** for smaller images
2. **Enable caching** in CI/CD pipelines
3. **Use health checks** for container orchestration
4. **Set resource limits** in production:

```yaml
services:
  api:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Docker image
        run: |
          cd api
          docker build -t feedback-api:${{ github.sha }} .
```

## 📝 Notes

- The container uses in-memory storage, so data resets on restart
- For persistent storage, integrate with Postgres/Redis
- The health check ensures the API is responding correctly
- CORS is configured to allow all origins (tighten in production)

## 🆘 Support

For issues, check:
1. Container logs
2. Port conflicts (8000)
3. Docker daemon status
4. Image build logs

