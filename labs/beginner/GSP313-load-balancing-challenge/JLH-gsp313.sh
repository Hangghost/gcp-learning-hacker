#!/bin/bash

# GSP313 - Implement Load Balancing on Compute Engine: Challenge Lab
# Automation Script

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

# Function to check if command succeeded
check_command() {
    if [ $? -eq 0 ]; then
        print_status "$1 completed successfully"
    else
        print_error "$1 failed"
        exit 1
    fi
}

# Function to prompt for input with default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local response

    read -p "$prompt [$default]: " response
    echo "${response:-$default}"
}

# Cleanup function
cleanup() {
    print_warning "Starting cleanup process..."

    # Clean up HTTP load balancer resources
    print_step "Cleaning up HTTP load balancer resources..."
    gcloud compute forwarding-rules delete http-content-rule --global --quiet 2>/dev/null || true
    gcloud compute addresses delete lb-ipv4-1 --global --quiet 2>/dev/null || true
    gcloud compute target-http-proxies delete http-lb-proxy --quiet 2>/dev/null || true
    gcloud compute url-maps delete web-map-http --quiet 2>/dev/null || true
    gcloud compute backend-services delete web-backend-service --global --quiet 2>/dev/null || true
    gcloud compute instance-groups managed delete lb-backend-group --zone=$ZONE --quiet 2>/dev/null || true
    gcloud compute instance-templates delete lb-backend-template --quiet 2>/dev/null || true
    gcloud compute health-checks delete http-basic-check --quiet 2>/dev/null || true
    gcloud compute firewall-rules delete fw-allow-health-check --quiet 2>/dev/null || true

    # Clean up network load balancer resources
    print_step "Cleaning up network load balancer resources..."
    gcloud compute forwarding-rules delete www-rule --region=$REGION --quiet 2>/dev/null || true
    gcloud compute target-pools delete www-pool --region=$REGION --quiet 2>/dev/null || true
    gcloud compute addresses delete network-lb-ip-1 --region=$REGION --quiet 2>/dev/null || true

    # Clean up instances
    print_step "Cleaning up VM instances..."
    gcloud compute instances delete web1 web2 web3 --zone=$ZONE --quiet 2>/dev/null || true

    # Clean up firewall rules
    print_step "Cleaning up firewall rules..."
    gcloud compute firewall-rules delete www-firewall-network-lb --quiet 2>/dev/null || true

    print_status "Cleanup completed!"
}

