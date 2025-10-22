# GSP323 - Prepare Data for ML APIs on Google Cloud: Challenge Lab - Step-by-Step Guide

## Lab Overview
This is a practical guide created for GSP323 Challenge Lab based on GSP097, GSP103, GSP119, and GSP192 labs. This guide will walk you through all 4 tasks.

## Prerequisites
- Google Cloud account and lab credentials
- Internet connection and Chrome browser
- Basic GCP Console operation knowledge
- Familiarity with command-line operations

## Estimated Time
60-90 minutes

---

## Initial Setup

### Set Environment Variables
```bash
# Set project and region information
export REGION=""
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="json" | jq -r '.projectNumber')

# Set resource names (based on actual lab values)
export BUCKET_NAME=""
export SPEECH_BUCKET="${BUCKET_NAME}-speech"
export NL_BUCKET="${BUCKET_NAME}-nl"
export DATASET_NAME=""
export TABLE_NAME=""
export CLUSTER_NAME="dataproc-cluster-$(date +%s)"

# Output file names and paths
export SPEECH_OUTPUT=""
export NL_OUTPUT=""
```

### Enable Required APIs
```bash
# Enable all required APIs
gcloud services enable dataflow.googleapis.com
gcloud services enable dataproc.googleapis.com
gcloud services enable speech.googleapis.com
gcloud services enable language.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable apikeys.googleapis.com
```

---

## Task 1: Run a Simple Dataflow Job

### Step Details

#### 1. Create BigQuery Dataset
```bash
bq mk $DATASET_NAME
```

#### 2. Create Cloud Storage Buckets
```bash
gsutil mb -p $PROJECT_ID -l $REGION gs://$BUCKET_NAME
```

#### 3. Copy Lab Files Locally
```bash
gsutil cp gs://spls/gsp323/lab.csv .
gsutil cp gs://spls/gsp323/lab.schema .
```

#### 4. Create BigQuery Table
```bash
# Define table schema
cat > lab.schema << 'EOF'
[
    {"type":"STRING","name":"guid"},
    {"type":"BOOLEAN","name":"isActive"},
    {"type":"STRING","name":"firstname"},
    {"type":"STRING","name":"surname"},
    {"type":"STRING","name":"company"},
    {"type":"STRING","name":"email"},
    {"type":"STRING","name":"phone"},
    {"type":"STRING","name":"address"},
    {"type":"STRING","name":"about"},
    {"type":"TIMESTAMP","name":"registered"},
    {"type":"FLOAT","name":"latitude"},
    {"type":"FLOAT","name":"longitude"}
]
EOF

# Create table
bq mk --table $DATASET_NAME.$TABLE_NAME lab.schema
```

#### 5. Run Dataflow Job
```bash
gcloud dataflow jobs run dataflow-lab-job \
    --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_BigQuery \
    --region $REGION \
    --worker-machine-type e2-standard-2 \
    --staging-location gs://$BUCKET_NAME/temp \
    --parameters \
"inputFilePattern=gs://spls/gsp323/lab.csv,\
outputTable=$PROJECT_ID:$DATASET_NAME.$TABLE_NAME,\
bigQueryLoadingTemporaryDirectory=gs://$BUCKET_NAME/bigquery_temp,\
JSONPath=gs://spls/gsp323/lab.schema,\
javascriptTextTransformGcsPath=gs://spls/gsp323/lab.js,\
javascriptTextTransformFunctionName=transform"
```

### Verification Steps
```bash
# Check Dataflow job status
gcloud dataflow jobs list --region=$REGION --filter="name:dataflow-lab-job"

# Check if BigQuery table was created
bq ls $DATASET_NAME

# Click Check my progress to verify Task 1
```

---

## Task 2: Run a Simple Dataproc Job

### Step Details

#### 1. Set IAM Permissions
```bash
# Assign permissions to service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role "roles/storage.admin"

# Set user permissions
export USER_EMAIL=$(gcloud config get-value account)
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:$USER_EMAIL \
    --role=roles/dataproc.editor

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:$USER_EMAIL \
    --role=roles/storage.objectViewer
```

