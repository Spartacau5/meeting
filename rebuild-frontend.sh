#!/bin/bash
set -e

echo "=== Rebuilding Frontend with Fixed Asset Paths ==="

# Project settings
FRONTEND_BUCKET="bettermeet-frontend"
BACKEND_URL="https://verdant-coyote-455921-h1.uc.r.appspot.com"

# Step 1: Update frontend environment variable
echo "Updating frontend API URL..."
cd frontend
echo "VUE_APP_API_URL=$BACKEND_URL" > .env

# Step 2: Rebuild frontend
echo "Building frontend with fixed asset paths..."
npm run build

# Step 3: Create a test HTML file for verification
echo "Creating test HTML file..."
cat > dist/test.html << EOF
<!DOCTYPE html>
<html>
<head>
  <title>Test Page</title>
</head>
<body>
  <h1>If you can see this, the bucket is configured correctly</h1>
</body>
</html>
EOF

# Step 4: Deploy to bucket
echo "Deploying to Cloud Storage..."
gsutil -m rm -r gs://$FRONTEND_BUCKET/** || true
gsutil -m cp -r dist/* gs://$FRONTEND_BUCKET/

# Step 5: Make sure all objects are publicly readable
echo "Ensuring public access..."
gsutil -m acl ch -r -u AllUsers:R gs://$FRONTEND_BUCKET

# Step 6: Set proper CORS headers
echo "Setting CORS headers..."
cat > cors.json << EOF
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "OPTIONS"],
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin", "Cache-Control"],
    "maxAgeSeconds": 3600
  }
]
EOF

gsutil cors set cors.json gs://$FRONTEND_BUCKET
rm cors.json

echo "=== Frontend Rebuild Complete ==="
echo "Frontend URL: https://storage.googleapis.com/$FRONTEND_BUCKET/index.html"
echo "Test URL: https://storage.googleapis.com/$FRONTEND_BUCKET/test.html"
echo "Backend URL: $BACKEND_URL" 