# Main script
main() {
    echo "=========================================="
    echo "GSP313 - Implement Load Balancing on Compute Engine: Challenge Lab"
    echo "=========================================="
    echo

    # Get user input for variables
    print_step "Setting up environment variables..."
    REGION=$(prompt_with_default "Enter REGION" "us-central1")
    ZONE=$(prompt_with_default "Enter ZONE" "us-central1-a")
    PROJECT_ID=$(gcloud config get-value project)

    export REGION ZONE PROJECT_ID

    print_status "Using REGION: $REGION"
    print_status "Using ZONE: $ZONE"
    print_status "Using PROJECT_ID: $PROJECT_ID"
    echo

    # Confirm before starting
    read -p "Ready to start the lab? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Lab execution cancelled by user"
        exit 0
    fi

    echo
    print_step "Starting GSP313 Challenge Lab execution..."
    echo "=========================================="

    # Task 1: Create multiple web server instances
    print_step "Task 1: Creating multiple web server instances..."
    echo

    print_status "Creating web1 instance..."
    gcloud compute instances create web1 \
      --zone=$ZONE \
      --machine-type=e2-small \
      --tags=network-lb-tag \
      --image-family=debian-12 \
      --image-project=debian-cloud \
      --metadata startup-script='#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo "<h3>Web Server: web1</h3>" | tee /var/www/html/index.html'
    check_command "web1 instance creation"

    print_status "Creating web2 instance..."
    gcloud compute instances create web2 \
      --zone=$ZONE \
      --machine-type=e2-small \
      --tags=network-lb-tag \
      --image-family=debian-12 \
      --image-project=debian-cloud \
      --metadata startup-script='#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo "<h3>Web Server: web2</h3>" | tee /var/www/html/index.html'
    check_command "web2 instance creation"

    print_status "Creating web3 instance..."
    gcloud compute instances create web3 \
      --zone=$ZONE \
      --machine-type=e2-small \
      --tags=network-lb-tag \
      --image-family=debian-12 \
      --image-project=debian-cloud \
      --metadata startup-script='#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo "<h3>Web Server: web3</h3>" | tee /var/www/html/index.html'
    check_command "web3 instance creation"

    print_status "Creating firewall rule to allow HTTP traffic..."
    gcloud compute firewall-rules create www-firewall-network-lb \
      --allow=tcp:80 \
      --target-tags=network-lb-tag
    check_command "Firewall rule creation"

    print_status "Task 1 completed successfully!"
    echo

    # Task 2: Configure the load balancing service
    print_step "Task 2: Configuring the load balancing service..."
    echo

    print_status "Creating static external IP..."
    gcloud compute addresses create network-lb-ip-1 \
      --region=$REGION
    check_command "Static IP creation"

    print_status "Creating HTTP health check..."
    gcloud compute http-health-checks create basic-check
    check_command "HTTP health check creation"

    print_status "Creating target pool..."
    gcloud compute target-pools create www-pool \
      --region=$REGION \
      --http-health-check=basic-check
    check_command "Target pool creation"

    print_status "Adding instances to target pool..."
    gcloud compute target-pools add-instances www-pool \
      --instances=web1,web2,web3 \
      --instances-zone=$ZONE \
      --region=$REGION
    check_command "Adding instances to target pool"

    print_status "Creating forwarding rule..."
    gcloud compute forwarding-rules create www-rule \
      --region=$REGION \
      --ports=80 \
      --address=network-lb-ip-1 \
      --target-pool=www-pool
    check_command "Forwarding rule creation"

    print_status "Task 2 completed successfully!"
    echo

    # Task 3: Create an HTTP load balancer
    print_step "Task 3: Creating an HTTP load balancer..."
    echo

    print_status "Creating instance template..."
    gcloud compute instance-templates create lb-backend-template \
      --region=$REGION \
      --network=default \
      --subnet=default \
      --tags=allow-health-check \
      --machine-type=e2-medium \
      --image-family=debian-12 \
      --image-project=debian-cloud \
      --metadata startup-script='#!/bin/bash
apt-get update
apt-get install apache2 -y
a2ensite default-ssl
a2enmod ssl
vm_hostname="$(curl -H "Metadata-Flavor:Google" \
http://169.254.169.254/computeMetadata/v1/instance/name)"
echo "Page served from: $vm_hostname" | \
tee /var/www/html/index.html
systemctl restart apache2'
    check_command "Instance template creation"

    print_status "Creating managed instance group..."
    gcloud compute instance-groups managed create lb-backend-group \
      --template=lb-backend-template \
      --size=2 \
      --zone=$ZONE
    check_command "Managed instance group creation"

    print_status "Creating firewall rule for health checks..."
    gcloud compute firewall-rules create fw-allow-health-check \
      --network=default \
      --action=allow \
      --direction=ingress \
      --source-ranges=130.211.0.0/22,35.191.0.0/16 \
      --target-tags=allow-health-check \
      --rules=tcp:80
    check_command "Health check firewall rule creation"

    print_status "Creating health check..."
    gcloud compute health-checks create http http-basic-check \
      --port=80
    check_command "Health check creation"

    print_status "Setting named port for instance group..."
    gcloud compute instance-groups managed set-named-ports lb-backend-group \
      --named-ports http:80 \
      --zone=$ZONE
    check_command "Named port configuration"

    print_status "Creating backend service..."
    gcloud compute backend-services create web-backend-service \
      --protocol=HTTP \
      --port-name=http \
      --health-checks=http-basic-check \
      --global
    check_command "Backend service creation"

    print_status "Adding backend to backend service..."
    gcloud compute backend-services add-backend web-backend-service \
      --instance-group=lb-backend-group \
      --instance-group-zone=$ZONE \
      --global
    check_command "Backend addition"

    print_status "Creating URL map..."
    gcloud compute url-maps create web-map-http \
      --default-service web-backend-service
    check_command "URL map creation"

    print_status "Creating target HTTP proxy..."
    gcloud compute target-http-proxies create http-lb-proxy \
      --url-map web-map-http
    check_command "Target HTTP proxy creation"

    print_status "Creating external IP address..."
    gcloud compute addresses create lb-ipv4-1 \
      --ip-version=IPV4 \
      --global
    check_command "External IP creation"

    print_status "Creating forwarding rule..."
    gcloud compute forwarding-rules create http-content-rule \
      --address=lb-ipv4-1 \
      --global \
      --target-http-proxy=http-lb-proxy \
      --ports=80
    check_command "Forwarding rule creation"

    print_status "Task 3 completed successfully!"
    echo

    # Lab completion
    echo "=========================================="
    print_status "GSP313 Challenge Lab completed successfully!"
    echo
    print_status "To test your load balancers:"
    echo "1. Network Load Balancer IP: $(gcloud compute addresses describe network-lb-ip-1 --region=$REGION --format='value(address)')"
    echo "2. HTTP Load Balancer IP: $(gcloud compute addresses describe lb-ipv4-1 --global --format='value(address)')"
    echo
    print_warning "Don't forget to clean up resources when done to avoid charges!"
    echo "Run this script with 'cleanup' argument to clean up all resources."
    echo
}

# Handle cleanup argument
if [ "$1" = "cleanup" ]; then
    print_warning "Cleanup mode activated"
    # Get user input for variables if not set
    if [ -z "$REGION" ]; then
        REGION=$(prompt_with_default "Enter REGION" "us-central1")
    fi
    if [ -z "$ZONE" ]; then
        ZONE=$(prompt_with_default "Enter ZONE" "us-central1-a")
    fi
    export REGION ZONE
    cleanup
    exit 0
fi

# Run main function
main "$@"
