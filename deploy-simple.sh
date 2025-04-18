#!/bin/bash
set -e

echo "=== Starting BetterMeet Deployment ==="

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
gcloud services enable run.googleapis.com storage.googleapis.com cloudbuild.googleapis.com

# Step 3: Deploy Frontend 
echo "Deploying frontend..."
gsutil ls -b gs://$FRONTEND_BUCKET || gsutil mb -l $REGION gs://$FRONTEND_BUCKET
gsutil iam ch allUsers:objectViewer gs://$FRONTEND_BUCKET
gsutil -m cp -r frontend/dist/* gs://$FRONTEND_BUCKET/
gsutil web set -m index.html gs://$FRONTEND_BUCKET

# Step 4: Use Cloud Run buildpacks to deploy the server
echo "Deploying backend..."
cd server

# Create a proper .gcloudignore file
echo "Creating .gcloudignore file..."
cat > .gcloudignore << EOL
.git
.gitignore
.DS_Store
server
tmp/
*.log
EOL

# Set build env var to indicate Go version
echo "Setting GOOGLE_RUNTIME_VERSION=1.23 in .env file..."
if grep -q "GOOGLE_RUNTIME_VERSION" .env; then
  sed -i '' 's/GOOGLE_RUNTIME_VERSION=.*/GOOGLE_RUNTIME_VERSION=1.23/' .env
else
  echo "GOOGLE_RUNTIME_VERSION=1.23" >> .env
fi

# Deploy the server using Cloud Run's built-in buildpacks
echo "Deploying to Cloud Run..."
gcloud run deploy bettermeet-server \
  --source . \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --cpu 1 \
  --memory 512Mi

cd ..

# Step 5: Get deployment URLs
echo "=== Deployment Complete ==="
BACKEND_URL=$(gcloud run services describe bettermeet-server --region $REGION --format="value(status.url)")
FRONTEND_URL="https://storage.googleapis.com/$FRONTEND_BUCKET/index.html"

echo "Frontend URL: $FRONTEND_URL"
echo "Backend URL: $BACKEND_URL"
echo ""
echo "To update the frontend to use the deployed backend, update the environment variables." 