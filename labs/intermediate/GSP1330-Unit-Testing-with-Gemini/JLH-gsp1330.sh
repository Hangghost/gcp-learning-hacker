#!/bin/bash

# GSP1330 - Unit Testing with Gemini
# This script automates the lab steps for unit testing with Gemini

set -e  # Exit on any error

# Colors for output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt user for input
prompt_user() {
    local prompt="$1"
    local default="$2"
    local response

    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " response
        response=${response:-$default}
    else
        read -p "$prompt: " response
    fi

    echo "$response"
}

# Function to wait for user confirmation
wait_for_user() {
    local message="$1"
    echo
    echo -e "${YELLOW}$message${NC}"
    read -p "Press Enter to continue..."
}

# Function to check if npm package is available
check_npm_dependency() {
    local package="$1"
    if ! npm list -g "$package" >/dev/null 2>&1 && ! npm list "$package" >/dev/null 2>&1; then
        print_warning "$package is not available. Some features may not work."
        return 1
    fi
    return 0
}

# Function to test API endpoint
test_endpoint() {
    local url="$1"
    local expected_status="${2:-200}"

    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "$expected_status"; then
        return 0
    else
        return 1
    fi
}

# Cleanup function
cleanup() {
    print_warning "Cleaning up resources..."
    echo "Note: This lab creates local development environment."
    echo "Consider cleaning up the following if needed:"
    echo "- cymbal-superstore directory"
    echo "- Node.js processes (use 'pkill node' if needed)"
}

# Trap cleanup function on script exit
trap cleanup EXIT

