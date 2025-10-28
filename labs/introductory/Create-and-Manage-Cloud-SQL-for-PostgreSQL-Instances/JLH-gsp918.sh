#!/bin/bash

# GSP918 - Create and Manage Cloud SQL for PostgreSQL Instances
# This script automates the lab steps for migrating PostgreSQL database to Cloud SQL

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Function to check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 command not found. Please install it first."
        exit 1
    fi
}

# Function to wait for user input
wait_for_user() {
    echo
    read -p "Press Enter to continue..."
}

# Function to prompt for required variables
setup_variables() {
    print_header "Setting up Lab Variables"

    echo "This script will help you complete the GSP918 lab."
    echo "Please provide the following information:"
    echo

    read -p "Enter your GCP Region (e.g., us-central1): " REGION
    read -p "Enter your GCP Zone (e.g., us-central1-a): " ZONE
    read -p "Enter your Project ID: " PROJECT_ID

    # Validate inputs
    if [[ -z "$REGION" || -z "$ZONE" || -z "$PROJECT_ID" ]]; then
        print_error "All fields are required!"
        exit 1
    fi

    print_success "Variables configured:"
    echo "  Region: $REGION"
    echo "  Zone: $ZONE"
    echo "  Project ID: $PROJECT_ID"
    echo
}

# Function to enable required APIs
enable_apis() {
    print_step "Enabling required APIs..."

    apis=(
        "databasemigration.googleapis.com"
        "servicenetworking.googleapis.com"
        "compute.googleapis.com"
        "sqladmin.googleapis.com"
    )

    for api in "${apis[@]}"; do
        print_step "Enabling $api..."
        if gcloud services enable $api --project=$PROJECT_ID; then
            print_success "$api enabled successfully"
        else
            print_warning "Failed to enable $api or it may already be enabled"
        fi
    done

    print_success "API setup completed"
    wait_for_user
}

