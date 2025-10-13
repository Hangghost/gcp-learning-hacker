#!/bin/bash

# GSP155 - Set Up Application Load Balancers
# Automated Lab Script
# This script automates the GSP155 lab for setting up application load balancers

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

# Function to wait for user
wait_for_user() {
    echo
    read -p "Press Enter to continue..."
    echo
}

# Function to cleanup resources
cleanup_resources() {
    print_step "Cleaning up resources"

    print_warning "This will delete all resources created during the lab"
    if ! confirm "Do you want to proceed with cleanup?"; then
        print_warning "Cleanup cancelled"
        return
    fi

    # Delete forwarding rule
    if gcloud compute forwarding-rules describe http-content-rule --global &>/dev/null; then
        print_warning "Deleting forwarding rule..."
        gcloud compute forwarding-rules delete http-content-rule --global --quiet
        print_success "Forwarding rule deleted"
    fi

    # Delete target HTTP proxy
    if gcloud compute target-http-proxies describe http-lb-proxy &>/dev/null; then
        print_warning "Deleting target HTTP proxy..."
        gcloud compute target-http-proxies delete http-lb-proxy --quiet
        print_success "Target HTTP proxy deleted"
    fi

    # Delete URL map
    if gcloud compute url-maps describe web-map-http &>/dev/null; then
        print_warning "Deleting URL map..."
        gcloud compute url-maps delete web-map-http --quiet
        print_success "URL map deleted"
    fi

    # Delete backend service
    if gcloud compute backend-services describe web-backend-service --global &>/dev/null; then
        print_warning "Deleting backend service..."
        gcloud compute backend-services delete web-backend-service --global --quiet
        print_success "Backend service deleted"
    fi

    # Delete instance group
    if gcloud compute instance-groups managed describe lb-backend-group --zone="$ZONE" &>/dev/null; then
        print_warning "Deleting instance group..."
        gcloud compute instance-groups managed delete lb-backend-group --zone="$ZONE" --quiet
        print_success "Instance group deleted"
    fi

    # Delete instance template
    if gcloud compute instance-templates describe lb-backend-template &>/dev/null; then
        print_warning "Deleting instance template..."
        gcloud compute instance-templates delete lb-backend-template --quiet
        print_success "Instance template deleted"
    fi

    # Delete health check
    if gcloud compute health-checks describe http-basic-check &>/dev/null; then
        print_warning "Deleting health check..."
        gcloud compute health-checks delete http-basic-check --quiet
        print_success "Health check deleted"
    fi

    # Delete global IP address
    if gcloud compute addresses describe lb-ipv4-1 --global &>/dev/null; then
        print_warning "Deleting global IP address..."
        gcloud compute addresses delete lb-ipv4-1 --global --quiet
        print_success "Global IP address deleted"
    fi

    # Delete firewall rules
    if gcloud compute firewall-rules describe www-firewall-network-lb &>/dev/null; then
        print_warning "Deleting www-firewall-network-lb..."
        gcloud compute firewall-rules delete www-firewall-network-lb --quiet
        print_success "Firewall rule www-firewall-network-lb deleted"
    fi

    if gcloud compute firewall-rules describe fw-allow-health-check &>/dev/null; then
        print_warning "Deleting fw-allow-health-check..."
        gcloud compute firewall-rules delete fw-allow-health-check --quiet
        print_success "Firewall rule fw-allow-health-check deleted"
    fi

    # Delete VM instances
    for instance in www1 www2 www3; do
        if gcloud compute instances describe "$instance" --zone="$ZONE" &>/dev/null; then
            print_warning "Deleting instance $instance..."
            gcloud compute instances delete "$instance" --zone="$ZONE" --quiet
            print_success "Instance $instance deleted"
        fi
    done

    print_success "Cleanup completed!"
}

