#!/bin/bash

# Exit on error
set -e

echo "=== BetterMeet GCP Deployment Script ==="

# Configuration
PROJECT_ID="verdant-coyote-455921-h1"
REGION="us-central1"
CREDENTIALS_FILE="verdant-coyote-455921-h1-22d94077f635.json"
SERVER_SERVICE_NAME="bettermeet-server"
FRONTEND_BUCKET_NAME="bettermeet-frontend"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Functions
function check_prereqs() {
  echo -e "${YELLOW}Checking prerequisites...${NC}"
  
  # Check if gcloud is installed
  if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Google Cloud SDK not found. Please install it:${NC}"
    echo "https://cloud.google.com/sdk/docs/install"
    exit 1
  fi
  
  # Check if docker is installed
  if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker not found. Please install it:${NC}"
    echo "https://docs.docker.com/get-docker/"
    exit 1
  fi
  
  # Check if npm is installed
  if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm not found. Please install Node.js and npm:${NC}"
    echo "https://nodejs.org/en/download/"
    exit 1
  fi
  
  # Verify the credentials file exists
  if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo -e "${RED}GCP credentials file not found: $CREDENTIALS_FILE${NC}"
    echo "Please place your credentials file in the current directory."
    exit 1
  fi
  
  echo -e "${GREEN}All prerequisites satisfied.${NC}"
}

function setup_gcloud() {
  echo -e "${YELLOW}Setting up Google Cloud...${NC}"
  
  # Set GCP credentials
  export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/$CREDENTIALS_FILE"
  
  # Authenticate with service account
  gcloud auth activate-service-account --key-file="$CREDENTIALS_FILE"
  
  # Set the current project
  gcloud config set project $PROJECT_ID
  
  # Configure Docker to use gcloud as a credential helper
  echo -e "${YELLOW}Configuring Docker authentication for GCR...${NC}"
  gcloud auth configure-docker gcr.io --quiet
  
  # Enable required APIs
  echo "Enabling required APIs..."
  gcloud services enable cloudresourcemanager.googleapis.com
  gcloud services enable artifactregistry.googleapis.com
  gcloud services enable cloudbuild.googleapis.com
  gcloud services enable run.googleapis.com
  gcloud services enable storage.googleapis.com
  
  echo -e "${GREEN}Google Cloud setup complete.${NC}"
}

function test_container_locally() {
  echo -e "${YELLOW}Testing container locally before deployment...${NC}"
  
  # Name of local test container
  LOCAL_CONTAINER_NAME="bettermeet-server-test"
  LOCAL_IMAGE_NAME="bettermeet-server-local"
  
  # Stop and remove any existing test container
  echo "Cleaning up any existing test containers..."
  docker stop $LOCAL_CONTAINER_NAME 2>/dev/null || true
  docker rm $LOCAL_CONTAINER_NAME 2>/dev/null || true

  # Copy the credentials file to the server directory for Docker build context
  echo "Copying credentials file to server directory..."
  cp "../$CREDENTIALS_FILE" .
  
  # Build the container for local testing
  echo "Building container for local testing..."
  docker build -t $LOCAL_IMAGE_NAME -f Dockerfile.cloud .
  
  # Run the container locally with the right environment variables
  echo "Running container locally..."
  docker run --name $LOCAL_CONTAINER_NAME -d \
    -p 8080:8080 \
    -e PORT=8080 \
    -e K_SERVICE=test \
    -e GOOGLE_APPLICATION_CREDENTIALS="/app/$CREDENTIALS_FILE" \
    -e SKIP_GCLOUD_INIT=true \
    $LOCAL_IMAGE_NAME
  
  # Wait for container to start
  echo "Waiting for container to start..."
  sleep 5
  
  # Check if container is running
  if ! docker ps | grep -q $LOCAL_CONTAINER_NAME; then
    echo -e "${RED}Container failed to start. Checking logs...${NC}"
    docker logs $LOCAL_CONTAINER_NAME
    echo -e "${RED}Local container test failed. Please fix the issues before deploying.${NC}"
    
    # Clean up the copied credentials file
    rm -f "$CREDENTIALS_FILE"
    
    return 1
  fi
  
  # Test the health endpoint
  echo "Testing container health check..."
  HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health || echo "failed")
  
  if [ "$HEALTH_STATUS" -eq 200 ]; then
    echo -e "${GREEN}Container health check passed (HTTP 200)${NC}"
  else
    echo -e "${RED}Container health check failed (HTTP $HEALTH_STATUS)${NC}"
    echo "Response from server:"
    curl -v http://localhost:8080/health || echo "Connection failed"
    echo "Container logs:"
    docker logs $LOCAL_CONTAINER_NAME
    echo -e "${RED}Local container test failed. Please fix the issues before deploying.${NC}"
    
    # Stop and remove the test container
    docker stop $LOCAL_CONTAINER_NAME
    docker rm $LOCAL_CONTAINER_NAME
    
    # Clean up the copied credentials file
    rm -f "$CREDENTIALS_FILE"
    
    return 1
  fi
  
  # Stop and remove the test container
  echo "Cleaning up test container..."
  docker stop $LOCAL_CONTAINER_NAME
  docker rm $LOCAL_CONTAINER_NAME
  
  echo -e "${GREEN}Local container test successful!${NC}"
  
  # Keep the copied credentials file for building the deployment image
  
  return 0
}

