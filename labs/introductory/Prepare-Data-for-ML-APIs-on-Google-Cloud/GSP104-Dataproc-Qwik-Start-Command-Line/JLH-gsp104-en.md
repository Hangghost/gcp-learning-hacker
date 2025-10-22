# GSP104 - Dataproc: Qwik Start - Command Line

## Lab Overview

Dataproc is a fast, easy-to-use, fully-managed cloud service for running Apache Spark and Apache Hadoop clusters in a simpler, more cost-efficient way. Operations that used to take hours or days take seconds or minutes instead. Create Dataproc clusters quickly and resize them at any time, so you don't have to worry about your data pipelines outgrowing your clusters.

This lab shows you how to use the command line to create a Dataproc cluster, run a simple Apache Spark job in the cluster, and then modify the number of workers in the cluster.

## Prerequisites

- Google Cloud Platform account
- Basic command line knowledge
- Understanding of basic Google Cloud Console operations

## Learning Objectives

By the end of this lab, you will be able to:

- Create a Dataproc cluster using the command line
- Run a simple Apache Spark job
- Modify the number of workers in the cluster

## Estimated Time

45 minutes

## Lab Steps

### Step 1: Create a cluster

In this task, you learn how to create a Dataproc cluster using the command line.

**Instructions:**

1. In Cloud Shell, run the following command to set the Region:

```bash
gcloud config set dataproc/region REGION
```

**Note:** Replace `REGION` with your actual region.

2. Disable the Dataproc API:

```bash
gcloud services disable dataproc.googleapis.com --force
```

3. Re-enable the Dataproc API:

```bash
gcloud services enable dataproc.googleapis.com
```

4. Dataproc creates staging and temp buckets that are shared among clusters in the same region. Since we're not specifying an account for Dataproc to use, it will use the Compute Engine default service account, which doesn't have storage bucket permissions by default. Let's add those.

   First, run the following commands to grab the PROJECT_ID and PROJECT_NUMBER:

```bash
PROJECT_ID=$(gcloud config get-value project) && \
gcloud config set project $PROJECT_ID

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
```

5. Now run the following command to give the Storage Admin and Dataproc Worker role to the Compute Engine default service account:

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role=roles/storage.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role=roles/dataproc.worker
```

6. Enable Private Google Access on your subnetwork by running the following command:

```bash
gcloud compute networks subnets update default --region=REGION  --enable-private-ip-google-access
```

**Note:** Replace `REGION` with your actual region.

7. Run the following command to create a cluster called `example-cluster` with e2-standard-4 VMs and default Cloud Dataproc settings:

```bash
gcloud dataproc clusters create example-cluster --worker-boot-disk-size 500 --worker-machine-type=e2-standard-4 --master-machine-type=e2-standard-4
```

8. If asked to confirm a zone for your cluster. Enter **Y**.

Your cluster will build for a couple of minutes.

```bash
Waiting for cluster creation operation...done.
Created [... example-cluster]
```

When you see a "Created" message, you're ready to move on.

**Expected Result:**
- Cluster creation successful with confirmation message displayed

### Step 2: Submit a job

In this task, you learn how to submit a sample Spark job that calculates a rough value for pi.

**Instructions:**

Run this command to submit a sample Spark job that calculates a rough value for pi:

```bash
gcloud dataproc jobs submit spark --cluster example-cluster \
  --class org.apache.spark.examples.SparkPi \
  --jars file:///usr/lib/spark/examples/jars/spark-examples.jar -- 1000
