# GSP081 - Cloud Run Functions: Qwik Start - Console

## Lab Overview
A Cloud Run function is a piece of code that runs in response to an event, such as an HTTP request, a message from a messaging service, or a file upload. Cloud events are *things* that happen in your cloud environment. These might be things like changes to data in a database, files added to a storage system, or a new virtual machine instance being created.

Since Cloud Run functions are event-driven, they only run when something happens. This makes them a good choice for tasks that need to be done quickly or that don't need to be running all the time.

For example, you can use a Cloud Run function to:

- automatically generate thumbnails for images that are uploaded to Cloud Storage.
- send a notification to a user's phone when a new message is received in Pub/Sub.
- process data from a Cloud Firestore database and generate a report.

You can write your code in any language that supports Node.js, and you can deploy your code to the cloud with a few clicks. Once your Cloud Run function is deployed, it will automatically start running in response to events.

This hands-on lab shows you how to create, deploy, and test a Cloud Run function using the Google Cloud console.

## Prerequisites
- Google Cloud Platform account
- Basic familiarity with Google Cloud Console
- Understanding of basic programming concepts

## Objectives
By the end of this lab, you will be able to:
- Create a Cloud Run function
- Deploy and test the function
- View logs from the function

## Estimated Time
30-45 minutes

## Lab Steps

### Step 1: Create a function
In this task, you're going to create a Cloud Run function using the console.

**Instructions:**
1. In the console, on the **Navigation menu ()** click **Cloud Run**.

2. Click **WRITE A FUNCTION**.

3. In the **function** dialog, enter the following values:

   | **Field** | **Value** |
   | --- | --- |
   | Service name | gcfunction |
   | Region | `REGION` |
   | Authentication | Allow public access |
   | Memory allocated (In Containers, Volumes, Networking, Security Settings) | Keep default |
   | Execution environment (In Containers, Volumes, Networking, Security Settings) | Second generation |
   | Revision scaling (In Containers, Volumes, Networking, Security Settings) | Set the **Maximum number of instance** to **5**, and then click **Create** |

**Note:** A helpful popup may appear to validate the required APIs are enabled in the project. Click the **ENABLE** button when requested.

You deploy the function in the next section.

**Expected Result:**
Function has been successfully created and ready for deployment.

### Step 2: Deploy the function
In this task, you will deploy the Cloud Run function.

**Instructions:**
1. Still in the **Create function** dialog, in Source code for **Inline editor** use the default `helloHttp` function implementation already provided for index.js.

2. Click **SAVE and REDEPLOY** to deploy the function.

**Note:** While the function is being deployed, the icon next to it is a small spinner. When it's deployed, the spinner is a green check mark.

**Expected Result:**
Function has been successfully deployed and ready for testing.

### Step 3: Test the function
In this task, you will test the deployed function.

**Instructions:**
1. On the function details dashboard, to test the function click **TEST**.

2. In the Triggering event field, enter the following text between the brackets `{}`.

   `"message":"Hello World!"`

3. Copy the **CLI test command** and run it in the Cloud Shell.

4. You will see the "Hello World!" message as the output.

**Expected Result:**
Function executed successfully and returned the "Hello World!" message.

### Step 4: View logs
In this task, you will view logs from the function.

**Instructions:**
1. On the **Service Details** page, click **Observability** and select **Logs**.

**Expected Result:**
You can see the log history for the function.

### Step 5: Test your understanding
Below are multiple-choice questions to reinforce your understanding of this lab's concepts. Answer them to the best of your abilities.

Cloud Run functions is a serverless execution environment for event driven services on Google Cloud.
- True
- False

Which type of trigger is used while creating Cloud Run functions in the lab?
- HTTP
- Pub/Sub
- Cloud Storage
- Firebase

## Verification
To verify that the lab was completed successfully:
- Function has been created and deployed
- Function test successfully returns "Hello World!" message
- Able to view function logs

## Troubleshooting
Common issues and their solutions:
- **API not enabled**: If you receive an error that APIs are not enabled, click the **ENABLE** button provided to enable the necessary APIs
- **Deployment failure**: Check your network connection and ensure you have appropriate permissions
- **Test failure**: Ensure the JSON format is correct and that the function has been fully deployed

## Cleanup
To clean up resources and avoid charges:
1. Navigate to the Cloud Run console
2. Select your function
3. Click **Delete** to delete the function
4. Confirm the deletion

## Additional Resources
- [Cloud Run Functions Documentation](https://cloud.google.com/functions/docs)
- [Events and Triggers](https://cloud.google.com/functions/docs/concepts/events-triggers)
- [Cloud Run Functions: Qwik Start - Using the Command Line](https://google.qwiklabs.com/catalog_lab/924)
- "Qwik Starts" series of labs in Google Cloud Skill Boost

## Notes
- Cloud Run Functions is Google's serverless functions service
- Functions only run when events occur, saving costs
- Can integrate with various GCP services
- Supports multiple programming languages and runtime environments
