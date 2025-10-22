# GSP192 - Dataflow: Qwik Start - Templates

## Lab Overview

In this lab, you learn how to create a streaming pipeline using one of Google's Dataflow templates. More specifically, you use the Pub/Sub to BigQuery template, which reads messages written in JSON from a Pub/Sub topic and pushes them to a BigQuery table. You can find the documentation for this template in the [Get started with Google-provided templates Guide](https://cloud.google.com/dataflow/docs/templates/provided-templates).

You are given the option to use the Cloud Shell command line or the Cloud console to create the BigQuery dataset and table. **Pick one method to use**, then continue with that method for the rest of the lab. If you want experience using both methods, run through this lab a second time.

## What you'll do

- Create a BigQuery dataset and table
- Create a Cloud Storage bucket
- Create a streaming pipeline using the Pub/Sub to BigQuery Dataflow template

## Prerequisites

- Basic knowledge of GCP
- Familiarity with BigQuery, Cloud Storage, and Dataflow concepts
- Understanding of Pub/Sub messaging

## Objectives

By the end of this lab, you will be able to:
- Create BigQuery resources using GCP Console or command line
- Deploy Dataflow templates to process streaming data
- Query data streamed from Pub/Sub to BigQuery

## Estimated Time

45 minutes

## Lab Steps

### Step 1: Ensure that the Dataflow API is successfully re-enabled

To ensure access to the necessary API, restart the connection to the Dataflow API.

**Instructions:**
1. In Cloud Shell, run the following commands to reset the Dataflow API by disabling and re-enabling it for your project.

```bash
gcloud services disable dataflow.googleapis.com --project $GOOGLE_CLOUD_PROJECT --force
gcloud services enable dataflow.googleapis.com --project $GOOGLE_CLOUD_PROJECT
```

**Expected Result:**
- Dataflow API has been disabled and re-enabled

### Step 2: Create a BigQuery dataset, BigQuery table, and Cloud Storage bucket using Cloud Shell

Let's first create a BigQuery dataset and table.

**Note:** This task uses the `bq` command-line tool. **Skip down to Step 3 if you want to complete these steps using the Cloud console.**

**Instructions:**
1. Run the following command to create a dataset called `taxirides`:

```bash
bq mk taxirides
```

**Expected Result:**
```
Dataset '<your-project-id:taxirides>' successfully created
```

2. Now that you have your dataset created, you'll use it in the following step to instantiate a BigQuery table.

```bash
bq mk \
--time_partitioning_field timestamp \
--schema ride_id:string,point_idx:integer,latitude:float,longitude:float,\
timestamp:timestamp,meter_reading:float,meter_increment:float,ride_status:string,\
passenger_count:integer -t taxirides.realtime
```

**Expected Result:**
```
Table 'your-project-id:taxirides.realtime' successfully created
```

**Create a Cloud Storage bucket using Cloud Shell:**

1. Use the Project ID as the bucket name to ensure a globally unique name:

```bash
export BUCKET_NAME=$GOOGLE_CLOUD_PROJECT
gsutil mb gs://$BUCKET_NAME/
```

**Expected Result:**
- Cloud Storage bucket created successfully

### Step 3: Create a BigQuery dataset, BigQuery table, and Cloud Storage bucket using the Google Cloud console

**Note:** Do not complete Step 3 if you completed Step 2, which includes the same tasks!

**Instructions:**
1. From the left-hand menu, in the Big Data section, click on **BigQuery**.
2. Then click **Done**.
3. Click on the three dots next to your project name under the **Explorer** section, then click **Create dataset**.
4. Input `taxirides` as your dataset ID:
5. Select **us (multiple regions in United States)** in Data location.
6. Leave all of the other default settings in place and click **CREATE DATASET**.

**Expected Result:**
- `taxirides` dataset appears under your project name in the left-hand console

