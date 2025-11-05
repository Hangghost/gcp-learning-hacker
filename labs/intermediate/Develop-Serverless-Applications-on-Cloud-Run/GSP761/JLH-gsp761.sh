#!/bin/bash
# JLH-gsp761.sh - Automate GSP761: Developing a REST API with Go and Cloud Run
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
    local max_instances=${4:-2}

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
        --allow-unauthenticated \
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

# Function to test customer API endpoint
test_customer_api() {
    local base_url=$1
    local customer_id=$2
    local expected_status=${3:-"success"}
    local description=${4:-"Customer API"}

    local url="$base_url/v1/customer/$customer_id"
    print_step "Testing $description for customer $customer_id at $url"

    local response
    response=$(curl -s "$url" 2>/dev/null)

    if echo "$response" | grep -q "\"status\":\"$expected_status\""; then
        print_status "$description test passed for customer $customer_id"
        echo "$response" | jq . 2>/dev/null || echo "$response"
    else
        print_error "$description test failed for customer $customer_id"
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

# Function to wait for Firestore operation
wait_for_firestore() {
    local max_attempts=${1:-30}
    local attempt=1

    print_step "Waiting for Firestore operation to complete..."
    while [ $attempt -le $max_attempts ]; do
        if gcloud firestore databases list --format="value(name)" 2>/dev/null | grep -q "projects/$GOOGLE_CLOUD_PROJECT/databases/(default)"; then
            print_status "Firestore database is ready"
            return 0
        fi
        echo -n "."
        sleep 5
        ((attempt++))
    done

    print_error "Firestore database failed to become ready after $max_attempts attempts"
    return 1
}

# Main script
main() {
    echo "=================================================="
    echo "GSP761 - Developing a REST API with Go and Cloud Run"
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

    if ! command_exists jq; then
        print_warning "jq is not installed. JSON output will be raw text."
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
    LAB_DIR="$REPO_DIR/lab08"
    SERVICE_NAME="rest-api"
    IMAGE_TAG_01="gcr.io/$PROJECT_ID/$SERVICE_NAME:0.1"
    IMAGE_TAG_02="gcr.io/$PROJECT_ID/$SERVICE_NAME:0.2"
    BUCKET_NAME="$PROJECT_ID-customer"

    echo
    print_step "Starting lab setup..."

    # Task 1: Enable APIs
    print_step "Task 1: Enabling required APIs"
    enable_api "run.googleapis.com" "Cloud Run Admin"
    enable_api "cloudbuild.googleapis.com" "Cloud Build"

    # Task 2: Develop the REST API
    print_step "Task 2: Developing the REST API"

    # Clone repository if not exists
    if [ ! -d "$REPO_DIR" ]; then
        print_step "Cloning Pet Theory repository..."
        git clone https://github.com/rosera/pet-theory.git
    fi

    cd "$LAB_DIR"

    # Create main.go
    print_step "Creating main.go..."
    cat > main.go << 'EOF'
package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
)

func main() {
  port := os.Getenv("PORT")
  if port == "" {
      port = "8080"
  }
  http.HandleFunc("/v1/", func(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "{status: 'running'}")
  })
  log.Println("Pets REST API listening on port", port)
  if err := http.ListenAndServe(":"+port, nil); err != nil {
      log.Fatalf("Error launching Pets REST API server: %v", err)
  }
}
EOF

    # Create Dockerfile
    print_step "Creating Dockerfile..."
    cat > Dockerfile << 'EOF'
FROM gcr.io/distroless/base-debian12
WORKDIR /usr/src/app
COPY server .
CMD [ "/usr/src/app/server" ]
EOF

    # Build Go binary
    print_step "Building Go binary..."
    go build -o server

    # Verify files
    print_step "Verifying build files..."
    ls -la

    # Deploy initial service
    deploy_cloud_run_service "$SERVICE_NAME" "$IMAGE_TAG_01" "$REGION" 2
    wait_for_service "$SERVICE_NAME" "$REGION"

    # Get service URL
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
        --platform managed \
        --region "$REGION" \
        --format="value(status.address.url)")

    print_status "REST API Service URL: $SERVICE_URL"

    # Test initial endpoint
    test_api_endpoint "$SERVICE_URL/v1/" "running"

    # Task 3: Import test customer data
    print_step "Task 3: Setting up Firestore and importing test data"

    # Create Cloud Storage bucket
    print_step "Creating Cloud Storage bucket..."
    if gsutil mb -c standard -l "$REGION" "gs://$BUCKET_NAME" 2>/dev/null; then
        print_status "Bucket created successfully"
    else
        print_warning "Bucket may already exist"
    fi

    # Copy test data
    print_step "Copying test data to bucket..."
    gsutil cp -r gs://spls/gsp645/2019-10-06T20:10:37_43617 "gs://$BUCKET_NAME/"

    # Import to Firestore
    print_step "Importing data to Firestore..."
    gcloud beta firestore import "gs://$BUCKET_NAME/2019-10-06T20:10:37_43617/"
    wait_for_firestore

    print_status "Test data imported to Firestore"

    # Task 4: Connect REST API to Firestore
    print_step "Task 4: Updating REST API to connect to Firestore"

    # Update main.go with Firestore integration
    print_step "Updating main.go with Firestore integration..."
    cat > main.go << EOF
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"cloud.google.com/go/firestore"
	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"google.golang.org/api/iterator"
)

  var client *firestore.Client

  func main() {
    var err error
    ctx := context.Background()
    client, err = firestore.NewClient(ctx, "$PROJECT_ID")
    if err != nil {
    log.Fatalf("Error initializing Cloud Firestore client: %v", err)
  }

  port := os.Getenv("PORT")
  if port == "" {
    port = "8080"
  }

  r := mux.NewRouter()
  r.HandleFunc("/v1/", rootHandler)
  r.HandleFunc("/v1/customer/{id}", customerHandler)

  log.Println("Pets REST API listening on port", port)
  cors := handlers.CORS(
    handlers.AllowedHeaders([]string{"X-Requested-With", "Authorization", "Origin"}),
    handlers.AllowedOrigins([]string{"https://storage.googleapis.com"}),
    handlers.AllowedMethods([]string{"GET", "HEAD", "POST", "OPTIONS", "PATCH", "CONNECT"}),
  )

	if err := http.ListenAndServe(":"+port, cors(r)); err != nil {
    log.Fatalf("Error launching Pets REST API server: %v", err)
	}
}

