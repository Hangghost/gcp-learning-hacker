#!/bin/bash

# GSP1227 - Introduction to Function Calling with Gemini
# https://www.skills.google/paths/1284/course_templates/981/labs/597908
#
# This script provides automation for the GSP1227 lab setup.
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
    # the necessary permissions. This is just for verification.

    print_success "Vertex AI authentication setup complete"
}

# Function to display lab information
display_lab_info() {
    cat << 'EOF'

================================================================================
 GSP1227 - Introduction to Function Calling with Gemini
================================================================================

Lab Overview:
This lab introduces Function Calling with Gemini, a powerful feature that allows
developers to create structured function calls from unstructured text inputs.

Function Calling enables:
- Structured output from LLM prompts and unstructured inputs
- API integration with external systems
- Entity extraction from text and logs
- Parameter extraction for function execution

Key Concepts:
- Function Calling vs Vertex AI Extensions
- JSON structured responses from LLMs
- Integration with external APIs
- Entity extraction and data transformation

Main Tasks:
1. Open notebook in Vertex AI Workbench
2. Set up the notebook environment
3. Structured Google Store queries with function calling
4. Address geocoding with external API calls
5. Entity extraction from log data

Function Calling Use Cases:
- E-commerce product queries
- Address geocoding and mapping
- Log analysis and error extraction
- Data transformation and structuring
- API integration workflows

Important Notes:
- Function calling extracts structured parameters from unstructured text
- Returns JSON with function name and arguments for your code to use
- Different from Vertex AI Extensions (which calls functions for you)
- Works with Gemini 2.0 Flash model
- Enables reliable structured output from LLMs

Next Steps:
1. Open Vertex AI Workbench instance in Google Cloud Console
2. Launch JupyterLab and open the lab notebook
3. Follow the step-by-step instructions for each function calling task
4. Experiment with different prompts and function definitions

================================================================================

EOF
}

# Function to cleanup resources
cleanup_resources() {
    print_info "Starting cleanup process..."

    # This lab primarily uses Vertex AI managed resources
    # Most cleanup happens automatically when the session ends

    print_success "Cleanup complete"
}

# Main function
main() {
    local project_id=""
    local region="us-central1"
    local workbench_instance=""
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
    print_info "Starting GSP1227 lab setup..."

    check_gcloud
    set_project "$project_id"
    enable_apis

    if [ -n "$workbench_instance" ]; then
        check_workbench_instance "$workbench_instance" "$region"
    else
        print_warning "No Workbench instance specified. Please check lab instructions."
    fi

    setup_vertex_ai_auth

    print_success "GSP1227 lab setup complete!"
    echo ""
    print_info "Next steps:"
    echo "1. Go to Google Cloud Console > Vertex AI > Workbench"
    echo "2. Open your Workbench instance"
    echo "3. Launch JupyterLab"
    echo "4. Open the lab notebook and follow the instructions"
    echo "5. Complete the function calling tasks in sequence"
    echo ""
    print_warning "Note: This lab demonstrates Gemini's function calling capabilities."
    echo "      Focus on understanding how to extract structured data from unstructured inputs."
}

# Run main function with all arguments
main "$@"
