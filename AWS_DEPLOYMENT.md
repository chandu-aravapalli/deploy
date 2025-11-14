# AWS Deployment Guide - FastAPI Backend

This guide will walk you through deploying the FastAPI backend to AWS App Runner with ECR.

## Architecture

- **Backend**: FastAPI on AWS App Runner (containerized via ECR)
- **Frontend**: Next.js on Vercel (or your preferred platform)
- **Storage**: In-memory (upgradeable to RDS/DynamoDB)

## Prerequisites

1. **AWS CLI** installed and configured
   ```bash
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Default region: us-east-1
   # Default output format: json
   ```

2. **Docker** installed and running
   ```bash
   docker --version
   ```

3. **AWS Account** with appropriate permissions:
   - ECR (Elastic Container Registry)
   - App Runner
   - IAM (for service roles)

## Quick Deployment

### Option 1: Automated Deployment (Recommended)

```bash
# Make scripts executable
chmod +x deploy-aws.sh create-apprunner-service.sh

# Deploy to ECR
./deploy-aws.sh

# Create App Runner service
./create-apprunner-service.sh
```

That's it! The scripts will output your API URL.

### Option 2: Manual Deployment

#### Step 1: Build and Push to ECR

```bash
# Set variables
export AWS_REGION=us-east-1
export ECR_REPO_NAME=tiny-feedback-backend
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create ECR repository
aws ecr create-repository --repository-name $ECR_REPO_NAME --region $AWS_REGION

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build image
docker build -t $ECR_REPO_NAME:latest .

# Tag for ECR
docker tag $ECR_REPO_NAME:latest \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:latest
```

#### Step 2: Create App Runner Service

1. Go to [AWS App Runner Console](https://console.aws.amazon.com/apprunner)
2. Click **"Create service"**
3. Choose **"Container registry"** → **"Amazon ECR"**
4. Select your image from ECR
5. Configure:
   - **Deployment trigger**: Manual or Automatic
   - **ECR access role**: Create new or use existing
6. Click **"Next"**
7. Configure service:
   - **Service name**: `tiny-feedback-service`
   - **Port**: `8000`
   - **CPU**: 1 vCPU
   - **Memory**: 2 GB
8. Configure health check:
   - **Protocol**: HTTP
   - **Path**: `/api/feedback`
   - **Interval**: 10 seconds
9. Click **"Next"** → **"Create & deploy"**

Wait 5-10 minutes for deployment to complete.

## Local Testing with Docker

Test your Docker container locally before deploying:

```bash
# Build image
docker build -t tiny-feedback-backend .

# Run container
docker run -p 8000:8000 tiny-feedback-backend

# Test API
curl http://localhost:8000/api/feedback

# Or use docker-compose
docker-compose up
```

## Connect Frontend to Backend

After deployment, you'll get an App Runner URL like:
```
https://abc123xyz.us-east-1.awsapprunner.com
```

### Update Next.js Frontend

**Option 1: Vercel Environment Variables**

1. Go to Vercel Dashboard → Your Project → Settings → Environment Variables
2. Add:
   ```
   NEXT_PUBLIC_API_URL=https://your-app-runner-url.awsapprunner.com
   ```
3. Redeploy your frontend

**Option 2: Local .env.local**

Create `.env.local`:
```bash
NEXT_PUBLIC_API_URL=https://your-app-runner-url.awsapprunner.com
```

## Update & Redeploy

When you make changes to your backend:

```bash
# Build and push new image
./deploy-aws.sh

# App Runner will auto-deploy if configured, or:
./create-apprunner-service.sh  # This updates the service
```

## Monitoring & Logs

### View Logs

```bash
# List services
aws apprunner list-services --region us-east-1

# Get service ARN (from above command)
export SERVICE_ARN="your-service-arn"

# View logs
aws apprunner list-operations --service-arn $SERVICE_ARN --region us-east-1
```

### CloudWatch Logs

App Runner automatically sends logs to CloudWatch:
1. Go to [CloudWatch Console](https://console.aws.amazon.com/cloudwatch)
2. Navigate to **Logs** → **Log groups**
3. Find `/aws/apprunner/tiny-feedback-service`

## Cost Estimation

AWS App Runner pricing (as of 2024):
- **Compute**: $0.064 per vCPU-hour + $0.007 per GB-hour
- **Example**: 1 vCPU + 2GB running 24/7 = ~$50/month
- **Free tier**: 20,000 build minutes per month

ECR pricing:
- **Storage**: $0.10 per GB/month
- **Data transfer**: Free for AWS services in same region

## Troubleshooting

### Service fails to start

Check logs in CloudWatch or App Runner console. Common issues:
- Port mismatch (ensure Dockerfile EXPOSE matches App Runner config)
- Health check failing (verify `/api/feedback` endpoint works)

### Cannot push to ECR

```bash
# Refresh ECR login
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

### Docker build fails

```bash
# Clean build
docker build --no-cache -t tiny-feedback-backend .
```

## Upgrade to Database

To add persistence, consider:
- **Amazon RDS** (PostgreSQL/MySQL)
- **Amazon DynamoDB** (NoSQL)
- **Vercel Postgres** (if keeping some Vercel integration)

Update `api/index.py` to use database instead of `FEEDBACK = []`.

## Security Best Practices

1. **Use secrets management** for sensitive data:
   ```bash
   aws apprunner create-service \
       --service-name tiny-feedback-service \
       ... \
       --instance-configuration "Cpu=1024,Memory=2048" \
       --secrets '[{"Name":"DB_PASSWORD","ValueFrom":"arn:aws:secretsmanager:..."}]'
   ```

2. **Enable HTTPS only** (App Runner provides this by default)

3. **Restrict CORS** in production:
   Update `api/index.py`:
   ```python
   allow_origins=["https://your-frontend-domain.com"]
   ```

4. **Use IAM roles** instead of access keys when possible

## CI/CD Pipeline

Consider setting up GitHub Actions for automatic deployment:

```yaml
# .github/workflows/deploy-backend.yml
name: Deploy to AWS App Runner

on:
  push:
    branches: [main]
    paths:
      - 'api/**'
      - 'Dockerfile'
      - 'requirements.txt'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - name: Deploy
        run: |
          chmod +x deploy-aws.sh create-apprunner-service.sh
          ./deploy-aws.sh
          ./create-apprunner-service.sh
```

## Support

For issues:
- **AWS App Runner**: [AWS Documentation](https://docs.aws.amazon.com/apprunner/)
- **ECR**: [ECR Documentation](https://docs.aws.amazon.com/ecr/)
- **Docker**: [Docker Documentation](https://docs.docker.com/)

## Clean Up

To avoid charges when testing:

```bash
# Delete App Runner service
aws apprunner delete-service \
    --service-arn your-service-arn \
    --region us-east-1

# Delete ECR repository
aws ecr delete-repository \
    --repository-name tiny-feedback-backend \
    --region us-east-1 \
    --force
```