#### 2. Update VPC Subnet Settings
```bash
# Enable private IP access
gcloud compute networks subnets update default \
    --region $REGION \
    --enable-private-ip-google-access
```

#### 3. Create Dataproc Cluster
```bash
gcloud dataproc clusters create $CLUSTER_NAME \
    --enable-component-gateway \
    --region $REGION \
    --master-machine-type e2-standard-2 \
    --master-boot-disk-type pd-balanced \
    --master-boot-disk-size 100 \
    --num-workers 2 \
    --worker-machine-type e2-standard-2 \
    --worker-boot-disk-type pd-balanced \
    --worker-boot-disk-size 100 \
    --image-version 2.2-debian12 \
    --project $PROJECT_ID
```

#### 4. Copy Data File to Cluster
```bash
# Method 1: SSH directly using cluster name (recommended - simpler)
echo "Copying data file to cluster..."
# First get cluster zone and network information
CLUSTER_ZONE=$(gcloud dataproc clusters describe $CLUSTER_NAME --region=$REGION --format="value(config.gceClusterConfig.zoneUri)" | awk -F/ '{print $NF}')
CLUSTER_NETWORK=$(gcloud dataproc clusters describe $CLUSTER_NAME --region=$REGION --format="value(config.gceClusterConfig.networkUri)" | awk -F/ '{print $NF}')

# SSH to cluster using correct zone
gcloud compute ssh $CLUSTER_NAME-m --zone=$CLUSTER_ZONE --command="hdfs dfs -cp gs://spls/gsp323/data.txt /data.txt"

# Method 2: If method 1 doesn't work, use manual approach
# First check cluster status
echo "Checking cluster status..."
gcloud dataproc clusters describe $CLUSTER_NAME --region=$REGION

# Then manual SSH (if cluster is running but SSH has issues)
# VM_NAME=$(gcloud compute instances list --project="$PROJECT_ID" --format=json | jq -r '.[0].name')
# ZONE=$(gcloud compute instances list --filter="name=$VM_NAME" --format 'csv[no-heading](zone)')
# gcloud compute ssh --zone "$ZONE" "$VM_NAME" --project "$PROJECT_ID" --command="hdfs dfs -cp gs://spls/gsp323/data.txt /data.txt"
```

#### 5. Submit Spark Job
```bash
gcloud dataproc jobs submit spark \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --class=org.apache.spark.examples.SparkPageRank \
    --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
    --project=$PROJECT_ID \
    -- /data.txt
```

### Verification Steps
```bash
# Check Dataproc job status
gcloud dataproc jobs list --region=$REGION --cluster=$CLUSTER_NAME

# Click Check my progress to verify Task 2
```

---

## Task 3: Use Google Cloud Speech-to-Text API

### Step Details

#### 1. Create API Key
```bash
# Create API key
gcloud alpha services api-keys create --display-name="speech-api-key"
API_KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=speech-api-key")
API_KEY=$(gcloud alpha services api-keys get-key-string $API_KEY_NAME --format="value(keyString)")
```

#### 2. Confirm Main Cloud Storage Bucket Exists
```bash
# Main bucket was created in Task 1, confirm it exists here
gsutil ls gs://$BUCKET_NAME
```

#### 3. Create Speech-to-Text API Request File
```bash
cat > request.json <<EOF
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://spls/gsp323/task3.flac"
  }
}
EOF
```

#### 4. Call Speech-to-Text API
```bash
curl -s -X POST -H "Content-Type: application/json" \
    --data-binary @request.json \
    "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > speech_result.json
```

#### 5. Upload Results to Specified Cloud Storage Location
```bash
gsutil cp speech_result.json gs://$BUCKET_NAME/$SPEECH_OUTPUT
```

### Verification Steps
```bash
# Check result file
gsutil cat gs://$BUCKET_NAME/$SPEECH_OUTPUT

# Click Check my progress to verify Task 3
```

---

## Task 4: Use Cloud Natural Language API

### Step Details

