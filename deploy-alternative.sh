#!/bin/bash
set -e

echo "=== Starting BetterMeet Alternative Deployment ==="

# Project settings
PROJECT_ID="verdant-coyote-455921-h1"
REGION="us-central1"
FRONTEND_BUCKET="bettermeet-frontend"

# Step 1: Authenticate and set project
echo "Authenticating with Google Cloud..."
gcloud auth login
gcloud config set project $PROJECT_ID

# Step 2: Enable required APIs
echo "Enabling required services..."
gcloud services enable storage.googleapis.com appengine.googleapis.com

# Step 3: Deploy Frontend 
echo "Deploying frontend..."
gsutil ls -b gs://$FRONTEND_BUCKET || gsutil mb -l $REGION gs://$FRONTEND_BUCKET
gsutil iam ch allUsers:objectViewer gs://$FRONTEND_BUCKET
gsutil -m cp -r frontend/dist/* gs://$FRONTEND_BUCKET/
gsutil web set -m index.html gs://$FRONTEND_BUCKET

# Step 4: Create App Engine application if it doesn't exist
echo "Creating App Engine application if it doesn't exist..."
gcloud app describe || gcloud app create --region=$REGION

# Step 5: Deploy backend to App Engine
echo "Deploying backend to App Engine..."
cd server

# Create a backup of go.mod
echo "Creating backup of go.mod..."
cp go.mod go.mod.backup

# Fix go.mod to match App Engine's supported Go version
echo "Updating go.mod file to use App Engine compatible Go version..."
sed -i '' 's/go 1.23.0/go 1.21/' go.mod
sed -i '' '/^toolchain/d' go.mod

# Update dependency versions for Go 1.21 compatibility
echo "Updating dependencies for Go 1.21 compatibility..."
cat > go.mod.temp << EOL
module schej.it/server

go 1.21

require (
	cloud.google.com/go/cloudtasks v1.10.0
	github.com/alecthomas/template v0.0.0-20190718012654-fb15b899a751
	github.com/brianvoe/sjwt v0.5.1
	github.com/bwmarrin/discordgo v0.27.1
	github.com/gin-contrib/cors v1.4.0
	github.com/gin-contrib/sessions v0.0.5
	github.com/gin-gonic/gin v1.9.1
	github.com/joho/godotenv v1.5.1
	github.com/jonyTF/go-webdav v0.5.2
	github.com/swaggo/files v1.0.1
	github.com/swaggo/gin-swagger v1.6.0
	github.com/swaggo/swag v1.16.1
	go.mongodb.org/mongo-driver v1.12.1
	google.golang.org/api v0.126.0
	google.golang.org/protobuf v1.31.0
	gopkg.in/gomail.v2 v2.0.0-20160411212932-81ebce5c23df
)

require github.com/google/uuid v1.3.0

require (
	cloud.google.com/go/compute v1.19.3
	cloud.google.com/go/compute/metadata v0.2.3
	cloud.google.com/go/iam v1.1.0
	github.com/KyleBanks/depth v1.2.1
	github.com/bytedance/sonic v1.9.1
	github.com/chenzhuoyu/base64x v0.0.0-20221115062448-fe3a3abad311
	github.com/emersion/go-ical v0.0.0-20220611163459-393e09692c74
	github.com/felixge/httpsnoop v1.0.3
	github.com/gabriel-vasile/mimetype v1.4.2
	github.com/gin-contrib/sse v0.1.0
	github.com/go-logr/logr v1.2.4
	github.com/go-logr/stdr v1.2.2
	github.com/go-openapi/jsonpointer v0.19.6
	github.com/go-openapi/jsonreference v0.20.2
	github.com/go-openapi/spec v0.20.9
	github.com/go-openapi/swag v0.22.3
	github.com/go-playground/locales v0.14.1
	github.com/go-playground/universal-translator v0.18.1
	github.com/go-playground/validator/v10 v10.14.0
	github.com/goccy/go-json v0.10.2
	github.com/golang/groupcache v0.0.0-20210331224755-41bb18bfe9da
	github.com/golang/protobuf v1.5.3
	github.com/golang/snappy v0.0.4
	github.com/google/s2a-go v0.1.4
	github.com/googleapis/enterprise-certificate-proxy v0.2.3
	github.com/googleapis/gax-go/v2 v2.11.0
	github.com/gorilla/context v1.1.1
	github.com/gorilla/securecookie v1.1.1
	github.com/gorilla/sessions v1.2.1
	github.com/gorilla/websocket v1.5.0
	github.com/josharian/intern v1.0.0
	github.com/json-iterator/go v1.1.12
	github.com/klauspost/compress v1.16.5
	github.com/klauspost/cpuid/v2 v2.2.4
	github.com/leodido/go-urn v1.2.4
	github.com/mailru/easyjson v0.7.7
	github.com/mattn/go-isatty v0.0.19
	github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd
	github.com/modern-go/reflect2 v1.0.2
	github.com/montanaflynn/stats v0.7.0
	github.com/pelletier/go-toml/v2 v2.0.8
	github.com/teambition/rrule-go v1.8.2
	github.com/twitchyliquid64/golang-asm v0.15.1
	github.com/ugorji/go/codec v1.2.11
	github.com/xdg-go/pbkdf2 v1.0.0
	github.com/xdg-go/scram v1.1.2
	github.com/xdg-go/stringprep v1.0.4
	github.com/youmark/pkcs8 v0.0.0-20201027041543-1326539a0a0a
	go.opencensus.io v0.24.0
	go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc v0.42.0
	go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp v0.42.0
	go.opentelemetry.io/otel v1.16.0
	go.opentelemetry.io/otel/metric v1.16.0
	go.opentelemetry.io/otel/trace v1.16.0
	golang.org/x/arch v0.3.0
	golang.org/x/crypto v0.14.0
	golang.org/x/net v0.17.0
	golang.org/x/oauth2 v0.8.0
	golang.org/x/sync v0.2.0
	golang.org/x/sys v0.13.0
	golang.org/x/text v0.13.0
	golang.org/x/time v0.3.0
	golang.org/x/tools v0.9.1
	google.golang.org/appengine v1.6.7
	google.golang.org/genproto v0.0.0-20230530153820-e85fd2cbaebc
	google.golang.org/genproto/googleapis/api v0.0.0-20230530153820-e85fd2cbaebc
	google.golang.org/genproto/googleapis/rpc v0.0.0-20230530153820-e85fd2cbaebc
	google.golang.org/grpc v1.55.0
	gopkg.in/alexcesaro/quotedprintable.v3 v3.0.0-20150716171945-2caba252f4dc
	gopkg.in/yaml.v3 v3.0.1
)
EOL

mv go.mod.temp go.mod

# Run go mod tidy to ensure dependencies are correct
echo "Running go mod tidy..."
go mod tidy -e

# Deploy to App Engine
echo "Deploying to App Engine..."
gcloud app deploy app.yaml --quiet

# Restore original go.mod
echo "Restoring original go.mod..."
mv go.mod.backup go.mod

cd ..

# Step 6: Get deployment URLs
echo "=== Deployment Complete ==="
BACKEND_URL=$(gcloud app describe --format="value(defaultHostname)")
FRONTEND_URL="https://storage.googleapis.com/$FRONTEND_BUCKET/index.html"

echo "Frontend URL: $FRONTEND_URL"
echo "Backend URL: https://$BACKEND_URL"
echo ""
echo "To update the frontend to use the deployed backend, update the environment variables in the frontend:"
echo "VUE_APP_API_URL=https://$BACKEND_URL" 