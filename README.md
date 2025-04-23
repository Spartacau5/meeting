# Gatherly
Gatherly helps you quickly find the best time for your group to meet. It's like When2meet with Google Calendar integration!

Live website: https://gatherly.app

##Latest Deployment Script to run
./deploy-firebase.sh

## Project Setup

### Prerequisites
- Node.js and npm
- Go (1.16+)
- MongoDB (4.4+)
- Firebase account (for authentication)

### Environment Configuration
1. **Frontend Configuration**: 
   - Copy `frontend/.env.template` to `frontend/.env`
   - Fill in the Firebase configuration details (or use the existing ones in firebase.js)

2. **Backend Configuration**:
   - Copy `server/.env.template` to `server/.env`
   - Fill in at minimum the required configuration parameters
   - Set `ENCRYPTION_KEY` for sensitive data encryption

### MongoDB Setup
MongoDB must be running for the server to work properly. Without it, you'll encounter errors when trying to create events.

#### Install MongoDB
**Mac (using Homebrew):**
```bash
brew tap mongodb/brew
brew install mongodb-community
```

**Start MongoDB service:**
```bash
brew services start mongodb-community
```

### Starting the Frontend
```bash
cd frontend
npm install
npm run serve
```
The frontend will be available at http://localhost:8080

### Starting the Backend
```bash
cd server
go run main.go
```
The backend API will be available at http://localhost:3002 (or the port specified in your server/.env file)

API documentation: http://localhost:3002/swagger/index.html

### Starting Both Services
To start both frontend and backend simultaneously:
```bash
# Terminal 1
cd frontend && npm run serve

# Terminal 2
cd server && go run main.go
```

### Common Issues
1. **MongoDB Connection Errors**: If you see errors like "server selection timeout", ensure MongoDB is installed and running.
2. **Frontend Script Confusion**: Use `npm run serve` (not `npm run dev`) to start the frontend.
3. **Backend Import Warnings**: You might see warnings about unused imports in events.go. These don't affect functionality.
4. **Firebase Authentication**: If you see Firebase authentication issues, check your environment variables and ensure they match the configuration in `frontend/src/firebase.js`.

## Development

### Debug Backend with Live Reload
- Install `air`, a package that facilitates live reload for Go apps
  - `go install github.com/cosmtrek/air@latest`
- Run `air` in the server directory

### Firebase Configuration
The project uses Firebase for authentication. If you need to update the Firebase configuration:
1. Update the values in your `frontend/.env` file
2. Ensure the Firebase Admin SDK key is properly configured for the backend

### MongoDB Backup and Restore
- Run `mongodump --host="localhost:27017" --db=gatherly` to make a backup
- Run `mongorestore --uri mongodb://localhost:27017 ./dump --drop` to restore

## Deployment

### Google Cloud Storage Frontend Hosting
This project uses Google Cloud Storage (GCS) for hosting the frontend. 

#### Maintenance Scripts
There are two scripts for managing the frontend deployment:

1. **maintain-frontend-hosting.sh**
   - Fixes the XML error by ensuring proper web hosting configuration
   - Sets the correct content type for index.html
   - Updates CORS configuration
   - Run this script whenever you see the XML error: `./maintain-frontend-hosting.sh`

2. **deploy-frontend-with-config.sh**
   - Builds the frontend
   - Uploads files to GCS
   - Sets all required configurations in one step
   - Use this for deployments: `./deploy-frontend-with-config.sh`

### Backend Deployment
The backend can be deployed to Google Cloud Run using one of the provided deployment scripts:
- `deploy_gcp.sh` - Full deployment script
- `redeploy-backend.sh` - For backend-only updates

#### Firebase Authentication
Make sure the Firebase service account key is properly set up on the backend server.

#### GCS XML Error
If you see an XML file listing instead of your web application, it's because the GCS bucket's web configuration has reset. Run `./maintain-frontend-hosting.sh` to fix it.