# Main script
main() {
    echo "=================================================="
    echo "GSP155 - Set Up Application Load Balancers"
    echo "Automated Lab Script"
    echo "=================================================="
    echo

    # Check if gcloud is available
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed or not in PATH"
        exit 1
    fi

    # Get required variables
    print_step "Configuration"

    # Get region
    get_input "Enter the region for your resources" "REGION" "us-central1"

    # Get zone
    get_input "Enter the zone for your resources" "ZONE" "us-central1-a"

    # Get project ID
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "(unset)" ]; then
        get_input "Enter your GCP Project ID" "PROJECT_ID"
        gcloud config set project "$PROJECT_ID"
    fi

    print_success "Configuration complete"
    echo "Region: $REGION"
    echo "Zone: $ZONE"
    echo "Project: $PROJECT_ID"
    echo

    # Confirm before starting
    if ! confirm "Do you want to start the lab setup?"; then
        print_warning "Lab setup cancelled"
        exit 0
    fi

    # Task 1: Set the default region and zone
    print_step "Task 1: Set the default region and zone for all resources"

    print_warning "Setting default region to $REGION"
    gcloud config set compute/region "$REGION"

    print_warning "Setting default zone to $ZONE"
    gcloud config set compute/zone "$ZONE"

    print_success "Default region and zone configured"
    echo

    wait_for_user

    # Task 2: Create multiple web server instances
    print_step "Task 2: Create multiple web server instances"

    print_warning "Creating VM instance www1"
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

    print_warning "Creating VM instance www2"
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

    print_warning "Creating VM instance www3"
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

    print_warning "Creating firewall rule for web servers"
    gcloud compute firewall-rules create www-firewall-network-lb \
        --target-tags network-lb-tag --allow tcp:80

    print_success "Web server instances created"
    echo

    # List instances and show IP addresses
    print_warning "Listing instances and their external IP addresses:"
    gcloud compute instances list --filter="name:(www1 www2 www3)"

    print_warning "Testing web servers (this may take a moment for instances to fully start)..."
    sleep 30

    # Get instance IPs and test them
    for instance in www1 www2 www3; do
        EXTERNAL_IP=$(gcloud compute instances describe "$instance" --zone="$ZONE" --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
        if [ -n "$EXTERNAL_IP" ]; then
            print_warning "Testing $instance at $EXTERNAL_IP"
            if curl -s --max-time 10 "http://$EXTERNAL_IP" | grep -q "Web Server: $instance"; then
                print_success "$instance is responding correctly"
            else
                print_warning "$instance may still be starting up"
            fi
        fi
    done

    echo
    wait_for_user

    # Task 3: Create an Application Load Balancer
    print_step "Task 3: Create an Application Load Balancer"

    print_warning "Creating instance template for load balancer backends"
    gcloud compute instance-templates create lb-backend-template \
       --region="$REGION" \
       --network=default \
       --subnet=default \
       --tags=allow-health-check \
       --machine-type=e2-medium \
       --image-family=debian-11 \
       --image-project=debian-cloud \
       --metadata=startup-script='#!/bin/bash
         apt-get update
         apt-get install apache2 -y
         a2ensite default-ssl
         a2enmod ssl
         vm_hostname="$(curl -H "Metadata-Flavor:Google" \
         http://169.254.169.254/computeMetadata/v1/instance/name)"
         echo "Page served from: $vm_hostname" | \
         tee /var/www/html/index.html
         systemctl restart apache2'

    print_warning "Creating managed instance group"
    gcloud compute instance-groups managed create lb-backend-group \
       --template=lb-backend-template --size=2 --zone="$ZONE"

    print_warning "Creating firewall rule for health checks"
    gcloud compute firewall-rules create fw-allow-health-check \
      --network=default \
      --action=allow \
      --direction=ingress \
      --source-ranges=130.211.0.0/22,35.191.0.0/16 \
      --target-tags=allow-health-check \
      --rules=tcp:80

    print_warning "Creating global static IP address"
    gcloud compute addresses create lb-ipv4-1 \
      --ip-version=IPV4 \
      --global

    # Get and display the IP address
    LB_IP=$(gcloud compute addresses describe lb-ipv4-1 \
      --format="get(address)" \
      --global)

    print_success "Load balancer IP address: $LB_IP"
    echo "Save this IP address for later testing"

    print_warning "Creating health check"
    gcloud compute health-checks create http http-basic-check \
      --port 80

    print_warning "Creating backend service"
    gcloud compute backend-services create web-backend-service \
      --protocol=HTTP \
      --port-name=http \
      --health-checks=http-basic-check \
      --global

    print_warning "Adding backend to backend service"
    gcloud compute backend-services add-backend web-backend-service \
      --instance-group=lb-backend-group \
      --instance-group-zone="$ZONE" \
      --global

    print_warning "Creating URL map"
    gcloud compute url-maps create web-map-http \
        --default-service web-backend-service

    print_warning "Creating target HTTP proxy"
    gcloud compute target-http-proxies create http-lb-proxy \
        --url-map web-map-http

    print_warning "Creating global forwarding rule"
    gcloud compute forwarding-rules create http-content-rule \
       --address=lb-ipv4-1\
       --global \
       --target-http-proxy=http-lb-proxy \
       --ports=80

    print_success "Application Load Balancer created"
    echo

    wait_for_user

    # Task 4: Test traffic sent to your instances
    print_step "Task 4: Test traffic sent to your instances"

    print_warning "Waiting for load balancer to be ready (this may take 3-5 minutes)..."
    sleep 180

    print_warning "Testing load balancer at http://$LB_IP"
    print_warning "You can also check the load balancer status in the Google Cloud Console"

    # Test the load balancer
    if curl -s --max-time 30 "http://$LB_IP" | grep -q "Page served from:"; then
        print_success "Load balancer is responding!"
        print_warning "Try refreshing the page multiple times to see responses from different backend instances"
        echo
        print_warning "Load balancer URL: http://$LB_IP"
    else
        print_warning "Load balancer may still be initializing. Check the Google Cloud Console for status."
        echo
        print_warning "Load balancer URL: http://$LB_IP"
        print_warning "Go to Load balancing in the Console and check the backend health status"
    fi

    echo
    print_success "Lab setup completed!"
    echo
    print_warning "Don't forget to clean up resources when you're done to avoid charges"

    # Ask if user wants to cleanup
    echo
    if confirm "Do you want to clean up all resources now?"; then
        cleanup_resources
    else
        print_warning "Remember to run this script again with --cleanup when you're done"
        echo "Or manually clean up resources using the Google Cloud Console"
    fi
}

# Handle command line arguments
case "${1:-}" in
    --cleanup)
        print_warning "Cleanup mode selected"
        # Get required variables for cleanup
        get_input "Enter the zone used in the lab" "ZONE" "us-central1-a"
        cleanup_resources
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  --cleanup    Clean up all resources created by this lab"
        echo "  --help, -h   Show this help message"
        echo
        echo "Without options, runs the complete lab setup"
        ;;
    *)
        main
        ;;
esac
