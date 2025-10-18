#!/bin/bash

# GSP041 - Use an Internal Application Load Balancer
# Automated Lab Script
# This script automates the GSP041 lab for creating an internal application load balancer

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

echo -e "${GREEN}GSP041 - Use an Internal Application Load Balancer${NC}"
echo "This script will automate the lab setup for creating an internal application load balancer."
echo

# Get user inputs
print_step "Getting Configuration Parameters"

get_input "Enter your project region" REGION "us-central1"
get_input "Enter your project zone" ZONE "us-central1-a"
get_input "Enter the internal IP address for the load balancer" INTERNAL_IP "10.128.0.100"
get_input "Enter the source IP range for backend firewall" SOURCE_RANGE "10.128.0.0/9"

echo
echo "Configuration Summary:"
echo "  Region: $REGION"
echo "  Zone: $ZONE"
echo "  Internal IP: $INTERNAL_IP"
echo "  Source Range: $SOURCE_RANGE"
echo

if ! confirm "Do you want to proceed with this configuration?"; then
    echo "Exiting..."
    exit 1
fi

# Set gcloud configuration
print_step "Setting gcloud Configuration"
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
print_success "gcloud configuration set"

# Task 1: Create virtual environment
print_step "Task 1: Creating Virtual Environment"
sudo apt-get install -y virtualenv
python3 -m venv venv
source venv/bin/activate
print_success "Virtual environment created and activated"

# Enable Gemini Code Assist API
print_step "Enabling Gemini Code Assist API"
gcloud services enable cloudaicompanion.googleapis.com
print_success "Gemini Code Assist API enabled"

# Task 2: Create backend managed instance group
print_step "Task 2: Creating Backend Managed Instance Group"

# Create backend startup script
cat > ~/backend.sh << 'EOF'
sudo chmod -R 777 /usr/local/sbin/
sudo cat << 'INNER_EOF' > /usr/local/sbin/serveprimes.py
import http.server

def is_prime(a): return a!=1 and all(a % i for i in range(2,int(a**0.5)+1))

class myHandler(http.server.BaseHTTPRequestHandler):
  def do_GET(s):
    s.send_response(200)
    s.send_header("Content-type", "text/plain")
    s.end_headers()
    s.wfile.write(bytes(str(is_prime(int(s.path[1:]))).encode('utf-8')))

http.server.HTTPServer(("",80),myHandler).serve_forever()
INNER_EOF
nohup python3 /usr/local/sbin/serveprimes.py >/dev/null 2>&1 &
EOF

print_success "Backend startup script created"

# Create instance template
gcloud compute instance-templates create primecalc \
--metadata-from-file startup-script=backend.sh \
--no-address --tags backend --machine-type=e2-medium

print_success "Instance template 'primecalc' created"

# Create firewall rule for backend
gcloud compute firewall-rules create http --network default --allow=tcp:80 \
--source-ranges $SOURCE_RANGE --target-tags backend

print_success "Firewall rule 'http' created for backend"

# Create managed instance group
gcloud compute instance-groups managed create backend \
--size 3 \
--template primecalc \
--zone $ZONE

print_success "Managed instance group 'backend' created with 3 instances"

# Wait for instances to be ready
print_step "Waiting for backend instances to be ready..."
sleep 30

# Task 3: Set up internal load balancer
print_step "Task 3: Setting Up Internal Load Balancer"

# Create health check
gcloud compute health-checks create http ilb-health --request-path /2
print_success "Health check 'ilb-health' created"

# Create backend service
gcloud compute backend-services create prime-service \
--load-balancing-scheme internal --region=$REGION \
--protocol tcp --health-checks ilb-health

print_success "Backend service 'prime-service' created"

# Add instance group to backend service
gcloud compute backend-services add-backend prime-service \
--instance-group backend --instance-group-zone=$ZONE \
--region=$REGION

print_success "Instance group added to backend service"

# Create forwarding rule
gcloud compute forwarding-rules create prime-lb \
--load-balancing-scheme internal \
--ports 80 --network default \
--region=$REGION --address $INTERNAL_IP \
--backend-service prime-service

print_success "Forwarding rule 'prime-lb' created with IP $INTERNAL_IP"

# Task 4: Test the load balancer
print_step "Task 4: Testing the Load Balancer"

# Create test instance
gcloud compute instances create testinstance \
--machine-type=e2-standard-2 --zone $ZONE

print_success "Test instance 'testinstance' created"

# Wait for test instance to be ready
echo "Waiting for test instance to be ready..."
sleep 20

# Test the load balancer
echo "Testing load balancer from test instance..."
gcloud compute ssh testinstance --zone $ZONE --command="curl $INTERNAL_IP/2; echo; curl $INTERNAL_IP/4; echo; curl $INTERNAL_IP/5; echo"

# Clean up test instance
gcloud compute instances delete testinstance --zone=$ZONE --quiet
print_success "Test instance deleted"

