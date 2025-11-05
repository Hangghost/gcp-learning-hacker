# GSP762 - Creating PDFs with Go and Cloud Run

## Lab Overview

In this lab, you build a PDF converter web app on Cloud Run, a serverless service, to automatically convert files stored in Google Drive into PDFs stored in segregated Google Drive folders.

## Scenario

You assist the Pet Theory Veterinary practice to automatically convert their invoices into PDFs for customer ease of use.

*Architecture diagram*

This lab requires the use of Google APIs. The following APIs have been enabled for you:

| Name | API |
|------|-----|
| Cloud Build | cloudbuild.googleapis.com |
| Cloud Storage | storage-component.googleapis.com |
| Cloud Run Admin | run.googleapis.com |

## Objectives

In this lab, you learn how to perform the following tasks:

- Obtain the source code for the lab
- Convert a Go application to a container
- Build containers with Google Cloud Build
- Create a Cloud Run service that converts files to PDF files in the cloud
- Create a service account and add permissions
- Initiate a trigger for Cloud Storage notifications
- Use event processing with Cloud Storage

## Task 1. Get the source code

In this task, you get started by downloading the code that's necessary for this lab.

1. Run the following command in Cloud Shell to activate your lab account:

```bash
gcloud auth list --filter=status:ACTIVE --format="value(account)"
```

2. Run the following command to clone the Pet Theory repository:

```bash
git clone https://github.com/Deleplace/pet-theory.git
```

3. Run the following command to change to the correct directory:

```bash
cd pet-theory/lab03
```

## Enable Gemini Code Assist in the Cloud Shell IDE

You can use Gemini Code Assist in an integrated development environment (IDE) such as Cloud Shell to receive guidance on code or solve problems with your code. Before you can start using Gemini Code Assist, you need to enable it.

1. In Cloud Shell, enable the **Gemini for Google Cloud** API with the following command:

```bash
gcloud services enable cloudaicompanion.googleapis.com
```

2. Click **Open Editor** on the Cloud Shell toolbar.

**Note:** To open the Cloud Shell Editor, click **Open Editor** on the Cloud Shell toolbar. You can switch between Cloud Shell and the code Editor by clicking **Open Editor** or **Open Terminal**, as required.

3. In the left pane, click the **Settings** icon, then in the **Settings** view, search for **Gemini Code Assist**.

4. Locate and ensure that the checkbox is selected for **Geminicodeassist: Enable**, and close the **Settings**.

5. Click **Cloud Code - No Project** in the status bar at the bottom of the screen.

6. Authorize the plugin as instructed. If a project is not automatically selected, click **Select a Google Cloud Project**, and choose `Project ID`.

7. Verify that your Google Cloud project (`Project ID`) displays in the Cloud Code status message in the status bar.

## Task 2. Create an invoice microservice

In this task, you create a Go application to process requests. As outlined in the architecture diagram, you intend to integrate Cloud Storage as part of the solution.

1. In the Cloud Shell Editor's File Explorer, navigate to **pet-theory** > **lab03** > **server.go**.

2. Open the `server.go` file. This action enables Gemini Code Assist, as indicated by the presence of the **Gemini Code Assist: Smart Actions** icon in the upper-right corner of the editor.

   *Gemini Code Assist: Smart Actions diagram*

3. Open the `server.go` source code and edit it to match the following:

