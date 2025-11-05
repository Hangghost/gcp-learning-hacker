#!/bin/bash
# JLH-gsp328.sh - Automate GSP328: Develop Serverless Applications on Cloud Run: Challenge Lab
# Generated: 2025-11-05

set -e  # Exit on any error

# Color codes for output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for user input
wait_for_user() {
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

# Function to prompt for variable input
prompt_variable() {
    local var_name=$1
    local prompt_text=$2
    local default_value=$3

    if [ -n "$default_value" ]; then
        read -p "$prompt_text [$default_value]: " input
        input=${input:-$default_value}
    else
        read -p "$prompt_text: " input
        while [ -z "$input" ]; do
            echo -e "${RED}This field is required.${NC}"
            read -p "$prompt_text: " input
        done
    fi

    eval "$var_name='$input'"
}

# Function to validate region
validate_region() {
    local region=$1
    # Basic validation for GCP regions
    if [[ ! $region =~ ^[a-z]+-[a-z]+[0-9]+$ ]]; then
        print_error "Invalid region format. Expected format: us-central1, europe-west1, etc."
        return 1
    fi
    return 0
}

# Function to enable API
enable_api() {
    local api_name=$1
    local display_name=$2

    print_step "Enabling $display_name API..."
    if gcloud services enable "$api_name" --quiet; then
        print_status "$display_name API enabled successfully"
    else
        print_error "Failed to enable $display_name API"
        return 1
    fi
}

# Function to create service account
create_service_account() {
    local sa_name=$1
    local display_name=$2

    print_step "Creating service account: $sa_name"
    if gcloud iam service-accounts create "$sa_name" \
        --display-name "$display_name" \
        --quiet 2>/dev/null; then
        print_status "Service account created successfully"
    else
        print_warning "Service account may already exist, continuing..."
    fi
}

# Function to build and deploy Cloud Run service
deploy_cloud_run() {
    local service_name=$1
    local image=$2
    local region=$3
    local auth_flag=$4
    local service_account=$5
    local env_vars=$6

    print_step "Building container image..."
    if gcloud builds submit --tag "$image" --quiet; then
        print_status "Container built successfully"
    else
        print_error "Failed to build container"
        return 1
    fi

    print_step "Deploying Cloud Run service..."
    local deploy_cmd="gcloud run deploy $service_name --image $image --platform managed --region $region"

    if [ "$auth_flag" = "unauthenticated" ]; then
        deploy_cmd="$deploy_cmd --allow-unauthenticated"
    else
        deploy_cmd="$deploy_cmd --no-allow-unauthenticated"
    fi

    if [ -n "$service_account" ]; then
        deploy_cmd="$deploy_cmd --service-account $service_account"
    fi

    if [ -n "$env_vars" ]; then
        deploy_cmd="$deploy_cmd --set-env-vars $env_vars"
    fi

    if eval "$deploy_cmd --quiet"; then
        print_status "Cloud Run service deployed successfully"
    else
        print_error "Failed to deploy Cloud Run service"
        return 1
    fi
}

# Function to test service
test_service() {
    local service_name=$1
    local region=$2
    local auth_required=$3

    print_step "Testing service: $service_name"

    # Get service URL
    local service_url
    service_url=$(gcloud run services describe "$service_name" \
        --platform managed \
        --region "$region" \
        --format "value(status.url)")

    if [ -z "$service_url" ]; then
        print_error "Failed to get service URL"
        return 1
    fi

    print_status "Service URL: $service_url"

    # Test the service
    if [ "$auth_required" = "true" ]; then
        if curl -X GET -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$service_url" --silent --output /dev/null; then
            print_status "Service authentication test passed"
        else
            print_error "Service authentication test failed"
            return 1
        fi
    else
        if curl -X GET "$service_url" --silent --output /dev/null; then
            print_status "Service test passed"
        else
            print_error "Service test failed"
            return 1
        fi
    fi
}

# Function to add IAM policy binding for Cloud Run
add_cloud_run_iam_binding() {
    local service_name=$1
    local member=$2
    local role=$3
    local region=$4

    print_step "Adding IAM policy binding to Cloud Run service: $service_name"
    if gcloud run services add-iam-policy-binding "$service_name" \
        --member="$member" \
        --role="$role" \
        --region="$region" \
        --quiet; then
        print_status "IAM policy binding added successfully"
    else
        print_error "Failed to add IAM policy binding"
        return 1
    fi
}

# Main script
main() {
    print_step "Starting GSP328: Develop Serverless Applications on Cloud Run: Challenge Lab"
    print_warning "This is a Challenge Lab. Make sure you understand the requirements before proceeding."

    # Check prerequisites
    print_step "Checking prerequisites..."

    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    if ! command_exists git; then
        print_error "git is not installed. Please install it first."
        exit 1
    fi

    print_status "Prerequisites check passed"

    # Prompt for variables
    print_step "Configuring environment variables..."

    # Get project ID
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
        prompt_variable PROJECT_ID "Enter your GCP Project ID"
        gcloud config set project "$PROJECT_ID"
    else
        print_status "Using project: $PROJECT_ID"
    fi

    # Set region
    prompt_variable REGION "Enter the region for Cloud Run deployments" "us-central1"
    if ! validate_region "$REGION"; then
        exit 1
    fi
    gcloud config set run/region "$REGION"

    # Set platform
    gcloud config set run/platform managed

    # Clone repository
    print_step "Cloning Pet Theory repository..."
    if [ ! -d "pet-theory" ]; then
        if git clone https://github.com/rosera/pet-theory.git; then
            print_status "Repository cloned successfully"
        else
            print_error "Failed to clone repository"
            exit 1
        fi
    else
        print_warning "Repository already exists, continuing..."
    fi

    cd pet-theory/lab07 || exit 1

    # Enable necessary APIs
    print_step "Enabling necessary APIs..."
    enable_api "run.googleapis.com" "Cloud Run Admin"
    enable_api "cloudbuild.googleapis.com" "Cloud Build"

    # Task 1: Enable a public service
    print_step "=== TASK 1: Enable a public service ==="
    print_status "Deploying public billing service..."

    cd unit-api-billing || exit 1
    deploy_cloud_run "public-billing-service" "gcr.io/$PROJECT_ID/billing-staging-api:0.1" "$REGION" "unauthenticated"
    test_service "public-billing-service" "$REGION" "false"
    cd ..

    # Task 2: Deploy a frontend service
    print_step "=== TASK 2: Deploy a frontend service ==="
    print_status "Deploying frontend staging service..."

    cd staging-frontend-billing || exit 1
    deploy_cloud_run "frontend-staging-service" "gcr.io/$PROJECT_ID/frontend-staging:0.1" "$REGION" "unauthenticated"
    test_service "frontend-staging-service" "$REGION" "false"
    cd ..

    # Task 3: Deploy a private service
    print_step "=== TASK 3: Deploy a private service ==="
    print_status "Deploying private billing service..."

    # Delete existing public service
    print_step "Deleting existing public billing service..."
    gcloud run services delete public-billing-service --region "$REGION" --quiet 2>/dev/null || true

    cd staging-api-billing || exit 1
    deploy_cloud_run "private-billing-service" "gcr.io/$PROJECT_ID/billing-staging-api:0.2" "$REGION" "authenticated"
    test_service "private-billing-service" "$REGION" "true"
    cd ..

    # Task 4: Create a billing service account
    print_step "=== TASK 4: Create a billing service account ==="
    create_service_account "billing-service" "Billing Service Cloud Run"

    # Task 5: Deploy the billing service
    print_step "=== TASK 5: Deploy the billing service ==="
    print_status "Deploying production billing service..."

    cd prod-api-billing || exit 1
    deploy_cloud_run "billing-production-service" "gcr.io/$PROJECT_ID/billing-prod-api:0.1" "$REGION" "authenticated" "billing-service@$PROJECT_ID.iam.gserviceaccount.com"
    test_service "billing-production-service" "$REGION" "true"
    cd ..

    # Task 6: Frontend service account
    print_step "=== TASK 6: Frontend service account ==="
    create_service_account "frontend-prod-service" "Billing Service Cloud Run Invoker"

    # Add IAM policy binding for frontend service account
    add_cloud_run_iam_binding "billing-production-service" "serviceAccount:frontend-prod-service@$PROJECT_ID.iam.gserviceaccount.com" "roles/run.invoker" "$REGION"

    # Task 7: Redeploy the frontend service
    print_step "=== TASK 7: Redeploy the frontend service ==="
    print_status "Deploying production frontend service..."

    cd prod-frontend-billing || exit 1
    deploy_cloud_run "frontend-production-service" "gcr.io/$PROJECT_ID/frontend-prod:0.1" "$REGION" "unauthenticated" "frontend-prod-service@$PROJECT_ID.iam.gserviceaccount.com"
    test_service "frontend-production-service" "$REGION" "false"
    cd ..

    print_step "=== ALL TASKS COMPLETED ==="
    print_status "Challenge Lab completed successfully!"
    print_warning "Don't forget to check your progress in the Cloud Skills Boost console."

    # Final URLs
    echo ""
    print_step "Service URLs:"
    echo "Frontend Production: $(gcloud run services describe frontend-production-service --region $REGION --format 'value(status.url)' 2>/dev/null || echo 'Not available')"
    echo "Billing Production: $(gcloud run services describe billing-production-service --region $REGION --format 'value(status.url)' 2>/dev/null || echo 'Not available')"
}

# Cleanup function
cleanup() {
    print_step "Starting cleanup process..."
    print_warning "This will delete all resources created by the lab."

    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleanup cancelled."
        exit 0
    fi

    # Delete services
    print_step "Deleting Cloud Run services..."
    gcloud run services delete frontend-production-service --region "$REGION" --quiet 2>/dev/null || true
    gcloud run services delete billing-production-service --region "$REGION" --quiet 2>/dev/null || true
    gcloud run services delete private-billing-service --region "$REGION" --quiet 2>/dev/null || true
    gcloud run services delete frontend-staging-service --region "$REGION" --quiet 2>/dev/null || true

    # Delete service accounts
    print_step "Deleting service accounts..."
    gcloud iam service-accounts delete frontend-prod-service@"$PROJECT_ID".iam.gserviceaccount.com --quiet 2>/dev/null || true
    gcloud iam service-accounts delete billing-service@"$PROJECT_ID".iam.gserviceaccount.com --quiet 2>/dev/null || true

    # Delete container images
    print_step "Deleting container images..."
    gcloud container images delete gcr.io/"$PROJECT_ID"/billing-staging-api:0.1 --quiet 2>/dev/null || true
    gcloud container images delete gcr.io/"$PROJECT_ID"/billing-staging-api:0.2 --quiet 2>/dev/null || true
    gcloud container images delete gcr.io/"$PROJECT_ID"/billing-prod-api:0.1 --quiet 2>/dev/null || true
    gcloud container images delete gcr.io/"$PROJECT_ID"/frontend-staging:0.1 --quiet 2>/dev/null || true
    gcloud container images delete gcr.io/"$PROJECT_ID"/frontend-prod:0.1 --quiet 2>/dev/null || true

    print_status "Cleanup completed!"
}

# Help function
show_help() {
    echo "JLH-gsp328.sh - Automate GSP328: Develop Serverless Applications on Cloud Run: Challenge Lab"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h          Show this help message"
    echo "  --cleanup           Clean up all resources created by the lab"
    echo "  --run               Run the complete lab automation (default)"
    echo ""
    echo "Environment Variables:"
    echo "  PROJECT_ID          GCP Project ID (will prompt if not set)"
    echo "  REGION              GCP Region (default: us-central1)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run the complete lab"
    echo "  $0 --cleanup         # Clean up resources"
    echo "  PROJECT_ID=my-project REGION=us-west1 $0  # Run with specific settings"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        show_help
        exit 0
        ;;
    --cleanup)
        # Get project and region for cleanup
        PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
        REGION=$(gcloud config get-value run/region 2>/dev/null || echo "us-central1")
        cleanup
        exit 0
        ;;
    --run|"")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
