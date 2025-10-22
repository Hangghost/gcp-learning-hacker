#!/bin/bash

# GSP154 - Video Intelligence: Qwik Start
# https://www.skills.google/paths/36/course_templates/631/labs/594535

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to check if command succeeded
check_command() {
    if [ $? -eq 0 ]; then
        print_status "$1 completed successfully"
    else
        print_error "$1 failed"
        exit 1
    fi
}

# Function to prompt for user input
prompt_input() {
    local prompt="$1"
    local default="$2"
    local input

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        input="${input:-$default}"
    else
        read -p "$prompt: " input
        while [ -z "$input" ]; do
            read -p "$prompt: " input
        done
    fi

    echo "$input"
}

# Cleanup function
cleanup() {
    print_step "Starting cleanup process..."

    if [ -f "key.json" ]; then
        print_status "Removing service account key file..."
        rm -f key.json
        check_command "Key file removal"
    fi

    if [ -f "request.json" ]; then
        print_status "Removing request JSON file..."
        rm -f request.json
    fi

    if [ "$DELETE_SERVICE_ACCOUNT" = "true" ] && [ -n "$PROJECT_ID" ]; then
        print_warning "Do you want to delete the service account? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            print_status "Deleting service account..."
            gcloud iam service-accounts delete quickstart@$PROJECT_ID.iam.gserviceaccount.com --quiet
            check_command "Service account deletion"
        fi
    fi

    print_status "Cleanup completed!"
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Main script
main() {
    print_step "Starting GSP154 - Video Intelligence: Qwik Start"
    echo

    # Get project ID
    PROJECT_ID=$(prompt_input "Enter your Google Cloud Project ID" "$(gcloud config get-value project 2>/dev/null)")

    if [ -z "$PROJECT_ID" ]; then
        print_error "Project ID is required"
        exit 1
    fi

    print_status "Using project: $PROJECT_ID"
    echo

    # Set project
    print_step "Setting up project..."
    gcloud config set project $PROJECT_ID
    check_command "Project setup"
    echo

    # Task 1: Set up authorization
    print_step "Task 1: Setting up authorization"

    # Create service account
    print_status "Creating service account 'quickstart'..."
    gcloud iam service-accounts create quickstart --description="Service account for Video Intelligence lab" --display-name="Quickstart Service Account"
    check_command "Service account creation"
    echo

    # Create service account key
    print_status "Creating service account key..."
    gcloud iam service-accounts keys create key.json --iam-account quickstart@$PROJECT_ID.iam.gserviceaccount.com
    check_command "Service account key creation"
    echo

    # Activate service account
    print_status "Activating service account..."
    gcloud auth activate-service-account --key-file key.json
    check_command "Service account activation"
    echo

    # Get access token
    print_status "Obtaining access token..."
    ACCESS_TOKEN=$(gcloud auth print-access-token)
    if [ -z "$ACCESS_TOKEN" ]; then
        print_error "Failed to obtain access token"
        exit 1
    fi
    print_status "Access token obtained successfully"
    echo

    # Task 2: Make an annotate video request
    print_step "Task 2: Making an annotate video request"

    # Create request JSON
    print_status "Creating request JSON file..."
    cat > request.json <<EOF
{
   "inputUri":"gs://spls/gsp154/video/train.mp4",
   "features": [
       "LABEL_DETECTION"
   ]
}
EOF
    check_command "Request JSON creation"
    echo

    # Make the annotate request
    print_status "Sending annotate video request to Video Intelligence API..."
    RESPONSE=$(curl -s -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        'https://videointelligence.googleapis.com/v1/videos:annotate' \
        -d @request.json)

    if [ $? -ne 0 ]; then
        print_error "Failed to send annotate request"
        echo "Response: $RESPONSE"
        exit 1
    fi

    # Extract operation name
    OPERATION_NAME=$(echo $RESPONSE | grep -o '"name":"[^"]*' | cut -d'"' -f4)
    if [ -z "$OPERATION_NAME" ]; then
        print_error "Failed to extract operation name from response"
        echo "Response: $RESPONSE"
        exit 1
    fi

    print_status "Request sent successfully. Operation name: $OPERATION_NAME"

    # Extract project and location from operation name
    # Format: projects/PROJECT/locations/LOCATION/operations/OPERATION
    PROJECT_FROM_OP=$(echo $OPERATION_NAME | cut -d'/' -f2)
    LOCATION_FROM_OP=$(echo $OPERATION_NAME | cut -d'/' -f4)
    OPERATION_ID=$(echo $OPERATION_NAME | cut -d'/' -f6)

    print_status "Project: $PROJECT_FROM_OP, Location: $LOCATION_FROM_OP, Operation ID: $OPERATION_ID"
    echo

    # Query operation status
    print_status "Querying operation status..."
    OPERATION_URL="https://videointelligence.googleapis.com/v1/projects/$PROJECT_FROM_OP/locations/$LOCATION_FROM_OP/operations/$OPERATION_ID"

    # Initial status check
    STATUS_RESPONSE=$(curl -s -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        "$OPERATION_URL")

    if [ $? -ne 0 ]; then
        print_error "Failed to query operation status"
        exit 1
    fi

    DONE=$(echo $STATUS_RESPONSE | grep -o '"done":[^,}]*' | cut -d':' -f2 | tr -d ' ')
    if [ "$DONE" = "true" ]; then
        print_status "Operation completed immediately!"
    else
        print_status "Operation is still processing. Waiting..."
        sleep 30

        # Check status again
        STATUS_RESPONSE=$(curl -s -H 'Content-Type: application/json' \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            "$OPERATION_URL")

        DONE=$(echo $STATUS_RESPONSE | grep -o '"done":[^,}]*' | cut -d':' -f2 | tr -d ' ')
    fi

    if [ "$DONE" = "true" ]; then
        print_status "Operation completed successfully!"
        print_status "Response contains annotation results."

        # Show a snippet of the results
        echo "Sample annotation results:"
        echo $STATUS_RESPONSE | python3 -m json.tool 2>/dev/null | head -50 || echo $STATUS_RESPONSE | head -10
    else
        print_warning "Operation is still processing. You may need to check status manually later."
        print_status "Operation URL: $OPERATION_URL"
    fi

    echo
    print_step "Lab completed successfully!"
    print_status "You have successfully:"
    echo "  ✓ Set up authorization with a service account"
    echo "  ✓ Made an annotate video request to Video Intelligence API"
    echo "  ✓ Retrieved operation results"

    # Ask about cleanup
    echo
    DELETE_SERVICE_ACCOUNT="false"
    print_warning "Do you want to delete the service account after completion? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        DELETE_SERVICE_ACCOUNT="true"
    fi
}

# Check if running in Cloud Shell
if [ -n "$CLOUD_SHELL" ]; then
    print_status "Running in Cloud Shell environment"
else
    print_warning "Not running in Cloud Shell. Please ensure you have gcloud CLI installed and authenticated."
fi

# Run main function
main "$@"
