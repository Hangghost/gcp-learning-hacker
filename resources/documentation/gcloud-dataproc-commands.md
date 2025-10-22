# Google Cloud Dataproc Commands Reference

## Description
Official reference documentation for Google Cloud SDK Dataproc commands, including cluster management, job submission, and resource configuration. Dataproc provides a fully managed service for running Apache Spark and Apache Hadoop clusters.

## URL
https://cloud.google.com/sdk/gcloud/reference/dataproc

## Category
documentation

## Target Audience
- Cloud engineers
- Data engineers
- DevOps engineers
- GCP administrators

## Prerequisites
- Google Cloud Platform account
- Google Cloud SDK (gcloud CLI) installed
- Basic understanding of command-line interfaces
- Familiarity with GCP concepts

## Key Commands Covered

### Cluster Management
- `gcloud dataproc clusters create` - Create a new Dataproc cluster
- `gcloud dataproc clusters delete` - Delete an existing cluster
- `gcloud dataproc clusters describe` - Get cluster details
- `gcloud dataproc clusters list` - List all clusters
- `gcloud dataproc clusters update` - Update cluster configuration

### Job Submission
- `gcloud dataproc jobs submit spark` - Submit Apache Spark jobs
- `gcloud dataproc jobs submit hadoop` - Submit Apache Hadoop jobs
- `gcloud dataproc jobs submit pig` - Submit Apache Pig jobs
- `gcloud dataproc jobs submit hive` - Submit Apache Hive jobs
- `gcloud dataproc jobs describe` - Get job details
- `gcloud dataproc jobs list` - List all jobs

### Specific Command: Submit Spark Job
The `gcloud dataproc jobs submit spark` command is particularly important for running Spark applications:

```bash
gcloud dataproc jobs submit spark \
  --cluster=CLUSTER_NAME \
  --class=MAIN_CLASS \
  --jars=JAR_LOCATION \
  -- PARAMETERS
```

**Parameters:**
- `--cluster`: Name of the Dataproc cluster
- `--class`: Main class containing the application entry point
- `--jars`: Location of JAR files containing the application code
- `--`: Separator for application-specific parameters

## Related Labs
- GSP103: Dataproc: Qwik Start - Console
- GSP104: Dataproc: Qwik Start - Command Line
- GSP105: Dataprep: Qwik Start

## Notes
- Dataproc commands require appropriate IAM permissions
- Clusters are created in specific regions and zones
- Job submission supports various frameworks (Spark, Hadoop, Pig, Hive)
- Commands can be automated in scripts for CI/CD pipelines
- Integration with Google Cloud Storage for data input/output
- Supports initialization actions for cluster customization
