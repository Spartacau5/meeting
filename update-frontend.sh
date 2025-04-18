#!/bin/bash
set -e

echo "=== Updating BetterMeet Frontend ==="

# Project settings
PROJECT_ID="verdant-coyote-455921-h1"
REGION="us-central1"
FRONTEND_BUCKET="bettermeet-frontend"
BACKEND_URL="https://verdant-coyote-455921-h1.uc.r.appspot.com"

# Step 1: Authenticate and set project
echo "Authenticating with Google Cloud..."
gcloud auth login
gcloud config set project $PROJECT_ID

# Step 2: Update frontend environment variable
echo "Updating frontend API URL..."
cd frontend
echo "VUE_APP_API_URL=$BACKEND_URL" > .env

# Step 3: Rebuild frontend
echo "Building frontend..."
npm install
npm run build

# Step 4: Deploy to bucket
echo "Deploying to Cloud Storage..."
gsutil -m cp -r dist/* gs://$FRONTEND_BUCKET/

echo "=== Frontend Update Complete ==="
echo "Frontend URL: https://storage.googleapis.com/$FRONTEND_BUCKET/index.html"
echo "Backend URL: $BACKEND_URL" 