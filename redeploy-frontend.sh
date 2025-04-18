#!/bin/bash
set -e

echo "=== Rebuilding and Redeploying Frontend ==="

# Project settings
FRONTEND_BUCKET="bettermeet-frontend"
BACKEND_URL="https://verdant-coyote-455921-h1.uc.r.appspot.com"

# Step 1: Update frontend environment variable
echo "Updating frontend API URL..."
cd frontend
echo "VUE_APP_API_URL=$BACKEND_URL" > .env

# Step 2: Rebuild frontend
echo "Building frontend..."
npm install
npm run build

# Step 3: Deploy to bucket
echo "Deploying to Cloud Storage..."
gsutil -m cp -r dist/* gs://$FRONTEND_BUCKET/

# Step 4: Set proper CORS headers
echo "Setting CORS headers..."
cat > cors.json << EOF
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "OPTIONS"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"],
    "maxAgeSeconds": 3600
  }
]
EOF

gsutil cors set cors.json gs://$FRONTEND_BUCKET
rm cors.json

# Step 5: Make sure all objects are publicly readable
echo "Ensuring public access..."
gsutil -m acl ch -r -u AllUsers:R gs://$FRONTEND_BUCKET

echo "=== Frontend Redeployment Complete ==="
echo "Frontend URL: https://storage.googleapis.com/$FRONTEND_BUCKET/index.html"
echo "Backend URL: $BACKEND_URL" 