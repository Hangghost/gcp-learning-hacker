#!/bin/bash

# GSP064 - Cloud IAM: Qwik Start
# Automated Lab Script
# This script automates parts of the GSP064 lab for Cloud IAM operations
# Note: This lab requires multiple user accounts (Username 1 & Username 2)
# Some steps must be performed manually in the console
# Usage: ./JLH-gsp064.sh [--verbose|-v] [cleanup]
# Status: verified on 2025-10-13

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

    read -p "$message (y/N): " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for user confirmation
wait_for_user() {
    local message="$1"
    echo
    print_warning "$message"
    read -p "Press Enter to continue..."
}

# Cleanup function
cleanup() {
    print_step "Starting cleanup process"

    if [ -n "$BUCKET_NAME" ]; then
        print_warning "Removing Cloud Storage bucket: $BUCKET_NAME"
        if gsutil ls -b gs://$BUCKET_NAME >/dev/null 2>&1; then
            gsutil rm -r gs://$BUCKET_NAME
            print_success "Bucket $BUCKET_NAME removed"
        else
            print_warning "Bucket $BUCKET_NAME not found or already removed"
        fi
    fi

    print_success "Cleanup completed"
}

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites"

    # Check if gcloud is installed
    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    # Check if gsutil is available
    if ! command_exists gsutil; then
        print_error "gsutil is not available. Please install Google Cloud SDK."
        exit 1
    fi

    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi

    print_success "Prerequisites check passed"
}

# Function to setup project
setup_project() {
    print_step "Setting up project configuration"

    # Get current project
    CURRENT_PROJECT=$(gcloud config get-value project)
    if [ -z "$CURRENT_PROJECT" ] || [ "$CURRENT_PROJECT" = "(unset)" ]; then
        print_error "No project set. Please set a project first:"
        echo "gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi

    print_success "Using project: $CURRENT_PROJECT"

    # Set default region (you can modify this)
    DEFAULT_REGION="us-central1"
    get_input "Enter region" REGION "$DEFAULT_REGION"
    gcloud config set compute/region "$REGION"
    print_success "Region set to: $REGION"
}

# Function to create Cloud Storage bucket
create_bucket() {
    print_step "Creating Cloud Storage bucket"

    # Generate a unique bucket name
    TIMESTAMP=$(date +%s)
    DEFAULT_BUCKET="gsp064-iam-demo-$TIMESTAMP"
    get_input "Enter bucket name" BUCKET_NAME "$DEFAULT_BUCKET"

    # Create bucket
    print_warning "Creating bucket: $BUCKET_NAME"
    gcloud storage buckets create gs://$BUCKET_NAME \
        --location=us \
        --uniform-bucket-level-access

    print_success "Bucket created: gs://$BUCKET_NAME"
}

# Function to create and upload sample file
upload_sample_file() {
    print_step "Creating and uploading sample file"

    # Create a sample text file
    SAMPLE_FILE="sample.txt"
    echo "This is a sample file for GSP064 Cloud IAM lab testing." > $SAMPLE_FILE
    echo "Created on: $(date)" >> $SAMPLE_FILE

    # Upload to bucket
    print_warning "Uploading $SAMPLE_FILE to gs://$BUCKET_NAME/"
    gcloud storage cp $SAMPLE_FILE gs://$BUCKET_NAME/

    # Clean up local file
    rm $SAMPLE_FILE

    print_success "Sample file uploaded to bucket"
}

# Function to demonstrate IAM operations (limited automation)
demonstrate_iam() {
    print_step "IAM Operations Demonstration"

    print_warning "NOTE: This lab requires TWO separate user accounts (Username 1 & Username 2)"
    print_warning "The following steps CANNOT be fully automated and require manual console operations:"
    echo
    echo "MANUAL STEPS REQUIRED:"
    echo "1. Task 1: Explore IAM console with Username 1 (Owner)"
    echo "2. Task 2: Switch to Username 2 console and verify Viewer role limitations"
    echo "3. Task 5: Remove Project Viewer role from Username 2 (as Username 1)"
    echo "4. Task 6: Grant Storage Object Viewer role to Username 2 (as Username 1)"
    echo "5. Task 6: Test Cloud Storage access with Username 2 via Cloud Shell"
    echo

    wait_for_user "Please complete the manual IAM console steps, then continue here"

    print_success "Manual IAM operations completed"
}

# Function to test Cloud Storage access
test_storage_access() {
    print_step "Testing Cloud Storage access"

    print_warning "Testing bucket access (this should work if you have proper permissions)"
    if gsutil ls gs://$BUCKET_NAME/ >/dev/null 2>&1; then
        print_success "Successfully accessed bucket contents:"
        gsutil ls gs://$BUCKET_NAME/
    else
        print_error "Failed to access bucket. Check your permissions."
        print_warning "If you're using Username 2, make sure Storage Object Viewer role was granted"
    fi
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
                print_error "Unknown argument: $1"
                echo "Usage: $0 [--verbose|-v] [cleanup]"
                exit 1
                ;;
        esac
    done

    echo "GSP064 - Cloud IAM: Qwik Start"
    echo "Automated Lab Script"
    echo "================================="
    echo

    if $do_cleanup; then
        cleanup
        exit 0
    fi

    # Welcome message
    print_warning "IMPORTANT: This script only automates PARTS of the lab."
    print_warning "You need TWO separate GCP user accounts to complete this lab."
    echo
    print_warning "The script will automate:"
    echo "- Cloud Storage bucket creation"
    echo "- Sample file upload"
    echo "- Basic access testing"
    echo
    print_warning "You must manually perform:"
    echo "- IAM role exploration and management"
    echo "- User account switching"
    echo "- Cloud Shell operations with different users"
    echo

    if ! confirm "Do you want to continue?"; then
        exit 0
    fi

    # Run the automated parts
    check_prerequisites
    setup_project
    create_bucket
    upload_sample_file
    demonstrate_iam
    test_storage_access

    echo
    print_success "Automated portion of GSP064 lab completed!"
    print_warning "Remember to complete the manual steps in the Google Cloud Console"
    print_warning "Don't forget to clean up resources when done: $0 cleanup"
}

# Run main function with all arguments
main "$@"
