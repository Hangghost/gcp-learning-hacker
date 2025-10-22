# GSP154 - Video Intelligence: Qwik Start

## Lab Title
Learn how to use the Google Cloud Video Intelligence API to annotate videos, making video content searchable and discoverable.

## Prerequisites
- Google Cloud Platform account
- Basic GCP knowledge
- Familiarity with command-line operations

## Objectives
By the end of this lab, you will be able to:
- Set up authorization for a custom service account
- Send an annotate video request to the Video Intelligence API

## Estimated Time
45 minutes

## Lab Steps

### Step 1: Activate Cloud Shell
Cloud Shell is a virtual machine loaded with development tools. It offers a persistent 5GB home directory and runs on Google Cloud.

**Instructions:**
1. Click **Activate Cloud Shell** at the top of the Google Cloud console
2. Click through the following windows:
   - Continue through the Cloud Shell information window
   - Authorize Cloud Shell to use your credentials to make Google Cloud API calls

**Expected Result:**
You are connected to Cloud Shell and authenticated.

### Step 2: Set up authorization
For this lab, create and use a service account that is tied to your Google Cloud project for authorization.

**Instructions:**
1. In Cloud Shell, run the following command to create a new service account named `quickstart`:
   ```bash
   gcloud iam service-accounts create quickstart
   ```

2. Create a service account key file, replacing `<your-project-123>` with your Project ID:
   ```bash
   gcloud iam service-accounts keys create key.json --iam-account quickstart@<your-project-123>.iam.gserviceaccount.com
   ```

3. Now authenticate your service account, passing the location of your service account key file:
   ```bash
   gcloud auth activate-service-account --key-file key.json
   ```

4. Obtain an authorization token using your service account:
   ```bash
   gcloud auth print-access-token
   ```

**Expected Result:**
You have successfully created a service account and obtained an authorization token.

### Step 3: Make an annotate video request
Use the Video Intelligence API to annotate a video.

**Instructions:**
1. Run this command to create a JSON request file named `request.json`:
   ```bash
   cat > request.json <<EOF
   {
      "inputUri":"gs://spls/gsp154/video/train.mp4",
      "features": [
          "LABEL_DETECTION"
      ]
   }
   EOF
   ```

2. Use `curl` to make a `videos:annotate` request:
   ```bash
   curl -s -H 'Content-Type: application/json' \
       -H 'Authorization: Bearer '$(gcloud auth print-access-token)'' \
       'https://videointelligence.googleapis.com/v1/videos:annotate' \
       -d @request.json
   ```

3. Note the operation name in the response for later queries.

4. Query the operation status using the operation name, replacing `PROJECTS`, `LOCATIONS`, and `OPERATION_NAME` with actual values:
   ```bash
   curl -s -H 'Content-Type: application/json' \
       -H 'Authorization: Bearer '$(gcloud auth print-access-token)'' \
       'https://videointelligence.googleapis.com/v1/projects/PROJECTS/locations/LOCATIONS/operations/OPERATION_NAME'
   ```

5. After waiting about a minute, re-run the query command and you should see completed results.

**Expected Result:**
You have successfully sent an annotate request to the Video Intelligence API and received processing results.

## Verification
Verify that your operation completed successfully:
- Confirm the API response includes `done: true`
- Verify `annotationResults` contains video label information
- Check that the response includes entity IDs and confidence scores

## Troubleshooting
Common issues and solutions:
- **Authorization failure**: Ensure the service account key file was created correctly and is not expired
- **API request failure**: Check that project ID and token are correct
- **Operation timeout**: Video processing may take several minutes, please be patient
- **Permission error**: Ensure the Video Intelligence API is enabled for your project

## Cleanup
To avoid additional charges, perform these cleanup steps:
1. Delete the created service account key file:
   ```bash
   rm key.json
   ```

2. Delete the service account (if no longer needed):
   ```bash
   gcloud iam service-accounts delete quickstart@<your-project-123>.iam.gserviceaccount.com
   ```

## Additional Resources
- [Video Intelligence API Official Documentation](https://cloud.google.com/video-intelligence/docs/)
- [Google Cloud Storage Documentation](https://cloud.google.com/storage/docs/)
- [IAM Service Accounts Guide](https://cloud.google.com/iam/docs/service-accounts)
- Related labs: GSP097 (Cloud Natural Language API), GSP119 (Speech-to-Text API)

## Notes
- Video Intelligence API can process videos stored in Cloud Storage
- Supports multiple annotation features including label detection, object tracking, etc.
- API is asynchronous and requires polling operation status
- Processing time depends on video length and complexity
