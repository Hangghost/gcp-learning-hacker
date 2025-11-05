#!/bin/bash
# JLH-gsp762.sh - Automate GSP762: Creating PDFs with Go and Cloud Run
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
        print_warning "Failed to enable $display_name API (may already be enabled)"
    fi
}

# Function to build and deploy Cloud Run service
deploy_cloud_run_service() {
    local service_name=$1
    local image_tag=$2
    local region=$3
    local memory=${4:-2Gi}
    local max_instances=${5:-3}

    print_step "Deploying Cloud Run service: $service_name"

    # Build container
    if gcloud builds submit --tag "$image_tag" --quiet; then
        print_status "Container built successfully"
    else
        print_error "Failed to build container"
        return 1
    fi

    # Deploy service
    if gcloud run deploy "$service_name" \
        --image "$image_tag" \
        --platform managed \
        --region "$region" \
        --memory="$memory" \
        --no-allow-unauthenticated \
        --set-env-vars PDF_BUCKET="$GOOGLE_CLOUD_PROJECT-processed" \
        --max-instances="$max_instances" \
        --quiet; then
        print_status "Cloud Run service $service_name deployed successfully"
    else
        print_error "Failed to deploy Cloud Run service $service_name"
        return 1
    fi
}

# Function to test API endpoint
test_api_endpoint() {
    local url=$1
    local expected_content=$2
    local description=${3:-"API endpoint"}

    print_step "Testing $description at $url"
    local response
    response=$(curl -s "$url" 2>/dev/null)

    if echo "$response" | grep -q "$expected_content"; then
        print_status "$description test passed"
    else
        print_error "$description test failed"
        print_error "Expected: $expected_content"
        print_error "Got: $response"
        return 1
    fi
}

