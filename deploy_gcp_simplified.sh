#!/bin/bash

# Exit on error
set -e

echo "=== BetterMeet GCP Simplified Deployment Script ==="

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Please install Homebrew first:"
    echo "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Check if Google Cloud SDK is installed, install if not
if ! command -v gcloud &> /dev/null; then
    echo "Installing Google Cloud SDK..."
    brew install --cask google-cloud-sdk
    
    # Initialize gcloud
    echo "Initializing Google Cloud SDK..."
    gcloud init
else
    echo "Google Cloud SDK already installed."
fi

# Configuration
PROJECT_ID="verdant-coyote-455921-h1"
REGION="us-central1"
CREDENTIALS_FILE="verdant-coyote-455921-h1-22d94077f635.json"
SERVER_SERVICE_NAME="bettermeet-server"
FRONTEND_BUCKET_NAME="bettermeet-frontend"

# Verify the credentials file exists
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "GCP credentials file not found: $CREDENTIALS_FILE"
    echo "Please place your credentials file in the current directory."
    exit 1
fi

# Set GCP credentials
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/$CREDENTIALS_FILE"

# Authenticate with Google account
echo "Authenticating with Google account..."
gcloud auth login

# Set the current project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable storage.googleapis.com

# Fix go.mod file to remove toolchain directive
echo "Fixing go.mod file..."
cd server
sed -i '' '/^toolchain/d' go.mod
cd ..

# Deploy to Cloud Run
echo "Deploying server to Cloud Run..."
gcloud run deploy $SERVER_SERVICE_NAME \
  --source server \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated

# Get the server URL
SERVER_URL=$(gcloud run services describe $SERVER_SERVICE_NAME --region $REGION --format="value(status.url)")
echo "Server deployed to: $SERVER_URL"

# Build and deploy the frontend
echo "Building and deploying frontend..."
cd frontend

# Update the API endpoint in environment variables if needed
echo "VUE_APP_API_URL=$SERVER_URL" > .env

# Install dependencies and build
npm install
npm run build

# Create a storage bucket for the frontend if it doesn't exist
gsutil ls -b gs://$FRONTEND_BUCKET_NAME || gsutil mb -l $REGION gs://$FRONTEND_BUCKET_NAME

# Make the bucket public
gsutil iam ch allUsers:objectViewer gs://$FRONTEND_BUCKET_NAME

# Upload the frontend build to the bucket
gsutil -m cp -r dist/* gs://$FRONTEND_BUCKET_NAME/

# Configure the bucket for website hosting
gsutil web set -m index.html gs://$FRONTEND_BUCKET_NAME

# Get the frontend URL
FRONTEND_URL="https://storage.googleapis.com/$FRONTEND_BUCKET_NAME/index.html"
echo "Frontend deployed to: $FRONTEND_URL"

echo "=== Deployment completed successfully! ==="
echo "Backend URL: $SERVER_URL"
echo "Frontend URL: $FRONTEND_URL" 