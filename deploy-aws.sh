#!/bin/bash

# AWS App Runner Deployment Script
# Prerequisites: AWS CLI configured with appropriate credentials

set -e

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REPO_NAME="${ECR_REPO_NAME:-tiny-feedback-backend}"
APP_NAME="${APP_NAME:-tiny-feedback-api}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "🚀 Deploying FastAPI Backend to AWS App Runner"
echo "================================================"
echo "Region: $AWS_REGION"
echo "ECR Repo: $ECR_REPO_NAME"
echo "App Name: $APP_NAME"
echo ""

# Step 1: Get AWS Account ID
echo "📋 Getting AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: $AWS_ACCOUNT_ID"

# Step 2: Create ECR repository if it doesn't exist
echo ""
echo "📦 Creating ECR repository (if not exists)..."
aws ecr describe-repositories --repository-names $ECR_REPO_NAME --region $AWS_REGION 2>/dev/null || \
    aws ecr create-repository --repository-name $ECR_REPO_NAME --region $AWS_REGION

ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME"
echo "ECR URI: $ECR_URI"

# Step 3: Login to ECR
echo ""
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

# Step 4: Build Docker image
echo ""
echo "🏗️  Building Docker image..."
docker build -t $ECR_REPO_NAME:$IMAGE_TAG .

# Step 5: Tag image for ECR
echo ""
echo "🏷️  Tagging image..."
docker tag $ECR_REPO_NAME:$IMAGE_TAG $ECR_URI:$IMAGE_TAG

# Step 6: Push to ECR
echo ""
echo "⬆️  Pushing image to ECR..."
docker push $ECR_URI:$IMAGE_TAG

# Step 7: Deploy to App Runner (optional - can be done via Console or apprunner.yaml)
echo ""
echo "✅ Image pushed successfully!"
echo ""
echo "ECR Image URI: $ECR_URI:$IMAGE_TAG"
echo ""
echo "Next steps:"
echo "1. Go to AWS App Runner Console: https://console.aws.amazon.com/apprunner/home?region=$AWS_REGION"
echo "2. Click 'Create service'"
echo "3. Choose 'Container registry' -> 'Amazon ECR'"
echo "4. Select image: $ECR_URI:$IMAGE_TAG"
echo "5. Configure:"
echo "   - Port: 8000"
echo "   - Health check path: /api/feedback"
echo "   - Auto-scaling: Configure as needed"
echo "6. Deploy!"
echo ""
echo "Or use the AWS CLI to create the service automatically:"
echo "./create-apprunner-service.sh"

