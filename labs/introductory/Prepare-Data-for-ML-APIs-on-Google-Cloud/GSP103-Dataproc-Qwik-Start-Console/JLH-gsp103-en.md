# GSP103 - Dataproc: Qwik Start - Console

## Lab Overview

Dataproc is a fast, easy-to-use, fully-managed cloud service for running Apache Spark and Apache Hadoop clusters in a simpler, more cost-efficient way. Operations that used to take hours or days take seconds or minutes instead. Create Dataproc clusters quickly and resize them at any time, so you don't have to worry about your data pipelines outgrowing your clusters.

This lab shows you how to use the Google Cloud console to create a Dataproc cluster, run a simple Apache Spark job in the cluster, and then modify the number of workers in the cluster.

## Prerequisites

- Google Cloud Platform account
- Basic GCP knowledge
- Familiarity with Google Cloud Console

## Learning Objectives

By the end of this lab, you will be able to:

- Create a Dataproc cluster in the Google Cloud console
- Run a simple Apache Spark job
- Modify the number of workers in the cluster

## Estimated Time

45 minutes

## Setup and Requirements

### Confirm Cloud Dataproc API is Enabled

To create a Dataproc cluster in Google Cloud, the Cloud Dataproc API must be enabled. To confirm the API is enabled:

1. Click **Navigation menu** > **APIs & Services** > **Library**
2. Type **Cloud Dataproc** in the **Search for APIs & Services** dialog
3. Click on **Cloud Dataproc API** to display the status of the API
4. If the API is not already enabled, click the **Enable** button

### Permission to Service Account

To assign storage permission to the service account, which is required for creating a cluster:

1. Go to **Navigation menu > IAM & Admin > IAM**
2. Click the pencil icon on the `compute@developer.gserviceaccount.com` service account
3. Click on the **+ ADD ANOTHER ROLE** button, select role **Storage Admin**

Once you've selected the **Storage Admin** role, click on **Save**

## Lab Steps

### Task 1: Create a cluster

1. In the Cloud Platform Console, select **Navigation menu** > **View all products** > **Dataproc** > **Clusters**, then click **Create cluster**
2. Click **Create** for **Cluster on Compute Engine**
3. Set the following fields for your cluster and accept the default values for all other fields:

**Note:** In the Configure nodes section ensure **both the Master node and Worker nodes** are set to the correct Machine Series and Machine Type. If the E2 series is not displayed, verify that you have selected "Standard Persistent Disk" as the Primary Disk type option.

| Field | Value |
|-------|-------|
| Name | example-cluster |
| Region | [YOUR_REGION] |
| Zone | [YOUR_ZONE] |
| Primary disk type (Manager Node) | Standard Persistent Disk |
| Machine Series (Manager Node) | E2 |
| Machine Type (Manager Node) | e2-standard-2 |
| Primary disk size (Manager Nodes) | 30 GB |
| Number of Worker Nodes | 2 |
| Primary disk type (Worker Node) | Standard Persistent Disk |
| Machine Series (Worker Nodes) | E2 |
| Machine Type (Worker Nodes) | e2-standard-2 |
| Primary disk size (Worker Nodes) | 30 GB |
| Internal IP only | Deselect "Configure all instances to have only internal IP addresses" |

**Note:** A Zone is a special multi-region namespace that is capable of deploying instances into all Google Compute zones globally. You can also specify distinct regions, such as `us-central1` or `europe-west1`, to isolate resources (including VM instances and Cloud Storage) and metadata storage locations utilized by Cloud Dataproc within the user-specified region.

4. Click **Create** to create the cluster

Your new cluster will appear in the Clusters list. It may take a few minutes to create, the cluster Status shows as **Provisioning** until the cluster is ready to use, then changes to **Running**.

**Test completed task**

Click **Check my progress** to verify your performed task.

Create a Dataproc cluster

### Task 2: Submit a job

To run a sample Spark job:

1. Click **Jobs** in the left pane to switch to Dataproc's jobs view, then click **Submit job**
2. Set the following fields to update Job. Accept the default values for all other fields:

| Field | Value |
|-------|-------|
| Region | [YOUR_REGION] |
| Cluster | example-cluster |
| Job type | Spark |
| Main class or jar | org.apache.spark.examples.SparkPi |
| Jar files | file:///usr/lib/spark/examples/jars/spark-examples.jar |
| Arguments | 1000 (This sets the number of tasks.) |

3. Click **Submit**

