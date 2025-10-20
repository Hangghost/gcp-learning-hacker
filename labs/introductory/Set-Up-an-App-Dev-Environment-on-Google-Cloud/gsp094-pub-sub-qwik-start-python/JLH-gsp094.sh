#!/bin/bash

# GSP094 - Pub/Sub: Qwik Start - Python
# This script automates the Pub/Sub Python lab execution
# Author: JLH (Generated)
# Date: 2025-10-19

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
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

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  GSP094 - Pub/Sub: Qwik Start - Python${NC}"
    echo -e "${BLUE}================================================${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for user confirmation
wait_for_confirmation() {
    echo -e "${YELLOW}$1${NC}"
    read -p "Press Enter to continue..."
}

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local input

    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# Function to check GCP project
check_project() {
    print_step "1" "Checking GCP project configuration..."

    if [[ -z "${GOOGLE_CLOUD_PROJECT}" ]]; then
        print_error "GOOGLE_CLOUD_PROJECT environment variable is not set"
        echo "Please set your GCP project ID:"
        echo "export GOOGLE_CLOUD_PROJECT=YOUR_PROJECT_ID"
        exit 1
    fi

    print_success "Using project: $GOOGLE_CLOUD_PROJECT"

    # Verify gcloud is configured
    if ! gcloud config get-value project >/dev/null 2>&1; then
        print_warning "gcloud not configured. Setting project..."
        gcloud config set project $GOOGLE_CLOUD_PROJECT
    fi
}

# Function to setup virtual environment
setup_virtual_env() {
    print_step "2" "Setting up Python virtual environment..."

    # Install virtualenv if not present
    if ! command_exists virtualenv; then
        print_warning "Installing virtualenv..."
        sudo apt-get update && sudo apt-get install -y virtualenv
    fi

    # Create virtual environment
    if [[ ! -d "venv" ]]; then
        python3 -m venv venv
        print_success "Virtual environment created"
    else
        print_warning "Virtual environment already exists"
    fi

    # Activate virtual environment
    source venv/bin/activate
    print_success "Virtual environment activated"

    # Upgrade pip
    pip install --upgrade pip
}

# Function to install dependencies
install_dependencies() {
    print_step "3" "Installing Python dependencies..."

    # Activate virtual environment if not already
    if [[ "$VIRTUAL_ENV" != *"venv" ]]; then
        source venv/bin/activate
    fi

    # Install Google Cloud Pub/Sub library
    pip install --upgrade google-cloud-pubsub
    print_success "Google Cloud Pub/Sub library installed"

    # Clone sample code if not exists
    if [[ ! -d "python-pubsub" ]]; then
        git clone https://github.com/googleapis/python-pubsub.git
        print_success "Sample code cloned"
    else
        print_warning "Sample code already exists"
    fi

    # Navigate to snippets directory
    cd python-pubsub/samples/snippets
    print_success "Navigated to snippets directory"
}

# Function to create topic
create_topic() {
    print_step "4" "Creating Pub/Sub topic..."

    # Activate virtual environment if not already
    if [[ "$VIRTUAL_ENV" != *"venv" ]]; then
        source venv/bin/activate
        cd python-pubsub/samples/snippets
    fi

    local topic_name="MyTopic"

    echo "Creating topic: $topic_name"
    python publisher.py $GOOGLE_CLOUD_PROJECT create $topic_name

    print_success "Topic '$topic_name' created"

    # List topics to verify
    echo "Listing topics:"
    python publisher.py $GOOGLE_CLOUD_PROJECT list
}

# Function to create subscription
create_subscription() {
    print_step "5" "Creating Pub/Sub subscription..."

    # Activate virtual environment if not already
    if [[ "$VIRTUAL_ENV" != *"venv" ]]; then
        source venv/bin/activate
        cd python-pubsub/samples/snippets
    fi

    local topic_name="MyTopic"
    local subscription_name="MySub"

    echo "Creating subscription: $subscription_name for topic: $topic_name"
    python subscriber.py $GOOGLE_CLOUD_PROJECT create $topic_name $subscription_name

    print_success "Subscription '$subscription_name' created"

    # List subscriptions to verify
    echo "Listing subscriptions:"
    python subscriber.py $GOOGLE_CLOUD_PROJECT list-in-project
}

