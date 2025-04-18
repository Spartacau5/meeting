#!/bin/bash

# Exit on error
set -e

BUCKET_NAME="bettermeet-frontend"
REGION="us-central1"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building and redeploying frontend with hash routing...${NC}"

# Navigate to frontend directory
cd frontend

# Build the app with the new configuration
echo "Installing dependencies..."
npm install

echo "Building the application..."
npm run build

# Update the bucket CORS configuration
echo "Configuring CORS for the Cloud Storage bucket..."
gsutil cors set ../cors-config.json gs://$BUCKET_NAME

# Empty the bucket (to ensure clean deployment)
echo "Clearing existing files from bucket..."
gsutil -m rm -r gs://$BUCKET_NAME/** || true

# Upload the new build to the bucket with appropriate caching
echo "Uploading new frontend build..."
gsutil -m cp -r dist/* gs://$BUCKET_NAME/

# Set metadata for proper caching
echo "Setting cache metadata..."
gsutil -m setmeta -h "Cache-Control:public, max-age=3600" gs://$BUCKET_NAME/**/*.html
gsutil -m setmeta -h "Cache-Control:public, max-age=31536000" gs://$BUCKET_NAME/**/*.js
gsutil -m setmeta -h "Cache-Control:public, max-age=31536000" gs://$BUCKET_NAME/**/*.css

# Configure the bucket for web hosting
echo "Configuring for web hosting..."
gsutil web set -m index.html gs://$BUCKET_NAME

echo -e "${GREEN}Frontend redeployed successfully!${NC}"
echo -e "${GREEN}Your frontend is now available at: https://storage.googleapis.com/$BUCKET_NAME/index.html${NC}"
echo -e "${YELLOW}Note: It may take a few minutes for changes to propagate through Google's CDN.${NC}" 