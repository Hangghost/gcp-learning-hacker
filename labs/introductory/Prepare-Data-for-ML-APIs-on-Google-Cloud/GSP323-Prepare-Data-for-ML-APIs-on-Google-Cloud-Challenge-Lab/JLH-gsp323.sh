#!/bin/bash

# GSP323 - Prepare Data for ML APIs on Google Cloud: Challenge Lab
# Automated script to complete all tasks

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for operation completion
wait_for_operation() {
    local operation_name="$1"
    local timeout="${2:-300}"  # Default timeout 5 minutes
    local interval="${3:-10}"  # Check every 10 seconds

    print_status "Waiting for $operation_name to complete..."
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if eval "$4"; then
            print_success "$operation_name completed successfully"
            return 0
        fi
        sleep $interval
        elapsed=$((elapsed + interval))
        print_status "Still waiting... (${elapsed}s elapsed)"
    done

    print_error "$operation_name timed out after ${timeout} seconds"
    return 1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."

    if ! command_exists gcloud; then
        print_error "gcloud CLI is not installed. Please install Google Cloud SDK."
        exit 1
    fi

    if ! command_exists bq; then
        print_error "BigQuery CLI is not installed. Please install it."
        exit 1
    fi

    if ! command_exists gsutil; then
        print_error "gsutil is not installed. Please install Google Cloud SDK."
        exit 1
    fi

    if ! command_exists python3; then
        print_error "Python 3 is not installed."
        exit 1
    fi

    print_success "All prerequisites met"
}

# Setup variables
setup_variables() {
    print_status "Setting up variables..."

    # Get project ID
    export PROJECT_ID=$(gcloud config get-value project)
    if [ -z "$PROJECT_ID" ]; then
        print_error "No project set. Please run 'gcloud config set project PROJECT_ID'"
        exit 1
    fi

    # Set default region (you can modify this)
    export REGION="${REGION:-us-east1}"
    export ZONE="${ZONE:-us-east1-b}"

    # Set resource names (based on actual lab values)
    export BUCKET_NAME="${PROJECT_ID}-marking"
    export DATASET_NAME="lab_676"
    export TABLE_NAME="customers_937"
    export CLUSTER_NAME="dataproc-cluster-$(date +%s)"
    export SPEECH_OUTPUT="task3-gcs-615.result"
    export NL_OUTPUT="task4-cnl-605.result"

    print_success "Variables set up successfully"
    echo "Project ID: $PROJECT_ID"
    echo "Region: $REGION"
    echo "Bucket: $BUCKET_NAME"
}

# Enable required APIs
enable_apis() {
    print_status "Enabling required APIs..."

    gcloud services enable dataflow.googleapis.com --project=$PROJECT_ID
    gcloud services enable dataproc.googleapis.com --project=$PROJECT_ID
    gcloud services enable speech.googleapis.com --project=$PROJECT_ID
    gcloud services enable language.googleapis.com --project=$PROJECT_ID
    gcloud services enable bigquery.googleapis.com --project=$PROJECT_ID
    gcloud services enable storage.googleapis.com --project=$PROJECT_ID

    print_success "APIs enabled"
}

