# BetterMeet GCP Deployment Guide

This guide explains how to deploy the BetterMeet application to Google Cloud Platform (GCP) using the provided deployment script.

## Prerequisites

Before deploying, ensure you have the following installed and configured:

1. [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
2. [Docker](https://docs.docker.com/get-docker/)
3. [Node.js and npm](https://nodejs.org/en/download/)
4. Access to the GCP project `verdant-coyote-455921-h1`
5. Service account key file (`verdant-coyote-455921-h1-22d94077f635.json`) placed in the project root directory

## Using the Deployment Script

1. Make the deployment script executable:
   ```bash
   chmod +x deploy_to_gcp.sh
   ```

2. Run the deployment script:
   ```bash
   ./deploy_to_gcp.sh
   ```

The script will:
- Check for all required prerequisites
- Set up Google Cloud authentication
- Deploy the Go backend server to Cloud Run
- Build and deploy the Vue.js frontend to Cloud Storage
- Configure the frontend to communicate with the backend
- Provide information on setting up continuous deployment with Cloud Build

## Deployment Architecture

The deployment uses the following GCP services:

1. **Cloud Run**: Hosts the containerized Go backend server
2. **Cloud Storage**: Hosts the static Vue.js frontend files
3. **Container Registry**: Stores the Docker image for the backend
4. **Cloud Build** (optional): Sets up continuous deployment

## Environment Variables

The deployment script automatically sets up the necessary environment variables:

- Backend: Uses the `.env` file in the server directory
- Frontend: Creates/updates the `.env` file with the backend URL

## Continuous Deployment with Cloud Build

The script includes information on setting up continuous deployment using Cloud Build. To enable this:

1. Follow the instructions provided at the end of the script execution
2. Use the existing `cloudbuild.yaml` file for configuration

## Troubleshooting

If you encounter issues during deployment:

1. **Authentication errors**: Ensure your service account key file is correct and has the necessary permissions
2. **Docker errors**: Make sure Docker is running and you have permissions to build/push images
3. **Go build errors**: Check for any toolchain directive issues in `go.mod`
4. **Frontend build errors**: Verify npm dependencies can be installed correctly

## Custom Domain Setup

To set up a custom domain for your deployed application:

1. Configure Cloud DNS with your domain
2. Set up Cloud Load Balancing with HTTPS
3. Update the frontend to use your custom domain

## Maintenance

- To update the application, simply run the deployment script again
- Monitor costs in the GCP Billing section
- Set up monitoring and alerting using Cloud Monitoring

## Security Considerations

- The Cloud Run service is publicly accessible (--allow-unauthenticated)
- The Cloud Storage bucket is configured for public access
- Review these settings for production deployments 