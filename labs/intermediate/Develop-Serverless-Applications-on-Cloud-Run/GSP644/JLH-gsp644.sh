#!/bin/bash
# JLH-gsp644.sh - Automate GSP644: Develop Serverless Applications on Cloud Run
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

# Function to create bucket
create_bucket() {
    local bucket_name=$1

    print_step "Creating Cloud Storage bucket: $bucket_name"
    if gsutil mb "gs://$bucket_name" 2>/dev/null; then
        print_status "Bucket created successfully"
    else
        print_warning "Bucket may already exist, continuing..."
    fi
}

# Function to build and deploy Cloud Run service
deploy_cloud_run() {
    local service_name=$1
    local image=$2
    local region=$3
    local memory=$4
    local env_vars=$5
    local extra_args=$6

    print_step "Building container image..."
    if gcloud builds submit --tag "$image" --quiet; then
        print_status "Container built successfully"
    else
        print_error "Failed to build container"
        return 1
    fi

    print_step "Deploying Cloud Run service..."
    if gcloud run deploy "$service_name" \
        --image "$image" \
        --platform managed \
        --region "$region" \
        --memory "$memory" \
        --no-allow-unauthenticated \
        --max-instances=1 \
        $env_vars \
        $extra_args \
        --quiet; then
        print_status "Cloud Run service deployed successfully"
    else
        print_error "Failed to deploy Cloud Run service"
        return 1
    fi
}

# Function to test service
test_service() {
    local service_url=$1

    print_step "Testing Cloud Run service..."
    if curl -X POST -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$service_url" 2>/dev/null | grep -q "OK"; then
        print_status "Service test passed"
    else
        print_error "Service test failed"
        return 1
    fi
}

