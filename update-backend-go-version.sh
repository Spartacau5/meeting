#!/bin/bash

# Exit on error
set -e

PROJECT_ID="verdant-coyote-455921-h1"
REGION="us-central1"
CREDENTIALS_FILE="verdant-coyote-455921-h1-22d94077f635.json"
SERVER_SERVICE_NAME="bettermeet-server"
GO_VERSION="1.22"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Updating backend Go version to $GO_VERSION and redeploying...${NC}"

# Navigate to server directory
cd server

# Update go.mod file
echo "Updating go.mod file..."
sed -i.bak -E "s/^go [0-9]+\.[0-9]+(\.[0-9]+)?/go $GO_VERSION/" go.mod
rm -f go.mod.bak

# Update MongoDB driver to a version compatible with Go 1.22
echo "Updating MongoDB driver version for compatibility with Go $GO_VERSION..."
go get -u go.mongodb.org/mongo-driver@v1.13.1

# Create a custom Dockerfile for Go 1.22
echo "Creating a custom Dockerfile for Cloud Run with Go $GO_VERSION..."
cat > Dockerfile.cloud << EOL
# Use an official Go 1.22 runtime as a parent image
FROM golang:$GO_VERSION AS builder

# Set the working directory in the container
WORKDIR /app

# Copy go.mod and go.sum files
COPY go.mod go.sum ./

# Download all dependencies
RUN go mod download
RUN go mod tidy

# Copy the source code
COPY . .

# Build the application with proper configuration
# Using -ldflags to reduce binary size and add build info
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o server .

# Use a smaller base image for the final stage
FROM debian:bullseye-slim

# Install CA certificates
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/server /app/
COPY .env /app/
COPY $CREDENTIALS_FILE /app/

# Make the binary executable
RUN chmod +x /app/server

# Set environment variables for Cloud Run
ENV K_SERVICE=bettermeet-server
ENV PORT=8080
ENV GOOGLE_APPLICATION_CREDENTIALS="/app/$CREDENTIALS_FILE"

# Expose the port
EXPOSE 8080

# Run the binary
CMD ["/app/server", "-release"]
EOL

# Copy the credentials file from the project root if needed
echo "Checking if credentials file exists in the current directory..."
if [ ! -f "$CREDENTIALS_FILE" ]; then
  echo "Copying credentials file from project root..."
  cp "../$CREDENTIALS_FILE" .
fi

# Build the Docker image for the specified Go version
echo "Building Docker image with Go $GO_VERSION..."
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVER_SERVICE_NAME"
docker buildx build --platform linux/amd64 -t $IMAGE_NAME -f Dockerfile.cloud .

# Verify authentication before push
echo "Authenticating with Google Cloud Registry..."
gcloud auth activate-service-account --key-file="$CREDENTIALS_FILE"
gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://gcr.io

# Push the image to GCR
echo "Pushing Docker image to Google Container Registry..."
docker push $IMAGE_NAME

# Deploy to Cloud Run
echo "Deploying to Cloud Run..."
gcloud run deploy $SERVER_SERVICE_NAME \
  --image $IMAGE_NAME \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --concurrency 80 \
  --timeout 300s \
  --min-instances 1 \
  --set-env-vars="GOOGLE_APPLICATION_CREDENTIALS=/app/$CREDENTIALS_FILE"

# Get the server URL
SERVER_URL=$(gcloud run services describe $SERVER_SERVICE_NAME --region $REGION --format="value(status.url)")
echo -e "${GREEN}Backend redeployed successfully with Go $GO_VERSION!${NC}"
echo -e "${GREEN}Your backend is now available at: $SERVER_URL${NC}"

# Clean up the copied credentials file if we created it
if [ ! -f "../$CREDENTIALS_FILE" ]; then
  echo "Cleaning up credentials file..."
  rm -f "$CREDENTIALS_FILE"
fi

cd ..

# Update the frontend .env file with the new backend URL
echo "Updating frontend environment with new backend URL..."
echo "VUE_APP_API_URL=$SERVER_URL" > frontend/.env

echo -e "${YELLOW}Note: Consider rebuilding and redeploying the frontend if the backend URL has changed.${NC}" 