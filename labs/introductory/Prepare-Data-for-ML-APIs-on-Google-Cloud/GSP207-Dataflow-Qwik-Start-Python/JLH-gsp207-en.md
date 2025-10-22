# GSP207 - Dataflow: Qwik Start - Python

## Lab Title
Learn to set up your Python development environment for Dataflow using the Apache Beam SDK and run an example pipeline.

## Prerequisites
- Basic GCP knowledge
- Familiarity with command line operations
- Dataflow API enabled
- Basic Python knowledge

## Objectives
By the end of this lab, you will be able to:
- Create a Cloud Storage bucket to store results of a Dataflow pipeline
- Install the Apache Beam SDK for Python
- Run a Dataflow pipeline example locally
- Run a pipeline remotely on Dataflow
- Verify pipeline execution results

## Estimated Time
45 minutes

## Lab Steps

### Step 1: Set the region

In Cloud Shell, run the following command to set the project region for this lab:

```bash
gcloud config set compute/region "REGION"
```

### Step 2: Ensure that the Dataflow API is successfully enabled

To ensure access to the necessary API, restart the connection to the Dataflow API.

1. In the Cloud Console, enter "Dataflow API" in the top search bar. Click on the result for **Dataflow API**.
2. Click **Manage**.
3. Click **Disable API**.

If asked to confirm, click **Disable**.

4. Click **Enable**.

When the API has been enabled again, the page will show the option to disable.

### Step 3: Create a Cloud Storage bucket

When you run a pipeline using Dataflow, your results are stored in a Cloud Storage bucket. In this task, you create a Cloud Storage bucket for the results of the pipeline that you run in a later task.

1. On the **Navigation menu** (), click **Cloud Storage** > **Buckets**.

2. Click **Create bucket**.
3. In the **Create bucket** dialog, specify the following attributes:
   - **Name**: To ensure a unique bucket name, use the following name: `____`bucket. Note that this name does not include sensitive information in the bucket name, as the bucket namespace is global and publicly visible.
   - **Location type**: Multi-region
   - **Location**: `us`
   - A location where bucket data will be stored.
4. Click **Create**.
5. If Prompted Public access will be prevented, click **Confirm**.

**Test completed task**

Click **Check my progress** to verify your performed task. If you have completed the task successfully you will be granted an assessment score.

Create a Cloud Storage bucket.

### Step 4: Install the Apache Beam SDK for Python

1. To ensure that you use a supported Python version, begin by running the `Python3.9` Docker Image:

```bash
docker run -it -e DEVSHELL_PROJECT_ID=$DEVSHELL_PROJECT_ID python:3.9 /bin/bash
```

This command pulls a Docker container with the latest stable version of Python 3.9 and then opens up a command shell for you to run the following commands inside your container.

2. After the container is running, install the latest version of the Apache Beam SDK for Python by running the following command from a virtual environment:

```bash
pip install 'apache-beam[gcp]'==2.42.0
```

You will see some warnings returned that are related to dependencies. It is safe to ignore them for this lab.

3. Run the `wordcount.py` example locally by running the following command:

```bash
python -m apache_beam.examples.wordcount --output OUTPUT_FILE
```

You may see a message similar to the following:

```
INFO:root:Missing pipeline option (runner). Executing pipeline using the default runner: DirectRunner.
INFO:oauth2client.client:Attempting refresh to obtain initial access_token
```

This message can be ignored.

4. You can now list the files that are on your local cloud environment to get the name of the `OUTPUT_FILE`:

```bash
ls
```

5. Copy the name of the `OUTPUT_FILE` and `cat` into it:

```bash
cat <file name>
```

Your results show each word in the file and how many times it appears.

### Step 5: Run an example Dataflow pipeline remotely

1. Set the BUCKET environment variable to the bucket you created earlier:

```bash
BUCKET=gs://<bucket name provided earlier>
```

2. Now you'll run the `wordcount.py` example remotely:

```bash
python -m apache_beam.examples.wordcount --project $DEVSHELL_PROJECT_ID \
  --runner DataflowRunner \
  --staging_location $BUCKET/staging \
  --temp_location $BUCKET/temp \
  --output $BUCKET/results/output \
  --region "filled in at lab start"
```

In your output, wait until you see the message:

```
JOB_MESSAGE_DETAILED: Workers have started successfully.
```

Then continue with the lab.

### Step 6: Check that your Dataflow job succeeded

1. Open the Navigation menu and click **Dataflow** from the list of services.

You should see your **wordcount** job with a **status** of **Running** at first.

2. Click on the name to watch the process. When all the boxes are checked off, you can continue watching the logs in Cloud Shell.

The process is complete when the status is **Succeeded**.

**Test completed task**

Click **Check my progress** to verify your performed task. If you have completed the task successfully you will be granted with an assessment score.

Run an Example Pipeline Remotely.

3. Click **Navigation menu** > **Cloud Storage** in the Cloud Console.
4. Click on the name of your bucket. In your bucket, you should see the **results** and **staging** directories.
5. Click on the **results** folder and you should see the output files that your job created:
6. Click on a file to see the word counts it contains.

### Step 7: Test your understanding

Below is a multiple choice question to reinforce your understanding of this lab's concepts. Answer it to the best of your abilities.

Dataflow temp_location must be a valid Cloud Storage URL.
- [x] True
- [ ] False

## Verification
To verify that the lab was completed successfully:

1. Check that the Dataflow job status is **Succeeded**
2. Confirm that results and staging directories exist in the Cloud Storage bucket
3. Verify that output files contain expected word count results

## Troubleshooting
Common issues and their solutions:

- **Docker container issues**: Ensure you have permissions to run Docker commands
- **Pip installation failures**: Check network connectivity and Python version compatibility
- **Dataflow job failures**: Check project quotas, permissions, and region settings
- **Cloud Storage access issues**: Verify bucket name and permissions

## Cleanup
To clean up resources and avoid charges:

1. Delete the Cloud Storage bucket:
```bash
gsutil rm -r gs://<your-bucket-name>
```

2. If any other resources were created, ensure they are deleted

## Additional Resources
- [Apache Beam Documentation](https://beam.apache.org/)
- [Google Cloud Dataflow Documentation](https://cloud.google.com/dataflow/docs)
- [Python Apache Beam SDK Documentation](https://beam.apache.org/documentation/sdks/python/)
- [Cloud Storage Documentation](https://cloud.google.com/storage/docs)

## Notes
- Apache Beam is an open source programming model for data pipelines
- Dataflow is Google's hosted Apache Beam runner on Google Cloud
- Always use staging_location and temp_location for storing temporary files
- Use DataflowRunner for remote execution instead of DirectRunner