function deploy_backend() {
  echo -e "${YELLOW}Deploying backend to Cloud Run...${NC}"
  
  cd server
  
  # Fix go.mod file to remove toolchain directive if present
  echo "Checking and fixing go.mod file..."
  if grep -q "^toolchain" go.mod; then
    sed -i '' '/^toolchain/d' go.mod
  fi
  
  # Create a modified version of main.go that conditionally initializes Cloud Tasks
  echo "Creating a modified version of main.go..."
  cp main.go main.go.original
  
  # Add a conditional to skip gcloud initialization during testing
  sed -i '' 's|// Init google cloud stuff|// Init google cloud stuff\n\tskipGcloud := os.Getenv("SKIP_GCLOUD_INIT")\n\tif skipGcloud != "true" {|' main.go
  sed -i '' 's|defer closeTasks()|defer closeTasks()\n\t}|' main.go
  
  # Create a custom Dockerfile for Cloud Run
  echo "Creating a custom Dockerfile for Cloud Run..."
  cat > Dockerfile.cloud << EOL
# Use an official Go runtime as a parent image
FROM golang:1.23rc1-bullseye AS builder

# Set the working directory in the container
WORKDIR /app

# Copy go.mod and go.sum files
COPY go.mod go.sum ./

# Download all dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the application with proper configuration
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server .

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

  # Test the container locally before deployment
  echo "Testing container locally before deployment..."
  if ! test_container_locally; then
    echo -e "${RED}Local container test failed. Aborting deployment.${NC}"
    
    # Restore the original main.go
    mv main.go.original main.go
    
    cd ..
    return 1
  fi

  # Build the Docker image with platform specification for x86_64/amd64
  echo "Building Docker image for amd64/linux platform..."
  IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVER_SERVICE_NAME"
  docker buildx build --platform linux/amd64 -t $IMAGE_NAME -f Dockerfile.cloud .
  
  # Verify authentication before push
  echo "Verifying Docker authentication for GCR..."
  gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://gcr.io
  
  # Push the image to GCR
  echo "Pushing Docker image to GCR..."
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
  echo -e "${GREEN}Server deployed to: $SERVER_URL${NC}"
  
  # Restore the original main.go
  mv main.go.original main.go
  
  # Clean up the copied credentials file
  rm -f "$CREDENTIALS_FILE"
  
  cd ..
  
  return 0
}

function deploy_frontend() {
  echo -e "${YELLOW}Building and deploying frontend...${NC}"
  
  cd frontend
  
  # Get the backend URL
  SERVER_URL=$(gcloud run services describe $SERVER_SERVICE_NAME --region $REGION --format="value(status.url)")
  
  # Update the API endpoint in environment variables
  echo "VUE_APP_API_URL=$SERVER_URL" > .env
  echo -e "${GREEN}Updated frontend .env with backend URL: $SERVER_URL${NC}"
  
  # Install dependencies and build
  echo "Installing frontend dependencies..."
  npm install
  
  echo "Building frontend..."
  npm run build
  
  # Create a storage bucket for the frontend if it doesn't exist
  echo "Setting up Cloud Storage bucket..."
  if ! gsutil ls -b gs://$FRONTEND_BUCKET_NAME &>/dev/null; then
    gsutil mb -l $REGION gs://$FRONTEND_BUCKET_NAME
    echo "Created new bucket: $FRONTEND_BUCKET_NAME"
  else
    echo "Using existing bucket: $FRONTEND_BUCKET_NAME"
  fi
  
  # Make the bucket public
  echo "Setting bucket permissions..."
  gsutil iam ch allUsers:objectViewer gs://$FRONTEND_BUCKET_NAME
  
  # Upload the frontend build to the bucket
  echo "Uploading frontend files..."
  gsutil -m cp -r dist/* gs://$FRONTEND_BUCKET_NAME/
  
  # Configure the bucket for website hosting
  echo "Configuring bucket for web hosting..."
  gsutil web set -m index.html gs://$FRONTEND_BUCKET_NAME
  
  # Get the frontend URL
  FRONTEND_URL="https://storage.googleapis.com/$FRONTEND_BUCKET_NAME/index.html"
  echo -e "${GREEN}Frontend deployed to: $FRONTEND_URL${NC}"
  
  cd ..
  
  return 0
}

function setup_cloud_build() {
  echo -e "${YELLOW}Setting up Cloud Build for continuous deployment...${NC}"
  
  # Check if cloudbuild.yaml exists
  if [ -f "cloudbuild.yaml" ]; then
    echo "Using existing cloudbuild.yaml configuration."
  else
    echo -e "${RED}cloudbuild.yaml not found. Skipping Cloud Build setup.${NC}"
    return 1
  fi
  
  # Connect the repository to Cloud Build (this part requires manual setup in GCP Console)
  echo -e "${YELLOW}To set up continuous deployment:${NC}"
  echo "1. Go to https://console.cloud.google.com/cloud-build/triggers"
  echo "2. Click 'CREATE TRIGGER'"
  echo "3. Connect your repository"
  echo "4. Configure the trigger to use the cloudbuild.yaml file"
  
  return 0
}

# Main execution
check_prereqs
setup_gcloud
deploy_backend
deploy_frontend
setup_cloud_build

echo -e "${GREEN}=== Deployment completed successfully! ===${NC}"
echo -e "${GREEN}Backend URL: $(gcloud run services describe $SERVER_SERVICE_NAME --region $REGION --format="value(status.url)")${NC}"
echo -e "${GREEN}Frontend URL: https://storage.googleapis.com/$FRONTEND_BUCKET_NAME/index.html${NC}"
echo ""
echo -e "${YELLOW}Note: For a custom domain, configure Cloud DNS and set up HTTPS with Cloud Load Balancing.${NC}"
echo -e "${YELLOW}Important: This deployment uses a simplified server. You'll need to update it to include your full application logic.${NC}" 