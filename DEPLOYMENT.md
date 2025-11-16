# Deployment Guide - Connecting Amplify Frontend to App Runner Backend

## 🏗️ Architecture

```
Frontend (Next.js)          Backend (FastAPI)
AWS Amplify        ------>  AWS App Runner
                   HTTPS    Port 8080
```

## 📋 Prerequisites

- ✅ Backend deployed on AWS App Runner
- ✅ Frontend code ready for Amplify
- ✅ App Runner URL (format: `https://xxxxx.us-east-1.awsapprunner.com`)

## 🔧 Step-by-Step Connection Guide

### Step 1: Get Your App Runner URL

1. Go to **AWS App Runner Console**: https://console.aws.amazon.com/apprunner
2. Click on your service (e.g., `fastapi-deploy`)
3. Copy the **Default domain** URL (e.g., `https://abc123.us-east-1.awsapprunner.com`)

### Step 2: Update Backend CORS (Optional - Already Configured)

Your backend already allows all origins:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows Amplify domain
)
```

**For production**, update to only allow your Amplify domain:
```python
allow_origins=[
    "https://your-amplify-domain.amplifyapp.com",
    "http://localhost:3000"  # For local development
]
```

### Step 3: Configure Environment Variable in Amplify

#### Option A: Via Amplify Console (Recommended)

1. **Go to AWS Amplify Console**: https://console.aws.amazon.com/amplify
2. **Select your app**
3. Click **"Environment variables"** in the left sidebar
4. Click **"Manage variables"**
5. **Add new variable:**
   - **Key:** `NEXT_PUBLIC_API_URL`
   - **Value:** `https://your-app-runner-url.us-east-1.awsapprunner.com`
   - Example: `https://abc123xyz.us-east-1.awsapprunner.com`
6. Click **"Save"**

#### Option B: Via AWS CLI

```bash
aws amplify update-app \
  --app-id YOUR_APP_ID \
  --environment-variables NEXT_PUBLIC_API_URL=https://your-app-runner-url.us-east-1.awsapprunner.com
```

### Step 4: Redeploy Frontend

After adding the environment variable:

1. Go to **Amplify Console** → Your App
2. Click **"Redeploy this version"**
3. Or push to your connected GitHub repo to trigger auto-deploy

### Step 5: Test the Connection

1. **Open your Amplify URL** (e.g., `https://main.xxxxx.amplifyapp.com`)
2. **Open Browser DevTools** (F12 → Network tab)
3. **Try creating feedback** - you should see:
   - ✅ Request to App Runner URL
   - ✅ Status: 200 OK
   - ✅ CORS headers present

## 🧪 Local Development

For local development, create `.env.local`:

```bash
# Copy the example file
cp .env.local.example .env.local

# Edit .env.local with your App Runner URL
NEXT_PUBLIC_API_URL=https://your-app-runner-url.us-east-1.awsapprunner.com
```

Then run:
```bash
npm run dev
```

## 📊 Environment Variables Summary

| Variable | Value | Where to Set |
|----------|-------|--------------|
| `NEXT_PUBLIC_API_URL` | App Runner URL | Amplify Console → Environment Variables |

**Format:** `https://xxxxx.region.awsapprunner.com` (no trailing slash)

## 🔍 Troubleshooting

### Issue 1: CORS Error

**Symptom:** `Access-Control-Allow-Origin` error in browser console

**Solutions:**
1. Verify backend CORS is configured (already done)
2. Make sure you're using HTTPS (not HTTP) for App Runner URL
3. Check App Runner is running and accessible

### Issue 2: 404 Not Found

**Symptom:** API calls return 404

**Solutions:**
1. Verify App Runner URL is correct (with HTTPS)
2. Check endpoint paths match: `/api/feedback`
3. Ensure backend is deployed and running

### Issue 3: Environment Variable Not Working

**Symptoms:** Still calling localhost or wrong URL

**Solutions:**
1. Verify variable name starts with `NEXT_PUBLIC_` (required for client-side)
2. Redeploy after adding environment variable
3. Check Amplify build logs for the variable
4. Clear browser cache

### Issue 4: Connection Timeout

**Symptom:** Requests take too long or timeout

**Solutions:**
1. Check App Runner service is running
2. Verify security settings allow public access
3. Test App Runner URL directly in browser

## 🔐 Security Best Practices

### 1. Tighten CORS in Production

Update `api/index.py`:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://main.dxxxxx.amplifyapp.com",  # Your Amplify domain
        "https://your-custom-domain.com"        # If using custom domain
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type"],
)
```

Rebuild and redeploy to App Runner.

### 2. Use HTTPS Only

Always use HTTPS URLs - App Runner provides this by default.

### 3. Add Rate Limiting (Future)

Consider adding rate limiting to your FastAPI backend:
```bash
pip install slowapi
```

## 📝 Quick Reference Commands

```bash
# Get App Runner URL
aws apprunner list-services --region us-east-1

# Set Amplify environment variable
aws amplify update-app \
  --app-id YOUR_APP_ID \
  --environment-variables NEXT_PUBLIC_API_URL=YOUR_APP_RUNNER_URL

# Trigger Amplify deployment
aws amplify start-job \
  --app-id YOUR_APP_ID \
  --branch-name main \
  --job-type RELEASE
```

## ✅ Verification Checklist

- [ ] App Runner service is running
- [ ] Copied App Runner URL (with HTTPS)
- [ ] Added `NEXT_PUBLIC_API_URL` to Amplify environment variables
- [ ] Redeployed frontend on Amplify
- [ ] Tested creating feedback on Amplify URL
- [ ] Verified API calls in browser DevTools
- [ ] No CORS errors in console
- [ ] Data persists correctly

## 🎯 Expected Flow

1. User visits Amplify URL
2. Next.js loads and reads `NEXT_PUBLIC_API_URL`
3. Frontend makes requests to App Runner URL
4. App Runner backend responds with JSON
5. Frontend displays data

## 📞 Support

If issues persist:
1. Check App Runner logs in CloudWatch
2. Check Amplify build logs
3. Test App Runner API directly with curl:

```bash
curl https://your-app-runner-url.us-east-1.awsapprunner.com/api/feedback
```

## 🔄 Future Enhancements

- [ ] Add authentication (Cognito)
- [ ] Use API Gateway for rate limiting
- [ ] Add CloudFront CDN
- [ ] Implement database (RDS/DynamoDB)
- [ ] Add monitoring and alerts