```go
package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
  "os/exec"
  "regexp"
  "strings"
)

func main() {
  http.HandleFunc("/", process)

  port := os.Getenv("PORT")
  if port == "" {
      port = "8080"
      log.Printf("Defaulting to port %s", port)
  }

  log.Printf("Listening on port %s", port)
  err := http.ListenAndServe(fmt.Sprintf(":%s", port), nil)
  log.Fatal(err)
}

func process(w http.ResponseWriter, r *http.Request) {
  log.Println("Serving request")

  if r.Method == "GET" {
      fmt.Fprintln(w, "Ready to process POST requests from Cloud Storage trigger")
      return
  }

  //
  // Read request body containing Cloud Storage object metadata
  //
  gcsInputFile, err1 := readBody(r)
  if err1 != nil {
      log.Printf("Error reading POST data: %v", err1)
      w.WriteHeader(http.StatusBadRequest)
      fmt.Fprintf(w, "Problem with POST data: %v \n", err1)
      return
  }

  //
  // Working directory (concurrency-safe)
  localDir, err := os.MkdirTemp("", "")
  if err != nil {
      log.Printf("Error creating local temp dir: %v", err)
      w.WriteHeader(http.StatusInternalServerError)
      fmt.Fprintf(w, "Could not create a temp directory on server. \n")
      return
  }
  defer os.RemoveAll(localDir)

  //
  // Download input file from Cloud Storage
  //
  localInputFile, err2 := download(gcsInputFile, localDir)
  if err2 != nil {
      log.Printf("Error downloading Cloud Storage file [%s] from bucket [%s]: %v",
          gcsInputFile.Name, gcsInputFile.Bucket, err2)
      w.WriteHeader(http.StatusInternalServerError)
      fmt.Fprintf(w, "Error downloading Cloud Storage file [%s] from bucket [%s]",
          gcsInputFile.Name, gcsInputFile.Bucket)
      return
  }

  //
  // Use LibreOffice to convert local input file to local PDF file.
  //
  localPDFFilePath, err3 := convertToPDF(localInputFile.Name(), localDir)
  if err3 != nil {
      log.Printf("Error converting to PDF: %v", err3)
      w.WriteHeader(http.StatusInternalServerError)
      fmt.Fprintf(w, "Error converting to PDF.")
      return
  }

  //
  // Upload the freshly generated PDF to Cloud Storage
  //
  targetBucket := os.Getenv("PDF_BUCKET")
  err4 := upload(localPDFFilePath, targetBucket)
  if err4 != nil {
      log.Printf("Error uploading PDF file to bucket [%s]: %v", targetBucket, err4)
      w.WriteHeader(http.StatusInternalServerError)
      fmt.Fprintf(w, "Error downloading Cloud Storage file [%s] from bucket [%s]",
          gcsInputFile.Name, gcsInputFile.Bucket)
      return
  }

  //
  // Delete the original input file from Cloud Storage.
  //
  err5 := deleteGCSFile(gcsInputFile.Bucket, gcsInputFile.Name)
  if err5 != nil {
      log.Printf("Error deleting file [%s] from bucket [%s]: %v", gcsInputFile.Name,
          gcsInputFile.Bucket, err5)
      // This is not a blocking error.
      // The PDF was successfully generated and uploaded.
  }

  log.Println("Successfully produced PDF")
  fmt.Fprintln(w, "Successfully produced PDF")
}

func convertToPDF(localFilePath string, localDir string) (resultFilePath string, err error) {
  log.Printf("Converting [%s] to PDF", localFilePath)
  cmd := exec.Command("libreoffice", "--headless", "--convert-to", "pdf",
      "--outdir", localDir,
      localFilePath)
  cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
  log.Println(cmd)
  err = cmd.Run()
  if err != nil {
      return "", err
  }

  pdfFilePath := regexp.MustCompile(`\.\w+$`).ReplaceAllString(localFilePath, ".pdf")
  if !strings.HasSuffix(pdfFilePath, ".pdf") {
      pdfFilePath += ".pdf"
  }
  log.Printf("Converted %s to %s", localFilePath, pdfFilePath)
  return pdfFilePath, nil
}
```

4. Click the **Gemini Code Assist: Smart Actions** icon and select **Explain this**.

   *Gemini Code Assist: Smart Actions diagram*

5. Gemini Code Assist opens a chat pane with the prefilled prompt of **Explain this**. In the inline text box of the Code Assist chat, replace the prefilled prompt with the following, and click **Send**:

```
You are an expert Go developer at Cymbal AI. A new team member is unfamiliar with this server implementation. Explain this "server.go" file in detail, breaking down its key components used in the code.

For the suggested improvements, don't update this file.
```

The explanation for the code in the `server.go` file appears in the **Gemini Code Assist** chat.

6. In the Cloud Shell terminal, run the following command to build the application:

```bash
go build -o server
```

The functions called by this top-level code are in source files:

- server.go
- notification.go
- gcs.go

With the application successfully built, you can create the PDF conversion service.

## Task 3. Create a PDF conversion service

The PDF service uses Cloud Run and Cloud Storage to initiate a process each time a file is uploaded to the designated storage.

To achieve this, you decide to use a common pattern of event notifications together with Cloud Pub/Sub. Doing this enables the application to concentrate only on processing information. Transporting and passing information is performed by other services, which allows you to keep the application simple.

Building the invoice module requires the integration of two components:

*Container including two components: server and LibreOffice*

