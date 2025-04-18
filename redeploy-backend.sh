#!/bin/bash
set -e

echo "=== Redeploying Backend to App Engine ==="

# Project settings
PROJECT_ID="verdant-coyote-455921-h1"
REGION="us-central1"

# Step 1: Authenticate and set project
echo "Authenticating with Google Cloud..."
gcloud auth login
gcloud config set project $PROJECT_ID

# Step 2: Deploy backend to App Engine
echo "Deploying backend to App Engine..."
cd server

# Create a backup of go.mod
echo "Creating backup of go.mod..."
cp go.mod go.mod.backup

# Fix go.mod to match App Engine's supported Go version
echo "Updating go.mod file to use App Engine compatible Go version..."
sed -i '' 's/go 1.23.0/go 1.21/' go.mod
sed -i '' '/^toolchain/d' go.mod

# Run go mod tidy to ensure dependencies are correct
echo "Running go mod tidy..."
go mod tidy -e

# Deploy to App Engine
echo "Deploying to App Engine..."
gcloud app deploy app.yaml

# Restore original go.mod
echo "Restoring original go.mod..."
mv go.mod.backup go.mod

cd ..

# Step 3: Get deployment URL
echo "=== Deployment Complete ==="
BACKEND_URL=$(gcloud app describe --format="value(defaultHostname)")

echo "Backend URL: https://$BACKEND_URL"
echo ""
echo "Your backend has been redeployed!" 