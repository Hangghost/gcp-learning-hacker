#!/bin/bash
# JLH-gsp650.sh - Automate GSP650: Build a Resilient, Asynchronous System with Cloud Run and Pub/Sub
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

# Function to add IAM policy binding
add_iam_policy_binding() {
    local resource=$1
    local member=$2
    local role=$3
    local extra_args=$4

    print_step "Adding IAM policy binding: $member -> $role"
    if eval "gcloud $resource add-iam-policy-binding $extra_args --member=\"$member\" --role=\"$role\" --quiet"; then
        print_status "IAM policy binding added successfully"
    else
        print_error "Failed to add IAM policy binding"
        return 1
    fi
}

# Function to create Pub/Sub topic
create_pubsub_topic() {
    local topic_name=$1

    print_step "Creating Pub/Sub topic: $topic_name"
    if gcloud pubsub topics create "$topic_name" --quiet 2>/dev/null; then
        print_status "Pub/Sub topic created successfully"
    else
        print_warning "Pub/Sub topic may already exist, continuing..."
    fi
}

# Function to create Cloud Run service
deploy_cloud_run_service() {
    local service_name=$1
    local source_dir=$2
    local image_tag=$3
    local region=$4
    local auth_flag=$5
    local max_instances=${6:-1}

    print_step "Deploying Cloud Run service: $service_name"

    # Navigate to service directory
    cd "$source_dir"

    # Build and deploy
    if gcloud builds submit --tag "$image_tag" --quiet; then
        print_status "Container built successfully"
    else
        print_error "Failed to build container for $service_name"
        return 1
    fi

    if gcloud run deploy "$service_name" \
        --image "$image_tag" \
        --platform managed \
        --region "$region" \
        $auth_flag \
        --max-instances="$max_instances" \
        --quiet; then
        print_status "Cloud Run service $service_name deployed successfully"
    else
        print_error "Failed to deploy Cloud Run service $service_name"
        return 1
    fi

    # Go back to original directory
    cd - > /dev/null
}

# Function to create Pub/Sub subscription
create_pubsub_subscription() {
    local subscription_name=$1
    local topic_name=$2
    local push_endpoint=$3
    local service_account=$4

    print_step "Creating Pub/Sub subscription: $subscription_name"
    if gcloud pubsub subscriptions create "$subscription_name" \
        --topic "$topic_name" \
        --push-endpoint="$push_endpoint" \
        --push-auth-service-account="$service_account" \
        --quiet 2>/dev/null; then
        print_status "Pub/Sub subscription created successfully"
    else
        print_warning "Pub/Sub subscription may already exist, continuing..."
    fi
}

# Function to test service
test_service() {
    local service_url=$1
    local test_data=$2
    local expected_code=${3:-204}

    print_step "Testing service at $service_url"
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d "$test_data" \
        "$service_url" 2>/dev/null)

    if [ "$response" = "$expected_code" ]; then
        print_status "Service test passed (HTTP $response)"
    else
        print_error "Service test failed (HTTP $response, expected $expected_code)"
        return 1
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local region=$2
    local max_attempts=${3:-30}
    local attempt=1

    print_step "Waiting for $service_name to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if gcloud run services describe "$service_name" \
            --platform managed \
            --region "$region" \
            --format="value(status.conditions[0].status)" 2>/dev/null | grep -q "True"; then
            print_status "Service $service_name is ready"
            return 0
        fi
        echo -n "."
        sleep 5
        ((attempt++))
    done

    print_error "Service $service_name failed to become ready after $max_attempts attempts"
    return 1
}

# Function to create test script
create_test_script() {
    local script_name=$1
    local service_url_var=$2
    local script_content=$3

    print_step "Creating test script: $script_name"
    cat > "$script_name" << EOF
#!/bin/bash
$script_content
EOF

    chmod +x "$script_name"
    print_status "Test script created and made executable"
}

