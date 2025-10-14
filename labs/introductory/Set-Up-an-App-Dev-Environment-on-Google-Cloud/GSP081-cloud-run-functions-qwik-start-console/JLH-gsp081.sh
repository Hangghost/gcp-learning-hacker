#!/bin/bash

# GSP081 - Cloud Run Functions: Qwik Start - Console
# Automated Lab Script
# This script provides guidance for the GSP081 lab
# Note: This lab is primarily console-based, so most steps require manual interaction
# Usage: ./JLH-gsp081.sh [--verbose|-v] [cleanup]
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
    gcloud config set compute/region "$REGION"

    print_success "Environment setup completed"
}

# Function to display manual steps
show_manual_steps() {
    print_step "Manual Steps Required"

    echo
    print_info "This lab is primarily console-based. Please follow these manual steps:"
    echo

    print_step "Task 1: Create a function"
    echo "1. Open the Google Cloud Console"
    echo "2. Click Navigation menu > Cloud Run"
    echo "3. Click WRITE A FUNCTION"
    echo "4. Configure the function with these settings:"
    echo "   - Service name: gcfunction"
    echo "   - Region: $REGION"
    echo "   - Authentication: Allow public access"
    echo "   - Memory: Keep default"
    echo "   - Execution environment: Second generation"
    echo "   - Maximum instances: 5"
    echo "5. Click Create"
    echo "6. If prompted, enable required APIs"
    echo

    print_step "Task 2: Deploy the function"
    echo "1. In the function editor, keep the default helloHttp code"
    echo "2. Click SAVE and REDEPLOY"
    echo "3. Wait for deployment to complete (green checkmark)"
    echo

    print_step "Task 3: Test the function"
    echo "1. On the function details page, click TEST"
    echo "2. In the Triggering event field, enter: {\"message\":\"Hello World!\"}"
    echo "3. Copy the CLI test command shown"
    echo

    confirm "Have you completed the manual steps above?"
}

# Function to run CLI test
run_cli_test() {
    print_step "Task 3: Testing the function via CLI"

    # Get function URL - this might need to be provided by user
    get_input "Enter your Cloud Run function URL (from the console)" FUNCTION_URL

    if [ -z "$FUNCTION_URL" ]; then
        print_warning "No function URL provided. Skipping CLI test."
        return
    fi

    print_info "Testing function with curl..."

    # Test the function
    if curl -X POST "$FUNCTION_URL" \
         -H "Content-Type: application/json" \
         -d '{"message":"Hello World!"}' 2>/dev/null; then
        print_success "Function test completed successfully"
        print_info "You should see 'Hello World!' in the response"
    else
        print_error "Function test failed. Please check your function URL and try again."
    fi
}

# Function to show log viewing instructions
show_log_instructions() {
    print_step "Task 4: View logs"

    echo
    print_info "To view function logs:"
    echo "1. Go to the Cloud Run service details page"
    echo "2. Click Observability > Logs"
    echo "3. You should see the execution logs"
    echo

    print_info "You can also view logs via CLI:"
    echo "gcloud functions logs read gcfunction --region=$REGION"
    echo
}

# Function to cleanup resources
cleanup() {
    print_step "Cleaning up resources"

    confirm "This will delete the Cloud Run function. Continue?"

    print_info "Deleting Cloud Run function..."
    if gcloud run services delete gcfunction --region="$REGION" --quiet; then
        print_success "Function deleted successfully"
    else
        print_error "Failed to delete function. Please check manually."
    fi

    print_success "Cleanup completed"
}

# Function to show quiz answers
show_quiz_answers() {
    print_step "Task 5: Test your understanding"

    echo
    print_info "Quiz Answers:"
    echo "1. Cloud Run functions is a serverless execution environment for event driven services on Google Cloud."
    echo "   Answer: True"
    echo
    echo "2. Which type of trigger is used while creating Cloud Run functions in the lab?"
    echo "   Answer: HTTP"
    echo
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

    echo "GSP081 - Cloud Run Functions: Qwik Start - Console"
    echo "Automated Lab Script"
    echo

    if $do_cleanup; then
        cleanup
        exit 0
    fi

    check_prerequisites
    setup_environment
    show_manual_steps
    run_cli_test
    show_log_instructions
    show_quiz_answers

    print_success "Lab guidance completed!"
    print_info "Don't forget to complete the manual steps in the console."
    print_info "Run '$0 cleanup' when done to clean up resources."
}

# Run main function
main "$@"