1. You should now see the `taxirides` dataset underneath your project ID in the left-hand console.
2. Click on the three dots next to `taxirides` dataset and select **Open**.
3. Then select **CREATE TABLE** in the right-hand side of the console.
4. In the **Destination** > **Table Name** input, enter `realtime`.
5. Under Schema, toggle the **Edit as text** slider and enter the following:

```
ride_id:string,point_idx:integer,latitude:float,longitude:float,timestamp:timestamp,
meter_reading:float,meter_increment:float,ride_status:string,passenger_count:integer
```

6. Now, click **Create table**.

**Create a Cloud Storage bucket using the Cloud console:**

1. Go back to the Cloud Console and navigate to **Cloud Storage** > **Buckets** > **Create bucket**.
2. Use the Project ID as the bucket name to ensure a globally unique name
3. Leave all other default settings, then click **Create**.

**Expected Result:**
- Cloud Storage bucket created successfully

### Step 4: Run the pipeline

Deploy the Dataflow Template:

```bash
gcloud dataflow jobs run iotflow \
    --gcs-location gs://dataflow-templates-us-central1/latest/PubSub_to_BigQuery \
    --region us-central1 \
    --worker-machine-type e2-medium \
    --staging-location gs://$BUCKET_NAME/temp \
    --parameters inputTopic=projects/pubsub-public-data/topics/taxirides-realtime,outputTableSpec=$GOOGLE_CLOUD_PROJECT:taxirides.realtime
```

**Expected Result:**
- In the **Navigation menu**, click **View All Products** > **Analytics** > **Dataflow** > **Jobs**. You will see your dataflow job.

**Note:** You may need to wait a minute for the activity tracking to complete.

### Step 5: Submit a query

You can submit queries using standard SQL.

**Instructions:**
1. In the BigQuery **Editor**, add the following to query the data in your project:

```sql
SELECT * FROM `$GOOGLE_CLOUD_PROJECT.taxirides.realtime` LIMIT 1000
```

2. Now click **RUN**.

If you run into any issues or errors, run the query again (the pipeline takes a minute to start up.)

**Expected Result:**
- When the query runs successfully, you'll see the output in the **Query Results** panel

## Verification

Proof that you successfully completed the lab:
- BigQuery table is populated with taxi ride data from the Pub/Sub topic
- Successfully run queries and retrieve data
- Dataflow job running in console with no errors

## Troubleshooting

Common issues and solutions:
- **Dataflow job fails**: Check your project permissions and API enablement status
- **BigQuery table not populated**: Wait a few minutes for the pipeline to fully start
- **Query returns empty results**: Ensure the Pub/Sub topic is sending data
- **Permission errors**: Ensure your account has the necessary IAM roles

## Cleanup

To avoid incurring charges, clean up the following resources:
1. Stop the Dataflow job:
   - Select the job in the Dataflow console
   - Click **Stop** and confirm

2. Delete the BigQuery dataset:
```bash
bq rm -r -f taxirides
```

3. Delete the Cloud Storage bucket:
```bash
gsutil rm -r gs://$BUCKET_NAME
```

## Additional Resources

- [Dataflow Documentation](https://cloud.google.com/dataflow/docs)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Pub/Sub Documentation](https://cloud.google.com/pubsub/docs)
- [Dataflow Templates Guide](https://cloud.google.com/dataflow/docs/templates/provided-templates)
- [BigQuery Command Line Reference](https://cloud.google.com/bigquery/docs/reference/bq-cli-reference)

## Test your understanding

Multiple choice questions to reinforce your understanding of this lab's concepts:

**Does Google Cloud Dataflow support batch processing?**
- Correct Answer: True

**Which Dataflow Template was used in the lab to run the pipeline?**
- Correct Answer: Pub/Sub to BigQuery

## Notes

- This lab demonstrates how to quickly set up streaming data pipelines using Google-provided templates
- The Pub/Sub to BigQuery template is a powerful tool for processing real-time data
- Remember to clean up resources to avoid unexpected charges
- Dataflow templates greatly simplify implementation of common data processing patterns
