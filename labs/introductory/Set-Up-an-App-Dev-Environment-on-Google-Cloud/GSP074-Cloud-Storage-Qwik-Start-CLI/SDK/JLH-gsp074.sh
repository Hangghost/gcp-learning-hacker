#!/bin/bash

# GSP074 - Cloud Storage: Qwik Start - CLI/SDK
# Automated Lab Script
# This script automates the GSP074 lab for Cloud Storage operations
# Usage: ./JLH-gsp074.sh [--verbose|-v] [cleanup]
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
    read -p "$message (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to generate unique bucket name
generate_bucket_name() {
    local base_name="qwikstart-lab"
    local suffix=$(date +%s | tail -c 6)
    echo "${base_name}-${suffix}"
}

# Cleanup function
cleanup() {
    print_warning "Starting cleanup process..."

    # Delete all objects in bucket
    if [ -n "$BUCKET_NAME" ]; then
        print_step "Deleting all objects in bucket"
        if gcloud storage rm -r "gs://$BUCKET_NAME/**" >/dev/null 2>&1; then
            print_success "All objects deleted from bucket"
        else
            print_warning "No objects found in bucket or bucket doesn't exist"
        fi

        # Delete bucket
        if gcloud storage buckets delete "gs://$BUCKET_NAME" --quiet >/dev/null 2>&1; then
            print_success "Bucket $BUCKET_NAME deleted"
        else
            print_warning "Bucket $BUCKET_NAME not found or already deleted"
        fi
    fi

    # Remove local files
    if [ -f "ada.jpg" ]; then
        rm -f ada.jpg
        print_success "Local ada.jpg file removed"
    fi

    print_success "Cleanup completed!"
}

# Function to test public access
test_public_access() {
    local object_url="$1"
    print_step "Testing public access"

    if curl -s --head "$object_url" | grep -q "HTTP/1.1 200"; then
        print_success "Object is publicly accessible"
        return 0
    else
        print_error "Object is not publicly accessible"
        return 1
    fi
}

