#!/bin/bash

# GSP007 - Set Up Network Load Balancers
# Automated Lab Script
# This script automates the GSP007 lab for setting up network load balancers

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    read -p "$message (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Cleanup function
cleanup() {
    print_warning "Starting cleanup process..."

    # Delete forwarding rule
    if gcloud compute forwarding-rules describe www-rule --region "$REGION" >/dev/null 2>&1; then
        print_step "Deleting forwarding rule"
        gcloud compute forwarding-rules delete www-rule --region "$REGION" --quiet
        print_success "Forwarding rule deleted"
    fi

    # Delete target pool
    if gcloud compute target-pools describe www-pool --region "$REGION" >/dev/null 2>&1; then
        print_step "Deleting target pool"
        gcloud compute target-pools delete www-pool --region "$REGION" --quiet
        print_success "Target pool deleted"
    fi

    # Delete instances
    for instance in www1 www2 www3; do
        if gcloud compute instances describe "$instance" --zone "$ZONE" >/dev/null 2>&1; then
            print_step "Deleting instance $instance"
            gcloud compute instances delete "$instance" --zone "$ZONE" --quiet
            print_success "Instance $instance deleted"
        fi
    done

    # Delete firewall rule
    if gcloud compute firewall-rules describe www-firewall-network-lb >/dev/null 2>&1; then
        print_step "Deleting firewall rule"
        gcloud compute firewall-rules delete www-firewall-network-lb --quiet
        print_success "Firewall rule deleted"
    fi

    # Delete static IP address
    if gcloud compute addresses describe network-lb-ip-1 --region "$REGION" >/dev/null 2>&1; then
        print_step "Deleting static IP address"
        gcloud compute addresses delete network-lb-ip-1 --region "$REGION" --quiet
        print_success "Static IP address deleted"
    fi

    # Delete health check
    if gcloud compute http-health-checks describe basic-check >/dev/null 2>&1; then
        print_step "Deleting health check"
        gcloud compute http-health-checks delete basic-check --quiet
        print_success "Health check deleted"
    fi

    print_success "Cleanup completed!"
}

# Function to test load balancer
test_load_balancer() {
    print_step "Testing load balancer"

    # Get load balancer IP
    IPADDRESS=$(gcloud compute forwarding-rules describe www-rule --region "$REGION" --format="json" | jq -r .IPAddress)
    echo "Load Balancer IP: $IPADDRESS"

    print_warning "Testing traffic distribution (Ctrl+C to stop)"
    echo "Expected: Responses should alternate between www1, www2, and www3"

    # Test for a few requests
    for i in {1..5}; do
        response=$(curl -m5 -s "$IPADDRESS" 2>/dev/null || echo "Connection failed")
        if [[ $response == *"Connection failed"* ]]; then
            print_error "Failed to connect to load balancer. Waiting for configuration to propagate..."
            sleep 10
        else
            echo "Request $i: $response"
        fi
    done

    print_success "Load balancer test completed"
}