# Task 1: Run a simple Dataflow job
task1_dataflow() {
    print_status "Starting Task 1: Dataflow job..."

    # Create BigQuery dataset
    print_status "Creating BigQuery dataset..."
    bq mk $DATASET_NAME || print_warning "Dataset might already exist"

    # Create Cloud Storage buckets
    print_status "Creating Cloud Storage buckets..."
    gsutil mb -p $PROJECT_ID -l $REGION gs://$BUCKET_NAME || print_warning "Bucket might already exist"
    gsutil mb -p $PROJECT_ID -l $REGION gs://$TEMP_BUCKET || print_warning "Temp bucket might already exist"

    # Submit Dataflow job
    print_status "Submitting Dataflow job..."
    gcloud dataflow jobs run dataflow-lab-job \
        --gcs-location gs://dataflow-templates/latest/GCS_Text_to_BigQuery \
        --region $REGION \
        --parameters \
"inputFilePattern=gs://spls/gsp323/lab.csv,\
outputTable=$PROJECT_ID:$DATASET_NAME.$TABLE_NAME,\
schemaFilePath=gs://spls/gsp323/lab.schema,\
javascriptTextTransformFunctionName=transform,\
javascriptTextTransformGcsPath=gs://spls/gsp323/lab.js,\
temporaryLocation=gs://$TEMP_BUCKET/df_temp/"

    # Wait for job completion
    print_status "Waiting for Dataflow job to complete..."
    sleep 60  # Give it some time to start

    # Check job status (this is a simplified check)
    JOB_ID=$(gcloud dataflow jobs list --region=$REGION --filter="name:dataflow-lab-job" --format="value(job_id)" | head -1)
    if [ -n "$JOB_ID" ]; then
        print_status "Dataflow job submitted with ID: $JOB_ID"
        print_success "Task 1 completed. Please check the job status in Cloud Console."
    else
        print_error "Failed to submit Dataflow job"
        return 1
    fi
}

# Task 2: Run a simple Dataproc job
task2_dataproc() {
    print_status "Starting Task 2: Dataproc job..."

    # Create Dataproc cluster
    print_status "Creating Dataproc cluster..."
    gcloud dataproc clusters create $CLUSTER_NAME \
        --region $REGION \
        --master-machine-type e2-standard-2 \
        --worker-machine-type e2-standard-2 \
        --num-workers 2 \
        --master-boot-disk-size 100 \
        --worker-boot-disk-size 100 \
        --no-address

    # Copy data file to HDFS
    print_status "Copying data file to HDFS..."
    # Try direct SSH first using correct zone
    CLUSTER_ZONE=$(gcloud dataproc clusters describe $CLUSTER_NAME --region=$REGION --format="value(config.gceClusterConfig.zoneUri)" | awk -F/ '{print $NF}')
    if gcloud compute ssh $CLUSTER_NAME-m --zone=$CLUSTER_ZONE --command="hdfs dfs -cp gs://spls/gsp323/data.txt /data.txt"; then
        print_success "Data file copied successfully"
    else
        print_warning "Direct SSH failed, trying alternative method..."
        # Alternative method using instance listing
        VM_NAME=$(gcloud compute instances list --project="$PROJECT_ID" --format=json | jq -r '.[0].name')
        ZONE=$(gcloud compute instances list --filter="name=$VM_NAME" --format 'csv[no-heading](zone)')
        gcloud compute ssh --zone "$ZONE" "$VM_NAME" --project "$PROJECT_ID" --command="hdfs dfs -cp gs://spls/gsp323/data.txt /data.txt"
    fi

    # Submit Spark job
    print_status "Submitting Spark job..."
    gcloud dataproc jobs submit spark \
        --region $REGION \
        --cluster $CLUSTER_NAME \
        --class org.apache.spark.examples.SparkPageRank \
        --jars file:///usr/lib/spark/examples/jars/spark-examples.jar \
        -- /data.txt

    print_success "Task 2 completed. Dataproc job submitted."
}

# Task 3: Use Google Cloud Speech-to-Text API
task3_speech() {
    print_status "Starting Task 3: Speech-to-Text API..."

    # Create API key
    print_status "Creating API key for Speech-to-Text..."
    gcloud alpha services api-keys create --display-name="speech-api-key" || print_warning "API key might already exist"
    API_KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=speech-api-key")
    API_KEY=$(gcloud alpha services api-keys get-key-string $API_KEY_NAME --format="value(keyString)")

    # Create request JSON
    cat > request.json <<EOF
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://spls/gsp323/task3.flac"
  }
}
EOF

    # Call Speech-to-Text API
    print_status "Calling Speech-to-Text API..."
    curl -s -X POST -H "Content-Type: application/json" \
        --data-binary @request.json \
        "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > speech_result.json

    # Upload result to specified location
    print_status "Uploading result to Cloud Storage..."
    gsutil cp speech_result.json gs://$BUCKET_NAME/$SPEECH_OUTPUT

    print_success "Task 3 completed. Speech analysis results saved to gs://$BUCKET_NAME/$SPEECH_OUTPUT"
}