# Function to publish messages
publish_messages() {
    print_step "6" "Publishing messages to topic..."

    local topic_name="MyTopic"

    # Get user information
    local user_name=$(get_input "Enter your name" "Harry")
    local favorite_food=$(get_input "Enter your favorite food" "cheese")

    echo "Publishing messages to topic: $topic_name"

    # Publish messages
    gcloud pubsub topics publish $topic_name --message "Hello"
    gcloud pubsub topics publish $topic_name --message "Publisher's name is $user_name"
    gcloud pubsub topics publish $topic_name --message "Publisher likes to eat $favorite_food"
    gcloud pubsub topics publish $topic_name --message "Publisher thinks Pub/Sub is awesome"

    print_success "Messages published successfully"
}

# Function to receive messages
receive_messages() {
    print_step "7" "Receiving messages from subscription..."

    # Activate virtual environment if not already
    if [[ "$VIRTUAL_ENV" != *"venv" ]]; then
        source venv/bin/activate
        cd python-pubsub/samples/snippets
    fi

    local subscription_name="MySub"

    echo "Receiving messages from subscription: $subscription_name"
    echo "Press Ctrl+C to stop listening..."
    echo ""

    # Start receiving messages (this will run until interrupted)
    timeout 30 python subscriber.py $GOOGLE_CLOUD_PROJECT receive $subscription_name || true

    print_success "Message reception completed"
}

# Function to cleanup resources
cleanup_resources() {
    print_step "8" "Cleaning up resources..."

    # Ask user if they want to cleanup
    echo "This will delete the topic and subscription created in this lab."
    read -p "Do you want to proceed with cleanup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Cleanup skipped by user"
        return
    fi

    # Activate virtual environment if not already
    if [[ "$VIRTUAL_ENV" != *"venv" ]]; then
        source venv/bin/activate
        cd python-pubsub/samples/snippets
    fi

    local topic_name="MyTopic"
    local subscription_name="MySub"

    # Delete subscription first
    echo "Deleting subscription: $subscription_name"
    python subscriber.py $GOOGLE_CLOUD_PROJECT delete $topic_name $subscription_name || true

    # Delete topic
    echo "Deleting topic: $topic_name"
    python publisher.py $GOOGLE_CLOUD_PROJECT delete $topic_name || true

    print_success "Cleanup completed"
}

# Function to show completion message
show_completion() {
    print_header
    print_success "Lab GSP094 completed successfully!"
    echo ""
    echo "What you accomplished:"
    echo "✓ Created a Python virtual environment"
    echo "✓ Installed Google Cloud Pub/Sub Python client library"
    echo "✓ Created a Pub/Sub topic"
    echo "✓ Created a Pub/Sub subscription"
    echo "✓ Published messages to the topic"
    echo "✓ Received messages from the subscription"
    echo ""
    echo "Next steps:"
    echo "- Explore Pub/Sub Lite for high-volume messaging"
    echo "- Learn about push subscriptions and webhooks"
    echo "- Implement Pub/Sub in your applications"
    echo ""
}

# Function to show help
show_help() {
    echo "GSP094 - Pub/Sub: Qwik Start - Python Automation Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -s, --skip-cleanup  Skip the cleanup step"
    echo "  --cleanup-only      Run only the cleanup step"
    echo ""
    echo "Environment Variables:"
    echo "  GOOGLE_CLOUD_PROJECT  Your GCP project ID (required)"
    echo ""
    echo "Examples:"
    echo "  $0                    Run the complete lab"
    echo "  $0 --cleanup-only    Clean up resources only"
    echo ""
}

# Main function
main() {
    local skip_cleanup=false
    local cleanup_only=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--skip-cleanup)
                skip_cleanup=true
                shift
                ;;
            --cleanup-only)
                cleanup_only=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Show header
    print_header

    # Check if cleanup only
    if [[ "$cleanup_only" == true ]]; then
        check_project
        cleanup_resources
        exit 0
    fi

    # Welcome message
    echo "This script will guide you through the Pub/Sub Python lab."
    echo "Make sure you have set the GOOGLE_CLOUD_PROJECT environment variable."
    echo ""

    # Execute lab steps
    check_project
    setup_virtual_env
    install_dependencies
    create_topic
    create_subscription
    publish_messages
    receive_messages

    # Cleanup (unless skipped)
    if [[ "$skip_cleanup" == false ]]; then
        cleanup_resources
    fi

    # Show completion
    show_completion
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}Script interrupted by user${NC}"; exit 1' INT TERM

# Run main function
main "$@"
