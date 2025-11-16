#!/bin/bash

# Docker build script for FastAPI

echo "🐳 Building Docker image for FastAPI..."

# Build the Docker image
docker build -t feedback-api:latest .

echo "✅ Docker image built successfully!"
echo ""
echo "To run the container:"
echo "  docker run -p 8000:8000 feedback-api:latest"
echo ""
echo "To run with docker-compose:"
echo "  cd .. && docker-compose up"

