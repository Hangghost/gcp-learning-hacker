#!/bin/bash

# GSP089 - Cloud Monitoring: Qwik Start
# Automated Lab Script
# This script automates parts of the GSP089 lab for Cloud Monitoring operations
# Some steps must be performed manually in the console
# Usage: ./JLH-gsp089.sh [--verbose|-v] [cleanup]
# Status: verified on 2025-10-14

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
VM_NAME="lamp-1-vm"
ZONE=""
REGION=""
EXTERNAL_IP=""

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

# Function to wait for VM to be ready
wait_for_vm() {
    local vm_name="$1"
    print_warning "Waiting for VM $vm_name to be ready..."
    while true; do
        local status=$(gcloud compute instances describe "$vm_name" --zone="$ZONE" --format="value(status)" 2>/dev/null)
        if [ "$status" = "RUNNING" ]; then
            print_success "VM $vm_name is now running"
            break
        fi
        echo "VM status: $status - waiting..."
        sleep 10
    done
}

# Cleanup function
cleanup() {
    print_step "Starting cleanup process"

    if [ -n "$VM_NAME" ] && [ -n "$ZONE" ]; then
        print_warning "Deleting VM instance: $VM_NAME"
        if gcloud compute instances describe "$VM_NAME" --zone="$ZONE" >/dev/null 2>&1; then
            gcloud compute instances delete "$VM_NAME" --zone="$ZONE" --quiet
            print_success "VM instance $VM_NAME deleted"
        else
            print_warning "VM instance $VM_NAME not found or already deleted"
        fi
    fi

    # Note: Dashboard, alerting policies, and uptime checks need to be cleaned up manually
    print_warning "Manual cleanup required:"
    echo "- Delete the custom dashboard 'Cloud Monitoring LAMP Qwik Start Dashboard'"
    echo "- Delete the alerting policy 'Inbound Traffic Alert'"
    echo "- Delete the uptime check 'Lamp Uptime Check'"

    print_success "Cleanup completed"
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
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi

    print_success "Prerequisites check passed"
}

# Function to setup project and zone
setup_project() {
    print_step "Setting up project configuration"

    # Get current project
    CURRENT_PROJECT=$(gcloud config get-value project)
    if [ -z "$CURRENT_PROJECT" ] || [ "$CURRENT_PROJECT" = "(unset)" ]; then
        print_error "No project set. Please set a project first:"
        echo "gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi

    print_success "Using project: $CURRENT_PROJECT"

    # Set default region and zone
    DEFAULT_REGION="us-central1"
    DEFAULT_ZONE="us-central1-a"

    get_input "Enter region" REGION "$DEFAULT_REGION"
    get_input "Enter zone" ZONE "$DEFAULT_ZONE"

    gcloud config set compute/region "$REGION"
    gcloud config set compute/zone "$ZONE"
    print_success "Region set to: $REGION"
    print_success "Zone set to: $ZONE"
}

