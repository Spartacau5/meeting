# BetterMeet GCP Deployment Guide

This guide explains how to deploy the BetterMeet application to Google Cloud Platform (GCP).

## Prerequisites

1. [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and configured
2. Docker installed (for local testing)
3. Access to the GCP project `verdant-coyote-455921-h1`
4. Service account key file (`verdant-coyote-455921-h1-22d94077f635.json`)

## Manual Deployment

### Option 1: Using the deployment script

1. Make the deployment script executable:
   ```bash
   chmod +x deploy_scripts/deploy_to_gcp.sh
   ```

2. Run the deployment script:
   ```bash
   ./deploy_scripts/deploy_to_gcp.sh
   ```

The script will:
- Build and deploy the Go server to Cloud Run
- Build the Vue.js frontend
- Create and configure a Cloud Storage bucket for hosting the frontend
- Upload the frontend build to the bucket

### Option 2: Manual step-by-step deployment

#### Backend Deployment

1. Navigate to the server directory:
   ```bash
   cd server
   ```

2. Build the Docker image:
   ```bash
   docker build -t gcr.io/verdant-coyote-455921-h1/bettermeet-server .
   ```

3. Push the image to Google Container Registry:
   ```bash
   docker push gcr.io/verdant-coyote-455921-h1/bettermeet-server
   ```

4. Deploy to Cloud Run:
   ```bash
   gcloud run deploy bettermeet-server \
     --image gcr.io/verdant-coyote-455921-h1/bettermeet-server \
     --region us-central1 \
     --platform managed \
     --allow-unauthenticated
   ```

#### Frontend Deployment

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Build the frontend:
   ```bash
   npm install
   npm run build
   ```

3. Create a Cloud Storage bucket (if it doesn't exist):
   ```bash
   gsutil mb -l us-central1 gs://bettermeet-frontend
   ```

4. Make the bucket publicly accessible:
   ```bash
   gsutil iam ch allUsers:objectViewer gs://bettermeet-frontend
   ```

5. Upload the frontend build to the bucket:
   ```bash
   gsutil -m cp -r dist/* gs://bettermeet-frontend/
   ```

6. Configure the bucket for web hosting:
   ```bash
   gsutil web set -m index.html gs://bettermeet-frontend
   ```

## Continuous Deployment with Cloud Build

1. Enable the Cloud Build API in your GCP project.

2. Connect your GitHub repository to Cloud Build.

3. Create a Cloud Build trigger that uses the `cloudbuild.yaml` configuration.

4. Each push to the repository will automatically deploy both the backend and frontend.

## Environment Variables

- Backend environment variables are configured in the `.env` file in the server directory.
- Frontend environment variables are set during the build process, particularly `VUE_APP_API_URL` which should point to the deployed backend URL.

## Troubleshooting

- Check Cloud Run logs for backend issues
- For frontend issues, verify the Cloud Storage bucket configurations
- Ensure the service account has the necessary permissions

## Maintenance

- To update the application, push changes to the repository or run the deployment script again
- Monitor costs in the GCP Billing section
- Set up monitoring and alerting using Cloud Monitoring 