#!/bin/bash

# GSP922 - Configure Replication and Enable Point-in-Time Recovery for Cloud SQL for PostgreSQL
# https://www.cloudskillsboost.google/course_templates/652/labs/564282

# Script configuration
set -e  # Exit on any error
set -u  # Exit on undefined variables

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Progress indicator
show_progress() {
    echo -e "${BLUE}[PROGRESS]${NC} $1"
}

# Error handler
error_exit() {
    log_error "$1"
    echo
    log_info "To clean up partially created resources, run:"
    echo "  gcloud sql instances delete postgres-orders-pitr --quiet 2>/dev/null || true"
    exit 1
}

# Function to wait for SQL instance to be ready
wait_for_sql_instance() {
    local instance_name=$1
    local max_attempts=60
    local attempt=1

    log_info "Waiting for SQL instance '$instance_name' to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if gcloud sql instances describe "$instance_name" --format="value(state)" 2>/dev/null | grep -q "RUNNABLE"; then
            log_success "SQL instance '$instance_name' is ready"
            return 0
        fi
        log_info "Attempt $attempt/$max_attempts: Instance not ready yet, waiting..."
        sleep 30
        ((attempt++))
    done

    error_exit "SQL instance '$instance_name' failed to become ready within expected time"
}

# Function to execute SQL command
execute_sql() {
    local instance=$1
    local sql_command=$2
    local db_name=${3:-postgres}

    log_info "Executing SQL on instance '$instance', database '$db_name'"

    # Create a temporary SQL file
    local temp_sql_file=$(mktemp)
    echo "$sql_command" > "$temp_sql_file"

    # Execute the SQL
    if ! gcloud sql connect "$instance" --user=postgres --database="$db_name" --quiet < "$temp_sql_file"; then
        rm -f "$temp_sql_file"
        error_exit "Failed to execute SQL command on instance '$instance'"
    fi

    rm -f "$temp_sql_file"
}

# Function to get row count from distribution_centers table
get_distribution_centers_count() {
    local instance=$1
    local db_name=${2:-orders}

    log_info "Getting row count from distribution_centers table on instance '$instance'"

    # SQL command to get count
    local sql="SELECT COUNT(*) FROM distribution_centers;"

    # Execute and capture output
    local output_file=$(mktemp)
    if ! gcloud sql connect "$instance" --user=postgres --database="$db_name" --quiet > "$output_file" 2>&1 << EOF
$sql
EOF
    then
        rm -f "$output_file"
        error_exit "Failed to query distribution_centers table on instance '$instance'"
    fi

    # Extract count from output
    local count=$(grep -oP '^\s*\K\d+(?=\s*$)' "$output_file" | tail -1)
    rm -f "$output_file"

    echo "$count"
}

