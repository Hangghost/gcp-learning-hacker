#!/bin/bash

# GSP1209 - Getting Started with Google Generative AI Using the Gen AI SDK
# https://www.skills.google/course_templates/959/labs/592557
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
        print_error "Project ID is required"
        exit 1
    fi

    print_info "Setting project to: $project_id"
    gcloud config set project "$project_id"

    print_success "Project set to: $project_id"
}

# Function to enable required APIs
enable_apis() {
    print_info "Enabling required APIs for Vertex AI and Generative AI..."

    # Enable Vertex AI API
    gcloud services enable aiplatform.googleapis.com

    # Enable Cloud Storage API (for batch predictions)
    gcloud services enable storage.googleapis.com

    # Enable BigQuery API (optional, for batch predictions)
    gcloud services enable bigquery.googleapis.com

    print_success "APIs enabled successfully"
}

# Function to check/create Vertex AI Workbench instance
check_workbench_instance() {
    local instance_name="$1"
    local region="${2:-us-central1}"

    if [ -z "$instance_name" ]; then
        print_warning "No Workbench instance name provided. Please check the lab instructions for the instance name."
        return 1
    fi

    print_info "Checking Vertex AI Workbench instance: $instance_name in region: $region"

    if gcloud workbench instances list --region="$region" --format="value(name)" | grep -q "^$instance_name$"; then
        print_success "Vertex AI Workbench instance '$instance_name' exists"
        return 0
    else
        print_warning "Vertex AI Workbench instance '$instance_name' not found"
        print_info "Please ensure the instance is created in the Google Cloud Console as per lab instructions"
        return 1
    fi
}

# Function to set up authentication for Vertex AI
setup_vertex_ai_auth() {
    print_info "Setting up authentication for Vertex AI..."

    # Get the current service account
    local service_account
    service_account=$(gcloud config get-value account)

    if [ -z "$service_account" ]; then
        print_error "No active service account found. Please authenticate with gcloud first."
        exit 1
    fi

    print_info "Using service account: $service_account"

    # Note: In a real lab environment, the service account should already have
    # the necessary permissions. This is just for verification.

    print_success "Vertex AI authentication setup complete"
}

# Function to create a Cloud Storage bucket for batch predictions (if needed)
create_batch_bucket() {
    local bucket_name="$1"
    local region="${2:-us-central1}"

    if [ -z "$bucket_name" ]; then
        # Generate a unique bucket name
        local project_id
        project_id=$(gcloud config get-value project)
        local timestamp
        timestamp=$(date +%s)
        bucket_name="${project_id}-genai-batch-${timestamp}"
    fi

    print_info "Creating Cloud Storage bucket for batch predictions: gs://$bucket_name"

    if gsutil ls -b "gs://$bucket_name" &>/dev/null; then
        print_warning "Bucket gs://$bucket_name already exists"
    else
        gsutil mb -p "$(gcloud config get-value project)" -l "$region" "gs://$bucket_name"
        print_success "Created bucket: gs://$bucket_name"
    fi

    echo "gs://$bucket_name"
}

# Function to display lab information
display_lab_info() {
    cat << 'EOF'

================================================================================
 GSP1209 - Getting Started with Google Generative AI Using the Gen AI SDK
================================================================================

Lab Overview:
The Google Gen AI SDK provides a unified interface to Google's generative AI
API services. This lab explores the SDK through Vertex AI Workbench notebooks.

Prerequisites:
- Basic Python programming knowledge
- General API concepts
- Access to Vertex AI Workbench

Main Tasks:
1. Open notebook in Vertex AI Workbench
2. Set up the notebook environment
3. Interact with Gemini models
4. Configure model parameters and safety filters
5. Manage model interactions
6. Use advanced features (function calling, context caching, batch prediction, embeddings)

Important Notes:
- The main lab work is performed in Jupyter notebooks
- This script only handles basic GCP setup
- Follow the notebook instructions carefully
- Some operations may take time (batch predictions up to 10 minutes)

Next Steps:
1. Open Vertex AI Workbench instance in Google Cloud Console
2. Launch JupyterLab
3. Open the lab notebook
4. Follow the step-by-step instructions

================================================================================

EOF
}

# Function to cleanup resources
cleanup_resources() {
    local bucket_name="$1"

    print_info "Starting cleanup process..."

    if [ -n "$bucket_name" ] && gsutil ls -b "gs://$bucket_name" &>/dev/null; then
        print_warning "The bucket gs://$bucket_name was created by this script."
        read -p "Do you want to delete it? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gsutil rm -r "gs://$bucket_name"
            print_success "Deleted bucket: gs://$bucket_name"
        else
            print_info "Keeping bucket: gs://$bucket_name"
        fi
    fi

    print_success "Cleanup complete"
}

# Main function
main() {
    local project_id=""
    local region="us-central1"
    local workbench_instance=""
    local create_bucket=false
    local cleanup=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --project-id)
                project_id="$2"
                shift 2
                ;;
            --region)
                region="$2"
                shift 2
                ;;
            --workbench-instance)
                workbench_instance="$2"
                shift 2
                ;;
            --create-bucket)
                create_bucket=true
                shift
                ;;
            --cleanup)
                cleanup=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --project-id PROJECT_ID    GCP Project ID (required)"
                echo "  --region REGION           GCP Region (default: us-central1)"
                echo "  --workbench-instance NAME Vertex AI Workbench instance name"
                echo "  --create-bucket           Create a Cloud Storage bucket for batch predictions"
                echo "  --cleanup                 Run cleanup process"
                echo "  --help                    Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Display lab information
    display_lab_info

    # Check if cleanup is requested
    if [ "$cleanup" = true ]; then
        cleanup_resources
        exit 0
    fi

    # Validate required parameters
    if [ -z "$project_id" ]; then
        print_error "Project ID is required. Use --project-id to specify it."
        exit 1
    fi

    # Run setup steps
    print_info "Starting GSP1209 lab setup..."

    check_gcloud
    set_project "$project_id"
    enable_apis

    if [ -n "$workbench_instance" ]; then
        check_workbench_instance "$workbench_instance" "$region"
    else
        print_warning "No Workbench instance specified. Please check lab instructions."
    fi

    setup_vertex_ai_auth

    local batch_bucket=""
    if [ "$create_bucket" = true ]; then
        batch_bucket=$(create_batch_bucket "" "$region")
        print_info "Batch prediction bucket: $batch_bucket"
    fi

    print_success "GSP1209 lab setup complete!"
    echo ""
    print_info "Next steps:"
    echo "1. Go to Google Cloud Console > Vertex AI > Workbench"
    echo "2. Open your Workbench instance"
    echo "3. Launch JupyterLab"
    echo "4. Open the lab notebook and follow the instructions"
    if [ -n "$batch_bucket" ]; then
        echo "5. Use bucket '$batch_bucket' for batch prediction tasks if needed"
    fi
    echo ""
    print_warning "Note: The main lab work is done in the Jupyter notebook environment."
}

# Run main function with all arguments
main "$@"
