# GSP644 - Develop Serverless Applications on Cloud Run

## Lab Overview

Twelve years ago, Lily started the Pet Theory chain of veterinary clinics. Pet Theory currently sends invoices in DOCX format to clients, but many clients have complained that they are unable to open them. To improve customer satisfaction, Lily has asked Patrick in IT to investigate an alternative to improve the current situation.

Pet Theory's Ops team is a single person, so they are keen to invest in a cost efficient solution that doesn't require a lot of ongoing maintenance. After analyzing the various processing options, Patrick decides to use Cloud Run.

Cloud Run is serverless, so it abstracts away all infrastructure management and lets you focus on building your application instead of worrying about overhead. As a Google serverless product, it is able to scale to zero, meaning it won't incur cost when not used. It also lets you use custom binary packages based on containers, which means building consistent isolated artifacts is now feasible.

In this lab you will build a PDF converter web app on Cloud Run that automatically converts files stored in Cloud Storage into PDFs stored in separate folders.

## Prerequisites

This is an intermediate level lab. This assumes familiarity with the console and shell environments. Experience with Firebase will be helpful, but it is not required. Before taking this lab it is recommended that you have completed the following Google Cloud Skills Boost labs before taking this one:

- [Importing Data to a Firestore Database](https://google.qwiklabs.com/catalog_lab/2163)
- [Build a Serverless Web App with Firebase](https://google.qwiklabs.com/catalog_lab/2166)

Once you're ready, scroll down and follow the steps below to set up your lab environment.

## Architecture

This diagram gives you an overview of the services you will be using and how they connect to one another:

*Architecture diagram: Cloud Storage → Pub/Sub → Cloud Run → Cloud Storage*

## Objectives

In this lab, you will learn how to:

- Convert a Node JS application to a container
- Build containers with Google Cloud Build
- Create a Cloud Run service that converts files to PDF files in the cloud
- Use event processing with Cloud Storage

## Task 1. Understanding the task

Pet theory would like to convert their invoices into PDFs so that customers can open them reliably. The team wants to accomplish this conversion automatically to minimize the workload for Lisa, the office manager.

Ruby, Pet Theory's computer consultant, gets a message from Patrick in IT...

Patrick sends Ruby the code fragment he wrote to produce a PDF from a file:

```javascript
const {promisify} = require('util');
const exec        = promisify(require('child_process').exec);

const cmd = 'libreoffice --headless --convert-to pdf --outdir ' +
            `/tmp "/tmp/${fileName}"`;

const { stdout, stderr } = await exec(cmd);
if (stderr) {
  throw stderr;
}
```

Ruby responds back to Patrick...

Building the container will require the integration of a number of components:

*Components diagram: index.js, LibreOffice, Express, body-parser, child_process, and @google-cloud/storage*

## Task 2. Enable the Cloud Run API

1. Open the Navigation menu () and click APIs & Services > Library. In the search bar, enter "Cloud Run" and select the Cloud Run Admin API from the results list.

   *Cloud Run API diagram*

2. Click Enable and then hit the back button in your browser twice. Your Console should now resemble the following:

   *Console diagram*

## Task 3. Deploy a simple Cloud Run service

Ruby has developed a Cloud Run prototype and would like Patrick to deploy it onto Google Cloud. Now help Patrick establish the PDF Cloud Run service for Pet Theory.

1. Open a new Cloud Shell session and run the following command to clone the Pet Theory repository:

```bash
git clone https://github.com/rosera/pet-theory.git
```

2. Then change your current working directory to lab03:

```bash
cd pet-theory/lab03
```

3. Edit package.json with Cloud Shell Code Editor or your preferred text editor. In the "scripts" section, add "start": "node index.js", as shown below:

```json
...
"scripts": {
    "start": "node index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
...
```

4. Now run the following commands in Cloud Shell to install the packages that your conversion script will be using:

```bash
npm install express
npm install body-parser
npm install child_process
npm install @google-cloud/storage
```

5. Now open the lab03/index.js file and review the code.

The application will be deployed as a Cloud Run service that accepts HTTP POSTs. If the POST request is a Pub/Sub notification about an uploaded file, the service writes the file details to the log. If not, the service simply returns the string "OK".

6. Review the file named lab03/Dockerfile.

The above file is called a manifest and provides a recipe for the Docker command to build an image. Each line begins with a command that tells Docker how to process the following information:

- The first list indicates the base image should use node as the template for the image to be created.
- The last line indicates the command to be performed, which in this instance refers to "npm start".

7. To build and deploy the REST API, use Google Cloud Build. Run this command to start the build process:

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter
```

The command builds a container with your code and puts it in the Artifact Registry of your project.

8. Return to the Cloud Console, on the Navigation menu (), click VIEW ALL PRODUCTS. In the CI/CD section, select Artifact Registry > Repositories. You should see your container hosted:

   *Container Registry diagram*

9. Open the gcr.io repository. You should see your container hosted:

   *Container Registry diagram*

**Test completed task**

Click Check my progress to verify that you've performed the above task.

Build simple a REST API

Return to your code editor tab and in Cloud Shell run the following command to deploy your application:

```bash
gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region Region \
  --no-allow-unauthenticated \
  --max-instances=1
```

When the deployment is complete, you will see a message like this:

```
Service [pdf-converter] revision [pdf-converter-00001] has been deployed and is serving 100 percent of traffic at https://pdf-converter-[hash].a.run.app
```

10. Create the environment variable $SERVICE_URL for the app so you can easily access it:

```bash
SERVICE_URL=$(gcloud beta run services describe pdf-converter --platform managed --region Lab Region --format="value(status.url)")
echo $SERVICE_URL
```

**Test completed task**

Click Check my progress to verify that you've performed the above task.

Create a Revision for Cloud Run

Make an anonymous POST request to your new service:

```bash
curl -X POST $SERVICE_URL
```

This will result in an error message saying "Your client does not have permission to get the URL". This is good; you don't want the service to be callable by anonymous users.

Now try invoking the service as an authorized user:

```bash
curl -X POST -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL
```

If you get the response "OK" you have successfully deployed a Cloud Run service. Well done!

## Task 4. Trigger your Cloud Run service when a new file is uploaded

Now that the Cloud Run service has been successfully deployed, Ruby would like Patrick to create a staging area for the data to be converted. The Cloud Storage bucket will use an event trigger to notify the application when a file has been uploaded and needs to be processed.

1. Run the following command to create a bucket in Cloud Storage for the uploaded docs:

```bash
gsutil mb gs://$GOOGLE_CLOUD_PROJECT-upload
```

2. And another bucket for the processed PDFs:

```bash
gsutil mb gs://$GOOGLE_CLOUD_PROJECT-processed
```

3. Now return to your Cloud Console tab, open the Navigation menu and select Cloud Storage. Verify that the buckets have been created (there will be other buckets there as well that are used by the platform.)

**Test completed task**

Click Check my progress to verify that you've performed the above task.

Create two cloud storage buckets

In Cloud Shell run the following command to tell Cloud Storage to send a Pub/Sub notification whenever a new file has finished uploading to the docs bucket:

```bash
gsutil notification create -t new-doc -f json -e OBJECT_FINALIZE gs://$GOOGLE_CLOUD_PROJECT-upload
```

The notifications will be labeled with the topic "new-doc".

**Test completed task**

Click Check my progress to verify that you've performed the above task.

Create a Pub/Sub topic for handling notifications from storage bucket

Then create a new service account which Pub/Sub will use to trigger the Cloud Run services:

```bash
gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"
```

Give the new service account permission to invoke the PDF converter service:

```bash
gcloud beta run services add-iam-policy-binding pdf-converter --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --platform managed --region Lab Region
```

Find your project number by running this command:

```bash
gcloud projects list
```

Look for the project whose name starts with "qwiklabs-gcp-". You will be using the value of the Project Number in the next command.

*Project number diagram*

Create a PROJECT_NUMBER environment variable, replacing [project number] with the Project Number from the last command:

```bash
PROJECT_NUMBER=[project number]
```

Then enable your project to create Cloud Pub/Sub authentication tokens:

```bash
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator
```

**Note:**If you are getting an error as service account does not exist on executing the above command. Enable the Cloud Pub/Sub API and if it is already enabled, first Disable it and then Enable it again. Then, re-run the above command.

Finally, create a Pub/Sub subscription so that the PDF converter can run whenever a message is published on the topic "new-doc".

```bash
gcloud beta pubsub subscriptions create pdf-conv-sub --topic new-doc --push-endpoint=$SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

**Test completed task**

Click Check my progress to verify that you've performed the above task.

Create a Pub/Sub subscription

## Task 5. See if the Cloud Run service is triggered when files are uploaded to Cloud Storage

To verify the application is working as expected, Ruby asks Patrick to upload some test data to the named storage bucket and then check Cloud Logging.

1. Copy some test files into your upload bucket:

```bash
gsutil -m cp gs://spls/gsp644/* gs://$GOOGLE_CLOUD_PROJECT-upload
```

2. Once the upload is done, return to your Cloud Console tab, open the Navigation menu and click VIEW ALL PRODUCTS. Select Logging under the Observability section.

3. In the All resources dropdown, filter your results to Cloud Run Revision and click Apply. Then click Run Query.

4. In the Query results, look for a log entry that starts with file: and click it. It shows a dump of the file data that Pub/Sub sends to your Cloud Run service when a new file is uploaded.

5. Can you find the name of the file you uploaded in this object?

*Query results diagram*

**Note:**If you do not see any log entries that begin with "file", try clicking on the "load newer logs" button near the bottom of the page.

6. Now return to the code editor tab and run the following command in Cloud Shell to clean up your upload directory by deleting the files in it:

```bash
gsutil -m rm gs://$GOOGLE_CLOUD_PROJECT-upload/*
```

## Task 6. Containers

Patrick needs to convert a backlog of invoices to PDFs so all customers can open them. He emails Ruby for some help...

Patrick sends Ruby the code fragment he wrote to produce a PDF from a file:

```javascript
const {promisify} = require('util');
const exec        = promisify(require('child_process').exec);

const cmd = 'libreoffice --headless --convert-to pdf --outdir ' +
            `/tmp "/tmp/${fileName}"`;

const { stdout, stderr } = await exec(cmd);
if (stderr) {
  throw stderr;
}
```

Ruby responds back to Patrick...

Building the container will require the integration of a number of components:

*Components diagram: index.js, LibreOffice, Express, body-parser, child_process, and @google-cloud/storage*

### Update the Manifest

With all the files identified, the manifest can now be created. Help Ruby set up and deploy the container.

The package for LibreOffice was not included in the container before, which means it now needs to be added. Patrick has previously provided the commands he uses to build his application, Ruby will add these as a RUN command within the Dockerfile.

- Open the Dockerfile manifest and add the command RUN apt-get update -y && apt-get install -y libreoffice && apt-get clean line as shown below:

```dockerfile
FROM NODE_VERSION
RUN apt-get update -y \
    && apt-get install -y libreoffice \
    && apt-get clean
WORKDIR /usr/src/app
COPY package.json package*.json ./
RUN npm install --only=production
COPY . .
CMD [ "npm", "start" ]
```

### Deploy the new version of the pdf-conversion service

1. Open the index.js file and add the following package requirements at the top of the file:

```javascript
const {promisify} = require('util');
const {Storage}   = require('@google-cloud/storage');
const exec        = promisify(require('child_process').exec);
const storage     = new Storage();
```

2. **Replace** the app.post('/', async (req, res) with the following code:

```javascript
app.post('/', async (req, res) => {
  try {
    const file = decodeBase64Json(req.body.message.data);
    await downloadFile(file.bucket, file.name);
    const pdfFileName = await convertFile(file.name);
    await uploadFile(process.env.PDF_BUCKET, pdfFileName);
    await deleteFile(file.bucket, file.name);
  }
  catch (ex) {
    console.log(`Error: ${ex}`);
  }
  res.set('Content-Type', 'text/plain');
  res.send('\n\nOK\n\n');
})
```

3. Now add the following code that processes LibreOffice documents to the bottom of the file:

```javascript
// Helper function to check file existence (using fs.promises for async)
async function fileExists(filePath) {
  try {
    await fs.promises.access(filePath); // Throws an error if the file doesn't exist
    return true;
  } catch (err) {
    return false;
  }
}

async function downloadFile(bucketName, fileName) {
  // 1. Check if the file exists
  const fileExistsLocally = await fileExists(`/tmp/${fileName}`);

  // 2. Delete if present
  if (fileExistsLocally) {
    console.log(`File exists locally. Deleting: ${fileName}`);
    await fs.promises.unlink(`/tmp/${fileName}`); // Use fs.promises for async file operations
    console.log(`File deleted.`);
  } else {
    console.log(`File does not exist locally: ${fileName}`);
  }

  // 3. Download from the storage bucket
  const options = { destination: `/tmp/${fileName}` };
  await storage.bucket(bucketName).file(fileName).download(options);
  console.log(`File downloaded: ${fileName}`);
}

async function convertFile(fileName) {
  const cmd = 'libreoffice --headless --convert-to pdf --outdir /tmp ' +
              `"/tmp/${fileName}"`;
  console.log(cmd);
  const { stdout, stderr } = await exec(cmd);
  if (stderr) {
    console.log(`Conversion Failed: ${stderr}`);
    throw stderr;
  }
  console.log(`Conversion Success: ${stdout}`);
  pdfFileName = fileName.replace(/\.\w+$/, '.pdf');
  return pdfFileName;
}

async function deleteFile(bucketName, fileName) {
  await storage.bucket(bucketName).file(fileName).delete();
}

async function uploadFile(bucketName, fileName) {
  await storage.bucket(bucketName).upload(`/tmp/${fileName}`);
}
```

4. Ensure your index.js file looks like the following:

**Note:**To avoid any formatting errors, it's recommended you replace all of the code in your index.js file with this example code.

```javascript
const {promisify} = require('util');
const {Storage}   = require('@google-cloud/storage');
const exec        = promisify(require('child_process').exec);
const storage     = new Storage();
const express     = require('express');
const bodyParser  = require('body-parser');
const app         = express();

app.use(bodyParser.json());

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Listening on port', port);
});

app.post('/', async (req, res) => {
  try {
    const file = decodeBase64Json(req.body.message.data);
    await downloadFile(file.bucket, file.name);
    const pdfFileName = await convertFile(file.name);
    await uploadFile(process.env.PDF_BUCKET, pdfFileName);
    await deleteFile(file.bucket, file.name);
  }
  catch (ex) {
    console.log(`Error: ${ex}`);
  }
  res.set('Content-Type', 'text/plain');
  res.send('\n\nOK\n\n');
})

function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}

// Helper function to check file existence (using fs.promises for async)
async function fileExists(filePath) {
  try {
    await fs.promises.access(filePath); // Throws an error if the file doesn't exist
    return true;
  } catch (err) {
    return false;
  }
}
async function downloadFile(bucketName, fileName) {
  // 1. Check if the file exists
  const fileExistsLocally = await fileExists(`/tmp/${fileName}`);

  // 2. Delete if present
  if (fileExistsLocally) {
    console.log(`File exists locally. Deleting: ${fileName}`);
    await fs.promises.unlink(`/tmp/${fileName}`); // Use fs.promises for async file operations
    console.log(`File deleted.`);
  } else {
    console.log(`File does not exist locally: ${fileName}`);
  }

  // 3. Download from the storage bucket
  const options = { destination: `/tmp/${fileName}` };
  await storage.bucket(bucketName).file(fileName).download(options);
  console.log(`File downloaded: ${fileName}`);
}

async function convertFile(fileName) {
  const cmd = 'libreoffice --headless --convert-to pdf --outdir /tmp ' +
              `"/tmp/${fileName}"`;
  console.log(cmd);
  const { stdout, stderr } = await exec(cmd);
  if (stderr) {
    console.log(`Conversion Failed: ${stderr}`);
    throw stderr;
  }
  console.log(`Conversion Success: ${stdout}`);
  pdfFileName = fileName.replace(/\.\w+$/, '.pdf');
  return pdfFileName;
}

async function deleteFile(bucketName, fileName) {
  await storage.bucket(bucketName).file(fileName).delete();
}

async function uploadFile(bucketName, fileName) {
  await storage.bucket(bucketName).upload(`/tmp/${fileName}`);
}
```

The main logic is housed in these functions:

```
const file = decodeBase64Json(req.body.message.data);
await downloadFile(file.bucket, file.name);
const pdfFileName = await convertFile(file.name);
await uploadFile(process.env.PDF_BUCKET, pdfFileName);
await deleteFile(file.bucket, file.name);
```

Whenever a file has been uploaded, this service gets triggered. It performs these tasks, one per line above:

- Extracts the file details from the Pub/Sub notification.
- Downloads the file from Cloud Storage to the local hard drive. This is actually not a physical disk, but a section of virtual memory that behaves like a disk.
- Converts the downloaded file to PDF.
- Uploads the PDF file to Cloud Storage. The environment variable process.env.PDF_BUCKET contains the name of the Cloud Storage bucket to write PDFs to. You will assign a value to this variable when you deploy the service below.
- Deletes the original file from Cloud Storage.

The rest of index.js implements the functions called by this top-level code.

It's time to deploy the service, and to set the PDF_BUCKET environment variable. It's also a good idea to give LibreOffice 2 GB of RAM to work with (see the line with the --memory option).

1. Run the following command to build the container:

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter
```

**Note:**Enter Y if you receive an pop to enable the Cloud Build API

**Test completed task**

Click Check my progress to verify that you've performed the above task.

Create another build for REST API

Now deploy the latest version of your application:

```bash
gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region Lab Region \
  --memory=2Gi \
  --no-allow-unauthenticated \
  --max-instances=1 \
  --set-env-vars PDF_BUCKET=$GOOGLE_CLOUD_PROJECT-processed
```

With LibreOffice part of the container, this build will take longer than the previous one. This is a good time to get up and stretch for a few minutes.

Click Check my progress to verify the objective.

Create a new Revision

## Task 7. Testing the pdf-conversion service

1. Once the deployment commands finish, make sure that the service was deployed correctly by running:

```bash
curl -X POST -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL
```

2. If you get the response "OK" you have successfully deployed the updated Cloud Run service. LibreOffice can convert many file types to PDF: DOCX, XLSX, JPG, PNG, GIF, etc.

3. Create a script to perform the upload

```bash
cat <<'EOF' > copy_files.sh
#!/bin/bash

SOURCE_BUCKET="gs://spls/gsp644"
DESTINATION_BUCKET="gs://${GOOGLE_CLOUD_PROJECT}-upload"  # Replace with your actual bucket name
DELAY=5

# Get a list of files in the source bucket
files=$(gsutil ls "$SOURCE_BUCKET")

# Loop through the files
for file in $files; do
  # Construct the full path of the source file
  source_file_path="$file"

  # Copy the file to the destination bucket
  gsutil cp "$source_file_path" "$DESTINATION_BUCKET"

  # Check if the copy was successful
  if [ $? -eq 0 ]; then  # $? is the exit status of the previous command
    echo "Copied: $source_file_path to $DESTINATION_BUCKET"
  else
    echo "Failed to copy: $source_file_path"
  fi

  # Sleep for 5 seconds
  sleep $DELAY
done

echo "All files copied!"
EOF
```

4. Run the following command to upload some example files:

```bash
bash copy_files.sh
```

5. Return to the Cloud Console, open the Navigation menu and select Cloud Storage. Open the upload bucket and click on the Refresh button a couple of times to see how the files are deleted, one by one, as they are converted to PDFs.

6. Then click Buckets from the left menu, and click on the bucket whose name ends in "-processed". It should contain PDF versions of all files. Feel free to open the PDF files to make sure they were properly converted:

**Note:**Re-run the command if you don't see all the converted PDF files in -processed bucket.

## Congratulations!

Pet Theory now has a system for converting their archive of old files to PDFs. By simply uploading the old files to the "upload" bucket, the pdf-converter service converts them and writes them as PDFs to the "processed" bucket.

Continue your serverless journey in the Serverless Cloud Run Development course. You will read through a fictitious business scenario and assist the characters with their serverless migration plan.

## Troubleshooting

Common issues and their solutions:

- **Build failures**: Ensure all required APIs are enabled (Cloud Run API, Cloud Build API)
- **Deployment failures**: Check region settings and service account permissions
- **Conversion failures**: Ensure LibreOffice is properly installed and has sufficient memory
- **Pub/Sub notification failures**: Verify topics and subscriptions are created correctly
- **Files not processed**: Check Cloud Storage bucket permissions and Pub/Sub triggers

## Cleanup

To avoid charges, perform these cleanup steps:

1. Delete the Cloud Run service:
```bash
gcloud run services delete pdf-converter
```

2. Delete Cloud Storage buckets:
```bash
gsutil rm -r gs://$GOOGLE_CLOUD_PROJECT-upload
gsutil rm -r gs://$GOOGLE_CLOUD_PROJECT-processed
```

3. Delete Pub/Sub resources:
```bash
gcloud pubsub topics delete new-doc
gcloud pubsub subscriptions delete pdf-conv-sub
```

4. Delete service account:
```bash
gcloud iam service-accounts delete pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

## Additional Resources

- [Cloud Run Documentation](https://cloud.google.com/run/)
- [Cloud Storage Documentation](https://cloud.google.com/storage/)
- [Pub/Sub Documentation](https://cloud.google.com/pubsub/)
- [Google Cloud Build Documentation](https://cloud.google.com/cloud-build/)
- Related labs:
  - [Build a Serverless Web App with Firebase](https://google.qwiklabs.com/catalog_lab/2166)
  - [Importing Data to a Firestore Database](https://google.qwiklabs.com/catalog_lab/2163)

## Personal Notes

- This lab demonstrates the power of Cloud Run for event-driven serverless processing
- LibreOffice can run in containers for document conversion tasks
- Pub/Sub provides reliable event-driven architecture
- Environment variables are important for configuration
- Proper permissions setup is critical for inter-service communication