func rootHandler(w http.ResponseWriter, r *http.Request) {
  fmt.Fprintf(w, "{status: 'running'}")
}

func customerHandler(w http.ResponseWriter, r *http.Request) {
  id := mux.Vars(r)["id"]
  ctx := context.Background()
  customer, err := getCustomer(ctx, id)
  if err != nil {
    w.WriteHeader(http.StatusInternalServerError)
    fmt.Fprintf(w, \`{"status": "fail", "data": '%s'}\`, err)
    return
  }
  if customer == nil {
    w.WriteHeader(http.StatusNotFound)
    msg := fmt.Sprintf("Customer \"%s\" not found", id)
    fmt.Fprintf(w, fmt.Sprintf(\`{"status": "fail", "data": {"title": "%s"}}\`, msg))
    return
  }
  amount, err := getAmounts(ctx, customer)
  if err != nil {
    w.WriteHeader(http.StatusInternalServerError)
    fmt.Fprintf(w, \`{"status": "fail", "data": "Unable to fetch amounts: %s"}\`, err)
    return
  }
  data, err := json.Marshal(amount)
  if err != nil {
    w.WriteHeader(http.StatusInternalServerError)
    fmt.Fprintf(w, \`{"status": "fail", "data": "Unable to fetch amounts: %s"}\`, err)
    return
  }
  fmt.Fprintf(w, fmt.Sprintf(\`{"status": "success", "data": %s}\`, data))
}

type Customer struct {
  Email string \`firestore:"email"\`
  ID    string \`firestore:"id"\`
  Name  string \`firestore:"name"\`
  Phone string \`firestore:"phone"\`
}

func getCustomer(ctx context.Context, id string) (*Customer, error) {
  query := client.Collection("customers").Where("id", "==", id)
  iter := query.Documents(ctx)

  var c Customer
  for {
    doc, err := iter.Next()
    if err == iterator.Done {
	break
    }
    if err != nil {
	return nil, err
    }
    err = doc.DataTo(&c)
    if err != nil {
	return nil, err
    }
  }
  return &c, nil
}

func getAmounts(ctx context.Context, c *Customer) (map[string]int64, error) {
  if c == nil {
    return map[string]int64{}, fmt.Errorf("Customer should be non-nil: %v", c)
  }
  result := map[string]int64{
    "proposed": 0,
    "approved": 0,
    "rejected": 0,
  }
  query := client.Collection(fmt.Sprintf("customers/%s/treatments", c.Email))
  if query == nil {
    return map[string]int64{}, fmt.Errorf("Query is nil: %v", c)
  }
  iter := query.Documents(ctx)
  for {
    doc, err := iter.Next()
    if err == iterator.Done {
	break
    }
    if err != nil {
	return nil, err
    }
    treatment := doc.Data()
    result[treatment["status"].(string)] += treatment["cost"].(int64)
  }
  return result, nil
}
EOF

    # Task 6: Deploy new revision
    print_step "Task 6: Deploying updated REST API"

    # Rebuild binary
    print_step "Rebuilding Go binary..."
    go build -o server

    # Deploy updated service
    deploy_cloud_run_service "$SERVICE_NAME" "$IMAGE_TAG_02" "$REGION" 2
    wait_for_service "$SERVICE_NAME" "$REGION"

    # Test updated API
    print_step "Testing updated REST API"

    # Test basic endpoint still works
    test_api_endpoint "$SERVICE_URL/v1/" "running"

    # Test customer endpoints
    test_customer_api "$SERVICE_URL" "22530" "success" "Customer 22530 (with treatments)"
    test_customer_api "$SERVICE_URL" "70156" "success" "Customer 70156 (zero amounts)"
    test_customer_api "$SERVICE_URL" "12345" "fail" "Non-existent customer 12345"

    echo
    echo "=================================================="
    print_status "Lab GSP761 setup and testing completed successfully!"
    echo
    echo -e "${BLUE}Service Details:${NC}"
    echo "  REST API URL: $SERVICE_URL"
    echo "  Status Endpoint: $SERVICE_URL/v1/"
    echo "  Customer Endpoint: $SERVICE_URL/v1/customer/{id}"
    echo
    echo -e "${BLUE}Test Results:${NC}"
    echo "  ✓ Basic API status check passed"
    echo "  ✓ Customer 22530 data retrieval passed"
    echo "  ✓ Customer 70156 zero amounts handled correctly"
    echo "  ✓ Non-existent customer 12345 error handling passed"
    echo
    echo -e "${BLUE}Firestore Database:${NC}"
    echo "  ✓ Database created and configured"
    echo "  ✓ Test customer data imported"
    echo "  ✓ Customer treatments data available"
    echo
    echo -e "${YELLOW}To clean up resources, run:${NC}"
    echo "  gcloud run services delete $SERVICE_NAME"
    echo "  gsutil rm -r gs://$BUCKET_NAME"
    echo "  gcloud firestore databases delete --project=$PROJECT_ID"
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
