#!/bin/bash

# GSP096 - Pub/Sub: Qwik Start - Console
# Automated Lab Script
# This script automates parts of the GSP096 lab for Pub/Sub operations
# Some steps must be performed manually in the console
# Usage: ./JLH-gsp096.sh [--verbose|-v] [cleanup]
# Status: verified on 2025-10-14

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
TOPIC_NAME="MyTopic"
SUBSCRIPTION_NAME="MySub"
PROJECT_ID=""
VERBOSE=false

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

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites"

    # Check if gcloud is installed
    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 > /dev/null; then
        print_error "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi

    # Get current project
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        print_error "No project set. Please run 'gcloud config set project PROJECT_ID' first."
        exit 1
    fi

    print_success "Prerequisites check passed"
    echo "Using project: $PROJECT_ID"
}

# Function to enable required APIs
enable_apis() {
    print_step "Enabling required APIs"

    gcloud services enable pubsub.googleapis.com --quiet
    print_success "Pub/Sub API enabled"
}

# Function to create Pub/Sub topic
create_topic() {
    print_step "Creating Pub/Sub topic"

    if gcloud pubsub topics describe "$TOPIC_NAME" --project="$PROJECT_ID" &>/dev/null; then
        print_warning "Topic '$TOPIC_NAME' already exists"
    else
        gcloud pubsub topics create "$TOPIC_NAME" --project="$PROJECT_ID"
        print_success "Created topic: $TOPIC_NAME"
    fi
}

# Function to create subscription
create_subscription() {
    print_step "Creating subscription"

    if gcloud pubsub subscriptions describe "$SUBSCRIPTION_NAME" --project="$PROJECT_ID" &>/dev/null; then
        print_warning "Subscription '$SUBSCRIPTION_NAME' already exists"
    else
        gcloud pubsub subscriptions create "$SUBSCRIPTION_NAME" \
            --topic="$TOPIC_NAME" \
            --project="$PROJECT_ID" \
            --ack-deadline=60 \
            --message-retention-duration=7d
        print_success "Created subscription: $SUBSCRIPTION_NAME"
    fi
}

# Function to publish message
publish_message() {
    print_step "Publishing message to topic"

    echo "Hello World" | gcloud pubsub topics publish "$TOPIC_NAME" \
        --project="$PROJECT_ID" \
        --message="Hello World"

    print_success "Published message: 'Hello World'"
}

# Function to pull message
pull_message() {
    print_step "Pulling message from subscription"

    print_warning "Pulling message from subscription..."
    gcloud pubsub subscriptions pull "$SUBSCRIPTION_NAME" \
        --project="$PROJECT_ID" \
        --auto-ack \
        --limit=1 \
        --format="value(message.data)"

    print_success "Message pulled and acknowledged"
}

# Function to show lab progress
show_progress() {
    print_step "Lab Progress Summary"
    echo
    echo "Completed steps:"
    echo "1. ✓ Prerequisites check"
    echo "2. ✓ APIs enabled"
    echo "3. ✓ Topic created: $TOPIC_NAME"
    echo "4. ✓ Subscription created: $SUBSCRIPTION_NAME"
    echo "5. ✓ Message published"
    echo "6. ✓ Message pulled"
    echo
    print_success "Lab automation completed!"
    echo
    print_warning "Note: Some steps require manual action in the Cloud Console:"
    echo "  - Creating topic (Step 1)"
    echo "  - Creating subscription (Step 2)"
    echo "  - Publishing message (Step 4)"
    echo "  - Viewing message (Step 5)"
    echo
    echo "These steps are better done manually in the console for learning purposes."
}

# Function to cleanup resources
cleanup() {
    print_step "Cleaning up resources"

    if confirm "Do you want to delete the subscription '$SUBSCRIPTION_NAME'?"; then
        if gcloud pubsub subscriptions describe "$SUBSCRIPTION_NAME" --project="$PROJECT_ID" &>/dev/null; then
            gcloud pubsub subscriptions delete "$SUBSCRIPTION_NAME" --project="$PROJECT_ID" --quiet
            print_success "Deleted subscription: $SUBSCRIPTION_NAME"
        else
            print_warning "Subscription '$SUBSCRIPTION_NAME' does not exist"
        fi
    fi

    if confirm "Do you want to delete the topic '$TOPIC_NAME'?"; then
        if gcloud pubsub topics describe "$TOPIC_NAME" --project="$PROJECT_ID" &>/dev/null; then
            gcloud pubsub topics delete "$TOPIC_NAME" --project="$PROJECT_ID" --quiet
            print_success "Deleted topic: $TOPIC_NAME"
        else
            print_warning "Topic '$TOPIC_NAME' does not exist"
        fi
    fi

    print_success "Cleanup completed"
}

# Function to show help
show_help() {
    cat << EOF
GSP096 - Pub/Sub: Qwik Start - Console
Automated Lab Script

USAGE:
    $0 [OPTIONS] [COMMAND]

OPTIONS:
    -v, --verbose    Enable verbose output
    -h, --help       Show this help message

COMMANDS:
    cleanup          Clean up created resources

DESCRIPTION:
    This script automates parts of the GSP096 Pub/Sub lab.
    Some steps are better performed manually in the console for learning.

    The script will:
    1. Check prerequisites
    2. Enable required APIs
    3. Create Pub/Sub topic
    4. Create subscription
    5. Publish a test message
    6. Pull the message

EXAMPLES:
    $0                    # Run the full automation
    $0 --verbose          # Run with verbose output
    $0 cleanup           # Clean up resources

EOF
}

# Main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            cleanup)
                cleanup
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo "GSP096 - Pub/Sub: Qwik Start - Console"
    echo "====================================="
    echo

    if $VERBOSE; then
        print_warning "Verbose mode enabled"
    fi

    # Run the lab automation
    check_prerequisites
    enable_apis
    create_topic
    create_subscription
    publish_message
    pull_message
    show_progress

    echo
    print_success "Script completed successfully!"
    echo
    echo "To clean up resources, run: $0 cleanup"
}

# Run main function
main "$@"
