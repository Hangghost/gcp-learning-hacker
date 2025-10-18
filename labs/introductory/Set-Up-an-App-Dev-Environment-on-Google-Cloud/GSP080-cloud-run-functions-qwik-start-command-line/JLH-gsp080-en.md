# GSP080 - Cloud Run Functions: Qwik Start - Command Line

## Lab Overview
A Cloud Run function is a piece of code that runs in response to an event, such as an HTTP request, a message from a messaging service, or a file upload. Cloud events are *things* that happen in your cloud environment. These might be things like changes to data in a database, files added to a storage system, or a new virtual machine instance being created.

Since Cloud Run functions are event-driven, they only run when something happens. This makes them a good choice for tasks that need to be done quickly or that don't need to be running all the time.

For example, you can use a Cloud Run function to:

- automatically generate thumbnails for images that are uploaded to Cloud Storage.
- send a notification to a user's phone when a new message is received in Pub/Sub.
- process data from a Cloud Firestore database and generate a report.

You can write your code in any language that supports Node.js, and you can deploy your code to the cloud with a few clicks. Once your Cloud Run function is deployed, it will automatically start running in response to events.

This hands-on lab shows you how to create, deploy, and test a Cloud Run function using the Google Cloud Shell command line.

## Prerequisites
- Google Cloud Platform account
- Basic familiarity with Google Cloud Shell and command line operations
- Understanding of basic programming concepts
- Familiarity with Node.js and JavaScript

## Objectives
By the end of this lab, you will be able to:
- Create a Cloud Run function using the command line
- Deploy and test the function
- View function logs
- Understand how Pub/Sub triggers work

## Estimated Time
45-60 minutes

## Lab Steps

### Step 1: Create a function
In this task, you're going to create a simple function named `helloWorld`. This function writes a message to the Cloud Run functions logs. It is triggered by Cloud Run function events and accepts a callback function used to signal completion of the function.

For this lab the Cloud Run function event is a pub/sub topic event. A pub/sub is a messaging service where the senders of messages are decoupled from the receivers of messages. When a message is sent or posted, a subscription is required for a receiver to be alerted and receive the message.

**Instructions:**
1. In Cloud Shell, run the following command to set the default region:

   ```bash
   gcloud config set run/region REGION
   ```

2. Create a directory for the function code:

   ```bash
   mkdir gcf_hello_world && cd $_
   ```

3. Create and open `index.js` to edit:

   ```bash
   nano index.js
   ```

4. Copy the following into the `index.js` file:

   ```javascript
   const functions = require('@google-cloud/functions-framework');

   // Register a CloudEvent callback with the Functions Framework that will
   // be executed when the Pub/Sub trigger topic receives a message.
   functions.cloudEvent('helloPubSub', cloudEvent => {
     // The Pub/Sub message is passed as the CloudEvent's data payload.
     const base64name = cloudEvent.data.message.data;

     const name = base64name
       ? Buffer.from(base64name, 'base64').toString()
       : 'World';

     console.log(`Hello, ${name}!`);
   });
   ```

5. To save the file and exit nano, press CTRL+X, then press Y, and then press ENTER.

6. Create and open `package.json` to edit:

   ```bash
   nano package.json
   ```

7. Copy the following into the `package.json` file:

   ```json
   {
     "name": "gcf_hello_world",
     "version": "1.0.0",
     "main": "index.js",
     "scripts": {
       "start": "node index.js",
       "test": "echo \"Error: no test specified\" && exit 1"
     },
     "dependencies": {
       "@google-cloud/functions-framework": "^3.0.0"
     }
   }
   ```

8. To save the file and exit nano, press CTRL+X, then press Y, and then press ENTER.

9. Install the package dependencies:

   ```bash
   npm install
   ```

**Expected Result:**
npm installation successful, showing 140 packages added.

### Step 2: Deploy your function
In this task, you will deploy the function to a pub/sub topic named `cf-demo`.

