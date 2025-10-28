#!/bin/bash

# GSP919 - Connect an App to a Cloud SQL for PostgreSQL Instance
# Automation script for the complete lab execution
# Generated on: 2025-10-28

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

# Function to wait for pods to be ready
wait_for_pods() {
    local namespace=${1:-default}
    local timeout=${2:-300}
    local interval=${3:-10}

    print_status "Waiting for pods to be ready in namespace: $namespace"

    local start_time=$(date +%s)
    while true; do
        local ready_pods=$(kubectl get pods -n $namespace --no-headers 2>/dev/null | grep -c "Running" || echo "0")
        local total_pods=$(kubectl get pods -n $namespace --no-headers 2>/dev/null | wc -l | tr -d ' ' || echo "0")

        if [ "$total_pods" -gt 0 ] && [ "$ready_pods" -eq "$total_pods" ]; then
            print_success "All pods are ready ($ready_pods/$total_pods)"
            return 0
        fi

        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [ $elapsed -gt $timeout ]; then
            print_error "Timeout waiting for pods to be ready"
            return 1
        fi

        print_status "Pods ready: $ready_pods/$total_pods. Waiting... ($elapsed/$timeout seconds)"
        sleep $interval
    done
}

# Function to wait for load balancer IP
wait_for_lb_ip() {
    local service_name=${1:-gmemegen}
    local namespace=${2:-default}
    local timeout=${3:-300}
    local interval=${4:-15}

    print_status "Waiting for LoadBalancer IP for service: $service_name"

    local start_time=$(date +%s)
    while true; do
        local lb_ip=$(kubectl get svc $service_name -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

        if [ ! -z "$lb_ip" ]; then
            print_success "LoadBalancer IP assigned: $lb_ip"
            echo "$lb_ip"
            return 0
        fi

        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [ $elapsed -gt $timeout ]; then
            print_error "Timeout waiting for LoadBalancer IP"
            return 1
        fi

        print_status "Waiting for LoadBalancer IP... ($elapsed/$timeout seconds)"
        sleep $interval
    done
}

# Pre-flight checks
preflight_checks() {
    print_status "Running pre-flight checks..."

    # Check if gcloud is installed
    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    # Check if kubectl is installed
    if ! command_exists kubectl; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi

    # Check if docker is installed
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi

    # Check if jq is installed
    if ! command_exists jq; then
        print_error "jq is not installed. Please install it first."
        exit 1
    fi

    # Check if gsutil is available (usually comes with gcloud)
    if ! command_exists gsutil; then
        print_error "gsutil is not available. Please ensure it's installed with gcloud."
        exit 1
    fi

    print_success "Pre-flight checks passed"
}

# Function to prompt for user input
prompt_user() {
    local var_name=$1
    local prompt_text=$2
    local default_value=$3

    if [ -z "$default_value" ]; then
        read -p "$prompt_text: " user_input
    else
        read -p "$prompt_text [$default_value]: " user_input
        user_input=${user_input:-$default_value}
    fi

    eval "$var_name='$user_input'"
}

# Main script
main() {
    echo "=========================================="
    echo "GSP919 - Connect an App to a Cloud SQL for PostgreSQL Instance"
    echo "Automation Script"
    echo "=========================================="
    echo

    # Pre-flight checks
    preflight_checks

    # Get user input for required variables
    echo
    print_status "Please provide the following information:"
    prompt_user "ZONE" "Enter your compute zone (e.g., us-central1-a)"
    prompt_user "REGION" "Enter your compute region (e.g., us-central1)"

    # Export variables
    export ZONE=$ZONE
    export REGION=$REGION
    export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
    export CLOUDSQL_SERVICE_ACCOUNT=cloudsql-service-account
    export REPO=gmemegen

    echo
    print_status "Configuration:"
    echo "  Project ID: $PROJECT_ID"
    echo "  Region: $REGION"
    echo "  Zone: $ZONE"
    echo "  Service Account: $CLOUDSQL_SERVICE_ACCOUNT"
    echo "  Artifact Registry Repo: $REPO"
    echo

    # Confirm before proceeding
    read -p "Continue with these settings? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Script cancelled by user"
        exit 0
    fi

    echo
    print_status "Starting lab execution..."
    echo

    # Task 1: Initialize APIs and create IAM service account
    echo "=========================================="
    print_status "TASK 1: Initialize APIs and create Cloud IAM service account"
    echo "=========================================="

    # Enable APIs
    print_status "Enabling required APIs..."
    gcloud services enable artifactregistry.googleapis.com
    print_success "APIs enabled"

    # Create service account
    print_status "Creating service account..."
    gcloud iam service-accounts create $CLOUDSQL_SERVICE_ACCOUNT --project=$PROJECT_ID
    print_success "Service account created"

    # Bind IAM role
    print_status "Binding IAM role..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$CLOUDSQL_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/cloudsql.admin"
    print_success "IAM role bound"

    # Create and download keys
    print_status "Creating service account keys..."
    gcloud iam service-accounts keys create $CLOUDSQL_SERVICE_ACCOUNT.json \
        --iam-account=$CLOUDSQL_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
        --project=$PROJECT_ID
    print_success "Service account keys created and downloaded"

    echo
    print_success "TASK 1 COMPLETED"
    echo

    # Task 2: Deploy lightweight GKE application
    echo "=========================================="
    print_status "TASK 2: Deploy a lightweight GKE application"
    echo "=========================================="

    # Create GKE cluster
    print_status "Creating GKE cluster (this may take a few minutes)..."
    gcloud container clusters create postgres-cluster \
        --zone=$ZONE --num-nodes=2
    print_success "GKE cluster created"

    # Get cluster credentials
    print_status "Getting cluster credentials..."
    gcloud container clusters get-credentials postgres-cluster --zone=$ZONE
    print_success "Cluster credentials obtained"

    # Create Kubernetes secrets
    print_status "Creating Kubernetes secrets..."
    kubectl create secret generic cloudsql-instance-credentials \
        --from-file=credentials.json=$CLOUDSQL_SERVICE_ACCOUNT.json

    kubectl create secret generic cloudsql-db-credentials \
        --from-literal=username=postgres \
        --from-literal=password=supersecret! \
        --from-literal=dbname=gmemegen_db
    print_success "Kubernetes secrets created"

    # Download and prepare application
    print_status "Downloading application code..."
    gsutil -m cp -r gs://spls/gsp919/gmemegen .
    cd gmemegen
    print_success "Application code downloaded"

    # Configure Docker authentication
    print_status "Configuring Docker authentication for Artifact Registry..."
    gcloud auth configure-docker ${REGION}-docker.pkg.dev
    print_success "Docker authentication configured"

    # Create Artifact Registry repository
    print_status "Creating Artifact Registry repository..."
    gcloud artifacts repositories create $REPO \
        --repository-format=docker --location=$REGION
    print_success "Artifact Registry repository created"

    # Build and push Docker image
    print_status "Building Docker image..."
    docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/gmemegen/gmemegen-app:v1 .
    print_success "Docker image built"

    print_status "Pushing Docker image to Artifact Registry..."
    docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/gmemegen/gmemegen-app:v1
    print_success "Docker image pushed"

    # Modify deployment YAML
    print_status "Modifying deployment configuration..."
    sed -i "s|\${REGION}|$REGION|g" gmemegen_deployment.yaml
    sed -i "s|\${PROJECT_ID}|$PROJECT_ID|g" gmemegen_deployment.yaml
    print_success "Deployment configuration updated"

    # Deploy application
    print_status "Deploying application..."
    kubectl create -f gmemegen_deployment.yaml
    print_success "Application deployed"

    # Wait for pods to be ready
    wait_for_pods

    echo
    print_success "TASK 2 COMPLETED"
    echo

    # Task 3: Connect to external load balancer
    echo "=========================================="
    print_status "TASK 3: Connect the GKE application to an external load balancer"
    echo "=========================================="

    # Create load balancer service
    print_status "Creating load balancer service..."
    kubectl expose deployment gmemegen \
        --type "LoadBalancer" \
        --port 80 --target-port 8080
    print_success "Load balancer service created"

    # Wait for load balancer IP
    LOAD_BALANCER_IP=$(wait_for_lb_ip gmemegen)

    echo
    print_success "Application is now accessible at: http://$LOAD_BALANCER_IP"
    echo
    print_status "You can now:"
    echo "1. Open http://$LOAD_BALANCER_IP in your browser"
    echo "2. Create memes using the application"
    echo "3. View recent/random memes"
    echo

    # Show application logs command
    echo "To view application logs, run:"
    echo "POD_NAME=\$(kubectl get pods --output=json | jq -r '.items[0].metadata.name')"
    echo "kubectl logs \$POD_NAME gmemegen | grep 'INFO'"
    echo

    echo
    print_success "TASK 3 COMPLETED"
    echo

    # Task 4: Verify read/write capabilities
    echo "=========================================="
    print_status "TASK 4: Verify full read/write capabilities of application to database"
    echo "=========================================="

    print_status "To verify database connectivity:"
    echo "1. Go to Google Cloud Console > Databases > SQL"
    echo "2. Select the 'postgres-gmemegen' instance"
    echo "3. Click 'Open Cloud Shell' in the 'Connect to this instance' section"
    echo "4. Run the auto-populated command"
    echo "5. When prompted, enter password: supersecret!"
    echo "6. Run: \\c gmemegen_db"
    echo "7. When prompted, enter password: supersecret!"
    echo "8. Run: SELECT * FROM meme;"
    echo
    print_success "You should see rows for each meme created through the application"

    echo
    print_success "ALL TASKS COMPLETED SUCCESSFULLY!"
    echo "=========================================="
    print_status "Lab GSP919 execution completed"
    echo
    print_status "Don't forget to clean up resources when done!"
    echo "Run the cleanup commands from the documentation to avoid charges."
    echo "=========================================="
}

# Cleanup function
cleanup() {
    echo
    print_warning "Script interrupted. You may need to clean up resources manually."
    echo
    print_status "To clean up resources, run these commands:"
    echo "gcloud container clusters delete postgres-cluster --zone=$ZONE"
    echo "gcloud artifacts repositories delete $REPO --location=$REGION"
    echo "gcloud iam service-accounts delete $CLOUDSQL_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com"
    echo
}

# Trap for cleanup on script exit
trap cleanup INT TERM

# Run main function
main "$@"
