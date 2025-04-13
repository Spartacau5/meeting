# Gatherly
Gatherly helps you quickly find the best time for your group to meet. It's like When2meet with Google Calendar integration!

Live website: https://gatherly.app

## Project Setup

### Prerequisites
- Node.js and npm
- Go (1.16+)
- MongoDB (4.4+)

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
The backend API will be available at http://localhost:3002

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

## Development

### Debug Backend with Live Reload
- Install `air`, a package that facilitates live reload for Go apps
  - `go install github.com/cosmtrek/air@latest`
- Run `air` in the server directory

### MongoDB Backup and Restore
- Run `mongodump --host="localhost:27017" --db=gatherly` to make a backup
- Run `mongorestore --uri mongodb://localhost:27017 ./dump --drop` to restore
