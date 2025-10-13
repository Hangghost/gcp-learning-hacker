# GSP315 - Set Up an App Dev Environment on Google Cloud: Challenge Lab

## Overview
This is the GSP315 - Set Up an App Dev Environment on Google Cloud: Challenge Lab overview. This lab tests your implementation skills on the Google Cloud Platform, specifically for configuring application development environments for new development teams.

## Tasks
In this lab, you need to complete the following tasks:
- Task 1: Create a bucket for storing photographs
- Task 2: Create a Pub/Sub topic
- Task 3: Create the thumbnail Cloud Run Function
- Task 4: Remove the previous cloud engineer's access

## Challenge Lab Summary

This section provides the commands needed to complete each task. Please follow the steps below, ensuring you have set all necessary variables.

### Initial Variable Settings
```bash
# Set your GCP project variables
export REGION="us-central1"  # or your specified region
export ZONE="us-central1-a"  # or your specified zone
export PROJECT_ID=$(gcloud config get-value project)

# Lab-specific variables (please set based on actual lab environment)
export BUCKET_NAME=""  # Bucket Name - get from lab interface
export TOPIC_NAME=""   # Topic Name - get from lab interface
export FUNCTION_NAME="" # Cloud Run Function Name - get from lab interface
export USERNAME_2=""   # Username 2 (previous cloud engineer) - get from lab interface
```

### Task Steps

#### Task 1: Create a bucket for storing photographs
```bash
# Create a Cloud Storage bucket for storing photographs
gcloud storage buckets create gs://$BUCKET_NAME \
  --location=$REGION \
  --uniform-bucket-level-access
```

#### Task 2: Create a Pub/Sub topic
```bash
# Create a Pub/Sub topic for the Cloud Run Function
gcloud pubsub topics create $TOPIC_NAME
```

#### Task 3: Create the thumbnail Cloud Run Function
```bash
# Create Cloud Run Function (2nd generation)
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
```

**Note:** You need to create `index.js` and `package.json` files with the following content:

**index.js:**
```javascript
const functions = require('@google-cloud/functions-framework');
const { Storage } = require('@google-cloud/storage');
const { PubSub } = require('@google-cloud/pubsub');
const sharp = require('sharp');

functions.cloudEvent('', async cloudEvent => {
  const event = cloudEvent.data;

  console.log(`Event: ${JSON.stringify(event)}`);
  console.log(`Hello ${event.bucket}`);

  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64";
  const bucket = new Storage().bucket(bucketName);
  const topicName = "";
  const pubsub = new PubSub();

  if (fileName.search("64x64_thumbnail") === -1) {
    // doesn't have a thumbnail, get the filename extension
    const filename_split = fileName.split('.');
    const filename_ext = filename_split[filename_split.length - 1].toLowerCase();
    const filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length - 1); // fix sub string to remove the dot

    if (filename_ext === 'png' || filename_ext === 'jpg' || filename_ext === 'jpeg') {
      // only support png and jpg at this point
      console.log(`Processing Original: gs://${bucketName}/${fileName}`);
      const gcsObject = bucket.file(fileName);
      const newFilename = `${filename_without_ext}_64x64_thumbnail.${filename_ext}`;
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
            contentType: `image/${filename_ext}`,
          },
        });

        console.log(`Success: ${fileName} → ${newFilename}`);

        await pubsub
          .topic(topicName)
          .publishMessage({ data: Buffer.from(newFilename) });

        console.log(`Message published to ${topicName}`);
      } catch (err) {
        console.error(`Error: ${err}`);
      }
    } else {
      console.log(`gs://${bucketName}/${fileName} is not an image I can handle`);
    }
  } else {
    console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
  }
});
```

**package.json:**
```json
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
```

**Test the function:**
Upload a PNG or JPG image to the bucket to verify the function works correctly.

#### Task 4: Remove the previous cloud engineer's access
```bash
# Remove the previous cloud engineer's project access
gcloud projects remove-iam-policy-binding $PROJECT_ID \
  --member="user:$USERNAME_2" \
  --role="roles/viewer"
```

## Cleanup
```bash
# To clean up resources, run the following commands:
gcloud functions delete $FUNCTION_NAME --region=$REGION --quiet
gcloud pubsub topics delete $TOPIC_NAME --quiet
gcloud storage rm -r gs://$BUCKET_NAME --quiet
```
