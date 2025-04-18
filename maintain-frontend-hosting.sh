#!/bin/bash
set -e

# Configuration
BUCKET_NAME="bettermeet-frontend"
FRONTEND_URL="https://storage.googleapis.com/$BUCKET_NAME"

echo "=== BetterMeet Frontend Hosting Maintenance ==="
echo "This script ensures the web hosting configuration stays properly set"

# 1. Set the web configuration to serve index.html for both main and error pages
echo "Setting web hosting configuration..."
gsutil web set -m index.html -e index.html gs://$BUCKET_NAME

# 2. Ensure index.html has correct content type and cache control
echo "Setting content type and cache control for index.html..."
gsutil setmeta -h "Content-Type:text/html" -h "Cache-Control:public, max-age=3600" gs://$BUCKET_NAME/index.html

# 3. Set proper CORS configuration
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

# 4. Make sure everything is publicly readable
echo "Ensuring public access..."
gsutil iam ch allUsers:objectViewer gs://$BUCKET_NAME

# 5. Create a copy of index.html as 404.html for SPA support
echo "Creating 404.html for SPA routing support..."
gsutil cp gs://$BUCKET_NAME/index.html gs://$BUCKET_NAME/404.html
gsutil setmeta -h "Content-Type:text/html" -h "Cache-Control:public, max-age=3600" gs://$BUCKET_NAME/404.html

echo "=== Maintenance Complete ==="
echo "Frontend URL: $FRONTEND_URL"
echo "Frontend URL with explicit index: $FRONTEND_URL/index.html"
echo ""
echo "To ensure this doesn't reset, you can:"
echo "1. Run this script manually when needed"
echo "2. Set up a cron job to run it periodically"
echo "3. Consider using Firebase Hosting instead of Cloud Storage for better web hosting" 