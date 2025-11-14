# Tiny Feedback Board

A simple feedback board application where users can submit short feedback messages and upvote existing ones.

## Tech Stack

- **Frontend**: Next.js 15 (App Router) with TypeScript and Tailwind CSS
- **Backend**: FastAPI (Python)
- **Storage**: In-memory (easily switchable to Vercel Postgres/Neon or RDS)
- **Deployment Options**:
  - Option 1: Backend on AWS App Runner + Frontend on Vercel
  - Option 2: Full stack on Vercel (serverless functions)

## Project Structure

```
tiny-feedback/
├── app/                    # Next.js app router
│   ├── page.tsx           # Main feedback board UI
│   ├── layout.tsx         # Root layout
│   └── globals.css        # Global styles
├── api/                   # Vercel Python Functions (FastAPI)
│   └── index.py          # FastAPI ASGI app
├── requirements.txt       # Python dependencies
├── package.json          # Node.js dependencies
├── next.config.js        # Next.js configuration
├── tailwind.config.ts    # Tailwind CSS configuration
├── tsconfig.json         # TypeScript configuration
└── vercel.json           # Vercel deployment config
```

## Features

- ✅ Submit feedback messages
- ✅ Upvote existing feedback
- ✅ Sorted by votes and recency
- ✅ Fully serverless deployment on Vercel
- ✅ FastAPI running natively on Vercel's Python runtime

## API Endpoints

- `GET /api/feedback` - List all feedback (sorted by votes and recency)
- `POST /api/feedback` - Create new feedback
- `POST /api/feedback/{id}/upvote` - Upvote a feedback item

## Local Development

### Prerequisites

- Node.js 18+ and npm/yarn/pnpm
- Python 3.9+

### Setup

1. **Install Node.js dependencies:**

```bash
npm install
```

2. **Install Python dependencies:**

```bash
pip install -r requirements.txt
```

3. **Run the development server:**

For Next.js:
```bash
npm run dev
```

For FastAPI (in a separate terminal):
```bash
cd api
uvicorn index:app --reload --port 8000
```

4. **Open your browser:**

Navigate to [http://localhost:3000](http://localhost:3000)

## Deployment Options

### Option 1: AWS App Runner (Recommended for Production)

Deploy FastAPI backend to AWS App Runner with ECR for better scalability and control.

**Quick Start:**
```bash
# Make scripts executable
chmod +x deploy-aws.sh create-apprunner-service.sh

# Deploy to AWS
./deploy-aws.sh
./create-apprunner-service.sh
```

📖 **[Full AWS Deployment Guide](AWS_DEPLOYMENT.md)**

After deployment, update your frontend environment variable:
```bash
# In Vercel dashboard or .env.local
NEXT_PUBLIC_API_URL=https://your-app-runner-url.awsapprunner.com
```

### Option 2: Full Vercel Deployment

1. **Install Vercel CLI (optional):**

```bash
npm i -g vercel
```

2. **Deploy:**

```bash
vercel
```

Or simply push to GitHub and connect your repository to Vercel. Vercel will automatically detect:
- Next.js frontend
- FastAPI backend in `/api`
- Python runtime requirements

## Storage Options

### Current: In-Memory

The app currently uses in-memory storage (resets on each deployment/restart). Perfect for testing!

### Upgrade to Vercel Postgres

To persist data, switch to Vercel Postgres (powered by Neon):

1. Add Vercel Postgres to your project in the Vercel dashboard
2. Update `api/index.py` to use `psycopg2` or SQLAlchemy
3. Add `psycopg2-binary` to `requirements.txt`

Example code:
```python
import os
import psycopg2

DATABASE_URL = os.environ.get("POSTGRES_URL")
conn = psycopg2.connect(DATABASE_URL)
```

## Environment Variables

### For AWS Deployment

Copy `env.example` to `.env.local`:

```bash
# Frontend (Next.js)
NEXT_PUBLIC_API_URL=https://your-app-runner-url.awsapprunner.com

# AWS CLI (for deployment scripts)
AWS_REGION=us-east-1
ECR_REPO_NAME=tiny-feedback-backend
```

### For Vercel-Only Deployment

No environment variables needed for the in-memory version!

For Postgres, Vercel automatically provides:
- `POSTGRES_URL`
- `POSTGRES_PRISMA_URL`
- `POSTGRES_URL_NON_POOLING`

## Docker Support

Test locally with Docker:

```bash
# Build and run
docker build -t tiny-feedback-backend .
docker run -p 8000:8000 tiny-feedback-backend

# Or use docker-compose
docker-compose up
```

## Contributing

Feel free to submit issues and pull requests!

## License

MIT