# Main script
main() {
    echo "=================================================="
    echo "GSP644 - Develop Serverless Applications on Cloud Run"
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
    SERVICE_NAME="pdf-converter"
    IMAGE_NAME="gcr.io/$PROJECT_ID/pdf-converter"
    UPLOAD_BUCKET="$PROJECT_ID-upload"
    PROCESSED_BUCKET="$PROJECT_ID-processed"
    TOPIC_NAME="new-doc"
    SUBSCRIPTION_NAME="pdf-conv-sub"
    SERVICE_ACCOUNT_NAME="pubsub-cloud-run-invoker"

    echo
    print_step "Starting lab setup..."

    # Task 2: Enable Cloud Run API
    print_step "Task 2: Enabling Cloud Run API"
    enable_api "run.googleapis.com" "Cloud Run"
    enable_api "cloudbuild.googleapis.com" "Cloud Build"
    enable_api "pubsub.googleapis.com" "Pub/Sub"

    # Task 3: Deploy simple Cloud Run service
    print_step "Task 3: Deploying simple Cloud Run service"

    # Clone repository
    print_step "Cloning Pet Theory repository..."
    if [ ! -d "pet-theory" ]; then
        git clone https://github.com/rosera/pet-theory.git
    fi
    cd pet-theory/lab03

    # Update package.json
    print_step "Updating package.json..."
    if ! grep -q '"start": "node index.js"' package.json; then
        # Use a more robust way to edit JSON
        npm pkg set scripts.start="node index.js"
    fi

    # Install packages
    print_step "Installing npm packages..."
    npm install express body-parser child_process @google-cloud/storage

    # Deploy initial service
    deploy_cloud_run "$SERVICE_NAME" "$IMAGE_NAME" "$REGION" "128Mi" "" ""

    # Get service URL
    SERVICE_URL=$(gcloud beta run services describe "$SERVICE_NAME" \
        --platform managed \
        --region "$REGION" \
        --format="value(status.url)")

    print_status "Service URL: $SERVICE_URL"

    # Test service
    test_service "$SERVICE_URL"

    # Task 4: Create buckets and Pub/Sub setup
    print_step "Task 4: Setting up Cloud Storage and Pub/Sub"

    # Create buckets
    create_bucket "$UPLOAD_BUCKET"
    create_bucket "$PROCESSED_BUCKET"

    # Create Pub/Sub topic
    print_step "Creating Pub/Sub topic..."
    if gcloud pubsub topics create "$TOPIC_NAME" --quiet 2>/dev/null; then
        print_status "Pub/Sub topic created"
    else
        print_warning "Pub/Sub topic may already exist"
    fi

    # Create notification
    print_step "Creating Cloud Storage notification..."
    gsutil notification create -t "$TOPIC_NAME" -f json -e OBJECT_FINALIZE "gs://$UPLOAD_BUCKET" || true

    # Create service account
    create_service_account "$SERVICE_ACCOUNT_NAME" "PubSub Cloud Run Invoker"

    # Add IAM permissions
    add_iam_policy_binding "beta run services" "pdf-converter" \
        "serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        "roles/run.invoker" \
        "--platform managed --region $REGION"

    # Get project number
    PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format="value(project_number)")

    # Enable Pub/Sub service account
    add_iam_policy_binding "projects" "$PROJECT_ID" \
        "serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com" \
        "roles/iam.serviceAccountTokenCreator"

    # Create subscription
    print_step "Creating Pub/Sub subscription..."
    if gcloud beta pubsub subscriptions create "$SUBSCRIPTION_NAME" \
        --topic "$TOPIC_NAME" \
        --push-endpoint="$SERVICE_URL" \
        --push-auth-service-account="$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        --quiet 2>/dev/null; then
        print_status "Pub/Sub subscription created"
    else
        print_warning "Pub/Sub subscription may already exist"
    fi

    # Task 5: Test initial trigger
    print_step "Task 5: Testing Cloud Run trigger"

    # Upload test files
    print_step "Uploading test files..."
    gsutil -m cp gs://spls/gsp644/* "gs://$UPLOAD_BUCKET"

    print_status "Waiting 30 seconds for processing..."
    sleep 30

    # Clean up upload bucket
    gsutil -m rm "gs://$UPLOAD_BUCKET/*" 2>/dev/null || true

    # Task 6: Update container with LibreOffice
    print_step "Task 6: Updating container with LibreOffice support"

    # Update Dockerfile
    print_step "Updating Dockerfile..."
    if ! grep -q "libreoffice" Dockerfile; then
        # Add LibreOffice installation to Dockerfile
        sed -i '/FROM/a RUN apt-get update -y \\\n    && apt-get install -y libreoffice \\\n    && apt-get clean' Dockerfile
    fi

    # Update index.js with full functionality
    print_step "Updating index.js with PDF conversion logic..."

    # Create new index.js with full functionality
    cat > index.js << 'EOF'
const {promisify} = require('util');
const {Storage}   = require('@google-cloud/storage');
const exec        = promisify(require('child_process').exec);
const storage     = new Storage();
const express     = require('express');
const bodyParser  = require('body-parser');
const app         = express();

app.use(bodyParser.json());

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Listening on port', port);
});

app.post('/', async (req, res) => {
  try {
    const file = decodeBase64Json(req.body.message.data);
    await downloadFile(file.bucket, file.name);
    const pdfFileName = await convertFile(file.name);
    await uploadFile(process.env.PDF_BUCKET, pdfFileName);
    await deleteFile(file.bucket, file.name);
  }
  catch (ex) {
    console.log(`Error: ${ex}`);
  }
  res.set('Content-Type', 'text/plain');
  res.send('\n\nOK\n\n');
})

function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}

// Helper function to check file existence (using fs.promises for async)
async function fileExists(filePath) {
  try {
    await fs.promises.access(filePath); // Throws an error if the file doesn't exist
    return true;
  } catch (err) {
    return false;
  }
}
async function downloadFile(bucketName, fileName) {
  // 1. Check if the file exists
  const fileExistsLocally = await fileExists(`/tmp/${fileName}`);

  // 2. Delete if present
  if (fileExistsLocally) {
    console.log(`File exists locally. Deleting: ${fileName}`);
    await fs.promises.unlink(`/tmp/${fileName}`); // Use fs.promises for async file operations
    console.log(`File deleted.`);
  } else {
    console.log(`File does not exist locally: ${fileName}`);
  }

  // 3. Download from the storage bucket
  const options = { destination: `/tmp/${fileName}` };
  await storage.bucket(bucketName).file(fileName).download(options);
  console.log(`File downloaded: ${fileName}`);
}

