hy #!/bin/bash
set -e

echo "=== BetterMeet Firebase Deployment Script ==="

# Configuration
PROJECT_ID="verdant-coyote-455921-h1"
REGION="us-central1"
SERVER_SERVICE_NAME="bettermeet-server"
CREDENTIALS_FILE="verdant-coyote-455921-h1-22d94077f635.json"
GOOGLE_CLIENT_ID="1069428562087-rtluai2vp0gg1vk2cq86nmr4l7ik4uke.apps.googleusercontent.com"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Check if already authenticated with Google Cloud
echo "Checking Google Cloud authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo "Not authenticated with Google Cloud. Logging in..."
    gcloud auth login
else
    echo "Already authenticated with Google Cloud."
fi

# Set project without requiring re-authentication
gcloud config set project $PROJECT_ID

# Verify credentials file exists
if [ ! -f "$CREDENTIALS_FILE" ]; then
  echo "Error: Credentials file not found: $CREDENTIALS_FILE"
  exit 1
fi

# Copy the credentials file to the server directory
echo "Copying credentials file to server directory..."
cp "$CREDENTIALS_FILE" server/

# Navigate to server directory
cd server

# Create backup of go.mod
echo "Creating backup of go.mod..."
cp go.mod go.mod.backup

# Fix go.mod to match Cloud Run's supported Go version
echo "Updating go.mod file to use Cloud Run compatible Go version..."
sed -i '' 's/go 1.2[0-9].*/go 1.21/' go.mod
sed -i '' '/^toolchain/d' go.mod

# Run go mod tidy
echo "Running go mod tidy..."
go mod tidy -e

# Build and deploy to Cloud Run
echo "Deploying to Cloud Run..."
gcloud run deploy $SERVER_SERVICE_NAME \
  --source . \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated \
  --timeout 300s \
  --cpu 1 \
  --memory 512Mi \
  --max-instances 10 \
  --min-instances 1

# Restore original go.mod
echo "Restoring original go.mod..."
mv go.mod.backup go.mod

# Get the server URL
BACKEND_URL=$(gcloud run services describe $SERVER_SERVICE_NAME --region $REGION --format="value(status.url)")
echo "Backend URL: $BACKEND_URL"

# Return to root directory
cd ..

# Now build and deploy the frontend
echo "Building and deploying frontend..."
cd frontend

# Update the API endpoint in environment variables
echo "Updating frontend configuration..."
cat > .env << EOL
VUE_APP_API_URL=$BACKEND_URL/api
VUE_APP_SOCKET_URL=$BACKEND_URL
VUE_APP_ENVIRONMENT=production
VUE_APP_GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
EOL

echo "Frontend environment configuration:"
cat .env

# Build frontend
echo "Building frontend..."
npm install
npm run build

cd ..

# Update Firebase config to include proper rewrites
echo "Updating Firebase configuration..."
cat > firebase.json << EOL
{
  "hosting": {
    "public": "frontend/dist",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "/api/**",
        "run": {
          "serviceId": "$SERVER_SERVICE_NAME",
          "region": "$REGION"
        }
      },
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
EOL

# Check if already authenticated with Firebase
echo "Checking Firebase authentication..."
if ! firebase use --add $PROJECT_ID &>/dev/null; then
    echo "Not authenticated with Firebase. Logging in..."
    firebase login --no-localhost
else
    echo "Already authenticated with Firebase."
fi

# Deploy to Firebase
echo "Deploying to Firebase..."
firebase deploy --project $PROJECT_ID

echo "=== Deployment Complete ==="
echo "Backend URL: $BACKEND_URL"
echo "Frontend URL: https://verdant-coyote-455921-h1.web.app" 