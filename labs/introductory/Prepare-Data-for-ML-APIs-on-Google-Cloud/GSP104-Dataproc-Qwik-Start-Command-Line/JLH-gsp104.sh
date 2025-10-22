#!/bin/bash

# GSP104 - Dataproc: Qwik Start - Command Line
# This script automates the Dataproc Qwik Start - Command Line lab

set -e  # Exit on any error

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for cluster to be ready
wait_for_cluster() {
    local cluster_name=$1
    local region=$2

    print_status "Waiting for cluster $cluster_name to be ready..."
    while true; do
        local status=$(gcloud dataproc clusters describe "$cluster_name" --region="$region" --format="value(status.state)" 2>/dev/null || echo "UNKNOWN")
        if [[ "$status" == "RUNNING" ]]; then
            break
        elif [[ "$status" == "ERROR" ]]; then
            print_error "Cluster creation failed!"
            exit 1
        fi
        sleep 10
    done
    print_status "Cluster $cluster_name is now running!"
}

# Cleanup function
cleanup() {
    print_step "Starting cleanup process..."

    if [[ -n "$CLUSTER_NAME" && -n "$REGION" ]]; then
        print_status "Deleting cluster $CLUSTER_NAME..."
        gcloud dataproc clusters delete "$CLUSTER_NAME" --region="$REGION" --quiet || print_warning "Failed to delete cluster $CLUSTER_NAME"
    fi

    # Clean up temporary buckets if they exist
    if [[ -n "$PROJECT_ID" && -n "$REGION" ]]; then
        print_status "Checking for temporary buckets to clean up..."
        STAGING_BUCKET="gs://dataproc-staging-$REGION-$PROJECT_ID"
        TEMP_BUCKET="gs://dataproc-temp-$REGION-$PROJECT_ID"

        if gsutil ls "$STAGING_BUCKET" >/dev/null 2>&1; then
            print_status "Deleting staging bucket $STAGING_BUCKET..."
            gsutil rm -r "$STAGING_BUCKET" || print_warning "Failed to delete staging bucket"
        fi

        if gsutil ls "$TEMP_BUCKET" >/dev/null 2>&1; then
            print_status "Deleting temp bucket $TEMP_BUCKET..."
            gsutil rm -r "$TEMP_BUCKET" || print_warning "Failed to delete temp bucket"
        fi
    fi

    print_status "Cleanup completed!"
}

# Set trap for cleanup on script exit
trap cleanup EXIT