# Main script
main() {
    print_status "Starting GSP1330 - Unit Testing with Gemini"
    print_status "This script will guide you through the lab steps"
    print_warning "Note: This lab requires significant manual interaction with Gemini in the editor"

    # Check prerequisites
    print_status "Checking prerequisites..."

    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    if ! command_exists node; then
        print_error "Node.js is not installed. Please install it first."
        exit 1
    fi

    if ! command_exists npm; then
        print_error "npm is not installed. Please install it first."
        exit 1
    fi

    # Set environment variables
    print_status "Setting up environment variables..."

    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [[ -z "$PROJECT_ID" ]] || [[ "$PROJECT_ID" == "(unset)" ]]; then
        PROJECT_ID=$(prompt_user "Enter your GCP Project ID")
        gcloud config set project "$PROJECT_ID"
    fi

    REGION=$(prompt_user "Enter the lab region" "us-central1")
    ZONE=$(prompt_user "Enter the lab zone" "us-central1-a")

    export PROJECT_ID="$PROJECT_ID"
    export REGION="$REGION"
    export ZONE="$ZONE"

    print_success "Environment variables set"

    # Download cymbal-superstore code
    if [[ ! -d "cymbal-superstore" ]]; then
        print_status "Downloading cymbal-superstore application code..."
        gsutil -m cp -r gs://duet-appdev/cymbal-superstore . || {
            print_error "Failed to download application code. Please check your permissions."
            exit 1
        }
    else
        print_warning "cymbal-superstore directory already exists. Skipping download."
    fi

    # Task 1: Setup and initial code generation
    print_status "=== Task 1: Setting up environment and generating initial code ==="

    print_warning "This task requires manual interaction with Gemini in the Cloud Shell Editor."
    echo "Please follow these steps manually:"
    echo "1. Open the editor with 'Open Editor' button"
    echo "2. Navigate to File > Open Folder > cymbal-superstore"
    echo "3. Open backend/index.ts"
    echo "4. Click Gemini icon and select your project"
    echo "5. Replace '/newproducts endpoint code goes here' with the specified comment"
    echo "6. Use Gemini to generate code for the /newproducts endpoint"

    wait_for_user "Press Enter after you have used Gemini to generate the /newproducts endpoint code"

    # Test the generated code
    print_status "Testing the generated code..."

    # Start the backend server
    print_status "Starting backend server..."
    cd cymbal-superstore/backend

    # Run in background
    npm run start &
    SERVER_PID=$!

    # Wait for server to start
    sleep 5

    # Test the endpoint
    print_status "Testing /newproducts endpoint..."
    if curl -s localhost:8000/newproducts >/dev/null 2>&1; then
        print_warning "Endpoint responded, but may have errors. Check server logs."
    else
        print_error "Endpoint test failed - this is expected initially"
    fi

    # Stop server
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true

    # Task 2: Debug with Gemini Chat
    print_status "=== Task 2: Debugging with Gemini Chat ==="

    print_warning "This task requires manual debugging with Gemini Chat."
    echo "Expected error: Inequality filter property and first sort order must be the same"
    echo "Please follow these steps manually:"
    echo "1. In the editor, open Gemini Chat"
    echo "2. Enter the Firestore error message"
    echo "3. Follow Gemini's suggestions to fix the inequality filter issue"
    echo "4. Ask Gemini for ways to filter out products with quantity 0"
    echo "5. Implement the suggested filtering logic"

    wait_for_user "Press Enter after you have debugged and fixed the Firestore query issue"

    # Test the fixed code
    print_status "Testing the fixed code..."

    cd cymbal-superstore/backend

    # Start server again
    npm run start &
    SERVER_PID=$!

    sleep 5

    # Test endpoint
    print_status "Testing fixed /newproducts endpoint..."
    if curl -s localhost:8000/newproducts | jq . >/dev/null 2>&1; then
        PRODUCT_COUNT=$(curl -s localhost:8000/newproducts | jq length)
        print_success "/newproducts endpoint working - returned $PRODUCT_COUNT products"
    else
        print_error "Endpoint still failing"
    fi

    # Stop server
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true

    # Task 3: Run existing tests
    print_status "=== Task 3: Running existing tests ==="

    cd cymbal-superstore/backend

    if npm test; then
        print_success "Existing tests passed"
    else
        print_warning "Some existing tests may have failed - this is expected at this stage"
    fi

    # Task 4: Generate unit tests with Gemini
    print_status "=== Task 4: Generating unit tests with Gemini ==="

    print_warning "This task requires manual test generation with Gemini."
    echo "Please follow these steps manually:"
    echo "1. Open backend/index.test.ts"
    echo "2. Add the specified comments at the end of the file"
    echo "3. Use Gemini to generate unit tests for the /newproducts endpoint"
    echo "4. Accept the generated test code"

    wait_for_user "Press Enter after you have generated unit tests with Gemini"

    # Run tests with new unit tests
    print_status "Running tests with new unit tests..."
    if npm test; then
        print_success "All tests passed"
    else
        print_warning "Some tests failed - you may need to fix the implementation"
        echo "Check the test output for details on which tests failed"
    fi

    # Task 5: Boundary condition tests
    print_status "=== Task 5: Creating boundary condition tests ==="

    print_warning "This task requires manual boundary condition test creation."
    echo "Please follow these steps manually:"
    echo "1. Close all open files"
    echo "2. Reset Gemini Chat and ask for boundary condition help"
    echo "3. Open index.ts for context and ask specific boundary condition questions"
    echo "4. Add boundary condition test comments to index.test.ts"
    echo "5. Use Gemini to generate boundary condition tests"

    wait_for_user "Press Enter after you have created boundary condition tests"

    # Final test run
    print_status "Running final comprehensive test suite..."
    if npm test; then
        print_success "All tests passed including boundary conditions!"
    else
        print_warning "Some tests still failing. Review the implementation and test logic."
    fi

    # Completion message
    print_success "=== Lab GSP1330 completed! ==="
    echo
    echo "Summary of what was accomplished:"
    echo "- Used Gemini to generate /newproducts endpoint code"
    echo "- Debugged Firestore inequality filter errors with Gemini Chat"
    echo "- Implemented quantity filtering logic"
    echo "- Generated unit tests for the new endpoint"
    echo "- Created boundary condition tests"
    echo
    print_warning "Key learnings:"
    echo "- Gemini can generate code from natural language comments"
    echo "- Gemini Chat helps with debugging complex errors"
    echo "- Firestore has limitations on inequality filters"
    echo "- Unit tests should cover both happy path and edge cases"
    echo "- Boundary condition testing is crucial for robust APIs"
    echo
    print_status "To clean up:"
    echo "- Remove cymbal-superstore directory if no longer needed"
    echo "- Kill any remaining Node.js processes: pkill node"
}

# Run main function
main "$@"