#### 1. Create Service Account and Set Permissions
```bash
# Create service account
gcloud iam service-accounts create nl-service-account \
    --display-name "Natural Language Service Account"

# Grant Cloud Storage permissions to service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:nl-service-account@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"

# Create service account key
gcloud iam service-accounts keys create ~/nl-key.json \
    --iam-account nl-service-account@$PROJECT_ID.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS="/home/$USER/nl-key.json"
```

#### 2. Set Service Account Authentication
```bash
# Switch to service account
gcloud auth activate-service-account nl-service-account@$PROJECT_ID.iam.gserviceaccount.com \
    --key-file=$GOOGLE_APPLICATION_CREDENTIALS
```

#### 3. Confirm Main Cloud Storage Bucket Exists
```bash
# Main bucket was created in Task 1, confirm it exists here
gsutil ls gs://$BUCKET_NAME
```

#### 4. Run Natural Language Entity Analysis
```bash
gcloud ml language analyze-entities \
    --content="Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat." \
    > nl_result.json
```

#### 5. Upload Results to Specified Cloud Storage Location
```bash
gsutil cp nl_result.json gs://$BUCKET_NAME/$NL_OUTPUT
```

### Verification Steps
```bash
# Check result file
gsutil cat gs://$BUCKET_NAME/$NL_OUTPUT

# Click Check my progress to verify Task 4
```

---

## Cleanup Resources

After completing all tasks, run the following commands to clean up resources and avoid additional charges:

```bash
# Delete Dataproc cluster
gcloud dataproc clusters delete $CLUSTER_NAME --region=$REGION --quiet

# Delete Cloud Storage buckets (Note: Keep main bucket as it contains task results)
# gsutil rm -r gs://$BUCKET_NAME  # Do not delete, this bucket contains task results

# Delete BigQuery dataset
bq rm -r -f $DATASET_NAME

# Delete service accounts
gcloud iam service-accounts delete nl-service-account@$PROJECT_ID.iam.gserviceaccount.com --quiet

# Delete API key
gcloud alpha services api-keys delete $API_KEY_NAME --quiet

# Clean up local files
rm -f lab.csv lab.schema request.json speech_result.json nl_result.json
rm -f ~/speech-key.json ~/nl-key.json
```

## Troubleshooting

### Common Issues

1. **Dataflow job failure**
   - Check if region settings are correct
   - Ensure Cloud Storage bucket exists
   - Verify BigQuery dataset permissions

2. **Dataproc cluster creation failure**
   - Check network settings
   - Ensure service account has sufficient permissions
   - Verify regional quotas

3. **Speech-to-Text API errors**
   - Check if API is enabled
   - Verify service account key
   - Ensure audio file format is correct

4. **Natural Language API errors**
   - Check if API is enabled
   - Verify service account permissions
   - Confirm text format is correct

### Reference Resources
- [Dataflow Documentation](https://cloud.google.com/dataflow/docs)
- [Dataproc Documentation](https://cloud.google.com/dataproc/docs)
- [Speech-to-Text API Documentation](https://cloud.google.com/speech-to-text/docs)
- [Natural Language API Documentation](https://cloud.google.com/natural-language/docs)

---

## Congratulations!

Congratulations on completing GSP323 Prepare Data for ML APIs on Google Cloud: Challenge Lab!

In this lab, you have demonstrated your skills by:
- ✅ Running a simple Dataflow job
- ✅ Running a simple Dataproc job
- ✅ Using Google Cloud Speech-to-Text API
- ✅ Using Cloud Natural Language API

**Important Reminders**:
- Remember to run the cleanup resources section to avoid additional charges (Note: Keep main bucket as it contains task results)
- All operations are performed through command line, familiarizing yourself with these commands will help your GCP learning journey
- CLUSTER_NAME is auto-generated with timestamp to ensure uniqueness for each run

**Variable Explanations**:
- `BUCKET_NAME`: Based on actual lab provided, format is `{PROJECT_ID}-marking`
- `CLUSTER_NAME`: Auto-generated as `dataproc-cluster-{timestamp}` to ensure uniqueness
- Result files are uploaded to specified Cloud Storage paths for verification

Continue your Google Cloud learning journey!