# Main script
main() {
    echo "=================================================="
    echo "GSP650 - Build a Resilient, Asynchronous System with Cloud Run and Pub/Sub"
    echo "Automated Setup Script"
    echo "=================================================="
    echo

    # Check prerequisites
    print_step "Checking prerequisites..."

    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install Google Cloud SDK first."
        exit 1
    fi

    if ! command_exists gsutil; then
        print_error "gsutil is not installed. Please install Google Cloud SDK first."
        exit 1
    fi

    if ! command_exists npm; then
        print_error "npm is not installed. Please install Node.js first."
        exit 1
    fi

    if ! command_exists git; then
        print_error "git is not installed. Please install git first."
        exit 1
    fi

    print_status "All prerequisites met"

    # Prompt for variables
    echo
    print_step "Please provide the following information:"

    prompt_variable REGION "Enter GCP region (e.g., us-central1, europe-west1)" "us-central1"
    if ! validate_region "$REGION"; then
        exit 1
    fi

    # Get project information
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        print_error "No GCP project set. Please run: gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi

    print_status "Using project: $PROJECT_ID"
    print_status "Using region: $REGION"

    # Confirm
    echo
    echo -e "${YELLOW}Configuration:${NC}"
    echo "  Project ID: $PROJECT_ID"
    echo "  Region: $REGION"
    echo
    read -p "Continue with these settings? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Setup cancelled"
        exit 0
    fi

    # Set variables
    REPO_DIR="pet-theory"
    LAB_SERVICE_DIR="$REPO_DIR/lab05/lab-service"
    EMAIL_SERVICE_DIR="$REPO_DIR/lab05/email-service"
    SMS_SERVICE_DIR="$REPO_DIR/lab05/sms-service"

    TOPIC_NAME="new-lab-report"
    SERVICE_ACCOUNT_NAME="pubsub-cloud-run-invoker"

    LAB_SERVICE_NAME="lab-report-service"
    EMAIL_SERVICE_NAME="email-service"
    SMS_SERVICE_NAME="sms-service"

    LAB_IMAGE="gcr.io/$PROJECT_ID/$LAB_SERVICE_NAME"
    EMAIL_IMAGE="gcr.io/$PROJECT_ID/$EMAIL_SERVICE_NAME"
    SMS_IMAGE="gcr.io/$PROJECT_ID/$SMS_SERVICE_NAME"

    EMAIL_SUBSCRIPTION="email-service-sub"
    SMS_SUBSCRIPTION="sms-service-sub"

    echo
    print_step "Starting lab setup..."

    # Clone repository if not exists
    if [ ! -d "$REPO_DIR" ]; then
        print_step "Cloning Pet Theory repository..."
        git clone https://github.com/rosera/pet-theory.git
    fi

    # Task 1: Create Pub/Sub topic and enable APIs
    print_step "Task 1: Setting up Pub/Sub topic and APIs"

    enable_api "run.googleapis.com" "Cloud Run"
    enable_api "pubsub.googleapis.com" "Pub/Sub"
    enable_api "cloudbuild.googleapis.com" "Cloud Build"

    create_pubsub_topic "$TOPIC_NAME"

    # Task 2: Build the Lab Report Service
    print_step "Task 2: Building the Lab Report Service"

    # Setup lab service
    cd "$LAB_SERVICE_DIR"

    # Install packages
    npm install express body-parser @google-cloud/pubsub

    # Update package.json
    if ! grep -q '"start": "node index.js"' package.json; then
        npm pkg set scripts.start="node index.js"
    fi

    # Create index.js
    cat > index.js << 'EOF'
const {PubSub} = require('@google-cloud/pubsub');
const pubsub = new PubSub();
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());
const port = process.env.PORT || 8080;

app.listen(port, () => {
  console.log('Listening on port', port);
});

app.post('/', async (req, res) => {
  try {
    const labReport = req.body;
    await publishPubSubMessage(labReport);
    res.status(204).send();
  }
  catch (ex) {
    console.log(ex);
    res.status(500).send(ex);
  }
})

async function publishPubSubMessage(labReport) {
  const buffer = Buffer.from(JSON.stringify(labReport));
  await pubsub.topic('new-lab-report').publish(buffer);
}
EOF

    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM node:18
WORKDIR /usr/src/app
COPY package.json package*.json ./
RUN npm install --only=production
COPY . .
CMD [ "npm", "start" ]
EOF

    # Create deploy script
    cat > deploy.sh << EOF
gcloud builds submit \\
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/lab-report-service
gcloud run deploy lab-report-service \\
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/lab-report-service \\
  --platform managed \\
  --region "$REGION" \\
  --allow-unauthenticated \\
  --max-instances=1
EOF

    chmod +x deploy.sh

    # Deploy lab service
    deploy_cloud_run_service "$LAB_SERVICE_NAME" "$LAB_SERVICE_DIR" "$LAB_IMAGE" "$REGION" "--allow-unauthenticated"
    wait_for_service "$LAB_SERVICE_NAME" "$REGION"

    # Get service URL
    LAB_REPORT_SERVICE_URL=$(gcloud run services describe "$LAB_SERVICE_NAME" \
        --platform managed \
        --region "$REGION" \
        --format="value(status.address.url)")

    print_status "Lab Report Service URL: $LAB_REPORT_SERVICE_URL"

    # Create test script
    create_test_script "post-reports.sh" "LAB_REPORT_SERVICE_URL" "
curl -X POST \\
  -H \"Content-Type: application/json\" \\
  -d '{\"id\": 12}' \\
  \$LAB_REPORT_SERVICE_URL &