# Main script
main() {
    echo "==============================================="
    echo "GSP104 - Dataproc: Qwik Start - Command Line"
    echo "==============================================="

    # Check if gcloud is installed
    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    # Check if gsutil is installed
    if ! command_exists gsutil; then
        print_error "gsutil is not installed. Please install Google Cloud SDK first."
        exit 1
    fi

    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 >/dev/null; then
        print_error "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi

    # Get user input
    print_step "Please provide the following information:"
    read -p "Enter your GCP Region (e.g., us-central1): " REGION
    read -p "Enter your GCP Zone (e.g., us-central1-a): " ZONE

    # Set default values
    CLUSTER_NAME="example-cluster"
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

    if [[ -z "$PROJECT_ID" ]]; then
        print_error "No project set. Please run 'gcloud config set project PROJECT_ID' first."
        exit 1
    fi

    print_status "Using project: $PROJECT_ID"
    print_status "Region: $REGION"
    print_status "Zone: $ZONE"
    print_status "Cluster name: $CLUSTER_NAME"

    # Confirm before proceeding
    read -p "Do you want to proceed with the lab setup? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Lab setup cancelled."
        exit 0
    fi

    # Task 1: Configure Dataproc region
    print_step "Task 1: Configuring Dataproc region..."
    print_status "Setting Dataproc region to $REGION..."
    gcloud config set dataproc/region "$REGION"

    # Disable and re-enable Dataproc API
    print_status "Disabling Dataproc API..."
    gcloud services disable dataproc.googleapis.com --force --quiet

    print_status "Re-enabling Dataproc API..."
    gcloud services enable dataproc.googleapis.com

    print_status "Dataproc API configuration completed!"

    # Task 2: Set up service account permissions
    print_step "Task 2: Setting up service account permissions..."

    # Get project number
    print_status "Getting project information..."
    PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')

    # Add IAM roles to Compute Engine default service account
    SERVICE_ACCOUNT="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"

    print_status "Adding Storage Admin role to service account..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT" \
        --role="roles/storage.admin" \
        --quiet

    print_status "Adding Dataproc Worker role to service account..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT" \
        --role="roles/dataproc.worker" \
        --quiet

    print_status "Service account permissions configured!"

    # Task 3: Enable Private Google Access
    print_step "Task 3: Enabling Private Google Access..."

    print_status "Enabling Private Google Access on default subnet..."
    gcloud compute networks subnets update default \
        --region="$REGION" \
        --enable-private-ip-google-access \
        --quiet

    print_status "Private Google Access enabled!"

    # Task 4: Create Dataproc cluster
    print_step "Task 4: Creating Dataproc cluster..."

    print_status "Creating cluster $CLUSTER_NAME with e2-standard-4 machines..."
    echo "This may take a few minutes..."

    gcloud dataproc clusters create "$CLUSTER_NAME" \
        --worker-boot-disk-size=500 \
        --worker-machine-type=e2-standard-4 \
        --master-machine-type=e2-standard-4 \
        --region="$REGION" \
        --zone="$ZONE" \
        --project="$PROJECT_ID"

    # Wait for cluster to be ready
    wait_for_cluster "$CLUSTER_NAME" "$REGION"

    print_status "Cluster $CLUSTER_NAME created successfully!"

    # Task 5: Submit Spark job
    print_step "Task 5: Submitting Spark job..."

    print_status "Submitting Spark Pi calculation job..."
    gcloud dataproc jobs submit spark \
        --cluster="$CLUSTER_NAME" \
        --class=org.apache.spark.examples.SparkPi \
        --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
        --region="$REGION" \
        -- \
        1000

    print_status "Spark job submitted and completed!"

    # Task 6: Update cluster (optional)
    print_step "Task 6: Cluster scaling demonstration..."

    read -p "Do you want to scale the cluster to 4 workers? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Scaling cluster to 4 workers..."
        gcloud dataproc clusters update "$CLUSTER_NAME" \
            --num-workers=4 \
            --region="$REGION"

        print_status "Cluster scaled successfully!"

        # Optional: Scale back down
        read -p "Do you want to scale back to 2 workers? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Scaling cluster back to 2 workers..."
            gcloud dataproc clusters update "$CLUSTER_NAME" \
                --num-workers=2 \
                --region="$REGION"

            print_status "Cluster scaled back successfully!"
        fi
    fi

    print_status ""
    print_status "Lab completed successfully!"
    print_status ""
    print_status "Summary of completed tasks:"
    print_status "✓ Configured Dataproc region"
    print_status "✓ Enabled/Disabled Dataproc API"
    print_status "✓ Set up service account permissions"
    print_status "✓ Enabled Private Google Access"
    print_status "✓ Created Dataproc cluster"
    print_status "✓ Submitted and ran Spark job"
    print_status "✓ Demonstrated cluster scaling"
    print_status ""
    print_status "Next steps:"
    print_status "1. You can explore the cluster in the GCP Console"
    print_status "2. Check job history in Dataproc > Jobs"
    print_status "3. When done, the cleanup function will automatically delete resources"
    print_status ""
    print_warning "Press Ctrl+C or let the script exit to trigger cleanup"

    # Keep script running to maintain cluster for manual inspection
    print_status "Keeping cluster alive for manual inspection. Press Ctrl+C to cleanup and exit."
    while true; do
        sleep 60
        print_status "Cluster $CLUSTER_NAME is still running. Press Ctrl+C to cleanup."
    done
}

# Run main function
main "$@"