**Note: How the job calculates Pi:** The Spark job estimates a value of Pi using the Monte Carlo method. It generates x,y points on a coordinate plane that models a circle enclosed by a unit square. The input argument (1000) determines the number of x,y pairs to generate; the more pairs generated, the greater the accuracy of the estimation. This estimation leverages Cloud Dataproc worker nodes to parallelize the computation. For more information, see [Estimating Pi using the Monte Carlo Method](https://academo.org/demos/estimating-pi-monte-carlo/) and see [JavaSparkPi.java on GitHub](https://github.com/Apache/spark/blob/master/examples/src/main/java/org/apache/spark/examples/JavaSparkPi.java).

Your job should appear in the **Jobs** list, which shows your project's jobs with its cluster, type, and current status. Job status displays as **Running**, and then **Succeeded** after it completes.

**Test completed task**

Click **Check my progress** to verify your performed task.

Submit a job

### Task 3: View the job output

To see your completed job's output:

1. Click the job ID in the **Jobs** list
2. Select **LINE WRAP** to `ON` or scroll all the way to the right to see the calculated value of Pi. Your output, with **LINE WRAP** `ON`, should look something like this:

[Output](https://cdn.qwiklabs.com/DnVGNZW%2F3WiDYaqOqt3ET3nW%2Bp4NZbZYgvi2OL0QjXo%3D)

Your job has successfully calculated a rough value for pi!

### Task 4: Update a cluster to modify the number of workers

To change the number of worker instances in your cluster:

1. Select **Clusters** in the left navigation pane to return to the Dataproc Clusters view
2. Click **example-cluster** in the **Clusters** list. By default, the page displays an overview of your cluster's CPU usage
3. Click **Configuration** to display your cluster's current settings
4. Click **Edit**. The number of worker nodes is now editable
5. Enter **4** in the **Worker nodes** field
6. Click **Save**

Your cluster is now updated. Check out the number of VM instances in the cluster.

**Test completed task**

Click **Check my progress** to verify your performed task.

Update a cluster

To rerun the job with the updated cluster, you would click **Jobs** in the left pane, then click **SUBMIT JOB**.

Set the same fields you set in the **Submit a job** section:

| Field | Value |
|-------|-------|
| Region | [YOUR_REGION] |
| Cluster | example-cluster |
| Job type | Spark |
| Main class or jar | org.apache.spark.examples.SparkPi |
| Jar files | file:///usr/lib/spark/examples/jars/spark-examples.jar |
| Arguments | 1000 (This sets the number of tasks.) |

Click **Submit**

### Task 5: Test your understanding

Below are multiple-choice questions to reinforce your understanding of this lab's concepts. Answer them to the best of your abilities.

Which type of Dataproc job is submitted in the lab?SparkSparkSqlHadoopPigPySpark

Dataproc helps users process, transform and understand vast quantities of data.TrueFalse

## Verification

Signs of successful completion of this lab include:

- Successfully created a Dataproc cluster named `example-cluster`
- Successfully submitted and ran a Spark Pi calculation job
- Ability to view job output and see the estimated value of Pi
- Successfully changed the cluster's worker node count from 2 to 4

## Troubleshooting

Common issues and solutions:

- **Cluster creation fails**: Ensure Cloud Dataproc API is enabled and service account has correct permissions
- **Job submission fails**: Check if cluster status is Running and region settings are correct
- **Cannot view job output**: Wait for job to complete (status Succeeded), then refresh the page
- **Permission errors**: Ensure your GCP account has necessary IAM permissions to create and use Dataproc resources

## Cleanup

To avoid additional charges, clean up resources after completing the lab:

1. Return to the Dataproc Clusters page
2. Select `example-cluster`
3. Click the **Delete** button
4. Confirm deletion

Alternatively, you can run the following command in Cloud Shell:

```bash
gcloud dataproc clusters delete example-cluster --region=[YOUR_REGION]
```

## Additional Resources

- [Cloud Dataproc Documentation](https://cloud.google.com/dataproc/docs)
- [Apache Spark Official Documentation](http://spark.apache.org/)
- [Apache Hadoop Official Documentation](http://hadoop.apache.org/)
- [Cloud Dataproc Quickstarts](https://cloud.google.com/dataproc/docs/quickstarts)
- [Estimating Pi using the Monte Carlo Method](https://academo.org/demos/estimating-pi-monte-carlo/)

## Related Labs

- GSP104: Dataproc: Qwik Start - Command Line
- GSP105: Dataprep: Qwik Start
- GSP192: Dataflow: Qwik Start - Templates

## Notes

- Dataproc is a fully managed service that can significantly simplify big data processing workloads
- Clusters can be dynamically resized as needed, which is useful for handling variable workloads
- The Spark Pi example demonstrates how to use Dataproc for parallel computation
- Remember to clean up resources to avoid unexpected charges