Adding the LibreOffice package means it can be used in your application.

1. In the **Open editor**, open the existing `Dockerfile` manifest and update the file as follows:

```dockerfile
FROM amd64/debian
RUN apt-get update -y \
  && apt-get install -y libreoffice \
  && apt-get clean
WORKDIR /usr/src/app
COPY server .
CMD [ "./server" ]
```

2. **Save** the updated `Dockerfile`.

3. Click the **Gemini Code Assist: Smart Actions** icon and select **Explain this**.

   *Gemini Code Assist: Smart Actions diagram*

4. Gemini Code Assist opens a chat pane with the prefilled prompt of **Explain this**. In the inline text box of the Code Assist chat, replace the prefilled prompt with the following, and click **Send**:

```
You are a Senior DevOps Engineer at Cymbal AI. A new team member has asked you to explain the Dockerfile. Provide a comprehensive explanation of the contents and structure of this Dockerfile, including key instructions and best practices.

For the suggested improvements, don't update this Dockerfile.
```

The explanation for the code in the `Dockerfile` file appears in the **Gemini Code Assist** chat.

5. Initiate a rebuild of the `pdf-converter` image using Cloud Build:

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter
```

Click **Check my progress** to verify that you've performed the above task.

Build an image with Cloud Build

6. Deploy the updated PDF converter service.

   **Note:** It's a good idea to give LibreOffice 2GB of RAM to work with, see the line with the `--memory` option.

7. Run the following commands to build the container and deploy it:

```bash
gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region "REGION" \
  --memory=2Gi \
  --no-allow-unauthenticated \
  --set-env-vars PDF_BUCKET=$GOOGLE_CLOUD_PROJECT-processed \
  --max-instances=3
```

Click **Check my progress** to verify that you've performed this task.

Deploy the PDF converter service

The Cloud Run service has now been deployed successfully. However, you deployed an application that requires the correct permissions to access it.

## Task 4. Create a service account

A [service account](https://cloud.google.com/iam/docs/understanding-service-accounts) is a special type of account with access to Google APIs.

This lab uses a service account to access Cloud Run when a Cloud Storage event is processed. Cloud Storage supports a rich set of notifications that can be used to trigger events.

In this task, you update the code to notify the application when a file has been uploaded.

1. Click the **Navigation menu** () > **Cloud Storage**, and verify that two buckets have been created. You should see:

   - `PROJECT_ID`processed
   - `PROJECT_ID`upload

2. Create a Pub/Sub notification to indicate that a new file has been uploaded to the docs bucket ("uploaded"). The notification is labeled with the topic "new-doc".

```bash
gsutil notification create -t new-doc -f json -e OBJECT_FINALIZE gs://$GOOGLE_CLOUD_PROJECT-upload
```

**Expected output:**

```
Created Cloud Pub/Sub topic projects/"PROJECT_ID"/topics/new-doc
Created notification config projects/_/buckets/"PROJECT_ID"-upload/notificationConfigs/1
```

3. Create a new service account to trigger the Cloud Run services:

```bash
gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"
```

**Expected output:**

```
Created service account [pubsub-cloud-run-invoker].
```

4. Give the service account permission to invoke the PDF converter service:

```bash
gcloud run services add-iam-policy-binding pdf-converter \
  --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
  --role=roles/run.invoker \
  --region "REGION" \
  --platform managed
```

**Expected output:**

```
Updated IAM policy for service [pdf-converter].
bindings:
- members:
  - serviceAccount:pubsub-cloud-run-invoker@"PROJECT_ID".iam.gserviceaccount.com
    role: roles/run.invoker
    etag: BwYYfbXS240=
    version: 1
```

5. Find your project number by running this command:

```bash
PROJECT_NUMBER=$(gcloud projects list \
 --format="value(PROJECT_NUMBER)" \
 --filter="$GOOGLE_CLOUD_PROJECT")
```

6. Enable your project to create Cloud Pub/Sub authentication tokens:

```bash
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member=serviceAccount:"PROJECT_ID"@"PROJECT_ID".iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountTokenCreator
```

Click **Check my progress** to verify that you've performed this task.

Create a service account

With the service account created, it can be used to invoke the Cloud Run Service.

## Task 5. Test the Cloud Run service

Before progressing further, you need to test the deployed service. Since the service requires authentication, testing it helps ensure that it is actually private.

1. Save the URL of your service in the environment variable **$SERVICE_URL**:

```bash
SERVICE_URL=$(gcloud run services describe pdf-converter \
  --platform managed \
  --region "REGION" \
  --format "value(status.url)")
