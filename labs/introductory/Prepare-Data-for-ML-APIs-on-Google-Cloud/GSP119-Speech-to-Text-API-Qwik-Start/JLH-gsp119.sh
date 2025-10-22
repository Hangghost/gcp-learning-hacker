#!/bin/bash

# GSP119 - Speech-to-Text API: Qwik Start
# Automation script for Google Cloud Skill Boost Lab
# Generated on: 2025-10-22

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/gsp119_execution.log"
PROJECT_ID=""
API_KEY=""

# Function to print colored output
print_step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate prerequisites
check_prerequisites() {
    print_step "0" "Checking prerequisites..."

    # Check if gcloud is installed
    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    # Check if curl is installed
    if ! command_exists curl; then
        print_error "curl is not installed. Please install it first."
        exit 1
    fi

    # Check if jq is installed (optional, for JSON parsing)
    if ! command_exists jq; then
        print_warning "jq is not installed. JSON output will not be formatted."
    fi

    print_success "Prerequisites check completed"
}

# Function to get user input
get_user_input() {
    local prompt="$1"
    local default_value="$2"
    local input

    if [[ -n "$default_value" ]]; then
        read -p "$prompt [$default_value]: " input
        input="${input:-$default_value}"
    else
        read -p "$prompt: " input
    fi

    echo "$input"
}

# Function to setup environment
setup_environment() {
    print_step "1" "Setting up environment..."

    # Get API key from user
    if [[ -z "$API_KEY" ]]; then
        API_KEY=$(get_user_input "Enter your Speech-to-Text API key")
        if [[ -z "$API_KEY" ]]; then
            print_error "API key is required"
            exit 1
        fi
    fi

    # Export API key as environment variable
    export API_KEY="$API_KEY"

    print_success "Environment setup completed"
    log_message "API key configured"
}

# Function to create request.json
create_request_json() {
    print_step "2" "Creating Speech-to-Text API request..."

    cat > request.json << EOF
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://cloud-samples-tests/speech/brooklyn.flac"
  }
}
EOF

    print_success "request.json created successfully"
    log_message "Created request.json for Speech-to-Text API"
}

# Function to call Speech-to-Text API
call_speech_api() {
    print_step "3" "Calling Speech-to-Text API..."

    local api_url="https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}"

    echo "Sending request to Speech-to-Text API..."
    echo "API URL: $api_url"
    echo "Request body:"
    cat request.json
    echo ""

    # Make the API call and save response
    if curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json "$api_url" > result.json; then
        print_success "API call completed successfully"
        log_message "Speech-to-Text API call successful"

        # Display the result
        echo "API Response:"
        if command_exists jq; then
            jq . result.json
        else
            cat result.json
        fi

        # Extract and display transcript
        if command_exists jq; then
            local transcript=$(jq -r '.results[0].alternatives[0].transcript' result.json 2>/dev/null)
            local confidence=$(jq -r '.results[0].alternatives[0].confidence' result.json 2>/dev/null)

            if [[ "$transcript" != "null" && -n "$transcript" ]]; then
                echo ""
                print_success "Transcript: \"$transcript\""
                print_success "Confidence: $confidence"
            fi
        fi

    else
        print_error "API call failed"
        log_message "Speech-to-Text API call failed"
        return 1
    fi
}

# Function to verify results
verify_results() {
    print_step "4" "Verifying results..."

    # Check if result.json exists
    if [[ ! -f "result.json" ]]; then
        print_error "result.json file not found"
        return 1
    fi

    # Check if result.json has content
    if [[ ! -s "result.json" ]]; then
        print_error "result.json is empty"
        return 1
    fi

    # Basic JSON validation
    if ! jq . result.json >/dev/null 2>&1; then
        print_error "result.json contains invalid JSON"
        return 1
    fi

    # Check for transcript in response
    if command_exists jq; then
        local transcript=$(jq -r '.results[0].alternatives[0].transcript' result.json 2>/dev/null)
        if [[ "$transcript" == "null" || -z "$transcript" ]]; then
            print_error "No transcript found in API response"
            return 1
        fi
    fi

    print_success "Results verification completed"
    log_message "Results verification successful"
}

# Function to display summary
display_summary() {
    echo ""
    echo "=========================================="
    echo "GSP119 Lab Execution Summary"
    echo "=========================================="
    print_success "Lab completed successfully!"
    echo ""
    echo "Files created:"
    echo "  - request.json: API request configuration"
    echo "  - result.json: API response with transcription"
    echo "  - $LOG_FILE: Execution log"
    echo ""
    echo "Next steps:"
    echo "1. Review the transcription in result.json"
    echo "2. Try the API with different audio files"
    echo "3. Explore other Speech-to-Text API features"
}

# Function to cleanup (optional)
cleanup() {
    print_step "5" "Cleanup (optional)..."

    local cleanup_choice=$(get_user_input "Do you want to clean up the generated files? (y/N)" "n")

    if [[ "$cleanup_choice" =~ ^[Yy]$ ]]; then
        rm -f request.json result.json
        print_success "Cleanup completed"
        log_message "Cleanup performed - removed request.json and result.json"
    else
        print_success "Files kept for reference"
    fi
}

# Main execution function
main() {
    echo "=========================================="
    echo "GSP119 - Speech-to-Text API: Qwik Start"
    echo "Automation Script"
    echo "=========================================="
    echo ""

    # Initialize log file
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting GSP119 lab execution" > "$LOG_FILE"

    # Execute steps
    check_prerequisites
    setup_environment
    create_request_json
    call_speech_api
    verify_results
    display_summary
    cleanup

    echo ""
    print_success "GSP119 lab execution completed!"
    log_message "Lab execution completed successfully"
}

# Function to show help
show_help() {
    cat << EOF
GSP119 - Speech-to-Text API: Qwik Start
Automation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -k, --api-key KEY   Provide API key directly (optional)
    -p, --project ID    GCP Project ID (optional)

DESCRIPTION:
    This script automates the GSP119 Speech-to-Text API lab execution.
    It will guide you through creating API requests and calling the Speech-to-Text API.

EXAMPLES:
    $0                          # Interactive mode
    $0 -k YOUR_API_KEY         # With API key provided

REQUIREMENTS:
    - gcloud CLI installed and configured
    - curl installed
    - jq installed (optional, for formatted JSON output)
    - Valid Speech-to-Text API key

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -k|--api-key)
            API_KEY="$2"
            shift 2
            ;;
        -p|--project)
            PROJECT_ID="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