# Task 4: Use Cloud Natural Language API
task4_natural_language() {
    print_status "Starting Task 4: Natural Language API..."

    # Create service account
    print_status "Creating service account for Natural Language API..."
    gcloud iam service-accounts create nl-service-account --display-name "Natural Language Service Account" || print_warning "Service account might already exist"

    # Grant Cloud Storage permissions
    print_status "Granting Cloud Storage permissions to service account..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:nl-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/storage.objectAdmin" || print_warning "Permission might already be granted"

    # Create service account key
    print_status "Creating service account key..."
    gcloud iam service-accounts keys create ~/nl-key.json \
        --iam-account nl-service-account@$PROJECT_ID.iam.gserviceaccount.com || print_warning "Key might already exist"

    export GOOGLE_APPLICATION_CREDENTIALS="/home/$USER/nl-key.json"

    # Activate service account
    print_status "Activating service account..."
    gcloud auth activate-service-account nl-service-account@$PROJECT_ID.iam.gserviceaccount.com \
        --key-file=$GOOGLE_APPLICATION_CREDENTIALS || print_warning "Service account might already be activated"

    # Run entity analysis
    print_status "Running Natural Language entity analysis..."
    gcloud ml language analyze-entities \
        --content="Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat." \
        > nl_result.json

    # Upload result to specified location
    print_status "Uploading result to Cloud Storage..."
    gsutil cp nl_result.json gs://$BUCKET_NAME/$NL_OUTPUT

    print_success "Task 4 completed. Natural Language analysis results saved to gs://$BUCKET_NAME/$NL_OUTPUT"
}

# Cleanup function
cleanup() {
    print_warning "Starting cleanup process..."

    # Delete Dataproc cluster
    print_status "Deleting Dataproc cluster..."
    gcloud dataproc clusters delete $CLUSTER_NAME --region=$REGION --quiet || print_warning "Failed to delete cluster"

    # Delete BigQuery dataset
    print_status "Deleting BigQuery dataset..."
    bq rm -r -f $DATASET_NAME || print_warning "Failed to delete dataset"

    # Delete service accounts
    print_status "Deleting service accounts..."
    gcloud iam service-accounts delete nl-service-account@$PROJECT_ID.iam.gserviceaccount.com --quiet || print_warning "Failed to delete NL SA"

    # Delete API key
    print_status "Deleting API key..."
    gcloud alpha services api-keys delete $API_KEY_NAME --quiet || print_warning "Failed to delete API key"

    # Clean up local files
    print_status "Cleaning up local files..."
    rm -f lab.csv lab.schema request.json speech_result.json nl_result.json
    rm -f ~/speech-key.json ~/nl-key.json

    print_success "Cleanup completed"
}

# Main execution
main() {
    print_status "Starting GSP323 Challenge Lab automation script"
    print_warning "This script will create resources that may incur costs."
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Script cancelled by user"
        exit 0
    fi

    check_prerequisites
    setup_variables
    enable_apis

    # Execute tasks
    task1_dataflow
    echo
    task2_dataproc
    echo
    task3_speech
    echo
    task4_natural_language

    print_success "All tasks completed!"
    print_warning "Please verify each task in the Cloud Console and click 'Check my progress' for each task."
    echo
    read -p "Do you want to run cleanup now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cleanup
    else
        print_warning "Remember to run cleanup when you're done to avoid charges!"
        print_status "You can run cleanup later with: ./JLH-gsp323.sh cleanup"
    fi
}

# Handle cleanup command
if [ "$1" = "cleanup" ]; then
    if [ -f ~/.gsp323_vars ]; then
        source ~/.gsp323_vars
        cleanup
    else
        print_error "Cannot find saved variables. Run the script first."
        exit 1
    fi
else
    # Save variables for cleanup
    main | tee /tmp/gsp323_output.log
    declare -p PROJECT_ID REGION BUCKET_NAME DATASET_NAME CLUSTER_NAME SPEECH_BUCKET NL_BUCKET > ~/.gsp323_vars 2>/dev/null || true
fi
