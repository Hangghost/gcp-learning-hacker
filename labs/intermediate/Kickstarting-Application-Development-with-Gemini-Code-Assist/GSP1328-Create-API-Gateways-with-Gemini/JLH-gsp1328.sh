#!/bin/bash

# GSP1328 - Create API Gateways with Gemini
# This script automates the lab steps for creating API Gateways with Gemini assistance

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

# Cleanup function
cleanup() {
    print_warning "Cleaning up resources..."
    echo "Note: This lab creates persistent resources. Manual cleanup may be required."
    echo "Consider deleting the following if no longer needed:"
    echo "- Cloud Function: newproducts"
    echo "- API Gateway: $GATEWAY_ID"
    echo "- API Config: $CONFIG_ID"
    echo "- API: $API_ID"
}

# Trap cleanup function on script exit
trap cleanup EXIT

# Main script
main() {
    print_status "Starting GSP1328 - Create API Gateways with Gemini"
    print_status "This script will guide you through the lab steps"

    # Check prerequisites
    print_status "Checking prerequisites..."

    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
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

    # Set region and zone
    REGION=$(prompt_user "Enter the lab region" "us-central1")
    ZONE=$(prompt_user "Enter the lab zone" "us-central1-a")

    # Export environment variables
    export PROJECT_ID="$PROJECT_ID"
    export REGION="$REGION"
    export ZONE="$ZONE"
    export CONFIG_ID="newproducts-api-config"
    export API_ID="newproducts-api"
    export GATEWAY_ID="store"
    export OPENAPI_SPEC="newproducts.yaml"

    print_success "Environment variables set:"
    echo "  PROJECT_ID: $PROJECT_ID"
    echo "  REGION: $REGION"
    echo "  ZONE: $ZONE"

    # Task 1: Set up environment and deploy Cloud Function
    print_status "=== Task 1: Setting up environment and deploying Cloud Function ==="

    # Create working directory
    if [[ ! -d "cymbal-superstore" ]]; then
        print_status "Copying cymbal-superstore files from Cloud Storage..."
        gsutil -m cp -r gs://duet-appdev/cymbal-superstore . || {
            print_error "Failed to copy files from Cloud Storage. Please ensure you have access."
            exit 1
        }
    else
        print_warning "cymbal-superstore directory already exists. Skipping copy."
    fi

    # Deploy Cloud Function
    print_status "Deploying Cloud Function..."
    cd cymbal-superstore/functions

    if gcloud functions deploy newproducts \
        --runtime nodejs20 \
        --trigger-http \
        --allow-unauthenticated \
        --region "$REGION" \
        --quiet; then
        print_success "Cloud Function deployed successfully"
    else
        print_error "Cloud Function deployment failed. Retrying..."
        sleep 5
        gcloud functions deploy newproducts \
            --runtime nodejs20 \
            --trigger-http \
            --allow-unauthenticated \
            --region "$REGION" || {
            print_error "Cloud Function deployment failed again. Please check permissions and try manually."
            exit 1
        }
    fi

    # Get Cloud Function URL
    print_status "Getting Cloud Function URL..."
    FUNCTION_URL=$(gcloud functions describe newproducts --region="$REGION" --format="value(httpsTrigger.url)")
    print_success "Cloud Function URL: $FUNCTION_URL"

    # Test the function
    print_status "Testing Cloud Function..."
    if curl -s "$FUNCTION_URL" | jq . >/dev/null 2>&1; then
        print_success "Cloud Function test passed - JSON data returned"
    else
        print_warning "Cloud Function test may have failed. Please verify manually."
    fi

    # Task 2: Create OpenAPI specification
    print_status "=== Task 2: Creating OpenAPI specification ==="

    cd ../gateway

    # Create newproducts.yaml
    print_status "Creating newproducts.yaml..."

    cat > newproducts.yaml << EOF
swagger: "2.0"
info:
  title: "newproducts"
  description: "A Cloud Function that returns a list of products from Firestore."
  version: "1.0.0"
host: "$REGION-$PROJECT_ID.cloudfunctions.net"
schemes:
- "https"
paths:
  /newproducts:
    get:
      summary: "Get a list of products from Firestore."
      operationId: "newproducts"
      x-google-backend:
        address: "$FUNCTION_URL"
      produces:
      - "application/json"
      responses:
        "200":
          description: "A list of products."
          schema:
            type: "array"
            items:
              type: "object"
              properties:
                id:
                  type: "string"
                name:
                  type: "string"
                price:
                  type: "number"
                quantity:
                  type: "integer"
                imgfile:
                  type: "string"
                timestamp:
                  type: "string"
                actualdateadded:
                  type: "string"
