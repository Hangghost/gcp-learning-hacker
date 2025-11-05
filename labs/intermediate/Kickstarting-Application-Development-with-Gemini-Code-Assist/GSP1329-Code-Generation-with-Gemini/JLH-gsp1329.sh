#!/bin/bash

# GSP1329 - Code Generation with Gemini
# This script automates the lab steps for code generation with Gemini

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt user for input
prompt_user() {
    local prompt="$1"
    local default="$2"
    local response

    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " response
        response=${response:-$default}
    else
        read -p "$prompt: " response
    fi

    echo "$response"
}

# Function to wait for user confirmation
wait_for_user() {
    local message="$1"
    echo
    echo -e "${YELLOW}$message${NC}"
    read -p "Press Enter to continue..."
}

# Function to check if service is enabled
service_enabled() {
    local service="$1"
    gcloud services list --enabled --filter="name:$service" --format="value(name)" | grep -q "$service"
}

# Cleanup function
cleanup() {
    print_warning "Cleaning up resources..."
    echo "Note: This lab creates persistent resources. Manual cleanup may be required."
    echo "Consider deleting the following if no longer needed:"
    echo "- Cloud Run service: inventory"
    echo "- Cloud Function: newproducts"
    echo "- Container images in Artifact Registry"
    echo "- Cloud Storage bucket: $PROJECT_ID-cymbal-frontend"
}

# Trap cleanup function on script exit
trap cleanup EXIT