curl -X POST \\
  -H \"Content-Type: application/json\" \\
  -d '{\"id\": 34}' \\
  \$LAB_REPORT_SERVICE_URL &
curl -X POST \\
  -H \"Content-Type: application/json\" \\
  -d '{\"id\": 56}' \\
  \$LAB_REPORT_SERVICE_URL &
"

    # Test lab service
    LAB_REPORT_SERVICE_URL="$LAB_REPORT_SERVICE_URL" ./post-reports.sh
    sleep 10

    # Task 3: Build the Email Service
    print_step "Task 3: Building the Email Service"

    cd "$EMAIL_SERVICE_DIR"

    # Install packages
    npm install express body-parser

    # Update package.json
    if ! grep -q '"start": "node index.js"' package.json; then
        npm pkg set scripts.start="node index.js"
    fi

    # Create index.js
    cat > index.js << 'EOF'
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Listening on port', port);
});

app.post('/', async (req, res) => {
  const labReport = decodeBase64Json(req.body.message.data);
  try {
    console.log(`Email Service: Report ${labReport.id} trying...`);
    sendEmail();
    console.log(`Email Service: Report ${labReport.id} success :-)`);
    res.status(204).send();
  }
  catch (ex) {
    console.log(`Email Service: Report ${labReport.id} failure: ${ex}`);
    res.status(500).send();
  }
})

function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}

function sendEmail() {
  console.log('Sending email');
}
EOF

    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM node:18
WORKDIR /usr/src/app
COPY package.json package*.json ./
RUN npm install --only=production
COPY . .
CMD [ "npm", "start" ]
EOF

    # Create deploy script
    cat > deploy.sh << EOF
gcloud builds submit \\
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/email-service
gcloud run deploy email-service \\
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/email-service \\
  --platform managed \\
  --region "$REGION" \\
  --no-allow-unauthenticated \\
  --max-instances=1
EOF

    chmod +x deploy.sh

    # Deploy email service
    deploy_cloud_run_service "$EMAIL_SERVICE_NAME" "$EMAIL_SERVICE_DIR" "$EMAIL_IMAGE" "$REGION" "--no-allow-unauthenticated"
    wait_for_service "$EMAIL_SERVICE_NAME" "$REGION"

    # Configure Pub/Sub for Email Service
    print_step "Configuring Pub/Sub for Email Service"

    create_service_account "$SERVICE_ACCOUNT_NAME" "PubSub Cloud Run Invoker"

    # Get project number
    PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format="value(project_number)")

    # Add IAM permissions
    add_iam_policy_binding "run services" "$EMAIL_SERVICE_NAME" \
        "serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        "roles/run.invoker" \
        "--region $REGION --platform managed"

    add_iam_policy_binding "projects" "$PROJECT_ID" \
        "serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com" \
        "roles/iam.serviceAccountTokenCreator"

    # Get email service URL
    EMAIL_SERVICE_URL=$(gcloud run services describe "$EMAIL_SERVICE_NAME" \
        --platform managed \
        --region "$REGION" \
        --format="value(status.address.url)")

    # Create subscription
    create_pubsub_subscription "$EMAIL_SUBSCRIPTION" "$TOPIC_NAME" "$EMAIL_SERVICE_URL" "$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"

    # Test services together
    print_step "Testing Lab Report and Email services together"
    LAB_REPORT_SERVICE_URL="$LAB_REPORT_SERVICE_URL" ./post-reports.sh
    sleep 15

    # Task 4: Build the SMS Service
    print_step "Task 4: Building the SMS Service"

    cd "$SMS_SERVICE_DIR"

    # Install packages
    npm install express body-parser

    # Update package.json
    if ! grep -q '"start": "node index.js"' package.json; then
        npm pkg set scripts.start="node index.js"
    fi

    # Create index.js
    cat > index.js << 'EOF'
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Listening on port', port);
});

app.post('/', async (req, res) => {
  const labReport = decodeBase64Json(req.body.message.data);
  try {
    console.log(`SMS Service: Report ${labReport.id} trying...`);
    sendSms();

    console.log(`SMS Service: Report ${labReport.id} success :-)`);
    res.status(204).send();
  }
  catch (ex) {
    console.log(`SMS Service: Report ${labReport.id} failure: ${ex}`);
    res.status(500).send();
  }
})

function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}

function sendSms() {
  console.log('Sending SMS');
}
EOF

    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM node:18
WORKDIR /usr/src/app
COPY package.json package*.json ./
RUN npm install --only=production
COPY . .
CMD [ "npm", "start" ]
EOF

    # Create deploy script
    cat > deploy.sh << EOF
gcloud builds submit \\
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/sms-service
gcloud run deploy sms-service \\
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/sms-service \\
  --platform managed \\
  --region "$REGION" \\
  --no-allow-unauthenticated \\
  --max-instances=1
