#!/bin/bash

# GSP103 - Dataproc: Qwik Start - Console
# This script automates the Dataproc Qwik Start lab

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

# Function to wait for operation completion
wait_for_operation() {
    local operation=$1
    local message=$2

    print_status "Waiting for $message to complete..."
    while true; do
        if gcloud dataproc operations describe "$operation" --region="$REGION" >/dev/null 2>&1; then
            sleep 5
        else
            break
        fi
    done
    print_status "$message completed!"
}

# Function to wait for cluster to be ready
wait_for_cluster() {
    local cluster_name=$1
    local region=$2

    print_status "Waiting for cluster $cluster_name to be ready..."
    while true; do
        local status=$(gcloud dataproc clusters describe "$cluster_name" --region="$region" --format="value(status.state)")
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

    if [[ -n "$CLUSTER_NAME" ]]; then
        print_status "Deleting cluster $CLUSTER_NAME..."
        gcloud dataproc clusters delete "$CLUSTER_NAME" --region="$REGION" --quiet || print_warning "Failed to delete cluster $CLUSTER_NAME"
    fi

    print_status "Cleanup completed!"
}

# Set trap for cleanup on script exit
trap cleanup EXIT

# Main script
main() {
    echo "========================================="
    echo "GSP103 - Dataproc: Qwik Start - Console"
    echo "========================================="

    # Check if gcloud is installed
    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
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

    # Task 1: Enable required APIs
    print_step "Task 1: Enabling required APIs..."

    print_status "Enabling Cloud Dataproc API..."
    gcloud services enable dataproc.googleapis.com --project="$PROJECT_ID"

    print_status "APIs enabled successfully!"

    # Task 2: Set up service account permissions
    print_step "Task 2: Setting up service account permissions..."

    SERVICE_ACCOUNT="compute@developer.gserviceaccount.com"

    print_status "Adding Storage Admin role to service account..."
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SERVICE_ACCOUNT" \
        --role="roles/storage.admin" \
        --quiet

    print_status "Service account permissions configured!"

    # Task 3: Create Dataproc cluster
    print_step "Task 3: Creating Dataproc cluster..."

    print_status "Creating cluster $CLUSTER_NAME..."
    gcloud dataproc clusters create "$CLUSTER_NAME" \
        --region="$REGION" \
        --zone="$ZONE" \
        --master-machine-type="e2-standard-2" \
        --master-boot-disk-size="30" \
        --num-workers="2" \
        --worker-machine-type="e2-standard-2" \
        --worker-boot-disk-size="30" \
        --image-version="2.0-debian10" \
        --project="$PROJECT_ID"

    # Wait for cluster to be ready
    wait_for_cluster "$CLUSTER_NAME" "$REGION"

    print_status "Cluster $CLUSTER_NAME created successfully!"

    # Task 4: Submit Spark job
    print_step "Task 4: Submitting Spark job..."

    print_status "Submitting Spark Pi calculation job..."
    JOB_OUTPUT=$(gcloud dataproc jobs submit spark \
        --region="$REGION" \
        --cluster="$CLUSTER_NAME" \
        --class="org.apache.spark.examples.SparkPi" \
        --jars="file:///usr/lib/spark/examples/jars/spark-examples.jar" \
        -- \
        1000)

    # Extract job ID from output
    JOB_ID=$(echo "$JOB_OUTPUT" | grep -oP 'jobId: \K[^\s]+' || echo "$JOB_OUTPUT" | grep -oP 'Submitted job \K[^\s]+')

    if [[ -n "$JOB_ID" ]]; then
        print_status "Job submitted successfully! Job ID: $JOB_ID"

        # Wait for job to complete
        print_status "Waiting for job to complete..."
        while true; do
            JOB_STATUS=$(gcloud dataproc jobs describe "$JOB_ID" --region="$REGION" --format="value(status.state)")
            if [[ "$JOB_STATUS" == "DONE" ]]; then
                print_status "Job completed successfully!"
                break
            elif [[ "$JOB_STATUS" == "ERROR" ]]; then
                print_error "Job failed!"
                exit 1
            fi
            sleep 5
        done

        # Get job output
        print_step "Task 5: Getting job output..."
        print_status "Job output:"
        gcloud dataproc jobs wait "$JOB_ID" --region="$REGION"

    else
        print_warning "Could not extract job ID. Please check the job status manually in the console."
    fi

    # Optional: Update cluster size
    print_step "Optional: Updating cluster size..."

    read -p "Do you want to update the cluster to have 4 workers? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Updating cluster to have 4 workers..."
        gcloud dataproc clusters update "$CLUSTER_NAME" \
            --region="$REGION" \
            --num-workers="4"

        print_status "Cluster updated successfully!"

        # Optional: Re-run the job with updated cluster
        read -p "Do you want to re-run the Spark job with the updated cluster? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Re-submitting Spark job..."
            gcloud dataproc jobs submit spark \
                --region="$REGION" \
                --cluster="$CLUSTER_NAME" \
                --class="org.apache.spark.examples.SparkPi" \
                --jars="file:///usr/lib/spark/examples/jars/spark-examples.jar" \
                -- \
                1000

            print_status "Job re-submitted!"
        fi
    fi

    print_status ""
    print_status "Lab completed successfully!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Check the job output in the Dataproc Jobs section of the console"
    print_status "2. Verify the cluster configuration in the Clusters section"
    print_status "3. When done, the cleanup function will automatically delete the cluster"
    print_status ""
    print_warning "Press Ctrl+C or let the script exit to trigger cleanup (cluster deletion)"

    # Keep script running to maintain cluster for manual inspection
    print_status "Keeping cluster alive for manual inspection. Press Ctrl+C to cleanup and exit."
    while true; do
        sleep 60
        print_status "Cluster $CLUSTER_NAME is still running. Press Ctrl+C to cleanup."
    done
}

# Run main function
main "$@"
