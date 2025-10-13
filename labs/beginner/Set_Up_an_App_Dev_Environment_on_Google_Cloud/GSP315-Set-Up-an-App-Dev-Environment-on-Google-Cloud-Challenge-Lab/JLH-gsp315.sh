#!/bin/bash

# GSP315 - Set Up an App Dev Environment on Google Cloud: Challenge Lab
# Automation Script

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
    print_step "Setting up Cloud Run Function code..."

    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    print_status "Created temporary directory: $TEMP_DIR"

    # Create package.json
    cat > "$TEMP_DIR/package.json" << 'EOF'
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
   "@google-cloud/storage": "^6.11.0",
   "sharp": "^0.32.1"
 },
 "devDependencies": {},
 "engines": {
   "node": ">=4.3.2"
 }
}
EOF

    # Create index.js with the topic name filled in
    cat > "$TEMP_DIR/index.js" << EOF
const functions = require('@google-cloud/functions-framework');
const { Storage } = require('@google-cloud/storage');
const { PubSub } = require('@google-cloud/pubsub');
const sharp = require('sharp');

functions.cloudEvent('', async cloudEvent => {
  const event = cloudEvent.data;

  console.log(\`Event: \${JSON.stringify(event)}\`);
  console.log(\`Hello \${event.bucket}\`);

  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64";
  const bucket = new Storage().bucket(bucketName);
  const topicName = "$TOPIC_NAME";
  const pubsub = new PubSub();

  if (fileName.search("64x64_thumbnail") === -1) {
    // doesn't have a thumbnail, get the filename extension
    const filename_split = fileName.split('.');
    const filename_ext = filename_split[filename_split.length - 1].toLowerCase();
    const filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length - 1); // fix sub string to remove the dot

    if (filename_ext === 'png' || filename_ext === 'jpg' || filename_ext === 'jpeg') {
      // only support png and jpg at this point
      console.log(\`Processing Original: gs://\${bucketName}/\${fileName}\`);
      const gcsObject = bucket.file(fileName);
      const newFilename = \`\${filename_without_ext}_64x64_thumbnail.\${filename_ext}\`;
      const gcsNewObject = bucket.file(newFilename);

      try {
        const [buffer] = await gcsObject.download();
        const resizedBuffer = await sharp(buffer)
          .resize(64, 64, {
            fit: 'inside',
            withoutEnlargement: true,
          })
          .toFormat(filename_ext)
          .toBuffer();

        await gcsNewObject.save(resizedBuffer, {
          metadata: {
            contentType: \`image/\${filename_ext}\`,
          },
        });

        console.log(\`Success: \${fileName} → \${newFilename}\`);

        await pubsub
          .topic(topicName)
          .publishMessage({ data: Buffer.from(newFilename) });

        console.log(\`Message published to \${topicName}\`);
      } catch (err) {
        console.error(\`Error: \${err}\`);
      }
    } else {
      console.log(\`gs://\${bucketName}/\${fileName} is not an image I can handle\`);
    }
  } else {
    console.log(\`gs://\${bucketName}/\${fileName} already has a thumbnail\`);
  }
});
EOF

    echo "$TEMP_DIR"
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
    curl -s -o test_image.jpg "https://storage.googleapis.com/cloud-training/gsp315/map.jpg"
    check_command "Download test image"

    # Upload to bucket
    print_status "Uploading test image to bucket..."
    gcloud storage cp test_image.jpg gs://$BUCKET_NAME/
    check_command "Upload test image"

    # Clean up local test file
    rm -f test_image.jpg

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
gcloud storage buckets create gs://$BUCKET_NAME \
  --location=$REGION \
  --uniform-bucket-level-access
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

# Change to temp directory and deploy function
cd "$TEMP_DIR"
print_status "Deploying Cloud Run Function..."
gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime=nodejs22 \
  --region=$REGION \
  --source=. \
  --entry-point=$FUNCTION_NAME \
  --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" \
  --trigger-event-filters="bucket=$BUCKET_NAME" \
  --allow-unauthenticated \
  --set-env-vars TOPIC_NAME=$TOPIC_NAME
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
    gcloud storage rm -r gs://$BUCKET_NAME --quiet
    check_command "Cleanup - Delete bucket"

    print_status "🧹 Cleanup completed!"
fi

print_status "Lab automation script completed. Thank you!"
