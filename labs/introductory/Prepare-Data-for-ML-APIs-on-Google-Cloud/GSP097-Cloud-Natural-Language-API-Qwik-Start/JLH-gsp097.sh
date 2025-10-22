#!/bin/bash

# GSP097 - Cloud Natural Language API: Qwik Start
# This script automates the Cloud Natural Language API lab

set -e  # Exit on any error

# Color codes for output
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

# Function to check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 command not found. Please install it first."
        exit 1
    fi
}

# Function to prompt user for confirmation
confirm() {
    local message=$1
    read -p "$message (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Function to cleanup resources
cleanup() {
    print_info "Starting cleanup process..."

    if [ -f "~/key.json" ]; then
        print_warning "Removing service account key file..."
        rm -f ~/key.json
        print_success "Service account key file removed."
    fi

    if confirm "Do you want to delete the service account 'my-natlang-sa'?"; then
        print_info "Deleting service account..."
        if gcloud iam service-accounts delete my-natlang-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --quiet 2>/dev/null; then
            print_success "Service account deleted successfully."
        else
            print_warning "Service account may not exist or already deleted."
        fi
    fi

    print_success "Cleanup completed."
}

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "GSP097 - Cloud Natural Language API: Qwik Start Automation Script"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help          Show this help message"
    echo "  -c, --cleanup       Run cleanup only"
    echo "  --skip-cleanup      Skip cleanup at the end"
    echo ""
    echo "This script will:"
    echo "1. Set up environment variables"
    echo "2. Create a service account and credentials"
    echo "3. Run Natural Language API entity analysis"
    echo "4. Display results"
    echo "5. Optionally clean up resources"
}

# Parse command line arguments
SKIP_CLEANUP=false
CLEANUP_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -c|--cleanup)
            CLEANUP_ONLY=true
            shift
            ;;
        --skip-cleanup)
            SKIP_CLEANUP=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_info "Starting GSP097 - Cloud Natural Language API: Qwik Start"
    print_info "This script will guide you through the lab steps."
    echo

    # Check prerequisites
    print_info "Checking prerequisites..."
    check_command gcloud
    print_success "gcloud command found."

    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 > /dev/null; then
        print_error "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi
    print_success "gcloud authentication verified."

    # If cleanup only, skip to cleanup
    if [ "$CLEANUP_ONLY" = true ]; then
        cleanup
        exit 0
    fi

    # Step 1: Set up environment variables
    print_info "Step 1: Setting up environment variables..."
    export GOOGLE_CLOUD_PROJECT=$(gcloud config get-value core/project)

    if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
        print_error "Could not determine project ID. Please set it manually:"
        echo "export GOOGLE_CLOUD_PROJECT=YOUR_PROJECT_ID"
        exit 1
    fi

    print_success "Project ID set to: $GOOGLE_CLOUD_PROJECT"

    # Step 2: Create service account
    print_info "Step 2: Creating service account..."

    if ! confirm "Create service account 'my-natlang-sa'?"; then
        print_warning "Service account creation skipped."
    else
        print_info "Creating service account..."
        gcloud iam service-accounts create my-natlang-sa \
            --display-name "my natural language service account" \
            --description "Service account for Natural Language API lab"

        print_success "Service account created."

        # Create credentials
        print_info "Creating service account key..."
        gcloud iam service-accounts keys create ~/key.json \
            --iam-account my-natlang-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com

        print_success "Service account key created at ~/key.json"

        # Set credentials
        print_info "Setting GOOGLE_APPLICATION_CREDENTIALS..."
        export GOOGLE_APPLICATION_CREDENTIALS=~/key.json
        print_success "Credentials configured."
    fi

    # Step 3: Run Natural Language API analysis
    print_info "Step 3: Running Natural Language API entity analysis..."

    if ! confirm "Run entity analysis on sample text?"; then
        print_warning "Entity analysis skipped."
    else
        print_info "Analyzing text: 'Michelangelo Caravaggio, Italian painter, is known for \"The Calling of Saint Matthew\".'"

        # Run the analysis
        gcloud ml language analyze-entities \
            --content="Michelangelo Caravaggio, Italian painter, is known for 'The Calling of Saint Matthew'." \
            > result.json

        print_success "Analysis completed. Results saved to result.json"

        # Display results
        echo
        print_info "Analysis Results:"
        echo "----------------------------------------"
        cat result.json
        echo "----------------------------------------"
        echo

        print_info "Result interpretation:"
        print_info "- 'Michelangelo Caravaggio' is identified as a PERSON"
        print_info "- 'Italian' is identified as a LOCATION"
        print_info "- 'The Calling of Saint Matthew' is identified as an EVENT"
        print_info "- Each entity includes salience scores and metadata"
    fi

    # Final cleanup
    if [ "$SKIP_CLEANUP" = false ]; then
        echo
        if confirm "Lab completed. Do you want to clean up resources now?"; then
            cleanup
        else
            print_warning "Remember to run cleanup later to avoid charges."
            print_info "You can run: $0 --cleanup"
        fi
    else
        print_warning "Cleanup skipped as requested."
    fi

    print_success "GSP097 lab completed successfully!"
    print_info "You can find the results in result.json file."
}

# Trap for cleanup on script exit
trap 'echo; print_warning "Script interrupted. You may need to run cleanup manually."; print_info "Run: $0 --cleanup"' INT TERM

# Run main function
main "$@"
