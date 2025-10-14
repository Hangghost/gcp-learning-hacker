#!/bin/bash

# GSP080 - Cloud Run Functions: Qwik Start - Command Line
# Automated Lab Script
# This script automates the GSP080 lab for Cloud Run Functions using command line
# Usage: ./JLH-gsp080.sh [--verbose|-v] [cleanup]
# Status: verified on 2025-10-14

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Function to get user input
get_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        eval "$var_name=\${input:-$default}"
    else
        read -p "$prompt: " input
        eval "$var_name=\"$input\""
    fi
}

# Function to confirm before proceeding
confirm() {
    local message="$1"
    local response

    echo -e "${YELLOW}$message${NC}"
    read -p "Do you want to continue? (y/N): " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            echo "Operation cancelled."
            return 1
            ;;
    esac
}

# Function to check if gcloud is installed and authenticated
check_prerequisites() {
    print_step "Checking prerequisites"

    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 > /dev/null; then
        print_error "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi

    # Check if npm is installed
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed. Please install Node.js first."
        exit 1
    fi

    print_success "Prerequisites check passed"
}

# Function to set up project and region
setup_environment() {
    print_step "Setting up environment"

    # Get project ID
    PROJECT_ID=$(gcloud config get-value project)
    if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
        get_input "Enter your GCP Project ID" PROJECT_ID
        gcloud config set project "$PROJECT_ID"
    fi

    print_info "Using project: $PROJECT_ID"

    # Get region
    get_input "Enter the region for your resources (e.g., us-central1)" REGION "us-central1"
    gcloud config set run/region "$REGION"

    # Create staging bucket if it doesn't exist
    BUCKET_NAME="${PROJECT_ID}-bucket"
    if ! gsutil ls -b gs://"$BUCKET_NAME" &>/dev/null; then
        print_info "Creating staging bucket: $BUCKET_NAME"
        gsutil mb -p "$PROJECT_ID" gs://"$BUCKET_NAME"
    else
        print_info "Staging bucket already exists: $BUCKET_NAME"
    fi

    print_success "Environment setup completed"
}

# Function to create the function code
create_function_code() {
    print_step "Task 1: Creating function code"

    # Create directory
    if [ -d "gcf_hello_world" ]; then
        print_warning "Directory gcf_hello_world already exists. Removing it..."
        rm -rf gcf_hello_world
    fi

    mkdir gcf_hello_world
    cd gcf_hello_world

    print_info "Creating index.js..."
    cat > index.js << 'EOF'
const functions = require('@google-cloud/functions-framework');

// Register a CloudEvent callback with the Functions Framework that will
// be executed when the Pub/Sub trigger topic receives a message.
functions.cloudEvent('helloPubSub', cloudEvent => {
  // The Pub/Sub message is passed as the CloudEvent's data payload.
  const base64name = cloudEvent.data.message.data;

  const name = base64name
    ? Buffer.from(base64name, 'base64').toString()
    : 'World';

  console.log(`Hello, ${name}!`);
});
EOF

    print_info "Creating package.json..."
    cat > package.json << 'EOF'
{
  "name": "gcf_hello_world",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "dependencies": {
    "@google-cloud/functions-framework": "^3.0.0"
  }
}
EOF

    print_info "Installing dependencies..."
    npm install

    print_success "Function code created successfully"
}

# Function to deploy the function
deploy_function() {
    print_step "Task 2: Deploying function"

    # Check if service account exists, if not create it
    SERVICE_ACCOUNT="cloudfunctionsa@${PROJECT_ID}.iam.gserviceaccount.com"
    if ! gcloud iam service-accounts describe "$SERVICE_ACCOUNT" &>/dev/null; then
        print_info "Creating service account..."
        gcloud iam service-accounts create cloudfunctionsa \
            --description="Service account for Cloud Functions" \
            --display-name="Cloud Functions Service Account"
    fi

    # Grant necessary permissions
    print_info "Granting permissions to service account..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT" \
        --role="roles/pubsub.publisher"

    print_info "Deploying function..."
    gcloud functions deploy nodejs-pubsub-function \
        --gen2 \
        --runtime=nodejs20 \
        --region="$REGION" \
        --source=. \
        --entry-point=helloPubSub \
        --trigger-topic cf-demo \
        --stage-bucket "$BUCKET_NAME" \
        --service-account "$SERVICE_ACCOUNT" \
        --allow-unauthenticated

    print_info "Verifying function status..."
    gcloud functions describe nodejs-pubsub-function --region="$REGION"

    print_success "Function deployed successfully"
}

# Function to test the function
test_function() {
    print_step "Task 3: Testing function"

    # Ensure the Pub/Sub topic exists
    if ! gcloud pubsub topics describe cf-demo &>/dev/null; then
        print_info "Creating Pub/Sub topic..."
        gcloud pubsub topics create cf-demo
    fi

    print_info "Publishing test message..."
    gcloud pubsub topics publish cf-demo --message="Cloud Function Gen2"

    print_success "Test message published"
    print_info "Function should trigger automatically. Check logs in a few minutes."
}

# Function to view logs
view_logs() {
    print_step "Task 4: Viewing logs"

    print_info "Fetching function logs..."
    print_warning "Note: Logs may take up to 10 minutes to appear"

    # Try to get logs, but don't fail if they're not ready yet
    if gcloud functions logs read nodejs-pubsub-function --region="$REGION" --limit=10; then
        print_success "Logs retrieved successfully"
    else
        print_warning "No logs available yet. Try again in a few minutes."
        print_info "Alternative: Check logs in Cloud Console > Logging > Logs Explorer"
    fi
}

# Function to show quiz answers
show_quiz_answers() {
    print_step "Task 5: Test your understanding"

    echo
    print_info "Quiz Answer:"
    echo "Serverless lets you write and deploy code without the hassle of managing the underlying infrastructure."
    echo "Answer: True"
    echo
}

# Function to cleanup resources
cleanup() {
    print_step "Cleaning up resources"

    confirm "This will delete the Cloud Run function, Pub/Sub topic, and storage bucket. Continue?"

    # Go back to project root if we're in function directory
    if [ -d "gcf_hello_world" ]; then
        cd ..
    fi

    print_info "Deleting function..."
    gcloud functions delete nodejs-pubsub-function --region="$REGION" --quiet 2>/dev/null || true

    print_info "Deleting Pub/Sub topic..."
    gcloud pubsub topics delete cf-demo --quiet 2>/dev/null || true

    print_info "Deleting storage bucket..."
    gsutil rm -r gs://"$BUCKET_NAME" 2>/dev/null || true

    print_info "Cleaning up local files..."
    rm -rf gcf_hello_world

    print_success "Cleanup completed"
}

# Main function
main() {
    local verbose=false
    local do_cleanup=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                verbose=true
                shift
                ;;
            cleanup)
                do_cleanup=true
                shift
                ;;
            *)
                echo "Usage: $0 [--verbose|-v] [cleanup]"
                exit 1
                ;;
        esac
    done

    echo "GSP080 - Cloud Run Functions: Qwik Start - Command Line"
    echo "Automated Lab Script"
    echo

    if $do_cleanup; then
        cleanup
        exit 0
    fi

    check_prerequisites
    setup_environment
    create_function_code
    deploy_function
    test_function
    view_logs
    show_quiz_answers

    print_success "Lab automation completed!"
    print_info "Note: Function logs may take several minutes to appear"
    print_info "Run '$0 cleanup' when done to clean up resources."
}

# Run main function
main "$@"