# Function to create VM instance
create_vm() {
    print_step "Creating Compute Engine instance"

    print_warning "Creating VM instance: $VM_NAME"

    gcloud compute instances create "$VM_NAME" \
        --zone="$ZONE" \
        --machine-type=e2-medium \
        --network-tier=PREMIUM \
        --maintenance-policy=MIGRATE \
        --image=debian-12-bookworm-v20241009 \
        --image-project=debian-cloud \
        --boot-disk-size=10GB \
        --boot-disk-type=pd-balanced \
        --boot-disk-device-name="$VM_NAME" \
        --tags=http-server \
        --create-disk=auto-delete=yes

    print_success "VM instance created"

    # Wait for VM to be ready
    wait_for_vm "$VM_NAME"

    # Get external IP
    EXTERNAL_IP=$(gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
    print_success "VM external IP: $EXTERNAL_IP"
}

# Function to install Apache and PHP on VM
install_apache() {
    print_step "Installing Apache2 and PHP on VM"

    print_warning "Installing Apache2 and PHP on $VM_NAME"

    # Update package list and install Apache2 and PHP
    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
        sudo apt-get update
        sudo apt-get install -y apache2 php7.0 || sudo apt-get install -y apache2 php
        sudo systemctl restart apache2
    " --ssh-flag="-o ConnectTimeout=10" --ssh-flag="-o StrictHostKeyChecking=no"

    print_success "Apache2 and PHP installed and restarted"

    # Verify installation
    print_warning "Verifying Apache installation..."
    sleep 5
    if curl -s --max-time 10 "http://$EXTERNAL_IP" | grep -q "Apache2"; then
        print_success "Apache is running and accessible at http://$EXTERNAL_IP"
    else
        print_warning "Apache may not be fully ready yet. You can check manually."
    fi
}

# Function to install monitoring and logging agents
install_agents() {
    print_step "Installing Cloud Monitoring and Logging agents"

    print_warning "Installing Cloud Monitoring agent on $VM_NAME"

    gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
        curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
        sudo bash add-google-cloud-ops-agent-repo.sh --also-install
        sudo systemctl status google-cloud-ops-agent --no-pager -l | head -10
        sudo apt-get update
    " --ssh-flag="-o ConnectTimeout=10" --ssh-flag="-o StrictHostKeyChecking=no"

    print_success "Cloud Monitoring and Logging agents installed"
}

# Function to demonstrate manual steps
demonstrate_manual_steps() {
    print_step "Manual Console Operations Required"

    print_warning "The following steps CANNOT be fully automated and require manual console operations:"
    echo
    echo "MANUAL STEPS REQUIRED:"
    echo
    echo "1. Task 4: Create Monitoring Metrics Scope"
    echo "   - Go to Navigation menu > View All Products > Observability > Monitoring"
    echo "   - Wait for metrics scope to be ready"
    echo
    echo "2. Task 5: Create an uptime check"
    echo "   - Go to Monitoring > Uptime checks > Create Uptime Check"
    echo "   - Protocol: HTTP, Resource Type: Instance, Instance: $VM_NAME"
    echo "   - Check Frequency: 1 minute, Title: Lamp Uptime Check"
    echo "   - Test and create the uptime check"
    echo
    echo "3. Task 6: Create an alerting policy"
    echo "   - Go to Monitoring > Alerting > +Create Policy"
    echo "   - Select metric: Network traffic (VM instance > Interface)"
    echo "   - Threshold: Above threshold, Value: 500, Retest window: 1 min"
    echo "   - Add email notification channel"
    echo "   - Name: Inbound Traffic Alert"
    echo
    echo "4. Task 7: Create a dashboard and charts"
    echo "   - Go to Monitoring > Dashboards > +Create Custom Dashboard"
    echo "   - Name: Cloud Monitoring LAMP Qwik Start Dashboard"
    echo "   - Add CPU Load chart (VM instance > Cpu > CPU load (1m))"
    echo "   - Add Received Packets chart (VM instance > Instance > Received packets)"
    echo
    echo "5. Task 8: View logs"
    echo "   - Go to Navigation menu > Logging > Logs Explorer"
    echo "   - Select resource: VM Instance > $VM_NAME"
    echo
    echo "6. Task 9: Test VM start/stop logging"
    echo "   - Stop and start the VM instance from Compute Engine"
    echo "   - Observe log changes in Logs Explorer"
    echo
    echo "7. Task 10: Check uptime check results and alerts"
    echo "   - Go to Monitoring > Uptime checks"
    echo "   - Check Lamp Uptime Check status"
    echo "   - Go to Alerting to see any triggered alerts"
    echo "   - Check your email for alert notifications"
    echo

    wait_for_user "Please complete the manual console steps, then continue here"

    print_success "Manual console operations completed"
}

# Main function
main() {
    local verbose=false
    local do_cleanup=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                verbose=true
                shift
                ;;
            cleanup)
                do_cleanup=true
                shift
                ;;
            *)
                print_error "Unknown argument: $1"
                echo "Usage: $0 [--verbose|-v] [cleanup]"
                exit 1
                ;;
        esac
    done

    echo "GSP089 - Cloud Monitoring: Qwik Start"
    echo "Automated Lab Script"
    echo "======================================"
    echo

    if $do_cleanup; then
        cleanup
        exit 0
    fi

    # Welcome message
    print_warning "IMPORTANT: This script automates PARTS of the lab."
    print_warning "Several steps require manual operations in the Google Cloud Console."
    echo
    print_warning "The script will automate:"
    echo "- VM instance creation"
    echo "- Apache2 and PHP installation"
    echo "- Cloud Monitoring and Logging agent installation"
    echo
    print_warning "You must manually perform:"
    echo "- Monitoring Metrics Scope setup"
    echo "- Uptime check creation"
    echo "- Alerting policy creation"
    echo "- Dashboard and chart creation"
    echo "- Log viewing and VM testing"
    echo

    if ! confirm "Do you want to continue?"; then
        exit 0
    fi

    # Run the automated parts
    check_prerequisites
    setup_project
    create_vm
    install_apache
    install_agents
    demonstrate_manual_steps

    echo
    print_success "Automated portion of GSP089 lab completed!"
    print_warning "Remember to complete all manual steps in the Google Cloud Console"
    print_warning "Don't forget to clean up resources when done: $0 cleanup"
    echo
    print_success "VM is accessible at: http://$EXTERNAL_IP"
    print_success "You can SSH to it with: gcloud compute ssh $VM_NAME --zone=$ZONE"
}

# Run main function with all arguments
main "$@"