**Instructions:**
1. Deploy the nodejs-pubsub-function function to a pub/sub topic named cf-demo:

   ```bash
   gcloud functions deploy nodejs-pubsub-function \
     --gen2 \
     --runtime=nodejs20 \
     --region=REGION \
     --source=. \
     --entry-point=helloPubSub \
     --trigger-topic cf-demo \
     --stage-bucket PROJECT_ID-bucket \
     --service-account cloudfunctionsa@PROJECT_ID.iam.gserviceaccount.com \
     --allow-unauthenticated
   ```

   **Note:** If you get a service account serviceAccountTokenCreator notification select "n".

2. Verify the status of the function:

   ```bash
   gcloud functions describe nodejs-pubsub-function \
     --region=REGION
   ```

**Expected Result:**
Function status shows as ACTIVE, indicating successful deployment.

### Step 3: Test the function
In this task, you will test that the deployed function writes a message to the cloud log after detecting an event.

**Instructions:**
1. Invoke the PubSub with some data:

   ```bash
   gcloud pubsub topics publish cf-demo --message="Cloud Function Gen2"
   ```

**Expected Result:**
Message published successfully, returning a message ID.

### Step 4: View logs
In this task, you will check the logs to see your messages in the log history.

**Instructions:**
1. Check the logs to see your messages in the log history:

   ```bash
   gcloud functions logs read nodejs-pubsub-function \
     --region=REGION
   ```

   **Note:** The logs can take around 10 mins to appear. Also, the alternative way to view the logs is, go to Logging > Logs Explorer.

**Expected Result:**
You can see function output similar to below:
```
LEVEL:
NAME: nodejs-pubsub-function
EXECUTION_ID: h4v6akxf4sxt
TIME_UTC: 2024-08-05 15:15:25.723
LOG: Hello, Cloud Function Gen2!
```

### Step 5: Test your understanding
Below are multiple-choice questions to reinforce your understanding of this lab's concepts. Answer them to the best of your abilities.

Serverless lets you write and deploy code without the hassle of managing the underlying infrastructure.
- True
- False

## Verification
To verify that the lab was completed successfully:
- Function has been created with correct code
- Function has been successfully deployed and is in ACTIVE state
- Function test successfully triggered and logged messages
- Able to view function logs

## Troubleshooting
Common issues and their solutions:
- **npm install failure**: Check your network connection and ensure you have appropriate permissions
- **Deployment failure**: Check that your project ID and region settings are correct
- **Pub/Sub publish failure**: Ensure the topic name is correct and you have publish permissions
- **Logs not appearing**: Wait a few minutes, logs may take time to appear

## Cleanup
To clean up resources and avoid charges:
1. Delete the function:
   ```bash
   gcloud functions delete nodejs-pubsub-function --region=REGION
   ```

2. Delete the Pub/Sub topic:
   ```bash
   gcloud pubsub topics delete cf-demo
   ```

3. Delete the storage bucket:
   ```bash
   gsutil rm -r gs://PROJECT_ID-bucket
   ```

## Additional Resources
- [Cloud Run Functions Documentation](https://cloud.google.com/functions/docs)
- [Pub/Sub: A Google-Scale Messaging Service](https://cloud.google.com/pubsub/architecture)
- [Background Functions](https://cloud.google.com/functions/docs/writing/background)
- [Events and Triggers](https://cloud.google.com/functions/docs/concepts/events-triggers)
- [Cloud Run Functions: Qwik Start - Console](https://google.qwiklabs.com/catalog_lab/704)
- "Qwik Starts" series of labs in Google Cloud Skill Boost

## Notes
- Cloud Run Functions Gen 2 uses new execution environment
- Pub/Sub is a core component of event-driven architecture
- Functions only run when events occur, saving costs
- Supports multiple programming languages and runtime environments
- Can integrate with various GCP services