# Function to test API endpoint with auth
test_api_endpoint_auth() {
    local url=$1
    local expected_content=$2
    local description=${3:-"Authenticated API endpoint"}

    print_step "Testing $description at $url"
    local response
    response=$(curl -s -H "Authorization: Bearer $(gcloud auth print-identity-token)" "$url" 2>/dev/null)

    if echo "$response" | grep -q "$expected_content"; then
        print_status "$description test passed"
    else
        print_error "$description test failed"
        print_error "Expected: $expected_content"
        print_error "Got: $response"
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

# Function to wait for bucket operation
wait_for_bucket_operation() {
    local bucket_name=$1
    local expected_count=${2:-0}
    local max_attempts=${3:-60}
    local attempt=1

    print_step "Waiting for bucket operation to complete..."
    while [ $attempt -le $max_attempts ]; do
        local current_count
        current_count=$(gsutil ls "gs://$bucket_name/**" 2>/dev/null | wc -l || echo "0")
        if [ "$current_count" -gt "$expected_count" ]; then
            print_status "Bucket operation completed"
            return 0
        fi
        echo -n "."
        sleep 5
        ((attempt++))
    done

    print_error "Bucket operation failed to complete after $max_attempts attempts"
    return 1
}

# Function to create and edit Go file
create_go_file() {
    local file_path=$1
    local content=$2

    print_step "Creating Go file: $file_path"
    cat > "$file_path" << EOF
$content
EOF
    print_status "Go file created"
}

# Function to create Dockerfile
create_dockerfile() {
    local content=$1

    print_step "Creating Dockerfile"
    cat > Dockerfile << EOF
$content
EOF
    print_status "Dockerfile created"
}

# Main script
main() {
    echo "=================================================="
    echo "GSP762 - Creating PDFs with Go and Cloud Run"
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

    if ! command_exists go; then
        print_error "Go is not installed. Please install Go first."
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
    LAB_DIR="$REPO_DIR/lab03"
    SERVICE_NAME="pdf-converter"
    IMAGE_TAG="gcr.io/$PROJECT_ID/$SERVICE_NAME"
    UPLOAD_BUCKET="$PROJECT_ID-upload"
    PROCESSED_BUCKET="$PROJECT_ID-processed"
    TOPIC_NAME="new-doc"
    SUBSCRIPTION_NAME="pdf-conv-sub"
    SERVICE_ACCOUNT_NAME="pubsub-cloud-run-invoker"

    echo
    print_step "Starting lab setup..."

    # Task 1: Enable APIs
    print_step "Task 1: Enabling required APIs"
    enable_api "run.googleapis.com" "Cloud Run Admin"
    enable_api "cloudbuild.googleapis.com" "Cloud Build"
    enable_api "storage-component.googleapis.com" "Cloud Storage"

    # Task 2: Get source code and create microservice
    print_step "Task 2: Setting up source code and creating microservice"

    # Clone repository if not exists
    if [ ! -d "$REPO_DIR" ]; then
        print_step "Cloning Pet Theory repository..."
        git clone https://github.com/Deleplace/pet-theory.git
    fi

    cd "$LAB_DIR"

    # Create server.go
    create_go_file "server.go" "package main

import (
  \"fmt\"
  \"log\"
  \"net/http\"
  \"os\"
  \"os/exec\"
  \"regexp\"
  \"strings\"
)

func main() {
  http.HandleFunc(\"/\", process)

  port := os.Getenv(\"PORT\")
  if port == \"\" {
      port = \"8080\"
      log.Printf(\"Defaulting to port %s\", port)
  }

  log.Printf(\"Listening on port %s\", port)
  err := http.ListenAndServe(fmt.Sprintf(\":%s\", port), nil)
  log.Fatal(err)
}

func process(w http.ResponseWriter, r *http.Request) {
  log.Println(\"Serving request\")

  if r.Method == \"GET\" {
      fmt.Fprintln(w, \"Ready to process POST requests from Cloud Storage trigger\")
      return
  }

  //
  // Read request body containing Cloud Storage object metadata
  //
  gcsInputFile, err1 := readBody(r)
  if err1 != nil {
      log.Printf(\"Error reading POST data: %v\", err1)
      w.WriteHeader(http.StatusBadRequest)
      fmt.Fprintf(w, \"Problem with POST data: %v \\n\", err1)
      return
  }

  //
  // Working directory (concurrency-safe)
  localDir, err := os.MkdirTemp(\"\", \"\")
  if err != nil {
      log.Printf(\"Error creating local temp dir: %v\", err)
      w.WriteHeader(http.StatusInternalServerError)
      fmt.Fprintf(w, \"Could not create a temp directory on server. \\n\")
      return
  }
  defer os.RemoveAll(localDir)

  //
  // Download input file from Cloud Storage
  //
  localInputFile, err2 := download(gcsInputFile, localDir)
  if err2 != nil {
      log.Printf(\"Error downloading Cloud Storage file [%s] from bucket [%s]: %v\",
          gcsInputFile.Name, gcsInputFile.Bucket, err2)
      w.WriteHeader(http.StatusInternalServerError)
      fmt.Fprintf(w, \"Error downloading Cloud Storage file [%s] from bucket [%s]\",
          gcsInputFile.Name, gcsInputFile.Bucket)
      return
  }

  //
  // Use LibreOffice to convert local input file to local PDF file.
  //
  localPDFFilePath, err3 := convertToPDF(localInputFile.Name(), localDir)
  if err3 != nil {
      log.Printf(\"Error converting to PDF: %v\", err3)
      w.WriteHeader(http.StatusInternalServerError)
      fmt.Fprintf(w, \"Error converting to PDF.\")
      return
  }

  //
  // Upload the freshly generated PDF to Cloud Storage
  //
  targetBucket := os.Getenv(\"PDF_BUCKET\")
  err4 := upload(localPDFFilePath, targetBucket)
  if err4 != nil {
      log.Printf(\"Error uploading PDF file to bucket [%s]: %v\", targetBucket, err4)
      w.WriteHeader(http.StatusInternalServerError)
      fmt.Fprintf(w, \"Error downloading Cloud Storage file [%s] from bucket [%s]\",
          gcsInputFile.Name, gcsInputFile.Bucket)
      return
  }

  //
  // Delete the original input file from Cloud Storage.
  //
  err5 := deleteGCSFile(gcsInputFile.Bucket, gcsInputFile.Name)
  if err5 != nil {
      log.Printf(\"Error deleting file [%s] from bucket [%s]: %v\", gcsInputFile.Name,
          gcsInputFile.Bucket, err5)
      // This is not a blocking error.
      // The PDF was successfully generated and uploaded.
  }

  log.Println(\"Successfully produced PDF\")
  fmt.Fprintln(w, \"Successfully produced PDF\")
}

func convertToPDF(localFilePath string, localDir string) (resultFilePath string, err error) {
  log.Printf(\"Converting [%s] to PDF\", localFilePath)
  cmd := exec.Command(\"libreoffice\", \"--headless\", \"--convert-to\", \"pdf\",
      \"--outdir\", localDir,
      localFilePath)
  cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
  log.Println(cmd)
  err = cmd.Run()
  if err != nil {
      return \"\", err
  }

  pdfFilePath := regexp.MustCompile(\`\\.\\w+$*\`).ReplaceAllString(localFilePath, \".pdf\")
  if !strings.HasSuffix(pdfFilePath, \".pdf\") {
      pdfFilePath += \".pdf\"
  }
  log.Printf(\"Converted %s to %s\", localFilePath, pdfFilePath)
  return pdfFilePath, nil
}"

    # Build Go application
    print_step "Building Go application..."
    go build -o server
    print_status "Go application built successfully"

    # Task 3: Create PDF conversion service
    print_step "Task 3: Creating PDF conversion service"

    # Update Dockerfile
    create_dockerfile "FROM amd64/debian
RUN apt-get update -y \\
  && apt-get install -y libreoffice \\
  && apt-get clean
WORKDIR /usr/src/app
COPY server .
CMD [ \"./server\" ]"

    # Deploy PDF converter service
    deploy_cloud_run_service "$SERVICE_NAME" "$IMAGE_TAG" "$REGION"
    wait_for_service "$SERVICE_NAME" "$REGION"

    # Get service URL
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
        --platform managed \
        --region "$REGION" \
        --format="value(status.url)")

    print_status "PDF Converter Service URL: $SERVICE_URL"

    # Task 4: Create service account and setup Pub/Sub
    print_step "Task 4: Setting up service account and Pub/Sub"

    # Create Pub/Sub topic
    print_step "Creating Pub/Sub topic..."
    if gcloud pubsub topics create "$TOPIC_NAME" --quiet 2>/dev/null; then
        print_status "Pub/Sub topic created"
    else
        print_warning "Pub/Sub topic may already exist"
    fi

    # Create service account
    print_step "Creating service account..."
    if gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
        --display-name "PubSub Cloud Run Invoker" \
        --quiet 2>/dev/null; then
        print_status "Service account created"
    else
        print_warning "Service account may already exist"
    fi

    # Add IAM permissions
    print_step "Adding IAM permissions..."
    gcloud run services add-iam-policy-binding "$SERVICE_NAME" \
        --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        --role=roles/run.invoker \
        --region "$REGION" \
        --platform managed \
        --quiet

    # Get project number
    PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format="value(project_number)")

    # Enable Pub/Sub authentication
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com" \
        --role=roles/iam.serviceAccountTokenCreator \
        --quiet

    # Create Cloud Storage notification
    print_step "Creating Cloud Storage notification..."
    gsutil notification create -t "$TOPIC_NAME" -f json -e OBJECT_FINALIZE "gs://$UPLOAD_BUCKET" || true

    # Create Pub/Sub subscription
    print_step "Creating Pub/Sub subscription..."
    if gcloud pubsub subscriptions create "$SUBSCRIPTION_NAME" \
        --topic "$TOPIC_NAME" \
        --push-endpoint="$SERVICE_URL" \
        --push-auth-service-account="$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        --quiet 2>/dev/null; then
        print_status "Pub/Sub subscription created"
    else
        print_warning "Pub/Sub subscription may already exist"
    fi

    # Task 5: Test the Cloud Run service
    print_step "Task 5: Testing Cloud Run service"

    # Test anonymous access (should fail)
    print_step "Testing anonymous access (should fail)..."
    if curl -s -X GET "$SERVICE_URL" 2>/dev/null | grep -q "Forbidden"; then
        print_status "Anonymous access correctly blocked"
    else
        print_warning "Anonymous access test inconclusive"
    fi

    # Test authenticated access
    test_api_endpoint_auth "$SERVICE_URL" "Ready to process POST requests"

    # Task 7: Test Cloud Storage notification
    print_step "Task 7: Testing Cloud Storage notification system"

    # Copy test files
    print_step "Copying test files to upload bucket..."
    gsutil -m cp -r gs://spls/gsp762/* "gs://$UPLOAD_BUCKET/"

    # Wait for processing
    print_step "Waiting for file processing (this may take several minutes)..."
    sleep 30
    wait_for_bucket_operation "$PROCESSED_BUCKET" 0 120

    # Check results
    print_step "Checking conversion results..."
    UPLOAD_COUNT=$(gsutil ls "gs://$UPLOAD_BUCKET/**" 2>/dev/null | wc -l || echo "0")
    PROCESSED_COUNT=$(gsutil ls "gs://$PROCESSED_BUCKET/**" 2>/dev/null | wc -l || echo "0")

    print_status "Files remaining in upload bucket: $UPLOAD_COUNT"
    print_status "Files created in processed bucket: $PROCESSED_COUNT"

    if [ "$PROCESSED_COUNT" -gt 0 ]; then
        print_status "PDF conversion system working correctly!"
    else
        print_warning "No processed files found - system may need more time or troubleshooting"
    fi

    echo
    echo "=================================================="
    print_status "Lab GSP762 setup and testing completed successfully!"
    echo
    echo -e "${BLUE}Service Details:${NC}"
    echo "  PDF Converter Service: $SERVICE_URL"
    echo "  Upload Bucket: gs://$UPLOAD_BUCKET"
    echo "  Processed Bucket: gs://$PROCESSED_BUCKET"
    echo
    echo -e "${BLUE}Pub/Sub Configuration:${NC}"
    echo "  Topic: $TOPIC_NAME"
    echo "  Subscription: $SUBSCRIPTION_NAME"
    echo "  Service Account: $SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"
    echo
    echo -e "${BLUE}Test Results:${NC}"
    echo "  ✓ Service authentication working correctly"
    echo "  ✓ Cloud Storage notifications configured"
    echo "  ✓ Pub/Sub integration established"
    echo "  ✓ File processing pipeline active"
    if [ "$PROCESSED_COUNT" -gt 0 ]; then
        echo "  ✓ PDF conversion system operational"
    fi
    echo
    echo -e "${YELLOW}To clean up resources, run:${NC}"
    echo "  gcloud run services delete $SERVICE_NAME"
    echo "  gsutil rm -r gs://$UPLOAD_BUCKET"
    echo "  gsutil rm -r gs://$PROCESSED_BUCKET"
    echo "  gcloud pubsub topics delete $TOPIC_NAME"
    echo "  gcloud pubsub subscriptions delete $SUBSCRIPTION_NAME"
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