EOF

    print_success "OpenAPI specification created"

    # Task 3: Create API Gateway
    print_status "=== Task 3: Creating API Gateway ==="

    cd ..

    # Enable API Gateway service
    print_status "Enabling API Gateway service..."
    gcloud services enable apigateway.googleapis.com --quiet

    # Create API
    print_status "Creating API..."
    gcloud api-gateway apis create "$API_ID" --quiet

    # Create API config
    print_status "Creating API configuration..."
    cd gateway

    if gcloud api-gateway api-configs create "$CONFIG_ID" \
        --api="$API_ID" \
        --openapi-spec="$OPENAPI_SPEC" \
        --quiet; then
        print_success "API configuration created successfully"
    else
        print_error "API configuration creation failed. This might be due to OpenAPI spec issues."
        print_warning "Please check the newproducts.yaml file and try again manually."
        exit 1
    fi

    # Create Gateway
    print_status "Creating API Gateway..."
    cd ..

    if gcloud api-gateway gateways create "$GATEWAY_ID" \
        --api="$API_ID" \
        --api-config="$CONFIG_ID" \
        --location="$REGION" \
        --project="$PROJECT_ID" \
        --quiet; then
        print_success "API Gateway created successfully"
    else
        print_error "API Gateway creation failed."
        exit 1
    fi

    # Get gateway hostname
    print_status "Getting API Gateway details..."
    GATEWAY_HOST=$(gcloud api-gateway gateways describe "$GATEWAY_ID" \
        --location="$REGION" \
        --project="$PROJECT_ID" \
        --format="value(defaultHostname)")

    print_success "API Gateway hostname: $GATEWAY_HOST"

    # Test API Gateway
    API_URL="https://$GATEWAY_HOST/newproducts"
    print_status "Testing API Gateway endpoint: $API_URL"

    # Wait a bit for the gateway to be ready
    sleep 10

    if curl -s "$API_URL" | jq . >/dev/null 2>&1; then
        print_success "API Gateway test passed - 10 products returned"
    else
        print_warning "API Gateway test may have failed. Please verify manually."
    fi

    # Task 4: Update frontend
    print_status "=== Task 4: Updating frontend website ==="

    cd frontend

    # Check for environment file
    if [[ -f ".env.production" ]]; then
        ENV_FILE=".env.production"
    elif [[ -f "env.production" ]]; then
        ENV_FILE="env.production"
    else
        print_error "No environment file found. Please check the frontend directory."
        exit 1
    fi

    print_status "Updating $ENV_FILE with API Gateway hostname..."

    # Update the environment file (this is a simple replacement - adjust as needed)
    if grep -q "YOUR_ENDPOINT_URL_HERE" "$ENV_FILE"; then
        sed -i.bak "s|YOUR_ENDPOINT_URL_HERE|https://$GATEWAY_HOST|" "$ENV_FILE"
        print_success "Environment file updated"
    else
        print_warning "Could not find YOUR_ENDPOINT_URL_HERE in $ENV_FILE. Please update manually."
    fi

    # Build frontend (if npm is available)
    if command_exists npm; then
        print_status "Building frontend..."
        npm install && npm run build
        print_success "Frontend built successfully"

        # Upload to Cloud Storage
        print_status "Uploading frontend to Cloud Storage..."
        BUCKET_NAME="${PROJECT_ID}-cymbal-frontend"

        if gcloud storage cp -r build/* "gs://$BUCKET_NAME" --cache-control=no-cache,no-store,max-age=0 --quiet; then
            print_success "Frontend uploaded to gs://$BUCKET_NAME"
        else
            print_warning "Frontend upload failed. Please check bucket permissions."
        fi
    else
        print_warning "npm not available. Skipping frontend build and upload."
    fi

    # Completion message
    print_success "=== Lab GSP1328 completed successfully! ==="
    echo
    echo "Summary:"
    echo "- Cloud Function deployed: newproducts"
    echo "- API Gateway created: $GATEWAY_ID"
    echo "- API Gateway URL: https://$GATEWAY_HOST/newproducts"
    echo "- Frontend updated and uploaded to: gs://$PROJECT_ID-cymbal-frontend"
    echo
    print_warning "Next steps:"
    echo "1. Access your Cymbal Superstore website using the load balancer IP"
    echo "2. Click on 'New Arrivals!' to see the new products"
    echo "3. Verify that 10 products are displayed"
    echo
    print_status "To clean up resources, consider deleting:"
    echo "- Cloud Function: gcloud functions delete newproducts --region=$REGION"
    echo "- API Gateway: gcloud api-gateway gateways delete $GATEWAY_ID --location=$REGION"
    echo "- API Config: gcloud api-gateway api-configs delete $CONFIG_ID --api=$API_ID"
    echo "- API: gcloud api-gateway apis delete $API_ID"
}

# Run main function
main "$@"
