#!/bin/bash

# Create AWS App Runner Service
# Run this after deploy-aws.sh

set -e

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REPO_NAME="${ECR_REPO_NAME:-tiny-feedback-backend}"
APP_NAME="${APP_NAME:-tiny-feedback-api}"
SERVICE_NAME="${SERVICE_NAME:-tiny-feedback-service}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "🚀 Creating AWS App Runner Service"
echo "===================================="

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG"

# Check if service already exists
if aws apprunner list-services --region $AWS_REGION --query "ServiceSummaryList[?ServiceName=='$SERVICE_NAME']" --output text | grep -q "$SERVICE_NAME"; then
    echo "⚠️  Service '$SERVICE_NAME' already exists. Updating..."
    
    SERVICE_ARN=$(aws apprunner list-services --region $AWS_REGION --query "ServiceSummaryList[?ServiceName=='$SERVICE_NAME'].ServiceArn" --output text)
    
    # Update service
    aws apprunner update-service \
        --service-arn "$SERVICE_ARN" \
        --source-configuration "ImageRepository={ImageIdentifier=$ECR_URI,ImageConfiguration={Port=8000},ImageRepositoryType=ECR}" \
        --region $AWS_REGION
    
    echo "✅ Service updated successfully!"
else
    echo "Creating new service..."
    
    # Create IAM role for App Runner if it doesn't exist
    ROLE_NAME="AppRunnerECRAccessRole"
    
    if ! aws iam get-role --role-name $ROLE_NAME 2>/dev/null; then
        echo "Creating IAM role for App Runner..."
        
        cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "build.apprunner.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
        
        aws iam create-role \
            --role-name $ROLE_NAME \
            --assume-role-policy-document file:///tmp/trust-policy.json
        
        aws iam attach-role-policy \
            --role-name $ROLE_NAME \
            --policy-arn arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess
        
        sleep 10  # Wait for role to propagate
    fi
    
    ROLE_ARN="arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME"
    
    # Create service
    aws apprunner create-service \
        --service-name $SERVICE_NAME \
        --source-configuration "ImageRepository={ImageIdentifier=$ECR_URI,ImageConfiguration={Port=8000,RuntimeEnvironmentVariables={ENVIRONMENT=production}},ImageRepositoryType=ECR},AutoDeploymentsEnabled=true,AuthenticationConfiguration={AccessRoleArn=$ROLE_ARN}" \
        --instance-configuration "Cpu=1024,Memory=2048" \
        --health-check-configuration "Protocol=HTTP,Path=/api/feedback,Interval=10,Timeout=5,HealthyThreshold=1,UnhealthyThreshold=5" \
        --region $AWS_REGION
    
    echo "✅ Service created successfully!"
fi

echo ""
echo "⏳ Waiting for service to be ready..."
aws apprunner wait service-running --service-arn $(aws apprunner list-services --region $AWS_REGION --query "ServiceSummaryList[?ServiceName=='$SERVICE_NAME'].ServiceArn" --output text) --region $AWS_REGION || true

# Get service URL
SERVICE_URL=$(aws apprunner list-services --region $AWS_REGION --query "ServiceSummaryList[?ServiceName=='$SERVICE_NAME'].ServiceUrl" --output text)

echo ""
echo "🎉 Deployment Complete!"
echo "======================="
echo "Service URL: https://$SERVICE_URL"
echo "API Endpoint: https://$SERVICE_URL/api/feedback"
echo ""
echo "Update your Next.js frontend with:"
echo "NEXT_PUBLIC_API_URL=https://$SERVICE_URL"

