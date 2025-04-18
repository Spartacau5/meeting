#!/bin/bash
set -e

echo "=== Deploying BetterMeet Frontend Only ==="

# Project settings
PROJECT_ID="verdant-coyote-455921-h1"
REGION="us-central1"
FRONTEND_BUCKET="bettermeet-frontend"

# Step 1: Authenticate and set project
echo "Authenticating with Google Cloud..."
gcloud auth login
gcloud config set project $PROJECT_ID

# Step 2: Enable required APIs
echo "Enabling required services..."
gcloud services enable storage.googleapis.com

# Step 3: Deploy Frontend to Cloud Storage
echo "Deploying frontend to Cloud Storage..."
gsutil ls -b gs://$FRONTEND_BUCKET || gsutil mb -l $REGION gs://$FRONTEND_BUCKET
gsutil iam ch allUsers:objectViewer gs://$FRONTEND_BUCKET
gsutil -m cp -r frontend/dist/* gs://$FRONTEND_BUCKET/
gsutil web set -m index.html gs://$FRONTEND_BUCKET

# Step 4: Configure CORS for the bucket
echo "Configuring CORS for the bucket..."
cat > cors-config.json << EOL
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "OPTIONS"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
    "maxAgeSeconds": 3600
  }
]
EOL

gsutil cors set cors-config.json gs://$FRONTEND_BUCKET
rm cors-config.json

# Step 5: Get deployment URL
FRONTEND_URL="https://storage.googleapis.com/$FRONTEND_BUCKET/index.html"

echo "=== Deployment Complete ==="
echo "Frontend URL: $FRONTEND_URL"
echo ""
echo "IMPORTANT: For now, only the frontend is deployed, which means:"
echo "1. You can see the UI but backend functionality won't work"
echo "2. For a full deployment, consider using Firebase Hosting with Cloud Functions"
echo "3. Or use a simpler Go hosting service like Heroku or DigitalOcean" 