```

The command specifies:

- That you want to run a spark job on the `example-cluster` cluster
- The class containing the main method for the job's pi-calculating application
- The location of the jar file containing your job's code
- The parameters you want to pass to the job—in this case, the number of tasks, which is `1000`

**Note:** Parameters passed to the job must follow a double dash (--). See the [gcloud documentation](https://cloud.google.com/sdk/gcloud/reference/dataproc/jobs/submit/spark) for more information.

The job's running and final output is displayed in the terminal window:

```bash
Waiting for job output...
...
Pi is roughly 3.14118528
...
state: FINISHED
```

**Expected Result:**
- Job runs successfully and displays approximate value of Pi
- Final state shows as FINISHED

### Step 3: Update a cluster

In this task, you learn how to modify the number of workers in the cluster.

**Instructions:**

1. To change the number of workers in the cluster to four, run the following command:

```bash
gcloud dataproc clusters update example-cluster --num-workers 4
```

Your cluster's updated details are displayed in the command's output:

```bash
Waiting on operation [projects/.../operations/...].
Waiting for cluster update operation...done.
```

2. You can use the same command to decrease the number of worker nodes:

```bash
gcloud dataproc clusters update example-cluster --num-workers 2
```

Now you can create a Dataproc cluster and adjust the number of workers from the `gcloud` command line on Google Cloud.

**Expected Result:**
- Cluster worker count updated successfully
- Cluster update operation completion message displayed

### Step 4: Test your understanding

Below are multiple-choice questions to reinforce your understanding of this lab's concepts. Answer them to the best of your abilities.

**Question:** Clusters can be created and scaled quickly with a variety of virtual machine types, disk sizes, and number of nodes.

- True
- False

**Correct Answer:** True

## Verification

To verify that the lab was completed successfully:

1. **Task 1 Verification:** Check that cluster was created successfully
   - Run: `gcloud dataproc clusters list`
   - Should see `example-cluster` in the list

2. **Task 2 Verification:** Check that job ran successfully
   - Look for "Pi is roughly" message in job output
   - Ensure final state is "FINISHED"

3. **Task 3 Verification:** Check that cluster was updated successfully
   - Run: `gcloud dataproc clusters describe example-cluster`
   - Verify worker count is correct

## Troubleshooting

Common issues and their solutions:

- **Permission Errors:** If you encounter permission-related errors, ensure the Compute Engine default service account has the correct IAM roles (Storage Admin and Dataproc Worker)

- **Cluster Creation Failure:** If cluster creation fails, check:
  - Region settings are correct
  - API is enabled
  - Quotas are sufficient

- **Job Submission Failure:** If job submission fails, check:
  - Cluster name is correct
  - Cluster status is running
  - Jar file path is correct

- **API Not Enabled:** If you get API not enabled error, re-run the enable command:
  ```bash
  gcloud services enable dataproc.googleapis.com
  ```

## Cleanup

To avoid incurring unnecessary charges, clean up resources after completing the lab:

1. Delete the cluster:
   ```bash
   gcloud dataproc clusters delete example-cluster --region=REGION
   ```

2. Delete temporary storage buckets (if they exist):
   ```bash
   gsutil rm -r gs://dataproc-staging-REGION-PROJECT_ID/
   gsutil rm -r gs://dataproc-temp-REGION-PROJECT_ID/
   ```

**Note:** Replace `REGION` and `PROJECT_ID` with your actual values.

## Additional Resources

- [Dataproc Documentation](https://cloud.google.com/dataproc/docs)
- [Apache Spark Documentation](http://spark.apache.org/)
- [Apache Hadoop Documentation](http://hadoop.apache.org/)
- [gcloud dataproc command reference](https://cloud.google.com/sdk/gcloud/reference/dataproc)
- [Dataproc Pricing](https://cloud.google.com/dataproc/pricing)

## Related Labs

- GSP103: Dataproc: Qwik Start - Console
- GSP105: Dataprep: Qwik Start
- GSP192: Dataflow: Qwik Start - Templates

## Notes

- Dataproc is Google's managed service for running Apache Spark and Hadoop on Google Cloud
- Clusters can be created and scaled quickly to adapt to workload demands
- Command line tools provide full control over Dataproc resources
- Remember to properly configure IAM permissions and security settings in production environments
