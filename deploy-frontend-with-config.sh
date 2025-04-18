#!/bin/bash
set -e

# Configuration
BUCKET_NAME="bettermeet-frontend"
FRONTEND_URL="https://storage.googleapis.com/$BUCKET_NAME"

echo "=== BetterMeet Frontend Deployment with Config ==="

# Step 1: Build the frontend
echo "Building frontend..."
cd frontend
npm run build
cd ..

# Step 2: Upload the built files to Cloud Storage
echo "Uploading to Cloud Storage..."
gsutil -m cp -r frontend/dist/* gs://$BUCKET_NAME/

# Step 3: Set the web configuration to serve index.html
echo "Setting web hosting configuration..."
gsutil web set -m index.html gs://$BUCKET_NAME

# Step 4: Ensure index.html has correct content type
echo "Setting content type for index.html..."
gsutil setmeta -h "Content-Type:text/html" gs://$BUCKET_NAME/index.html

# Step 5: Set proper CORS configuration
echo "Setting CORS configuration..."
cat > temp_cors.json << EOF
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "OPTIONS"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin", "Cache-Control"],
    "maxAgeSeconds": 3600
  }
]
EOF
gsutil cors set temp_cors.json gs://$BUCKET_NAME
rm temp_cors.json

echo "=== Deployment Complete ==="
echo "Frontend URL: $FRONTEND_URL"
echo "Frontend URL with explicit index: $FRONTEND_URL/index.html"
echo ""
echo "If you ever see the XML error again, just run ./maintain-frontend-hosting.sh" 