# Main script execution
main() {
    log_info "Starting GSP922 - Configure Replication and Enable Point-in-Time Recovery for Cloud SQL for PostgreSQL"
    echo

    # Configuration
    CLOUD_SQL_INSTANCE="postgres-orders"
    NEW_INSTANCE_NAME="postgres-orders-pitr"
    DB_PASSWORD="supersecret!"
    DB_NAME="orders"

    # Export variables for use in commands
    export CLOUD_SQL_INSTANCE
    export NEW_INSTANCE_NAME

    show_progress "Task 1: Enable backups on the Cloud SQL for PostgreSQL instance"

    # Step 1: Display instance details
    log_info "Step 1: Checking instance details..."
    if ! gcloud sql instances describe "$CLOUD_SQL_INSTANCE" > /dev/null 2>&1; then
        error_exit "Cloud SQL instance '$CLOUD_SQL_INSTANCE' not found. Please ensure it exists."
    fi
    log_success "Instance '$CLOUD_SQL_INSTANCE' found"

    # Step 2: Get current time and calculate backup time
    log_info "Step 2: Getting current UTC time..."
    CURRENT_TIME=$(date +"%R")
    log_info "Current time: $CURRENT_TIME"

    # Calculate backup time (1 hour earlier)
    CURRENT_HOUR=$(date +"%H")
    CURRENT_MIN=$(date +"%M")
    BACKUP_HOUR=$(( (CURRENT_HOUR - 1 + 24) % 24 ))
    BACKUP_TIME=$(printf "%02d:%02d" $BACKUP_HOUR $CURRENT_MIN)

    log_info "Setting backup time to: $BACKUP_TIME (1 hour earlier than current time)"

    # Step 3: Enable scheduled backups
    log_info "Step 3: Enabling scheduled backups..."
    if ! gcloud sql instances patch "$CLOUD_SQL_INSTANCE" \
        --backup-start-time="$BACKUP_TIME" > /dev/null 2>&1; then
        error_exit "Failed to enable backups on instance '$CLOUD_SQL_INSTANCE'"
    fi

    # Step 4: Confirm backup configuration
    log_info "Step 4: Confirming backup configuration..."
    BACKUP_CONFIG=$(gcloud sql instances describe "$CLOUD_SQL_INSTANCE" --format 'value(settings.backupConfiguration)')
    if [[ $BACKUP_CONFIG == *"enabled=True"* ]]; then
        log_success "Backups enabled successfully"
        log_info "Backup configuration: $BACKUP_CONFIG"
    else
        error_exit "Failed to enable backups. Configuration: $BACKUP_CONFIG"
    fi

    echo
    show_progress "Task 2: Enable and run point-in-time recovery"

    # Step 1: Enable point-in-time recovery
    log_info "Step 1: Enabling point-in-time recovery..."
    if ! gcloud sql instances patch "$CLOUD_SQL_INSTANCE" \
        --enable-point-in-time-recovery \
        --retained-transaction-log-days=1 > /dev/null 2>&1; then
        error_exit "Failed to enable point-in-time recovery on instance '$CLOUD_SQL_INSTANCE'"
    fi
    log_success "Point-in-time recovery enabled"

    # Wait a moment for the change to take effect
    log_info "Waiting for point-in-time recovery to take effect..."
    sleep 30

    # Step 2: Get initial row count
    log_info "Step 2: Getting initial row count from distribution_centers table..."
    INITIAL_COUNT=$(get_distribution_centers_count "$CLOUD_SQL_INSTANCE" "$DB_NAME")
    log_info "Initial row count: $INITIAL_COUNT"

    if [ "$INITIAL_COUNT" != "10" ]; then
        log_warning "Expected 10 rows initially, but found $INITIAL_COUNT. This might be expected if the database has been modified."
    fi

    # Step 3: Get timestamp for point-in-time recovery
    log_info "Step 3: Getting timestamp for point-in-time recovery..."
    PITR_TIMESTAMP=$(date --rfc-3339=seconds)
    log_info "Point-in-time recovery timestamp: $PITR_TIMESTAMP"

    # Wait a few seconds to ensure changes happen after timestamp
    log_info "Waiting 10 seconds to ensure subsequent changes occur after timestamp..."
    sleep 10

    # Step 4: Add a row to the database
    log_info "Step 4: Adding a row to the distribution_centers table..."
    INSERT_SQL="INSERT INTO distribution_centers VALUES(-80.1918,25.7617,'Miami FL',11);"
    execute_sql "$CLOUD_SQL_INSTANCE" "$INSERT_SQL" "$DB_NAME"

    # Verify the row was added
    AFTER_INSERT_COUNT=$(get_distribution_centers_count "$CLOUD_SQL_INSTANCE" "$DB_NAME")
    log_info "Row count after insert: $AFTER_INSERT_COUNT"

    if [ "$AFTER_INSERT_COUNT" -le "$INITIAL_COUNT" ]; then
        error_exit "Failed to insert row. Count should have increased from $INITIAL_COUNT to $(($INITIAL_COUNT + 1))"
    fi
    log_success "Successfully added row to database"

    # Step 5: Create point-in-time recovery instance
    log_info "Step 5: Creating point-in-time recovery instance..."
    log_info "This may take 10 minutes or more. Please be patient."

    if ! gcloud sql instances clone "$CLOUD_SQL_INSTANCE" "$NEW_INSTANCE_NAME" \
        --point-in-time "$PITR_TIMESTAMP" > /dev/null 2>&1; then
        error_exit "Failed to create point-in-time recovery instance '$NEW_INSTANCE_NAME'"
    fi

    # Wait for the new instance to be ready
    wait_for_sql_instance "$NEW_INSTANCE_NAME"

    echo
    show_progress "Task 3: Confirm database has been restored to the correct point-in-time"

    # Step 1: Get row count from the restored instance
    log_info "Step 1: Getting row count from restored instance..."
    RESTORED_COUNT=$(get_distribution_centers_count "$NEW_INSTANCE_NAME" "$DB_NAME")
    log_info "Restored instance row count: $RESTORED_COUNT"

    # Step 2: Verify the restoration
    log_info "Step 2: Verifying point-in-time recovery..."
    if [ "$RESTORED_COUNT" = "$INITIAL_COUNT" ]; then
        log_success "Point-in-time recovery successful!"
        log_success "Original instance has $AFTER_INSERT_COUNT rows"
        log_success "Restored instance has $RESTORED_COUNT rows (matches state at timestamp)"
    else
        log_error "Point-in-time recovery verification failed!"
        log_error "Expected $INITIAL_COUNT rows in restored instance, but found $RESTORED_COUNT"
        log_error "Original instance has $AFTER_INSERT_COUNT rows"
        error_exit "Point-in-time recovery did not work as expected"
    fi

    echo
    log_success "Lab GSP922 completed successfully!"
    echo
    log_info "Summary:"
    echo "  - Enabled backups on Cloud SQL instance '$CLOUD_SQL_INSTANCE'"
    echo "  - Enabled point-in-time recovery"
    echo "  - Created point-in-time recovery instance '$NEW_INSTANCE_NAME'"
    echo "  - Verified that the restored database reflects the correct point-in-time"
    echo
    log_info "To clean up the resources created by this lab, run:"
    echo "  gcloud sql instances delete $NEW_INSTANCE_NAME --quiet"
    echo
    log_warning "Note: The original instance '$CLOUD_SQL_INSTANCE' is not deleted as it may be part of your lab environment."
}

# Cleanup function
cleanup() {
    log_warning "Script interrupted. Cleaning up partially created resources..."
    gcloud sql instances delete "$NEW_INSTANCE_NAME" --quiet 2>/dev/null || true
    log_info "Cleanup completed."
}

# Set trap for cleanup on script exit
trap cleanup EXIT INT TERM

# Run main function
main "$@"
