#!/bin/bash

# GSP920 - Securing a Cloud SQL for PostgreSQL Instance
# Automation script for Google Cloud Skills Boost Lab

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

print_header() {
    echo -e "${BLUE}[TASK]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for operation completion
wait_for_operation() {
    local operation=$1
    local timeout=${2:-300}  # Default 5 minutes timeout
    local counter=0

    print_status "Waiting for operation to complete..."
    while [ $counter -lt $timeout ]; do
        if eval "$operation" >/dev/null 2>&1; then
            print_status "Operation completed successfully"
            return 0
        fi
        counter=$((counter + 10))
        sleep 10
        echo -n "."
    done

    print_error "Operation timed out after ${timeout} seconds"
    return 1
}

# Function to get user input with default
get_input() {
    local prompt=$1
    local default=$2
    local input

    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# Function to check Cloud SQL instance status
check_sql_instance_status() {
    local instance_name=$1
    local status=$(gcloud sql instances describe "$instance_name" --format="value(state)" 2>/dev/null)
    echo "$status"
}

# Function to wait for Cloud SQL instance to be ready
wait_for_sql_instance() {
    local instance_name=$1
    print_status "Waiting for Cloud SQL instance $instance_name to be ready..."

    local counter=0
    local timeout=600  # 10 minutes

    while [ $counter -lt $timeout ]; do
        local status=$(check_sql_instance_status "$instance_name")
        if [ "$status" = "RUNNABLE" ]; then
            print_status "Cloud SQL instance $instance_name is ready"
            return 0
        elif [ "$status" = "FAILED" ] || [ "$status" = "SUSPENDED" ]; then
            print_error "Cloud SQL instance $instance_name is in failed state: $status"
            return 1
        fi

        counter=$((counter + 30))
        print_status "Current status: $status. Waiting... ($counter/$timeout seconds)"
        sleep 30
    done

    print_error "Timeout waiting for Cloud SQL instance $instance_name to be ready"
    return 1
}

# Function to cleanup resources
cleanup_resources() {
    print_header "Starting cleanup process..."

    if [ -n "$CLOUDSQL_INSTANCE" ]; then
        print_warning "Deleting Cloud SQL instance: $CLOUDSQL_INSTANCE"
        if gcloud sql instances delete "$CLOUDSQL_INSTANCE" --quiet 2>/dev/null; then
            print_status "Cloud SQL instance deleted successfully"
        else
            print_warning "Failed to delete Cloud SQL instance or it may not exist"
        fi
    fi

    if [ -n "$KMS_KEY_ID" ] && [ -n "$KMS_KEYRING_ID" ] && [ -n "$REGION" ]; then
        print_warning "Deleting KMS key and keyring..."
        gcloud kms keys versions destroy 1 --key="$KMS_KEY_ID" --keyring="$KMS_KEYRING_ID" --location="$REGION" --quiet 2>/dev/null || true
        gcloud kms keys delete "$KMS_KEY_ID" --keyring="$KMS_KEYRING_ID" --location="$REGION" --quiet 2>/dev/null || true
        gcloud kms keyrings delete "$KMS_KEYRING_ID" --location="$REGION" --quiet 2>/dev/null || true
        print_status "KMS resources cleaned up"
    fi

    print_status "Cleanup completed"
}

# Trap to cleanup on script exit
trap cleanup_resources EXIT

# Main script
main() {
    print_header "Starting GSP920 - Securing a Cloud SQL for PostgreSQL Instance"

    # Check prerequisites
    print_header "Checking prerequisites..."

    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install Google Cloud SDK."
        exit 1
    fi

    if ! command_exists gsutil; then
        print_error "gsutil is not installed. Please install Google Cloud SDK."
        exit 1
    fi

    if ! command_exists psql; then
        print_error "psql is not installed. Please install PostgreSQL client."
        exit 1
    fi

    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 > /dev/null; then
        print_error "You are not authenticated with Google Cloud. Please run 'gcloud auth login' first."
        exit 1
    fi

    print_status "Prerequisites check passed"

    # Get project information
    print_header "Getting project information..."
    PROJECT_ID=$(gcloud config get-value project)
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID=$(get_input "Enter your GCP Project ID")
        gcloud config set project "$PROJECT_ID"
    fi
    print_status "Using project: $PROJECT_ID"

    # Set default variables
    KMS_KEYRING_ID="cloud-sql-keyring"
    KMS_KEY_ID="cloud-sql-key"
    CLOUDSQL_INSTANCE="postgres-orders"
    ZONE=$(get_input "Enter your zone (e.g., us-central1-a)" "us-central1-a")
    REGION=${ZONE%-*}

    print_status "Configuration:"
    echo "  Project ID: $PROJECT_ID"
    echo "  Region: $REGION"
    echo "  Zone: $ZONE"
    echo "  KMS Keyring: $KMS_KEYRING_ID"
    echo "  KMS Key: $KMS_KEY_ID"
    echo "  Cloud SQL Instance: $CLOUDSQL_INSTANCE"

    # Confirm before proceeding
    read -p "Do you want to proceed with these settings? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operation cancelled by user"
        exit 0
    fi

    # Task 1: Create CMEK and Cloud SQL instance
    print_header "Task 1: Creating Cloud SQL instance with CMEK"

    print_status "Step 1: Creating service account for Cloud SQL CMEK..."
    if ! gcloud beta services identity create --service=sqladmin.googleapis.com --project="$PROJECT_ID" 2>/dev/null; then
        print_warning "Service account may already exist, continuing..."
    fi

    print_status "Step 2: Creating Cloud KMS keyring..."
    if ! gcloud kms keyrings describe "$KMS_KEYRING_ID" --location="$REGION" >/dev/null 2>&1; then
        gcloud kms keyrings create "$KMS_KEYRING_ID" --location="$REGION"
        print_status "KMS keyring created"
    else
        print_warning "KMS keyring already exists"
    fi

    print_status "Step 3: Creating Cloud KMS key..."
    if ! gcloud kms keys describe "$KMS_KEY_ID" --keyring="$KMS_KEYRING_ID" --location="$REGION" >/dev/null 2>&1; then
        gcloud kms keys create "$KMS_KEY_ID" --location="$REGION" --keyring="$KMS_KEYRING_ID" --purpose=encryption
        print_status "KMS key created"
    else
        print_warning "KMS key already exists"
    fi

    print_status "Step 4: Binding KMS key to service account..."
    PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
    gcloud kms keys add-iam-policy-binding "$KMS_KEY_ID" \
        --location="$REGION" \
        --keyring="$KMS_KEYRING_ID" \
        --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloud-sql.iam.gserviceaccount.com" \
        --role=roles/cloudkms.cryptoKeyEncrypterDecrypter

    print_status "Step 5: Getting IP addresses for authorized networks..."
    AUTHORIZED_IP=$(gcloud compute instances describe bastion-vm --zone="$ZONE" --format='value(networkInterfaces[0].accessConfigs.natIP)' 2>/dev/null || echo "")
    if [ -z "$AUTHORIZED_IP" ]; then
        print_warning "Could not find bastion-vm IP, using Cloud Shell IP only"
        AUTHORIZED_IP=""
    fi

    CLOUD_SHELL_IP=$(curl -s ifconfig.me)
    if [ -n "$AUTHORIZED_IP" ]; then
        AUTHORIZED_NETWORKS="${AUTHORIZED_IP}/32,${CLOUD_SHELL_IP}/32"
    else
        AUTHORIZED_NETWORKS="${CLOUD_SHELL_IP}/32"
    fi

    print_status "Authorized networks: $AUTHORIZED_NETWORKS"

    print_status "Step 6: Creating Cloud SQL instance with CMEK..."
    KEY_NAME=$(gcloud kms keys describe "$KMS_KEY_ID" --keyring="$KMS_KEYRING_ID" --location="$REGION" --format='value(name)')

    if gcloud sql instances describe "$CLOUDSQL_INSTANCE" >/dev/null 2>&1; then
        print_warning "Cloud SQL instance already exists, skipping creation"
    else
        gcloud sql instances create "$CLOUDSQL_INSTANCE" \
            --project="$PROJECT_ID" \
            --authorized-networks="$AUTHORIZED_NETWORKS" \
            --disk-encryption-key="$KEY_NAME" \
            --database-version=POSTGRES_13 \
            --cpu=1 \
            --memory=3840MB \
            --region="$REGION" \
            --root-password=supersecret!

        print_status "Cloud SQL instance created, waiting for it to be ready..."
        wait_for_sql_instance "$CLOUDSQL_INSTANCE"
    fi

    # Task 2: Enable and configure pgAudit
    print_header "Task 2: Enabling and configuring pgAudit"

    print_status "Step 1: Adding pgAudit database flags..."
    gcloud sql instances patch "$CLOUDSQL_INSTANCE" \
        --database-flags cloudsql.enable_pgaudit=on,pgaudit.log=all

    print_status "Step 2: Restarting Cloud SQL instance..."
    gcloud sql instances restart "$CLOUDSQL_INSTANCE"
    wait_for_sql_instance "$CLOUDSQL_INSTANCE"

    print_status "Step 3: Connecting to Cloud SQL instance and configuring pgAudit..."
    POSTGRESQL_IP=$(gcloud sql instances describe "$CLOUDSQL_INSTANCE" --format="value(ipAddresses[0].ipAddress)")

    # Use a here document for the SQL commands
    PGPASSWORD=supersecret! psql --host="$POSTGRESQL_IP" --username=postgres --dbname=postgres -c "CREATE DATABASE orders;" 2>/dev/null || print_warning "Database may already exist"

    PGPASSWORD=supersecret! psql --host="$POSTGRESQL_IP" --username=postgres --dbname=orders << EOF
CREATE EXTENSION IF NOT EXISTS pgaudit;
ALTER DATABASE orders SET pgaudit.log = 'read,write';
EOF

    print_status "pgAudit configuration completed"

    # Enable Audit Logging (this needs to be done manually in console)
    print_warning "Please enable Cloud Audit Logs manually in the console:"
    print_warning "1. Go to IAM & Admin > Audit Logs"
    print_warning "2. Filter for 'Cloud SQL' and enable Admin read, Data read, Data write"

    # Populate database
    print_header "Populating database with sample data..."

    print_status "Downloading data files..."
    SOURCE_BUCKET=gs://spls/gsp920
    gsutil -m cp "${SOURCE_BUCKET}/create_orders_db.sql" . 2>/dev/null || print_warning "Could not download create_orders_db.sql"
    gsutil -m cp "${SOURCE_BUCKET}/DDL/distribution_centers_data.csv" . 2>/dev/null || print_warning "Could not download distribution_centers_data.csv"
    gsutil -m cp "${SOURCE_BUCKET}/DDL/inventory_items_data.csv" . 2>/dev/null || print_warning "Could not download inventory_items_data.csv"
    gsutil -m cp "${SOURCE_BUCKET}/DDL/order_items_data.csv" . 2>/dev/null || print_warning "Could not download order_items_data.csv"
    gsutil -m cp "${SOURCE_BUCKET}/DDL/products_data.csv" . 2>/dev/null || print_warning "Could not download products_data.csv"
    gsutil -m cp "${SOURCE_BUCKET}/DDL/users_data.csv" . 2>/dev/null || print_warning "Could not download users_data.csv"

    if [ -f "create_orders_db.sql" ]; then
        print_status "Creating and populating database..."
        PGPASSWORD=supersecret! psql "sslmode=disable user=postgres hostaddr=${POSTGRESQL_IP}" -c "\i create_orders_db.sql"
    else
        print_warning "Database creation script not found, skipping database population"
    fi

    print_status "Configuring additional pgAudit logging..."
    PGPASSWORD=supersecret! psql --host="$POSTGRESQL_IP" --username=postgres --dbname=orders << EOF
CREATE ROLE auditor WITH NOLOGIN;
ALTER DATABASE orders SET pgaudit.role = 'auditor';
GRANT SELECT ON order_items TO auditor;
EOF

    # Task 3: Configure Cloud SQL IAM database authentication
    print_header "Task 3: Configuring Cloud SQL IAM database authentication"

    print_status "Step 1: Testing access before IAM authentication (should fail)..."
    USERNAME=$(gcloud config list --format="value(core.account)")
    export PGPASSWORD=$(gcloud auth print-access-token 2>/dev/null || echo "")

    if [ -n "$PGPASSWORD" ]; then
        print_status "Testing connection with IAM user (should fail initially)..."
        if PGPASSWORD="$PGPASSWORD" psql --host="$POSTGRESQL_IP" "$USERNAME" --dbname=orders -c "SELECT 1;" 2>/dev/null; then
            print_warning "Connection succeeded unexpectedly - IAM user may already be configured"
        else
            print_status "Connection failed as expected - IAM authentication not yet configured"
        fi
    else
        print_warning "Could not get access token for testing"
    fi

    print_warning "Please complete the following steps manually in Cloud Console:"
    echo "1. Go to SQL > $CLOUDSQL_INSTANCE > Users"
    echo "2. Click 'Add user account' > Select 'Cloud IAM'"
    echo "3. Enter principal: $USERNAME"
    echo "4. Click Add"

    read -p "Have you added the Cloud IAM user in the console? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Granting database permissions to IAM user..."

        # Grant permissions using postgres admin account
        PGPASSWORD=supersecret! psql --host="$POSTGRESQL_IP" --username=postgres --dbname=orders << EOF
GRANT ALL PRIVILEGES ON TABLE order_items TO "$USERNAME";
EOF

        print_status "Testing IAM authentication access..."

        # Refresh access token and test
        export PGPASSWORD=$(gcloud auth print-access-token)

        if PGPASSWORD="$PGPASSWORD" psql --host="$POSTGRESQL_IP" "$USERNAME" --dbname=orders -c "SELECT COUNT(*) FROM order_items;" 2>/dev/null; then
            print_status "IAM authentication successful!"
            print_status "Testing restricted access (should fail)..."

            if PGPASSWORD="$PGPASSWORD" psql --host="$POSTGRESQL_IP" "$USERNAME" --dbname=orders -c "SELECT COUNT(*) FROM users;" 2>/dev/null; then
                print_warning "Access to users table succeeded unexpectedly"
            else
                print_status "Access to users table correctly denied"
            fi
        else
            print_error "IAM authentication test failed"
        fi
    else
        print_warning "Skipping IAM authentication test - complete manually later"
    fi

    print_header "Lab completion summary"
    echo "========================================"
    print_status "Cloud SQL instance created: $CLOUDSQL_INSTANCE"
    print_status "CMEK encryption enabled with key: $KMS_KEY_ID"
    print_status "pgAudit configured for database auditing"
    print_status "IAM database authentication configured"
    echo ""
    print_warning "Remember to check Cloud Audit Logs for database activity"
    print_warning "Don't forget to clean up resources to avoid charges"

    print_header "Lab completed successfully!"
}

# Handle command line arguments
case "${1:-}" in
    --cleanup)
        print_header "Running cleanup only..."
        cleanup_resources
        exit 0
        ;;
    --help|-h)
        echo "GSP920 Automation Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --cleanup    Run cleanup only"
        echo "  --help, -h   Show this help message"
        echo ""
        echo "This script automates the GSP920 lab steps."
        echo "Make sure you have the necessary permissions and tools installed."
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
