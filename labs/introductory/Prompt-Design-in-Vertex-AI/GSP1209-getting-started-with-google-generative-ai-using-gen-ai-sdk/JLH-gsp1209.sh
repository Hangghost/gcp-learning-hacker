#!/bin/bash

# GSP1209 - Getting Started with Google Generative AI Using the Gen AI SDK
# https://www.skills.google/paths/236/course_templates/978/labs/592571
#
# This script provides automation for the GSP1209 lab setup.
# Note: The main lab work is performed in Vertex AI Workbench notebooks.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
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

# Function to check if gcloud is installed and authenticated
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi

    print_success "gcloud CLI is installed and authenticated"
}

# Function to set project
set_project() {
    local project_id="$1"

    if [ -z "$project_id" ]; then
        print_warning "No project ID provided. Please enter your GCP project ID:"
        read -r project_id
    fi

    if ! gcloud projects describe "$project_id" &> /dev/null; then
        print_error "Project $project_id does not exist or you don't have access to it."
        exit 1
    fi

    gcloud config set project "$project_id"
    print_success "Set project to: $project_id"
}

# Function to enable required APIs
enable_apis() {
    print_info "Enabling required APIs..."

    local apis=(
        "vertexai.googleapis.com"
        "aiplatform.googleapis.com"
        "storage.googleapis.com"
    )

    for api in "${apis[@]}"; do
        if gcloud services enable "$api" --quiet; then
            print_success "Enabled API: $api"
        else
            print_warning "Failed to enable API: $api (might already be enabled)"
        fi
    done
}

# Function to create a storage bucket for batch prediction (if needed)
create_storage_bucket() {
    local bucket_name="$1"
    local location="${2:-us-central1}"

    if [ -z "$bucket_name" ]; then
        local project_id
        project_id=$(gcloud config get-value project)
        bucket_name="${project_id}-genai-batch-$(date +%Y%m%d-%H%M%S)"
    fi

    if gsutil ls -b "gs://$bucket_name" &> /dev/null; then
        print_info "Storage bucket gs://$bucket_name already exists"
    else
        if gsutil mb -p "$(gcloud config get-value project)" -l "$location" "gs://$bucket_name"; then
            print_success "Created storage bucket: gs://$bucket_name"
        else
            print_error "Failed to create storage bucket: gs://$bucket_name"
            return 1
        fi
    fi

    echo "gs://$bucket_name"
}

# Function to check Vertex AI Workbench instance
check_workbench() {
    print_info "Checking Vertex AI Workbench instances..."

    local instances
    instances=$(gcloud workbench instances list --format="value(name)")

    if [ -z "$instances" ]; then
        print_warning "No Vertex AI Workbench instances found."
        print_info "You may need to create a Workbench instance manually in the GCP Console."
        print_info "Go to: https://console.cloud.google.com/vertex-ai/workbench"
        return 1
    else
        print_success "Found Vertex AI Workbench instances:"
        echo "$instances"
        return 0
    fi
}

# Function to provide lab instructions
print_lab_instructions() {
    cat << 'EOF'

================================================================================
GSP1209 - Getting Started with Google Generative AI Using the Gen AI SDK
================================================================================

This lab is primarily completed through Vertex AI Workbench notebooks.
Follow these steps:

1. MANUAL STEP: Open Vertex AI Workbench in GCP Console
   - Go to: https://console.cloud.google.com/vertex-ai/workbench
   - Find your Workbench instance and click "Open JupyterLab"

2. MANUAL STEP: In JupyterLab, locate and open the lab notebook
   - The notebook name should be similar to: "getting-started-with-genai-sdk.ipynb"

3. MANUAL STEP: Execute the notebook sections in order:
   - Getting Started (imports and setup)
   - Choose a model
   - Send text prompts
   - Send multimodal prompts
   - Set system instruction
   - Configure model parameters
   - Configure safety filters
   - Start a multi-turn chat
   - Control generated output
   - Generate content stream
   - Send asynchronous requests
   - Count tokens
   - Compute tokens
   - Function calling
   - Create a cache (context caching)
   - Use a cache
   - Delete a cache
   - Prepare batch inputs
   - Prepare batch output location
   - Send a batch prediction request
   - Retrieve batch prediction results
   - Get text embeddings

4. IMPORTANT NOTES:
   - If you get 429 errors, wait 1 minute before retrying
   - Batch prediction may take up to 10 minutes to complete
   - Ensure your service account has proper permissions

5. CLEANUP: After completing the lab, remember to:
   - Delete any created Cloud Storage buckets
   - Delete context caches if created
   - Stop Workbench instances if not needed

================================================================================

EOF
}

# Main function
main() {
    print_info "Starting GSP1209 lab setup..."

    # Parse command line arguments
    local project_id=""
    local create_bucket=false
    local bucket_name=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --project)
                project_id="$2"
                shift 2
                ;;
            --create-bucket)
                create_bucket=true
                shift
                ;;
            --bucket-name)
                bucket_name="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [--project PROJECT_ID] [--create-bucket] [--bucket-name BUCKET_NAME]"
                echo ""
                echo "Options:"
                echo "  --project PROJECT_ID    GCP project ID to use"
                echo "  --create-bucket         Create a Cloud Storage bucket for batch prediction"
                echo "  --bucket-name BUCKET    Specific bucket name to create"
                echo "  --help                  Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Check prerequisites
    check_gcloud

    # Set project if provided
    if [ -n "$project_id" ]; then
        set_project "$project_id"
    fi

    # Enable required APIs
    enable_apis

    # Create storage bucket if requested
    if [ "$create_bucket" = true ]; then
        local created_bucket
        created_bucket=$(create_storage_bucket "$bucket_name")
        if [ $? -eq 0 ]; then
            print_info "Created bucket: $created_bucket"
            print_info "You can use this bucket for batch prediction output in the lab"
        fi
    fi

    # Check Workbench instances
    check_workbench

    # Print lab instructions
    print_lab_instructions

    print_success "GSP1209 lab setup completed!"
    print_info "Follow the manual steps above to complete the lab in Vertex AI Workbench."
}

# Run main function with all arguments
main "$@"
