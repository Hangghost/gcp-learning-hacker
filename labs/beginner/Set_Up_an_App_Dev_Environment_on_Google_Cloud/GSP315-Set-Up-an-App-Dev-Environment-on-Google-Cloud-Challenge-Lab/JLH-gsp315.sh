# GSP315 - Set Up an App Dev Environment on Google Cloud: Challenge Lab
# Automation Script

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

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to check if command succeeded
check_command() {
    if [ $? -eq 0 ]; then
        print_status "$1 completed successfully"
    else
        print_error "$1 failed"
        exit 1
    fi
}

# Function to prompt for input with default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local response

    read -p "$prompt [$default]: " response
    echo "${response:-$default}"
}

# Function to create temporary directory for function code
setup_function_code() {
    # Create temporary directory
    local temp_dir=$(mktemp -d)

    # Create package.json
    cat > "$temp_dir/package.json" << 'EOF'
{
    "name": "thumbnails",
    "version": "1.0.0",
    "description": "Create Thumbnail of uploaded image",
    "scripts": {
      "start": "node index.js"
    },
    "dependencies": {
      "@google-cloud/functions-framework": "^3.0.0",
      "@google-cloud/pubsub": "^2.0.0",
      "@google-cloud/storage": "^5.0.0",
      "fast-crc32c": "1.0.4",
      "imagemagick-stream": "4.1.1"
    },
    "devDependencies": {},
    "engines": {
      "node": ">=4.3.2"
    }
  }
EOF

    # Create index.js with the topic name filled in
    cat > "$temp_dir/index.js" << EOF
const functions = require('@google-cloud/functions-framework');
const crc32 = require("fast-crc32c");
const { Storage } = require('@google-cloud/storage');
const gcs = new Storage();
const { PubSub } = require('@google-cloud/pubsub');
const imagemagick = require("imagemagick-stream");

functions.cloudEvent('$FUNCTION_NAME', cloudEvent => {
  const event = cloudEvent.data;

  console.log(\`Event: \${event}\`);
  console.log(\`Hello \${event.bucket}\`);

  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64"
  const bucket = gcs.bucket(bucketName);
  const topicName = "$TOPIC_NAME";
  const pubsub = new PubSub();
  if ( fileName.search("64x64_thumbnail") == -1 ){
    // doesn't have a thumbnail, get the filename extension
    var filename_split = fileName.split('.');
    var filename_ext = filename_split[filename_split.length - 1];
    var filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length );
    if (filename_ext.toLowerCase() == 'png' || filename_ext.toLowerCase() == 'jpg'){
      // only support png and jpg at this point
      console.log(\`Processing Original: gs://\${bucketName}/\${fileName}\`);
      const gcsObject = bucket.file(fileName);
      let newFilename = filename_without_ext + size + '_thumbnail.' + filename_ext;
      let gcsNewObject = bucket.file(newFilename);
      let srcStream = gcsObject.createReadStream();
      let dstStream = gcsNewObject.createWriteStream();
      let resize = imagemagick().resize(size).quality(90);
      srcStream.pipe(resize).pipe(dstStream);
      return new Promise((resolve, reject) => {
        dstStream
          .on("error", (err) => {
            console.log(\`Error: \${err}\`);
            reject(err);
          })
          .on("finish", () => {
            console.log(\`Success: \${fileName} → \${newFilename}\`);
              // set the content-type
              gcsNewObject.setMetadata(
              {
                contentType: 'image/'+ filename_ext.toLowerCase()
              }, function(err, apiResponse) {});
              pubsub
                .topic(topicName)
                .publisher()
                .publish(Buffer.from(newFilename))
                .then(messageId => {
                  console.log(\`Message \${messageId} published.\`);
                })
                .catch(err => {
                  console.error('ERROR:', err);
                });
          });
      });
    }
    else {
      console.log(\`gs://\${bucketName}/\${fileName} is not an image I can handle\`);
    }
  }
  else {
    console.log(\`gs://\${bucketName}/\${fileName} already has a thumbnail\`);
  }
});
EOF

    echo "$temp_dir"
}

# Function to cleanup temporary directory
cleanup_temp_dir() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        print_step "Cleaning up temporary directory..."
        rm -rf "$TEMP_DIR"
        print_status "Temporary directory cleaned up"
    fi
}

# Function to download and upload test image
test_function() {
    print_step "Testing Cloud Run Function..."

    # Download test image
    print_status "Downloading test image..."
    curl -o map.jpg "https://storage.googleapis.com/cloud-training/gsp315/map.jpg"
    check_command "Download test image"

    # Upload to bucket
    print_status "Uploading test image to bucket..."
    gsutil cp map.jpg gs://$BUCKET_NAME/map.jpg
    check_command "Upload test image"

    # Clean up local test file
    rm -f map.jpg

    print_warning "Please check the bucket for the thumbnail image. It may take a few minutes to appear."
    print_status "Function test completed. Check gs://$BUCKET_NAME/ for thumbnail image."
}

# Main execution starts here
print_step "Starting GSP315 - Set Up an App Dev Environment on Google Cloud: Challenge Lab"

# Get user input for variables
echo
print_step "Please provide the following information:"
REGION=$(prompt_with_default "Enter REGION" "us-central1")
ZONE=$(prompt_with_default "Enter ZONE" "us-central1-a")
BUCKET_NAME=$(prompt_with_default "Enter BUCKET_NAME" "")
TOPIC_NAME=$(prompt_with_default "Enter TOPIC_NAME" "")
FUNCTION_NAME=$(prompt_with_default "Enter FUNCTION_NAME" "")
USERNAME_2=$(prompt_with_default "Enter USERNAME_2 (previous cloud engineer)" "")

# Validate required inputs
if [ -z "$BUCKET_NAME" ] || [ -z "$TOPIC_NAME" ] || [ -z "$FUNCTION_NAME" ] || [ -z "$USERNAME_2" ]; then
    print_error "All lab-specific variables (BUCKET_NAME, TOPIC_NAME, FUNCTION_NAME, USERNAME_2) are required."
    exit 1
fi

PROJECT_ID=$(gcloud config get-value project)
print_status "Using project: $PROJECT_ID"

# Extract REGION from ZONE if not provided
if [ -z "$REGION" ]; then
    REGION="${ZONE%-*}"
    print_status "Extracted REGION from ZONE: $REGION"
fi

echo
print_step "Enabling required GCP services..."
gcloud services enable \
  artifactregistry.googleapis.com \
  cloudfunctions.googleapis.com \
  cloudbuild.googleapis.com \
  eventarc.googleapis.com \
  run.googleapis.com \
  logging.googleapis.com \
  pubsub.googleapis.com
check_command "Enable GCP services"

print_status "Waiting for services to be enabled..."
sleep 70

# Set up service account permissions
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
print_status "Project number: $PROJECT_NUMBER"

print_step "Setting up service account permissions..."

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
    --role=roles/eventarc.eventReceiver
check_command "Add Eventarc event receiver role"

sleep 20

SERVICE_ACCOUNT="$(gsutil kms serviceaccount -p $PROJECT_ID)"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role='roles/pubsub.publisher'
check_command "Add PubSub publisher role to storage service account"

sleep 20

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
    --role=roles/iam.serviceAccountTokenCreator
check_command "Add service account token creator role"

sleep 20

echo
print_step "Lab configuration:"
echo "REGION: $REGION"
echo "ZONE: $ZONE"
echo "BUCKET_NAME: $BUCKET_NAME"
echo "TOPIC_NAME: $TOPIC_NAME"
echo "FUNCTION_NAME: $FUNCTION_NAME"
echo "USERNAME_2: $USERNAME_2"
echo "PROJECT_ID: $PROJECT_ID"

read -p "Press Enter to continue or Ctrl+C to abort..."

# Task 1: Create bucket
echo
print_step "Task 1: Creating bucket for storing photographs..."
gsutil mb -l $REGION gs://$BUCKET_NAME
check_command "Task 1 - Create bucket"

# Task 2: Create Pub/Sub topic
echo
print_step "Task 2: Creating Pub/Sub topic..."
gcloud pubsub topics create $TOPIC_NAME
check_command "Task 2 - Create Pub/Sub topic"

# Task 3: Create Cloud Run Function
echo
print_step "Task 3: Creating Cloud Run Function..."

# Setup function code
TEMP_DIR=$(setup_function_code)
print_status "Created temporary directory: $TEMP_DIR"

# Change to temp directory and deploy function
cd "$TEMP_DIR"

# Add additional service account permission for bucket
BUCKET_SERVICE_ACCOUNT="${PROJECT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$BUCKET_SERVICE_ACCOUNT \
  --role=roles/pubsub.publisher
check_command "Add bucket service account permission"

print_status "Deploying Cloud Run Function..."

# Deploy function with retry logic
deploy_function() {
    gcloud functions deploy $FUNCTION_NAME \
    --gen2 \
    --runtime nodejs20 \
    --trigger-resource $BUCKET_NAME \
    --trigger-event google.storage.object.finalize \
    --entry-point $FUNCTION_NAME \
    --region=$REGION \
    --source . \
    --quiet
}

# Variables
SERVICE_NAME="$FUNCTION_NAME"

# Loop until the Cloud Run service is created
while true; do
  # Run the deployment command
  deploy_function

  # Check if Cloud Run service is created
  if gcloud run services describe $SERVICE_NAME --region $REGION &> /dev/null; then
    print_status "Cloud Run service is created successfully."
    break
  else
    print_warning "Waiting for Cloud Run service to be created..."
    print_status "Meantime Subscribe to Quicklab[https://www.youtube.com/@quick_lab]."
    sleep 10
  fi
done

check_command "Task 3 - Create Cloud Run Function"

# Return to original directory
cd - > /dev/null

# Test the function
echo
read -p "Do you want to test the function by uploading an image? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    test_function
fi

# Task 4: Remove previous cloud engineer
echo
print_step "Task 4: Removing previous cloud engineer's access..."
gcloud projects remove-iam-policy-binding $PROJECT_ID \
  --member="user:$USERNAME_2" \
  --role="roles/viewer"
check_command "Task 4 - Remove previous cloud engineer"

# Cleanup
cleanup_temp_dir

echo
print_status "🎉 All tasks completed successfully!"
print_warning "Don't forget to verify each task in the lab interface."
echo
print_step "Lab completion summary:"
echo "- ✅ Bucket created: gs://$BUCKET_NAME"
echo "- ✅ Pub/Sub topic created: $TOPIC_NAME"
echo "- ✅ Cloud Run Function deployed: $FUNCTION_NAME"
echo "- ✅ Previous engineer access removed: $USERNAME_2"

echo
read -p "Do you want to run cleanup to remove all created resources? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    print_step "Starting cleanup process..."

    print_warning "Removing Cloud Run Function..."
    gcloud functions delete $FUNCTION_NAME --region=$REGION --quiet
    check_command "Cleanup - Delete function"

    print_warning "Removing Pub/Sub topic..."
    gcloud pubsub topics delete $TOPIC_NAME --quiet
    check_command "Cleanup - Delete topic"

    print_warning "Removing bucket and all contents..."
    gsutil rm -r gs://$BUCKET_NAME
    check_command "Cleanup - Delete bucket"

    print_status "🧹 Cleanup completed!"
fi

print_status "Lab automation script completed. Thank you!"
