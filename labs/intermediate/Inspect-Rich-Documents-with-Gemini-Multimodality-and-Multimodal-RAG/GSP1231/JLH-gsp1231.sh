#!/bin/bash

# GSP1231 - Multimodal Retrieval Augmented Generation (RAG) using the Gemini API in Vertex AI
# https://www.skills.google/paths/1284/course_templates/981/labs/597910
#
# This script provides automation for the GSP1231 lab setup.
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
    print_info "Enabling required APIs for Vertex AI, Embeddings, and Generative AI..."

    # Enable Vertex AI API
    gcloud services enable aiplatform.googleapis.com

    # Enable Cloud Storage API (for multimodal content)
    gcloud services enable storage.googleapis.com

    # Enable Cloud Vision API (for image processing)
    gcloud services enable vision.googleapis.com

    # Enable Document AI API (for document processing)
    gcloud services enable documentai.googleapis.com

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

# Function to setup authentication for Vertex AI
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
    # the necessary permissions for Vertex AI, embeddings, and multimodal operations.

    print_success "Vertex AI authentication setup complete"
}

# Function to create a Cloud Storage bucket for multimodal RAG content
create_rag_bucket() {
    local bucket_name="$1"
    local region="${2:-us-central1}"

    if [ -z "$bucket_name" ]; then
        # Generate a unique bucket name
        local project_id
        project_id=$(gcloud config get-value project)
        local timestamp
        timestamp=$(date +%s)
        bucket_name="${project_id}-multimodal-rag-${timestamp}"
    fi

    print_info "Creating Cloud Storage bucket for multimodal RAG content: gs://$bucket_name"

    if gsutil ls -b "gs://$bucket_name" &>/dev/null; then
        print_warning "Bucket gs://$bucket_name already exists"
    else
        gsutil mb -p "$(gcloud config get-value project)" -l "$region" "gs://$bucket_name"
        print_success "Created bucket: gs://$bucket_name"
    fi

    echo "gs://$bucket_name"
}

# Function to verify embeddings API access
verify_embeddings_access() {
    print_info "Verifying access to Vertex AI Embeddings API..."

    # Try to list available embedding models
    if gcloud ai models list --region=us-central1 --filter="name:embeddings" --format="value(name)" | grep -q .; then
        print_success "Embeddings API access verified"
    else
        print_warning "Could not verify embeddings API access. This may be expected in some environments."
    fi
}

# Function to display lab information
display_lab_info() {
    cat << 'EOF'

================================================================================
 GSP1231 - Multimodal Retrieval Augmented Generation (RAG) using the Gemini API
================================================================================

Lab Overview:
This lab demonstrates how to build a multimodal Retrieval Augmented Generation (RAG)
system using the Gemini API in Vertex AI. You'll learn to perform Q&A over documents
containing both text and images, combining text embeddings and multimodal embeddings.

Key Learning Objectives:
- Extract and store metadata from documents with text and images
- Generate embeddings for multimodal content
- Perform text-based and image-based similarity searches
- Implement multimodal RAG for enhanced Q&A capabilities
- Compare text-based vs multimodal RAG approaches

Main Tasks:
1. Open notebook in Vertex AI Workbench
2. Set up the notebook environment
3. Download utilities and sample documents from Cloud Storage
4. Build metadata of documents containing text and images
5. Perform text search using text embeddings
6. Perform image search using multimodal embeddings
7. Implement comparative reasoning across images
8. Build complete multimodal RAG system

Technical Requirements:
- Vertex AI Workbench instance with sufficient resources
- Access to Gemini API and embedding models
- Cloud Storage access for sample data
- Python environment with required libraries

Key Components:
- Text Embeddings API for semantic text search
- Multimodal Embeddings API for image understanding
- Gemini API for multimodal reasoning and generation
- Cloud Storage for document and image assets

Important Notes:
- The main lab work is performed in Jupyter notebooks
- This script only handles basic GCP setup and API enablement
- RAG processing may require significant compute resources
- Sample data includes modified Google-10K financial documents
- Both text and image search capabilities are demonstrated

Next Steps:
1. Open Vertex AI Workbench instance in Google Cloud Console
2. Launch JupyterLab and open the lab notebook
3. Follow the step-by-step instructions for each RAG task
4. Complete all sections to understand multimodal RAG fully

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
                echo "  --create-bucket           Create a Cloud Storage bucket for RAG content"
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
    print_info "Starting GSP1231 lab setup..."

    check_gcloud
    set_project "$project_id"
    enable_apis

    if [ -n "$workbench_instance" ]; then
        check_workbench_instance "$workbench_instance" "$region"
    else
        print_warning "No Workbench instance specified. Please check lab instructions."
    fi

    setup_vertex_ai_auth
    verify_embeddings_access

    local rag_bucket=""
    if [ "$create_bucket" = true ]; then
        rag_bucket=$(create_rag_bucket "" "$region")
        print_info "Multimodal RAG bucket: $rag_bucket"
    fi

    print_success "GSP1231 lab setup complete!"
    echo ""
    print_info "Next steps:"
    echo "1. Go to Google Cloud Console > Vertex AI > Workbench"
    echo "2. Open your Workbench instance"
    echo "3. Launch JupyterLab"
    echo "4. Open the lab notebook and follow the instructions"
    echo "5. Complete each RAG task in sequence (may take significant time)"
    if [ -n "$rag_bucket" ]; then
        echo "6. Use bucket '$rag_bucket' for multimodal RAG content if needed"
    fi
    echo ""
    print_warning "Note: This lab demonstrates multimodal RAG capabilities using Gemini."
    echo "      The notebook tasks may require substantial compute resources and time."
    echo "      Ensure your Workbench instance has adequate CPU/memory allocation."
}

# Run main function with all arguments
main "$@"