# Function to prepare source database
prepare_source_database() {
    print_header "Task 1: Prepare the source database for migration"

    print_step "Connecting to postgresql-vm instance..."

    # Get the VM's external IP
    VM_IP=$(gcloud compute instances describe postgresql-vm \
        --zone=$ZONE \
        --project=$PROJECT_ID \
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

    if [[ -z "$VM_IP" ]]; then
        print_error "Could not find postgresql-vm instance. Please ensure it exists."
        exit 1
    fi

    print_success "VM IP: $VM_IP"

    # SSH into VM and run commands
    print_step "Installing pglogical extension..."
    gcloud compute ssh postgresql-vm --zone=$ZONE --project=$PROJECT_ID --command="
        sudo apt update
        sudo apt install -y postgresql-13-pglogical
    "

    print_step "Configuring PostgreSQL for pglogical..."
    gcloud compute ssh postgresql-vm --zone=$ZONE --project=$PROJECT_ID --command="
        sudo su - postgres -c 'gsutil cp gs://spls/gsp918/pg_hba_append.conf .'
        sudo su - postgres -c 'gsutil cp gs://spls/gsp918/postgresql_append.conf .'
        sudo su - postgres -c 'cat pg_hba_append.conf >> /etc/postgresql/13/main/pg_hba.conf'
        sudo su - postgres -c 'cat postgresql_append.conf >> /etc/postgresql/13/main/postgresql.conf'
        sudo systemctl restart postgresql@13-main
    "

    print_step "Creating pglogical extensions in databases..."
    gcloud compute ssh postgresql-vm --zone=$ZONE --project=$PROJECT_ID --command="
        sudo su - postgres -c 'psql -c \"CREATE EXTENSION pglogical;\" postgres'
        sudo su - postgres -c 'psql -c \"CREATE EXTENSION pglogical;\" orders'
        sudo su - postgres -c 'psql -c \"CREATE EXTENSION pglogical;\" gmemegen_db'
    "

    print_step "Creating migration_admin user..."
    gcloud compute ssh postgresql-vm --zone=$ZONE --project=$PROJECT_ID --command="
        sudo su - postgres -c \"psql -c \\\"CREATE USER migration_admin PASSWORD 'DMS_1s_cool!'; ALTER DATABASE orders OWNER TO migration_admin; ALTER ROLE migration_admin WITH REPLICATION;\\\" postgres\"
    "

    print_step "Granting permissions for postgres database..."
    gcloud compute ssh postgresql-vm --zone=$ZONE --project=$PROJECT_ID --command="
        sudo su - postgres -c \"
        psql -c \\\"
        \\\\c postgres;
        GRANT USAGE ON SCHEMA pglogical TO migration_admin;
        GRANT ALL ON SCHEMA pglogical TO migration_admin;
        GRANT SELECT ON pglogical.tables TO migration_admin;
        GRANT SELECT ON pglogical.depend TO migration_admin;
        GRANT SELECT ON pglogical.local_node TO migration_admin;
        GRANT SELECT ON pglogical.local_sync_status TO migration_admin;
        GRANT SELECT ON pglogical.node TO migration_admin;
        GRANT SELECT ON pglogical.node_interface TO migration_admin;
        GRANT SELECT ON pglogical.queue TO migration_admin;
        GRANT SELECT ON pglogical.replication_set TO migration_admin;
        GRANT SELECT ON pglogical.replication_set_seq TO migration_admin;
        GRANT SELECT ON pglogical.replication_set_table TO migration_admin;
        GRANT SELECT ON pglogical.sequence_state TO migration_admin;
        GRANT SELECT ON pglogical.subscription TO migration_admin;
        \\\" postgres
    "

    print_step "Granting permissions for orders database..."
    gcloud compute ssh postgresql-vm --zone=$ZONE --project=$PROJECT_ID --command="
        sudo su - postgres -c \"
        psql -c \\\"
        \\\\c orders;
        GRANT USAGE ON SCHEMA pglogical TO migration_admin;
        GRANT ALL ON SCHEMA pglogical TO migration_admin;
        GRANT SELECT ON pglogical.tables TO migration_admin;
        GRANT SELECT ON pglogical.depend TO migration_admin;
        GRANT SELECT ON pglogical.local_node TO migration_admin;
        GRANT SELECT ON pglogical.local_sync_status TO migration_admin;
        GRANT SELECT ON pglogical.node TO migration_admin;
        GRANT SELECT ON pglogical.node_interface TO migration_admin;
        GRANT SELECT ON pglogical.queue TO migration_admin;
        GRANT SELECT ON pglogical.replication_set TO migration_admin;
        GRANT SELECT ON pglogical.replication_set_seq TO migration_admin;
        GRANT SELECT ON pglogical.replication_set_table TO migration_admin;
        GRANT SELECT ON pglogical.sequence_state TO migration_admin;
        GRANT SELECT ON pglogical.subscription TO migration_admin;
        GRANT USAGE ON SCHEMA public TO migration_admin;
        GRANT ALL ON SCHEMA public TO migration_admin;
        GRANT SELECT ON public.distribution_centers TO migration_admin;
        GRANT SELECT ON public.inventory_items TO migration_admin;
        GRANT SELECT ON public.order_items TO migration_admin;
        GRANT SELECT ON public.products TO migration_admin;
        GRANT SELECT ON public.users TO migration_admin;
        \\\" postgres
    "

    print_step "Granting permissions for gmemegen_db database..."
    gcloud compute ssh postgresql-vm --zone=$ZONE --project=$PROJECT_ID --command="
        sudo su - postgres -c \"
        psql -c \\\"
        \\\\c gmemegen_db;
        GRANT USAGE ON SCHEMA pglogical TO migration_admin;
        GRANT ALL ON SCHEMA pglogical TO migration_admin;
        GRANT SELECT ON pglogical.tables TO migration_admin;
        GRANT SELECT ON pglogical.depend TO migration_admin;
        GRANT SELECT ON pglogical.local_node TO migration_admin;
        GRANT SELECT ON pglogical.local_sync_status TO migration_admin;
        GRANT SELECT ON pglogical.node TO migration_admin;
        GRANT SELECT ON pglogical.node_interface TO migration_admin;
        GRANT SELECT ON pglogical.queue TO migration_admin;
        GRANT SELECT ON pglogical.replication_set TO migration_admin;
        GRANT SELECT ON pglogical.replication_set_seq TO migration_admin;
        GRANT SELECT ON pglogical.replication_set_table TO migration_admin;
        GRANT SELECT ON pglogical.sequence_state TO migration_admin;
        GRANT SELECT ON pglogical.subscription TO migration_admin;
        GRANT USAGE ON SCHEMA public TO migration_admin;
        GRANT ALL ON SCHEMA public TO migration_admin;
        GRANT SELECT ON public.meme TO migration_admin;
        \\\" postgres
    "

    print_step "Changing table ownership in orders database..."
    gcloud compute ssh postgresql-vm --zone=$ZONE --project=$PROJECT_ID --command="
        sudo su - postgres -c \"
        psql -c \\\"
        \\\\c orders;
        ALTER TABLE public.distribution_centers OWNER TO migration_admin;
        ALTER TABLE public.inventory_items OWNER TO migration_admin;
        ALTER TABLE public.order_items OWNER TO migration_admin;
        ALTER TABLE public.products OWNER TO migration_admin;
        ALTER TABLE public.users OWNER TO migration_admin;
        \\\" postgres
    "

    print_success "Source database preparation completed"
    wait_for_user
}

# Function to create connection profile
create_connection_profile() {
    print_header "Task 2: Create Database Migration Service connection profile"

    # Get VM internal IP
    VM_INTERNAL_IP=$(gcloud compute instances describe postgresql-vm \
        --zone=$ZONE \
        --project=$PROJECT_ID \
        --format="value(networkInterfaces[0].networkIP)")

    if [[ -z "$VM_INTERNAL_IP" ]]; then
        print_error "Could not find VM internal IP"
        exit 1
    fi

    print_step "VM Internal IP: $VM_INTERNAL_IP"

    print_step "Creating connection profile..."
    gcloud database-migration connection-profiles create postgres-vm \
        --project=$PROJECT_ID \
        --region=$REGION \
        --source-database-engine=postgresql \
        --host=$VM_INTERNAL_IP \
        --port=5432 \
        --username=migration_admin \
        --password=DMS_1s_cool!

    print_success "Connection profile created"
    wait_for_user
}

# Function to create migration job
create_migration_job() {
    print_header "Task 3: Create and start a continuous migration job"

    print_step "Creating migration job..."
    gcloud database-migration migration-jobs create vm-to-cloudsql \
        --project=$PROJECT_ID \
        --region=$REGION \
        --source=postgres-vm \
        --destination-database-engine=cloudsql-postgresql \
        --destination-cloudsql-instance-id=postgresql-cloudsql \
        --destination-cloudsql-database-version=postgresql-13 \
        --destination-cloudsql-edition=enterprise \
        --destination-cloudsql-zone=$ZONE \
        --destination-cloudsql-private-ip \
        --destination-cloudsql-public-ip \
        --migration-job-type=continuous

    print_step "Migration job created. Please complete the Cloud Console steps for:"
    echo "  - Setting up Cloud SQL instance"
    echo "  - Configuring connectivity"
    echo "  - Testing and starting the job"
    print_warning "Complete these steps in the Cloud Console before continuing"

    wait_for_user
}

# Function to verify migration
verify_migration() {
    print_header "Task 4: Confirm the data in Cloud SQL for PostgreSQL"

    print_step "Connecting to Cloud SQL instance..."
    gcloud sql connect postgresql-cloudsql --user=postgres --project=$PROJECT_ID --quiet << EOF
supersecret!
\c orders;
SELECT COUNT(*) as total_centers FROM distribution_centers;
\q
EOF

    print_success "Data verification completed"
    wait_for_user
}

# Function to test continuous migration
test_continuous_migration() {
    print_header "Testing continuous migration"

    # Get VM external IP for testing
    VM_IP=$(gcloud compute instances describe postgresql-vm \
        --zone=$ZONE \
        --project=$PROJECT_ID \
        --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

    print_step "Adding new data to source database..."
    psql -h $VM_IP -p 5432 -d orders -U migration_admin << EOF
DMS_1s_cool!
INSERT INTO distribution_centers VALUES(-80.1918,25.7617,'Miami FL',11);
\q
EOF

    print_step "Waiting for data to sync..."
    sleep 30

    print_step "Checking if data was migrated..."
    gcloud sql connect postgresql-cloudsql --user=postgres --project=$PROJECT_ID --quiet << EOF
supersecret!
\c orders;
SELECT * FROM distribution_centers WHERE name = 'Miami FL';
\q
EOF

    print_success "Continuous migration test completed"
    wait_for_user
}

# Function to promote Cloud SQL
promote_cloudsql() {
    print_header "Task 5: Promote Cloud SQL to be a stand-alone instance"

    print_step "Promoting Cloud SQL instance..."
    gcloud database-migration migration-jobs promote vm-to-cloudsql \
        --project=$PROJECT_ID \
        --region=$REGION

    print_success "Cloud SQL instance promoted to standalone"
    wait_for_user
}

# Function to cleanup resources
cleanup_resources() {
    print_header "Cleanup Resources"

    read -p "Do you want to clean up resources? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Cleaning up resources..."

        # Stop migration job
        print_step "Stopping migration job..."
        gcloud database-migration migration-jobs delete vm-to-cloudsql \
            --project=$PROJECT_ID \
            --region=$REGION --quiet || true

        # Delete connection profile
        print_step "Deleting connection profile..."
        gcloud database-migration connection-profiles delete postgres-vm \
            --project=$PROJECT_ID \
            --region=$REGION --quiet || true

        # Delete Cloud SQL instance
        print_step "Deleting Cloud SQL instance..."
        gcloud sql instances delete postgresql-cloudsql \
            --project=$PROJECT_ID --quiet || true

        # Delete VM instance
        print_step "Deleting VM instance..."
        gcloud compute instances delete postgresql-vm \
            --zone=$ZONE \
            --project=$PROJECT_ID --quiet || true

        print_success "Cleanup completed"
    else
        print_warning "Cleanup skipped"
    fi
}

# Main menu function
show_menu() {
    echo
    print_header "GSP918 Lab Automation Script"
    echo "Choose an option:"
    echo "1) Setup variables and enable APIs"
    echo "2) Prepare source database (Task 1)"
    echo "3) Create connection profile (Task 2)"
    echo "4) Create migration job (Task 3)"
    echo "5) Verify migration (Task 4)"
    echo "6) Test continuous migration"
    echo "7) Promote Cloud SQL (Task 5)"
    echo "8) Cleanup resources"
    echo "9) Run all steps (except manual console steps)"
    echo "0) Exit"
    echo
}

# Main execution
main() {
    # Check prerequisites
    check_command gcloud
    check_command psql

    # Set project
    gcloud config set project $PROJECT_ID 2>/dev/null || true

    while true; do
        show_menu
        read -p "Enter your choice (0-9): " choice

        case $choice in
            1)
                setup_variables
                enable_apis
                ;;
            2)
                prepare_source_database
                ;;
            3)
                create_connection_profile
                ;;
            4)
                create_migration_job
                ;;
            5)
                verify_migration
                ;;
            6)
                test_continuous_migration
                ;;
            7)
                promote_cloudsql
                ;;
            8)
                cleanup_resources
                ;;
            9)
                print_warning "This will run automated steps. Manual console steps still required."
                read -p "Continue? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    enable_apis
                    prepare_source_database
                    create_connection_profile
                    # Note: Migration job creation requires manual steps in console
                    print_warning "Complete migration job setup in Cloud Console"
                fi
                ;;
            0)
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option"
                ;;
        esac
    done
}

# Check if variables are provided as arguments
if [[ $# -ge 3 ]]; then
    REGION=$1
    ZONE=$2
    PROJECT_ID=$3
    print_success "Using provided variables: Region=$REGION, Zone=$ZONE, Project=$PROJECT_ID"
else
    setup_variables
fi

main
