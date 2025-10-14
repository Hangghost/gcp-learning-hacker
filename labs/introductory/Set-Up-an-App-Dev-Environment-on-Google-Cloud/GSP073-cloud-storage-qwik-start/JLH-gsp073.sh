#!/bin/bash

# GSP073 - Cloud Storage: Qwik Start - Cloud Console
# Automation script for Cloud Storage lab
# 
# This script automates the Cloud Storage lab tasks including:
# - Creating a Cloud Storage bucket
# - Uploading objects to the bucket
# - Making objects publicly accessible
# - Creating folders and subfolders
# - Cleaning up resources

set -e  # Exit on any error

# Color codes for output
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

# Function to check if gcloud is installed and authenticated
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "No active gcloud authentication found. Please run 'gcloud auth login' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to get user input for lab variables
get_lab_variables() {
    print_status "Getting lab variables..."
    
    # Get current project ID
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        echo -n "Enter your GCP Project ID: "
        read PROJECT_ID
        gcloud config set project $PROJECT_ID
    else
        echo "Using current project: $PROJECT_ID"
    fi
    
    # Get region
    echo -n "Enter your preferred region (e.g., us-central1): "
    read REGION
    
    # Use project ID as bucket name (ensures uniqueness)
    BUCKET_NAME="$PROJECT_ID"
    
    print_success "Lab variables configured"
    print_status "Project ID: $PROJECT_ID"
    print_status "Region: $REGION"
    print_status "Bucket Name: $BUCKET_NAME"
}

# Function to create Cloud Storage bucket
create_bucket() {
    print_status "Creating Cloud Storage bucket: $BUCKET_NAME"
    
    # Create bucket with specified configuration
    gcloud storage buckets create gs://$BUCKET_NAME \
        --location=$REGION \
        --default-storage-class=STANDARD \
        --uniform-bucket-level-access \
        --no-public-access-prevention
    
    if [ $? -eq 0 ]; then
        print_success "Bucket $BUCKET_NAME created successfully"
    else
        print_error "Failed to create bucket"
        exit 1
    fi
}

# Function to upload test object
upload_object() {
    print_status "Uploading test object to bucket"
    
    # Create a simple test file if kitten.png doesn't exist
    if [ ! -f "kitten.png" ]; then
        print_warning "kitten.png not found, creating a test file instead"
        echo "This is a test file for GSP073 lab" > test-file.txt
        gcloud storage cp test-file.txt gs://$BUCKET_NAME/kitten.png
        rm test-file.txt
    else
        gcloud storage cp kitten.png gs://$BUCKET_NAME/kitten.png
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Object uploaded successfully"
    else
        print_error "Failed to upload object"
        exit 1
    fi
}

# Function to make object publicly accessible
make_public() {
    print_status "Making object publicly accessible"
    
    # Add allUsers as Storage Object Viewer
    gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME \
        --member=allUsers \
        --role=roles/storage.objectViewer
    
    if [ $? -eq 0 ]; then
        print_success "Object made publicly accessible"
        print_status "Public URL: https://storage.googleapis.com/$BUCKET_NAME/kitten.png"
    else
        print_error "Failed to make object public"
        exit 1
    fi
}

# Function to create folders
create_folders() {
    print_status "Creating folder structure"
    
    # Create folder1
    echo "Folder 1 content" | gcloud storage cp - gs://$BUCKET_NAME/folder1/.folder-marker
    
    # Create folder2 inside folder1
    echo "Folder 2 content" | gcloud storage cp - gs://$BUCKET_NAME/folder1/folder2/.folder-marker
    
    # Upload a file to folder2
    echo "Test file in folder2" > test-folder-file.txt
    gcloud storage cp test-folder-file.txt gs://$BUCKET_NAME/folder1/folder2/test-file.txt
    rm test-folder-file.txt
    
    if [ $? -eq 0 ]; then
        print_success "Folder structure created successfully"
        print_status "Created: folder1/folder2/test-file.txt"
    else
        print_error "Failed to create folder structure"
        exit 1
    fi
}

# Function to verify lab completion
verify_lab() {
    print_status "Verifying lab completion..."
    
    # Check if bucket exists
    if gcloud storage buckets describe gs://$BUCKET_NAME &>/dev/null; then
        print_success "✓ Bucket exists"
    else
        print_error "✗ Bucket does not exist"
        return 1
    fi
    
    # Check if object exists
    if gcloud storage objects describe gs://$BUCKET_NAME/kitten.png &>/dev/null; then
        print_success "✓ Object uploaded"
    else
        print_error "✗ Object not found"
        return 1
    fi
    
    # Check if object is public
    if gcloud storage buckets get-iam-policy gs://$BUCKET_NAME --format="value(bindings.members)" | grep -q "allUsers"; then
        print_success "✓ Object is publicly accessible"
    else
        print_warning "⚠ Object may not be publicly accessible"
    fi
    
    # Check folder structure
    if gcloud storage objects list gs://$BUCKET_NAME/folder1/folder2/ --format="value(name)" | grep -q "test-file.txt"; then
        print_success "✓ Folder structure created"
    else
        print_error "✗ Folder structure not found"
        return 1
    fi
    
    print_success "Lab verification completed successfully!"
}

# Function to display lab summary
show_summary() {
    echo
    print_status "=== GSP073 Lab Summary ==="
    echo "Project ID: $PROJECT_ID"
    echo "Region: $REGION"
    echo "Bucket Name: $BUCKET_NAME"
    echo "Public URL: https://storage.googleapis.com/$BUCKET_NAME/kitten.png"
    echo
    print_status "Lab tasks completed:"
    echo "✓ Created Cloud Storage bucket"
    echo "✓ Uploaded object to bucket"
    echo "✓ Made object publicly accessible"
    echo "✓ Created folder structure"
    echo
    print_warning "Remember to clean up resources when done!"
}

# Function to clean up resources
cleanup() {
    print_status "Cleaning up resources..."
    
    if gcloud storage buckets describe gs://$BUCKET_NAME &>/dev/null; then
        print_warning "Deleting bucket: $BUCKET_NAME"
        gcloud storage buckets delete gs://$BUCKET_NAME --quiet
        
        if [ $? -eq 0 ]; then
            print_success "Bucket deleted successfully"
        else
            print_error "Failed to delete bucket"
        fi
    else
        print_warning "Bucket $BUCKET_NAME does not exist"
    fi
}

# Function to show help
show_help() {
    echo "GSP073 - Cloud Storage: Qwik Start - Cloud Console"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  run      Run the complete lab (default)"
    echo "  verify   Verify lab completion"
    echo "  cleanup  Clean up created resources"
    echo "  help     Show this help message"
    echo
    echo "Examples:"
    echo "  $0           # Run the complete lab"
    echo "  $0 run       # Run the complete lab"
    echo "  $0 verify    # Verify lab completion"
    echo "  $0 cleanup   # Clean up resources"
}

# Main execution
main() {
    case "${1:-run}" in
        "run")
            echo "=== GSP073 - Cloud Storage: Qwik Start - Cloud Console ==="
            echo
            check_prerequisites
            get_lab_variables
            echo
            create_bucket
            upload_object
            make_public
            create_folders
            echo
            verify_lab
            show_summary
            ;;
        "verify")
            get_lab_variables
            verify_lab
            ;;
        "cleanup")
            get_lab_variables
            cleanup
            ;;
        "help")
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
