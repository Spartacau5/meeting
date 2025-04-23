#!/bin/bash
set -e

# Get the backend URL from Cloud Run
BACKEND_URL=$(gcloud run services describe bettermeet-server --region us-central1 --format="value(status.url)")

# Update the .env file in the frontend directory
cd frontend
echo "Updating frontend configuration with backend URL: $BACKEND_URL"

# Create or update the .env file
cat > .env << EOL
VUE_APP_API_URL=$BACKEND_URL/api
VUE_APP_SOCKET_URL=$BACKEND_URL
VUE_APP_ENVIRONMENT=production
VUE_APP_GOOGLE_CLIENT_ID=1069428562087-rtluai2vp0gg1vk2cq86nmr4l7ik4uke.apps.googleusercontent.com
EOL

# Rebuild and redeploy the frontend
npm run build
cd ..
firebase deploy

echo "Update completed successfully!"
echo "Frontend available at: https://verdant-coyote-455921-h1.web.app"
echo "Backend available at: $BACKEND_URL" 