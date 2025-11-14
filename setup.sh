#!/bin/bash

# Setup script for Tiny Feedback Board

echo "🚀 Setting up Tiny Feedback Board..."

# Create Python virtual environment
echo "📦 Creating Python virtual environment..."
python3 -m venv venv

# Activate virtual environment
echo "✅ Activating virtual environment..."
source venv/bin/activate

# Install Python dependencies
echo "📥 Installing Python dependencies..."
pip install -r requirements.txt
pip install uvicorn

# Install Node.js dependencies
echo "📥 Installing Node.js dependencies..."
npm install

echo ""
echo "✨ Setup complete!"
echo ""
echo "To start development:"
echo "1. Activate venv:     source venv/bin/activate"
echo "2. Run FastAPI:       cd api && uvicorn index:app --reload --port 8000"
echo "3. Run Next.js:       npm run dev (in a new terminal)"
echo ""