# Task 5: Create public-facing web server
print_step "Task 5: Creating Public-Facing Web Server"

# Create frontend startup script
cat > ~/frontend.sh << EOF
sudo chmod -R 777 /usr/local/sbin/
sudo cat << 'INNER_EOF' > /usr/local/sbin/getprimes.py
import urllib.request
from multiprocessing.dummy import Pool as ThreadPool
import http.server
PREFIX="http://$INTERNAL_IP/" #HTTP Load Balancer
def get_url(number):
    return urllib.request.urlopen(PREFIX+str(number)).read().decode('utf-8')
class myHandler(http.server.BaseHTTPRequestHandler):
  def do_GET(s):
    s.send_response(200)
    s.send_header("Content-type", "text/html")
    s.end_headers()
    i = int(s.path[1:]) if (len(s.path)>1) else 1
    s.wfile.write("<html><body><table>".encode('utf-8'))
    pool = ThreadPool(10)
    results = pool.map(get_url,range(i,i+100))
    for x in range(0,100):
      if not (x % 10): s.wfile.write("<tr>".encode('utf-8'))
      if results[x]=="True":
        s.wfile.write("<td bgcolor='#00ff00'>".encode('utf-8'))
      else:
        s.wfile.write("<td bgcolor='#ff0000'>".encode('utf-8'))
      s.wfile.write(str(x+i).encode('utf-8')+"</td> ".encode('utf-8'))
      if not ((x+1) % 10): s.wfile.write("</tr>".encode('utf-8'))
    s.wfile.write("</table></body></html>".encode('utf-8'))
http.server.HTTPServer(("",80),myHandler).serve_forever()
INNER_EOF
nohup python3 /usr/local/sbin/getprimes.py >/dev/null 2>&1 &
EOF

print_success "Frontend startup script created"

# Create frontend instance
gcloud compute instances create frontend --zone=$ZONE \
--metadata-from-file startup-script=frontend.sh \
--tags frontend --machine-type=e2-standard-2

print_success "Frontend instance 'frontend' created"

# Create firewall rule for frontend
gcloud compute firewall-rules create http2 --network default --allow=tcp:80 \
--source-ranges 0.0.0.0/0 --target-tags frontend

print_success "Firewall rule 'http2' created for frontend"

# Wait for frontend to be ready
echo "Waiting for frontend instance to be ready..."
sleep 30

# Get frontend external IP
FRONTEND_IP=$(gcloud compute instances describe frontend --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

print_step "Lab Setup Complete!"
echo
echo "Summary of created resources:"
echo "  - Backend managed instance group: backend (3 instances)"
echo "  - Internal load balancer IP: $INTERNAL_IP"
echo "  - Frontend instance: frontend"
echo "  - Frontend external IP: $FRONTEND_IP"
echo
echo "You can now:"
echo "  1. Access the frontend at: http://$FRONTEND_IP"
echo "  2. Test different paths like: http://$FRONTEND_IP/10000"
echo "  3. Check VM instances in Google Cloud Console"
echo

# Cleanup function
cleanup() {
    echo
    print_warning "Cleaning up resources..."
    
    # Delete frontend instance
    gcloud compute instances delete frontend --zone=$ZONE --quiet 2>/dev/null || true
    
    # Delete backend instance group
    gcloud compute instance-groups managed delete backend --zone=$ZONE --quiet 2>/dev/null || true
    
    # Delete instance template
    gcloud compute instance-templates delete primecalc --quiet 2>/dev/null || true
    
    # Delete load balancer components
    gcloud compute forwarding-rules delete prime-lb --region=$REGION --quiet 2>/dev/null || true
    gcloud compute backend-services delete prime-service --region=$REGION --quiet 2>/dev/null || true
    gcloud compute health-checks delete ilb-health --quiet 2>/dev/null || true
    
    # Delete firewall rules
    gcloud compute firewall-rules delete http --quiet 2>/dev/null || true
    gcloud compute firewall-rules delete http2 --quiet 2>/dev/null || true
    
    print_success "Cleanup completed"
}

# Ask if user wants to cleanup
echo
if confirm "Do you want to cleanup all resources now? (This will delete all created resources)"; then
    cleanup
else
    echo
    echo "To cleanup later, run:"
    echo "  gcloud compute instances delete frontend --zone=$ZONE"
    echo "  gcloud compute instance-groups managed delete backend --zone=$ZONE"
    echo "  gcloud compute instance-templates delete primecalc"
    echo "  gcloud compute forwarding-rules delete prime-lb --region=$REGION"
    echo "  gcloud compute backend-services delete prime-service --region=$REGION"
    echo "  gcloud compute health-checks delete ilb-health"
    echo "  gcloud compute firewall-rules delete http"
    echo "  gcloud compute firewall-rules delete http2"
fi

echo
print_success "GSP041 Lab completed successfully!"