# Main script
main() {
    print_status "Starting GSP1329 - Code Generation with Gemini"
    print_status "This script will guide you through the lab steps"

    # Check prerequisites
    print_status "Checking prerequisites..."

    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    if ! command_exists docker; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi

    if ! command_exists npm; then
        print_warning "npm is not installed. Frontend build steps will be skipped."
    fi

    # Authenticate and set project
    print_status "Setting up GCP environment..."

    # Get current project
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [[ -z "$CURRENT_PROJECT" ]] || [[ "$CURRENT_PROJECT" == "(unset)" ]]; then
        PROJECT_ID=$(prompt_user "Enter your GCP Project ID")
        gcloud config set project "$PROJECT_ID"
    else
        PROJECT_ID="$CURRENT_PROJECT"
        print_status "Using current project: $PROJECT_ID"
    fi

    # Get user account
    USER=$(gcloud config get-value account 2>/dev/null)
    if [[ -z "$USER" ]]; then
        print_error "Unable to get user account. Please authenticate with gcloud."
        exit 1
    fi

    # Set region and zone
    REGION=$(prompt_user "Enter the lab region" "us-central1")
    ZONE=$(prompt_user "Enter the lab zone" "us-central1-a")

    # Export environment variables
    export PROJECT_ID="$PROJECT_ID"
    export USER="$USER"
    export REPO_NAME="store-repo"
    export REGION="$REGION"
    export ZONE="$ZONE"
    export APP_NAME="inventory"

    print_success "Environment variables set:"
    echo "  PROJECT_ID: $PROJECT_ID"
    echo "  USER: $USER"
    echo "  REGION: $REGION"
    echo "  ZONE: $ZONE"

    # Task 1: Setup environment and deploy initial backend
    print_status "=== Task 1: Setting up environment and deploying initial backend ==="

    # Configure Docker
    print_status "Configuring Docker authentication..."
    gcloud auth configure-docker --quiet

    # Enable Cloud AI Companion API
    print_status "Enabling Cloud AI Companion API..."
    if ! service_enabled "cloudaicompanion.googleapis.com"; then
        gcloud services enable cloudaicompanion.googleapis.com --project "$PROJECT_ID" --quiet
        print_success "Cloud AI Companion API enabled"
    else
        print_warning "Cloud AI Companion API already enabled"
    fi

    # Grant IAM roles for Gemini
    print_status "Granting IAM roles for Gemini access..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member "user:$USER" \
        --role=roles/cloudaicompanion.user \
        --quiet || print_warning "IAM role cloudaicompanion.user may already be granted"

    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member "user:$USER" \
        --role=roles/serviceusage.serviceUsageViewer \
        --quiet || print_warning "IAM role serviceusage.serviceUsageViewer may already be granted"

    print_success "IAM roles configured"

    # Download cymbal-superstore code
    if [[ ! -d "cymbal-superstore" ]]; then
        print_status "Downloading cymbal-superstore application code..."
        gsutil -m cp -r gs://duet-appdev/cymbal-superstore . || {
            print_error "Failed to download application code. Please check your permissions."
            exit 1
        }
    else
        print_warning "cymbal-superstore directory already exists. Skipping download."
    fi

    # Build and deploy backend
    print_status "Building and deploying backend..."
    cd cymbal-superstore/backend

    # Build container image
    print_status "Building container image..."
    docker build -t "gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api:latest" . || {
        print_error "Failed to build container image."
        exit 1
    }

    # Push to Artifact Registry
    print_status "Pushing image to Artifact Registry..."
    docker push "gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api:latest" || {
        print_error "Failed to push container image."
        exit 1
    }

    # Deploy to Cloud Run
    print_status "Deploying to Cloud Run..."
    CLOUD_RUN_URL=$(gcloud run deploy inventory \
        --image="gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api" \
        --port=8000 \
        --region="$REGION" \
        --allow-unauthenticated \
        --quiet \
        --format="value(status.url)")

    if [[ -z "$CLOUD_RUN_URL" ]]; then
        print_error "Failed to deploy to Cloud Run."
        exit 1
    fi

    print_success "Backend deployed to Cloud Run: $CLOUD_RUN_URL"

    # Test endpoints
    print_status "Testing API endpoints..."
    sleep 5  # Wait for deployment to be ready

    # Test root endpoint
    if curl -s "$CLOUD_RUN_URL" | grep -q "Cymbal Superstore Inventory API"; then
        print_success "Root endpoint working"
    else
        print_warning "Root endpoint may not be responding correctly"
    fi

    # Test /products endpoint
    if curl -s "$CLOUD_RUN_URL/products" | jq . >/dev/null 2>&1; then
        print_success "/products endpoint working"
    else
        print_warning "/products endpoint may not be responding correctly"
    fi

    # Test /newproducts endpoint (should fail initially)
    if curl -s "$CLOUD_RUN_URL/newproducts" | grep -q "Cannot GET"; then
        print_success "/newproducts endpoint correctly returns error (not implemented yet)"
    else
        print_warning "/newproducts endpoint unexpected response"
    fi

    # Build frontend
    print_status "Building frontend..."
    cd ../frontend

    if command_exists npm; then
        # Install dependencies and build
        npm install || print_warning "npm install failed"
        npm audit fix --force || print_warning "npm audit fix failed"

        export NODE_OPTIONS=--openssl-legacy-provider
        npm install react-scripts@5.0.1 --save-dev || print_warning "react-scripts install failed"

        npm run build || {
            print_error "Frontend build failed."
            exit 1
        }

        # Upload to Cloud Storage
        print_status "Uploading frontend to Cloud Storage..."
        BUCKET_NAME="${PROJECT_ID}-cymbal-frontend"

        gcloud storage cp -r build/* "gs://$BUCKET_NAME" \
            --cache-control=no-cache,no-store,max-age=0 \
            --quiet || {
            print_error "Failed to upload frontend to Cloud Storage."
            exit 1
        }

        print_success "Frontend built and uploaded to gs://$BUCKET_NAME"
    else
        print_warning "npm not available. Skipping frontend build."
    fi

    # Task 2: Add newProducts endpoint using Gemini
    print_status "=== Task 2: Adding newProducts endpoint using Gemini ==="

    # Note: This step requires manual interaction with Gemini in the editor
    print_warning "This step requires manual interaction with Gemini in the Cloud Shell Editor."
    echo "Please follow these steps manually:"
    echo "1. Open the editor with 'Open Editor' button"
    echo "2. Navigate to cymbal-superstore/backend/index.ts"
    echo "3. Find the placeholder comment '// /newproducts endpoint goes here'"
    echo "4. Replace with the Gemini prompt as specified in the lab"
    echo "5. Use Gemini to generate the code"
    echo "6. Accept the generated code"

    wait_for_user "Press Enter after you have used Gemini to generate the /newproducts endpoint code"

    # Redeploy backend with new endpoint
    print_status "Redeploying backend with new endpoint..."
    cd ../backend

    # Rebuild and push
    docker build -t "gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api:latest" .
    docker push "gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api:latest"

    # Redeploy
    CLOUD_RUN_URL=$(gcloud run deploy inventory \
        --image="gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api" \
        --port=8000 \
        --region="$REGION" \
        --allow-unauthenticated \
        --quiet \
        --format="value(status.url)")

    print_success "Backend redeployed: $CLOUD_RUN_URL"

    # Test new endpoint
    print_status "Testing /newproducts endpoint..."
    sleep 5

    if curl -s "$CLOUD_RUN_URL/newproducts" | jq . >/dev/null 2>&1; then
        PRODUCT_COUNT=$(curl -s "$CLOUD_RUN_URL/newproducts" | jq length)
        print_success "/newproducts endpoint working - returned $PRODUCT_COUNT products"
    else
        print_error "/newproducts endpoint test failed"
    fi

    # Update frontend configuration
    print_status "Updating frontend configuration..."
    cd ../frontend

    # Find the correct env file
    if [[ -f ".env.production" ]]; then
        ENV_FILE=".env.production"
    elif [[ -f "env.production" ]]; then
        ENV_FILE="env.production"
    else
        print_error "No environment file found"
        exit 1
    fi

    # Update the environment file
    if grep -q "YOUR_ENDPOINT_URL_HERE" "$ENV_FILE"; then
        sed -i.bak "s|YOUR_ENDPOINT_URL_HERE|$CLOUD_RUN_URL|" "$ENV_FILE"
        print_success "Environment file updated with Cloud Run URL"
    else
        print_warning "Could not find YOUR_ENDPOINT_URL_HERE in $ENV_FILE. Please update manually."
    fi

    # Rebuild frontend
    if command_exists npm; then
        print_status "Rebuilding frontend..."
        npm run build

        gcloud storage cp -r build/* "gs://$BUCKET_NAME" \
            --cache-control=no-cache,no-store,max-age=0 \
            --quiet

        print_success "Frontend rebuilt and redeployed"
    fi

    # Task 3: Extract to Cloud Function microservice
    print_status "=== Task 3: Extracting to Cloud Function microservice ==="

    # Note: This step requires manual interaction with Gemini
    print_warning "This step requires manual interaction with Gemini to get the deployment command."
    echo "Please follow these steps manually:"
    echo "1. Open cymbal-superstore/functions/index.js"
    echo "2. Use Gemini to explain the code"
    echo "3. Ask Gemini for the gcloud command to deploy as Cloud Function"
    echo "4. Run the provided command"

    # Prompt for Cloud Function deployment
    echo
    print_status "Please run the Cloud Function deployment command that Gemini provided."
    echo "It should look similar to:"
    echo "gcloud functions deploy newproducts --runtime nodejs20 --trigger-http --allow-unauthenticated --region=$REGION"
    echo

    DEPLOY_CMD=$(prompt_user "Enter the gcloud command to deploy the Cloud Function")

    if [[ -z "$DEPLOY_CMD" ]]; then
        print_error "No deployment command provided."
        exit 1
    fi

    # Execute the deployment command
    print_status "Deploying Cloud Function..."
    cd ../functions

    if eval "$DEPLOY_CMD"; then
        print_success "Cloud Function deployed successfully"
    else
        print_error "Cloud Function deployment failed."
        exit 1
    fi

    # Get Cloud Function URL
    print_status "Getting Cloud Function URL..."
    FUNCTION_URL=$(gcloud functions describe newproducts \
        --region="$REGION" \
        --format="value(httpsTrigger.url)")

    if [[ -z "$FUNCTION_URL" ]]; then
        print_error "Could not get Cloud Function URL."
        exit 1
    fi

    print_success "Cloud Function URL: $FUNCTION_URL"

    # Test Cloud Function
    print_status "Testing Cloud Function..."
    if curl -s "$FUNCTION_URL" | jq . >/dev/null 2>&1; then
        CF_PRODUCT_COUNT=$(curl -s "$FUNCTION_URL" | jq length)
        print_success "Cloud Function working - returned $CF_PRODUCT_COUNT products"
    else
        print_error "Cloud Function test failed"
    fi

    # Update frontend to use Cloud Function
    print_status "Updating frontend to use Cloud Function..."
    cd ../frontend

    # Update environment file with Cloud Function URL
    if grep -q "$CLOUD_RUN_URL" "$ENV_FILE"; then
        sed -i.bak "s|$CLOUD_RUN_URL|$FUNCTION_URL|" "$ENV_FILE"
        print_success "Environment file updated with Cloud Function URL"
    else
        print_warning "Could not update environment file automatically. Please update manually."
    fi

    # Final frontend build
    if command_exists npm; then
        print_status "Final frontend build..."
        npm run build

        gcloud storage cp -r build/* "gs://$BUCKET_NAME" \
            --cache-control=no-cache,no-store,max-age=0 \
            --quiet

        print_success "Frontend final build completed"
    fi

    # Completion message
    print_success "=== Lab GSP1329 completed successfully! ==="
    echo
    echo "Summary:"
    echo "- Backend API deployed to Cloud Run: $CLOUD_RUN_URL"
    echo "- New /newproducts endpoint implemented using Gemini"
    echo "- Extracted to Cloud Function microservice: $FUNCTION_URL"
    echo "- Frontend deployed to: gs://$PROJECT_ID-cymbal-frontend"
    echo
    print_warning "Next steps:"
    echo "1. Access your Cymbal Superstore website using the load balancer IP"
    echo "2. Click on 'New Arrivals!' to see the new products from the Cloud Function"
    echo "3. Verify that the products are fetched from the microservice"
    echo
    print_status "To clean up resources, consider deleting:"
    echo "- Cloud Run service: gcloud run services delete inventory --region=$REGION"
    echo "- Cloud Function: gcloud functions delete newproducts --region=$REGION"
    echo "- Container images: gcloud artifacts docker images delete gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api --delete-tags"
    echo "- Cloud Storage bucket: gsutil rm -r gs://$PROJECT_ID-cymbal-frontend"
}

# Run main function
main "$@"