EOF

    chmod +x deploy.sh

    # Deploy SMS service
    deploy_cloud_run_service "$SMS_SERVICE_NAME" "$SMS_SERVICE_DIR" "$SMS_IMAGE" "$REGION" "--no-allow-unauthenticated"
    wait_for_service "$SMS_SERVICE_NAME" "$REGION"

    # Configure Pub/Sub for SMS Service
    add_iam_policy_binding "run services" "$SMS_SERVICE_NAME" \
        "serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        "roles/run.invoker" \
        "--region $REGION --platform managed"

    # Get SMS service URL
    SMS_SERVICE_URL=$(gcloud run services describe "$SMS_SERVICE_NAME" \
        --platform managed \
        --region "$REGION" \
        --format="value(status.address.url)")

    # Create subscription
    create_pubsub_subscription "$SMS_SUBSCRIPTION" "$TOPIC_NAME" "$SMS_SERVICE_URL" "$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"

    # Test all services
    print_step "Testing all services together"
    cd "$LAB_SERVICE_DIR"
    LAB_REPORT_SERVICE_URL="$LAB_REPORT_SERVICE_URL" ./post-reports.sh
    sleep 15

    # Task 5: Test resiliency
    print_step "Task 5: Testing system resiliency"

    cd "$EMAIL_SERVICE_DIR"

    # Create bad version of email service
    print_step "Deploying bad version of Email Service to test resiliency"
    sed -i 's/function sendEmail() {/function sendEmail() {\n  throw '\''Email server is down'\'';/' index.js

    deploy_cloud_run_service "$EMAIL_SERVICE_NAME" "$EMAIL_SERVICE_DIR" "$EMAIL_IMAGE" "$REGION" "--no-allow-unauthenticated"
    wait_for_service "$EMAIL_SERVICE_NAME" "$REGION"

    # Test with bad service
    cd "$LAB_SERVICE_DIR"
    print_step "Testing with bad Email Service (should show retries)"
    LAB_REPORT_SERVICE_URL="$LAB_REPORT_SERVICE_URL" ./post-reports.sh
    sleep 20

    # Fix the service
    print_step "Fixing Email Service"
    cd "$EMAIL_SERVICE_DIR"
    sed -i '/throw '\''Email server is down'\'';/d' index.js

    deploy_cloud_run_service "$EMAIL_SERVICE_NAME" "$EMAIL_SERVICE_DIR" "$EMAIL_IMAGE" "$REGION" "--no-allow-unauthenticated"
    wait_for_service "$EMAIL_SERVICE_NAME" "$REGION"

    # Final test
    print_step "Final test with all services working"
    cd "$LAB_SERVICE_DIR"
    LAB_REPORT_SERVICE_URL="$LAB_REPORT_SERVICE_URL" ./post-reports.sh
    sleep 15

    echo
    echo "=================================================="
    print_status "Lab GSP650 setup and testing completed successfully!"
    echo
    echo -e "${BLUE}Services Created:${NC}"
    echo "  Lab Report Service: $LAB_REPORT_SERVICE_URL"
    echo "  Email Service: $EMAIL_SERVICE_URL"
    echo "  SMS Service: $SMS_SERVICE_URL"
    echo
    echo -e "${BLUE}Pub/Sub Resources:${NC}"
    echo "  Topic: $TOPIC_NAME"
    echo "  Email Subscription: $EMAIL_SUBSCRIPTION"
    echo "  SMS Subscription: $SMS_SUBSCRIPTION"
    echo
    echo -e "${BLUE}Key Takeaways Demonstrated:${NC}"
    echo "  ✓ Asynchronous communication via Pub/Sub"
    echo "  ✓ Service isolation and independence"
    echo "  ✓ Automatic retry mechanism"
    echo "  ✓ System resiliency and self-healing"
    echo
    echo -e "${YELLOW}To clean up resources, run:${NC}"
    echo "  gcloud run services delete $LAB_SERVICE_NAME"
    echo "  gcloud run services delete $EMAIL_SERVICE_NAME"
    echo "  gcloud run services delete $SMS_SERVICE_NAME"
    echo "  gcloud pubsub topics delete $TOPIC_NAME"
    echo "  gcloud pubsub subscriptions delete $EMAIL_SUBSCRIPTION"
    echo "  gcloud pubsub subscriptions delete $SMS_SUBSCRIPTION"
    echo "  gcloud iam service-accounts delete $SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"
    echo "=================================================="
}

# Function to cleanup on error
cleanup() {
    echo
    print_error "An error occurred. Performing cleanup..."
    # Add cleanup logic here if needed
    exit 1
}

# Set trap for cleanup
trap cleanup ERR

# Run main function
main "$@"