async function convertFile(fileName) {
  const cmd = 'libreoffice --headless --convert-to pdf --outdir /tmp ' +
              `"/tmp/${fileName}"`;
  console.log(cmd);
  const { stdout, stderr } = await exec(cmd);
  if (stderr) {
    console.log(`Conversion Failed: ${stderr}`);
    throw stderr;
  }
  console.log(`Conversion Success: ${stdout}`);
  pdfFileName = fileName.replace(/\.\w+$/, '.pdf');
  return pdfFileName;
}

async function deleteFile(bucketName, fileName) {
  await storage.bucket(bucketName).file(fileName).delete();
}

async function uploadFile(bucketName, fileName) {
  await storage.bucket(bucketName).upload(`/tmp/${fileName}`);
}
EOF

    # Deploy updated service
    deploy_cloud_run "$SERVICE_NAME" "$IMAGE_NAME" "$REGION" "2Gi" \
        "--set-env-vars PDF_BUCKET=$PROCESSED_BUCKET" ""

    # Task 7: Final testing
    print_step "Task 7: Final testing of PDF conversion service"

    # Test service
    test_service "$SERVICE_URL"

    # Create upload script
    print_step "Creating file upload script..."
    cat > copy_files.sh << EOF
#!/bin/bash

SOURCE_BUCKET="gs://spls/gsp644"
DESTINATION_BUCKET="gs://${UPLOAD_BUCKET}"
DELAY=5

# Get a list of files in the source bucket
files=\$(gsutil ls "\$SOURCE_BUCKET")

# Loop through the files
for file in \$files; do
  # Construct the full path of the source file
  source_file_path="\$file"

  # Copy the file to the destination bucket
  gsutil cp "\$source_file_path" "\$DESTINATION_BUCKET"

  # Check if the copy was successful
  if [ \$? -eq 0 ]; then  # \$? is the exit status of the previous command
    echo "Copied: \$source_file_path to \$DESTINATION_BUCKET"
  else
    echo "Failed to copy: \$source_file_path"
  fi

  # Sleep for 5 seconds
  sleep \$DELAY
done

echo "All files copied!"
EOF

    chmod +x copy_files.sh

    # Upload test files
    print_step "Uploading test files for conversion..."
    ./copy_files.sh

    print_status "Waiting for file processing (this may take a few minutes)..."
    sleep 60

    # Check results
    print_step "Checking conversion results..."
    PROCESSED_FILES=$(gsutil ls "gs://$PROCESSED_BUCKET" | wc -l)
    print_status "Found $PROCESSED_FILES processed files in gs://$PROCESSED_BUCKET"

    echo
    echo "=================================================="
    print_status "Lab GSP644 setup completed successfully!"
    echo
    echo -e "${BLUE}Service Details:${NC}"
    echo "  Service URL: $SERVICE_URL"
    echo "  Upload Bucket: gs://$UPLOAD_BUCKET"
    echo "  Processed Bucket: gs://$PROCESSED_BUCKET"
    echo
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Check Cloud Logging for conversion logs"
    echo "2. Verify PDF files in the processed bucket"
    echo "3. Upload your own files to test the service"
    echo
    echo -e "${YELLOW}To clean up resources, run:${NC}"
    echo "  gcloud run services delete $SERVICE_NAME"
    echo "  gsutil rm -r gs://$UPLOAD_BUCKET"
    echo "  gsutil rm -r gs://$PROCESSED_BUCKET"
    echo "  gcloud pubsub topics delete $TOPIC_NAME"
    echo "  gcloud pubsub subscriptions delete $SUBSCRIPTION_NAME"
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
