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
    export REGION="${REGION:-us-central1}"
    export ZONE="${ZONE:-us-central1-a}"

    # Generate unique names
    export BUCKET_NAME="${PROJECT_ID}-gsp323-$(date +%s)"
    export DATASET_NAME="lab_dataset_gsp323"
    export TABLE_NAME="lab_table"
    export TEMP_BUCKET="${BUCKET_NAME}-temp"
    export SPEECH_BUCKET="${BUCKET_NAME}-speech"
    export NL_BUCKET="${BUCKET_NAME}-nl"
    export CLUSTER_NAME="dataproc-cluster-gsp323"
    export SPEECH_OUTPUT="speech_output.json"
    export NL_OUTPUT="nl_output.json"

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
    gcloud compute ssh $CLUSTER_NAME-m --region=$REGION -- "hdfs dfs -cp gs://spls/gsp323/data.txt /data.txt"

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

    # Create bucket for results
    gsutil mb -p $PROJECT_ID -l $REGION gs://$SPEECH_BUCKET || print_warning "Bucket might already exist"

    # Create service account
    print_status "Creating service account for Speech API..."
    gcloud iam service-accounts create speech-sa-gsp323 --display-name "Speech Service Account" || print_warning "Service account might already exist"

    gcloud iam service-accounts keys create ~/speech-key.json \
        --iam-account speech-sa-gsp323@$PROJECT_ID.iam.gserviceaccount.com || print_warning "Key might already exist"

    export GOOGLE_APPLICATION_CREDENTIALS=~/speech-key.json

    # Create Python script for Speech-to-Text
    cat > speech_analysis.py << 'EOF'
from google.cloud import speech_v1p1beta1 as speech
from google.cloud import storage
import io
import json

def transcribe_audio():
    """Transcribe audio from GCS bucket."""
    client = speech.SpeechClient()

    # Audio file from lab
    audio_uri = "gs://spls/gsp323/task3.flac"

    audio = speech.RecognitionAudio(uri=audio_uri)
    config = speech.RecognitionConfig(
        encoding=speech.RecognitionConfig.AudioEncoding.FLAC,
        sample_rate_hertz=16000,
        language_code='en-US',
    )

    operation = client.long_running_recognize(config=config, audio=audio)
    print("Waiting for operation to complete...")
    response = operation.result(timeout=300)

    # Process results
    results = []
    for result in response.results:
        results.append({
            'transcript': result.alternatives[0].transcript,
            'confidence': result.alternatives[0].confidence
        })

    # Save to Cloud Storage
    storage_client = storage.Client()
    bucket = storage_client.bucket('${SPEECH_BUCKET}')
    blob = bucket.blob('${SPEECH_OUTPUT}')

    blob.upload_from_string(json.dumps(results, indent=2), content_type='application/json')
    print(f"Results saved to gs://${SPEECH_BUCKET}/${SPEECH_OUTPUT}")

    return results

if __name__ == "__main__":
    transcribe_audio()
EOF

    # Replace variables in script
    sed -i "s/\${SPEECH_BUCKET}/$SPEECH_BUCKET/g" speech_analysis.py
    sed -i "s/\${SPEECH_OUTPUT}/$SPEECH_OUTPUT/g" speech_analysis.py

    # Install requirements and run
    pip install google-cloud-speech google-cloud-storage --quiet

    python3 speech_analysis.py

    print_success "Task 3 completed. Speech analysis results saved."
}

# Task 4: Use Cloud Natural Language API
task4_natural_language() {
    print_status "Starting Task 4: Natural Language API..."

    # Create bucket for results
    gsutil mb -p $PROJECT_ID -l $REGION gs://$NL_BUCKET || print_warning "Bucket might already exist"

    # Create service account
    print_status "Creating service account for Natural Language API..."
    gcloud iam service-accounts create nl-sa-gsp323 --display-name "NL Service Account" || print_warning "Service account might already exist"

    gcloud iam service-accounts keys create ~/nl-key.json \
        --iam-account nl-sa-gsp323@$PROJECT_ID.iam.gserviceaccount.com || print_warning "Key might already exist"

    export GOOGLE_APPLICATION_CREDENTIALS=~/nl-key.json

    # Create Python script for Natural Language
    cat > nl_analysis.py << 'EOF'
from google.cloud import language_v1
from google.cloud import storage
import json

def analyze_text():
    """Analyze text using Natural Language API."""
    client = language_v1.LanguageServiceClient()

    text_content = "Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat."

    document = language_v1.Document(
        content=text_content,
        type_=language_v1.Document.Type.PLAIN_TEXT,
        language="en"
    )

    # Analyze entities
    entities_response = client.analyze_entities(document=document)
    sentiment_response = client.analyze_sentiment(document=document)

    # Prepare results
    results = {
        'text': text_content,
        'entities': [],
        'sentiment': {
            'magnitude': sentiment_response.document_sentiment.magnitude,
            'score': sentiment_response.document_sentiment.score
        }
    }

    for entity in entities_response.entities:
        results['entities'].append({
            'name': entity.name,
            'type': language_v1.Entity.Type(entity.type_).name,
            'salience': entity.salience,
            'mentions': len(entity.mentions)
        })

    # Save to Cloud Storage
    storage_client = storage.Client()
    bucket = storage_client.bucket('${NL_BUCKET}')
    blob = bucket.blob('${NL_OUTPUT}')

    blob.upload_from_string(json.dumps(results, indent=2), content_type='application/json')
    print(f"Results saved to gs://${NL_BUCKET}/${NL_OUTPUT}")

    print("Entities found:")
    for entity in results['entities']:
        print(f"- {entity['name']} ({entity['type']})")

    return results

if __name__ == "__main__":
    analyze_text()
EOF

    # Replace variables in script
    sed -i "s/\${NL_BUCKET}/$NL_BUCKET/g" nl_analysis.py
    sed -i "s/\${NL_OUTPUT}/$NL_OUTPUT/g" nl_analysis.py

    # Install requirements and run
    pip install google-cloud-language google-cloud-storage --quiet

    python3 nl_analysis.py

    print_success "Task 4 completed. Natural Language analysis results saved."
}

# Cleanup function
cleanup() {
    print_warning "Starting cleanup process..."

    # Delete Dataproc cluster
    print_status "Deleting Dataproc cluster..."
    gcloud dataproc clusters delete $CLUSTER_NAME --region=$REGION --quiet || print_warning "Failed to delete cluster"

    # Delete buckets
    print_status "Deleting Cloud Storage buckets..."
    gsutil rm -r gs://$BUCKET_NAME || print_warning "Failed to delete bucket"
    gsutil rm -r gs://$TEMP_BUCKET || print_warning "Failed to delete temp bucket"
    gsutil rm -r gs://$SPEECH_BUCKET || print_warning "Failed to delete speech bucket"
    gsutil rm -r gs://$NL_BUCKET || print_warning "Failed to delete NL bucket"

    # Delete BigQuery dataset
    print_status "Deleting BigQuery dataset..."
    bq rm -r -f $DATASET_NAME || print_warning "Failed to delete dataset"

    # Delete service accounts
    print_status "Deleting service accounts..."
    gcloud iam service-accounts delete speech-sa-gsp323@$PROJECT_ID.iam.gserviceaccount.com --quiet || print_warning "Failed to delete speech SA"
    gcloud iam service-accounts delete nl-sa-gsp323@$PROJECT_ID.iam.gserviceaccount.com --quiet || print_warning "Failed to delete NL SA"

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