# Main script
main() {
    echo "========================================="
    echo "GSP007 - Set Up Network Load Balancers"
    echo "Automated Lab Script"
    echo "========================================="

    # Check prerequisites
    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    if ! command_exists jq; then
        print_error "jq is not installed. Please install it first."
        exit 1
    fi

    # Get user input
    print_step "Configuration"
    get_input "Enter your GCP region" REGION "us-central1"
    get_input "Enter your GCP zone" ZONE "us-central1-a"

    echo "Region: $REGION"
    echo "Zone: $ZONE"

    if ! confirm "Do you want to proceed with these settings?"; then
        print_warning "Script cancelled by user"
        exit 0
    fi

    # Set trap for cleanup on error
    trap cleanup ERR

    # Task 1: Set default region and zone
    print_step "Task 1: Setting default region and zone"
    gcloud config set compute/region "$REGION"
    print_success "Default region set to $REGION"

    gcloud config set compute/zone "$ZONE"
    print_success "Default zone set to $ZONE"

    # Task 2: Create web server instances
    print_step "Task 2: Creating web server instances"

    # Create www1
    print_step "Creating instance www1"
    gcloud compute instances create www1 \
        --zone="$ZONE" \
        --tags=network-lb-tag \
        --machine-type=e2-small \
        --image-family=debian-11 \
        --image-project=debian-cloud \
        --metadata=startup-script='#!/bin/bash
          apt-get update
          apt-get install apache2 -y
          service apache2 restart
          echo "
    <h3>Web Server: www1</h3>" | tee /var/www/html/index.html'
    print_success "Instance www1 created"

    # Create www2
    print_step "Creating instance www2"
    gcloud compute instances create www2 \
        --zone="$ZONE" \
        --tags=network-lb-tag \
        --machine-type=e2-small \
        --image-family=debian-11 \
        --image-project=debian-cloud \
        --metadata=startup-script='#!/bin/bash
          apt-get update
          apt-get install apache2 -y
          service apache2 restart
          echo "
    <h3>Web Server: www2</h3>" | tee /var/www/html/index.html'
    print_success "Instance www2 created"

    # Create www3
    print_step "Creating instance www3"
    gcloud compute instances create www3 \
        --zone="$ZONE" \
        --tags=network-lb-tag \
        --machine-type=e2-small \
        --image-family=debian-11 \
        --image-project=debian-cloud \
        --metadata=startup-script='#!/bin/bash
          apt-get update
          apt-get install apache2 -y
          service apache2 restart
          echo "
    <h3>Web Server: www3</h3>" | tee /var/www/html/index.html'
    print_success "Instance www3 created"

    # Create firewall rule
    print_step "Creating firewall rule"
    gcloud compute firewall-rules create www-firewall-network-lb \
        --target-tags network-lb-tag --allow tcp:80
    print_success "Firewall rule created"

    # Verify instances
    print_step "Verifying instances"
    gcloud compute instances list --filter="name:(www1,www2,www3)"
    print_success "Instances created and listed"

    # Task 3: Configure load balancing service
    print_step "Task 3: Configuring load balancing service"

    # Create static IP
    print_step "Creating static external IP"
    gcloud compute addresses create network-lb-ip-1 --region "$REGION"
    print_success "Static IP created"

    # Create health check
    print_step "Creating HTTP health check"
    gcloud compute http-health-checks create basic-check
    print_success "Health check created"

    # Task 4: Create target pool and forwarding rule
    print_step "Task 4: Creating target pool and forwarding rule"

    # Create target pool
    print_step "Creating target pool"
    if gcloud compute target-pools create www-pool \
        --region "$REGION" --http-health-check basic-check; then
        print_success "Target pool created"
    else
        print_error "Failed to create target pool"
        exit 1
    fi

    # Wait for target pool to be ready
    print_warning "Waiting 10 seconds for target pool to be ready..."
    sleep 10

    # Add instances to pool
    print_step "Adding instances to target pool"
    gcloud compute target-pools add-instances www-pool \
        --instances www1,www2,www3
    print_success "Instances added to target pool"

    # Create forwarding rule
    print_step "Creating forwarding rule"
    if gcloud compute forwarding-rules create www-rule \
        --region "$REGION" \
        --ports 80 \
        --address network-lb-ip-1 \
        --target-pool www-pool; then
        print_success "Forwarding rule created"
    else
        print_error "Failed to create forwarding rule"
        exit 1
    fi

    # Task 5: Test the load balancer
    print_step "Task 5: Testing load balancer"

    print_warning "Waiting 30 seconds for configuration to propagate..."
    sleep 30

    test_load_balancer

    print_success "Lab completed successfully!"

    echo
    print_warning "Don't forget to clean up resources to avoid charges!"
    if confirm "Do you want to run cleanup now?"; then
        cleanup
    else
        print_warning "To clean up later, run this script with 'cleanup' as an argument"
        echo "Or manually delete the resources created in this lab"
    fi
}

# Check if cleanup was requested
if [ "$1" = "cleanup" ]; then
    print_warning "Cleanup mode selected"

    # Get required variables for cleanup
    get_input "Enter your GCP region" REGION "us-central1"
    get_input "Enter your GCP zone" ZONE "us-central1-a"

    cleanup
    exit 0
fi

# Run main function
main