```

2. Display the SERVICE URL:

```bash
echo $SERVICE_URL
```

3. Make an anonymous GET request to your new service:

```bash
curl -X GET $SERVICE_URL
```

**Expected output:**

```
<html><head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<title>403 Forbidden</title>
</head>
<body text=#000000 bgcolor=#ffffff>
<h1>Error: Forbidden</h1>
<h2>Your client does not have permission to get URL <code>/</code> from this server.</h2>
<h2></h2>
```

**Note:** The anonymous GET request results in an error message: `"Your client does not have permission to get URL"`. This is good; you don't want the service to be callable by anonymous users.

4. Now try invoking the service as an authorized user:

```bash
curl -X GET -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL
```

**Expected output:**

```
Ready to process POST requests from Cloud Storage trigger
```

Great work, you have successfully deployed an authenticated Cloud Run service.

## Task 6. Configure a Cloud Storage trigger

To initiate a notification when new content is uploaded to Cloud Storage, add a subscription to your existing Pub/Sub Topic.

**Note:** Cloud Storage notifications automatically push a message to your Topic queue when new content is uploaded. Using notifications allows you to create powerful applications that respond to events without needing to write additional code.

- Create a Pub/Sub subscription so that the PDF converter runs whenever a message is published to the topic `new-doc`:

```bash
gcloud pubsub subscriptions create pdf-conv-sub \
  --topic new-doc \
  --push-endpoint=$SERVICE_URL \
  --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

**Expected output:**

```
Created subscription [projects/"PROJECT_ID"/subscriptions/pdf-conv-sub].
```

Click **Check my progress** to verify that you've performed this task.

Confirm the Pub/Sub subscription

Now whenever a file is uploaded, the Pub/Sub subscription interacts with your service account. The service account then initiates your PDF Converter Cloud Run service.

## Task 7. Test the Cloud Storage notification

To test the Cloud Run service, use the example files available.

1. Copy the test files into your upload bucket:

```bash
gsutil -m cp -r gs://spls/gsp762/* gs://$GOOGLE_CLOUD_PROJECT-upload
```

**Expected output:**

```
Copying gs://spls/gsp762/cat-and-mouse.jpg [Content-Type=image/jpeg]...
Copying gs://spls/gsp762/file-sample_100kB.doc [Content-Type=application/msword]...
Copying gs://spls/gsp762/file-sample_500kB.docx [Content-Type=application/vnd.openxmlformats-officedocument.wordprocessingml.document]...
Copying gs://spls/gsp762/file_example_XLS_10.xls [Content-Type=application/vnd.ms-excel]...
Copying gs://spls/gsp762/file-sample_1MB.docx [Content-Type=application/vnd.openxmlformats-officedocument.wordprocessingml.document]...
Copying gs://spls/gsp762/file_example_XLSX_50.xlsx [Content-Type=application/vnd.openxmlformats-officedocument.spreadsheetml.sheet]...
Copying gs://spls/gsp762/file_example_XLS_100.xls [Content-Type=application/vnd.ms-excel]...
Copying gs://spls/gsp762/file_example_XLS_50.xls [Content-Type=application/vnd.ms-excel]...
Copying gs://spls/gsp762//Copy of cat-and-mouse.jpg [Content-Type=image/jpeg]...
```

2. In the Cloud Console, click **Cloud Storage > Buckets** followed by the bucket name ending in "**`PROJECT_ID`upload**"

3. Click the **Refresh** button a few times and see how the files are deleted, one by one, as they are converted to PDFs.

4. Then click **Buckets**, followed by the bucket name ending in "**`PROJECT_ID`processed**". It should contain PDF versions of all files.

   **Note:** It can take a few minutes for files to be processed. Use the Bucket refresh option to check the processing completion state.

5. Feel free to open the PDF files to make sure they were properly converted.

6. Once the upload is done, click **Navigation menu > Cloud Run**, and click on the **pdf-converter** service.

7. Select the **LOGS** tab and add a filter of "Converting" to see the converted files.

8. Navigate to **Navigation menu > Cloud Storage** and open the bucket name ending in "**`PROJECT_ID`upload**" to confirm all files uploaded have been processed.

Excellent work, you have successfully built a new service that creates PDFs from files uploaded to Cloud Storage.