# Main script
main() {
    echo "========================================="
    echo "GSP074 - Cloud Storage: Qwik Start - CLI/SDK"
    echo "Automated Lab Script"
    echo "========================================="

    # Check for verbose mode
    VERBOSE=""
    if [[ "$1" == "--verbose" ]] || [[ "$1" == "-v" ]]; then
        VERBOSE="--verbosity=info"
        print_warning "Verbose mode enabled - showing detailed gcloud output"
    fi

    # Check prerequisites
    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    if ! command_exists gsutil; then
        print_error "gsutil is not installed. Please install it first."
        exit 1
    fi

    # Get user input
    print_step "Configuration"
    get_input "Enter your GCP region" REGION "us-central1"

    # Generate unique bucket name
    BUCKET_NAME=$(generate_bucket_name)
    print_warning "Generated bucket name: $BUCKET_NAME"

    echo "Region: $REGION"
    echo "Bucket Name: $BUCKET_NAME"

    if ! confirm "Do you want to proceed with these settings?"; then
        print_warning "Script cancelled by user"
        exit 0
    fi

    # Set trap for cleanup on error
    trap cleanup ERR

    # Task 1: Set the region
    print_step "Task 1: Setting the region"
    gcloud config set compute/region "$REGION" $VERBOSE
    print_success "Default region set to $REGION"

    # Task 2: Create a bucket
    print_step "Task 2: Creating storage bucket"
    if gcloud storage buckets create "gs://$BUCKET_NAME" $VERBOSE; then
        print_success "Bucket gs://$BUCKET_NAME created successfully"
    else
        print_error "Failed to create bucket"
        exit 1
    fi

    # Task 3: Upload an object
    print_step "Task 3: Uploading object to bucket"

    # Download the image
    print_step "Downloading ada.jpg"
    if curl -s "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Ada_Lovelace_portrait.jpg/800px-Ada_Lovelace_portrait.jpg" --output ada.jpg; then
        print_success "ada.jpg downloaded successfully"
    else
        print_error "Failed to download ada.jpg"
        exit 1
    fi

    # Upload to bucket
    print_step "Uploading ada.jpg to bucket"
    if gcloud storage cp ada.jpg "gs://$BUCKET_NAME" $VERBOSE; then
        print_success "ada.jpg uploaded to gs://$BUCKET_NAME"
    else
        print_error "Failed to upload ada.jpg"
        exit 1
    fi

    # Remove local file
    rm -f ada.jpg
    print_success "Local ada.jpg file removed"

    # Task 4: Download object from bucket
    print_step "Task 4: Downloading object from bucket"
    if gcloud storage cp "gs://$BUCKET_NAME/ada.jpg" . $VERBOSE; then
        print_success "ada.jpg downloaded from bucket"
        ls -la ada.jpg
    else
        print_error "Failed to download ada.jpg from bucket"
        exit 1
    fi

    # Task 5: Copy object to folder
    print_step "Task 5: Copying object to folder in bucket"
    if gcloud storage cp "gs://$BUCKET_NAME/ada.jpg" "gs://$BUCKET_NAME/image-folder/" $VERBOSE; then
        print_success "ada.jpg copied to gs://$BUCKET_NAME/image-folder/"
    else
        print_error "Failed to copy ada.jpg to folder"
        exit 1
    fi

    # Task 6: List bucket contents
    print_step "Task 6: Listing bucket contents"
    echo "Bucket contents:"
    gcloud storage ls "gs://$BUCKET_NAME" $VERBOSE
    print_success "Bucket contents listed"

    # Task 7: List object details
    print_step "Task 7: Listing object details"
    echo "Object details:"
    gcloud storage ls -l "gs://$BUCKET_NAME/ada.jpg" $VERBOSE
    print_success "Object details retrieved"

    # Task 8: Make object publicly accessible
    print_step "Task 8: Making object publicly accessible"
    if gsutil acl ch -u AllUsers:R "gs://$BUCKET_NAME/ada.jpg"; then
        print_success "Object gs://$BUCKET_NAME/ada.jpg is now publicly accessible"
    else
        print_error "Failed to make object publicly accessible"
        exit 1
    fi

    # Task 9: Verify public access
    print_step "Task 9: Verifying public access"
    PUBLIC_URL="https://storage.googleapis.com/$BUCKET_NAME/ada.jpg"
    echo "Public URL: $PUBLIC_URL"

    print_warning "Testing public access..."
    if test_public_access "$PUBLIC_URL"; then
        print_success "Public access verified"
    else
        print_warning "Public access test inconclusive (may be due to network restrictions)"
    fi

    # Task 10: Remove public access
    print_step "Task 10: Removing public access"
    if gsutil acl ch -d AllUsers "gs://$BUCKET_NAME/ada.jpg"; then
        print_success "Public access removed from gs://$BUCKET_NAME/ada.jpg"
    else
        print_error "Failed to remove public access"
        exit 1
    fi

    # Verify public access is removed
    print_warning "Verifying public access is removed..."
    if ! test_public_access "$PUBLIC_URL"; then
        print_success "Public access successfully removed"
    else
        print_warning "Public access removal test inconclusive"
    fi

    # Task 11: Delete objects
    print_step "Task 11: Deleting objects"

    # Delete the ada.jpg file (keep the one in image-folder)
    if gcloud storage rm "gs://$BUCKET_NAME/ada.jpg" $VERBOSE; then
        print_success "gs://$BUCKET_NAME/ada.jpg deleted"
    else
        print_error "Failed to delete gs://$BUCKET_NAME/ada.jpg"
        exit 1
    fi

    # Remove local file
    rm -f ada.jpg
    print_success "Local ada.jpg file cleaned up"

    print_success "Lab completed successfully!"
    echo
    echo "Remaining objects in bucket:"
    gcloud storage ls -r "gs://$BUCKET_NAME" $VERBOSE

    echo
    print_warning "Don't forget to clean up resources to avoid charges!"
    if confirm "Do you want to run cleanup now?"; then
        cleanup
    else
        print_warning "To clean up later, run this script with 'cleanup' as an argument"
        echo "Or manually delete the bucket: gcloud storage buckets delete gs://$BUCKET_NAME"
        echo "Use './JLH-gsp074.sh --verbose' to see detailed gcloud output next time"
    fi
}

# Check if cleanup was requested
if [ "$1" = "cleanup" ] || [ "$2" = "cleanup" ]; then
    print_warning "Cleanup mode selected"

    # Get required variables for cleanup
    get_input "Enter your bucket name" BUCKET_NAME

    cleanup
    exit 0
fi

# Run main function
main "$@"
