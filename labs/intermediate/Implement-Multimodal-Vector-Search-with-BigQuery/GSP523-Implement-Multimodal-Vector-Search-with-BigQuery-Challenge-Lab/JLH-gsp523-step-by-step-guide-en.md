# GSP523 - Implement Multimodal Vector Search with BigQuery: Challenge Lab - Step-by-Step Guide

## Lab Overview

This challenge lab will test your ability to implement multimodal vector search with BigQuery. You will act as a data scientist at Cymbal, an online retail store, and need to build a pipeline to continuously search for similar products on the market to inform a marketing comparison study.

The challenges you face include:
- How to handle multimodal data (including text, images, and videos in Cloud Storage)
- How to perform semantic similarity search instead of keyword search
- How to use BigQuery to implement these features

## Environment Setup

Before starting the lab, set up the necessary environment variables and enable required APIs. Ensure you are authenticated with `gcloud` and the `aiplatform.googleapis.com` service is enabled.

```bash
# Check gcloud authentication
gcloud auth list

# Enable Vertex AI API
gcloud services enable aiplatform.googleapis.com

# Set environment variables for Project ID and Region
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export PROJECT_ID=$(gcloud config get-value project)

# Verify variables are set
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
```

## Prerequisites

- Familiarity with BigQuery and Cloud Storage
- Completion of courses in the Gemini in BigQuery learning path:
  - Boost Productivity with Gemini in BigQuery (introductory)
  - Work with Gemini Models in BigQuery (intermediate)
  - Create Embeddings, Vector Search, and RAG with BigQuery (advanced)

## Estimated Time

60 minutes

## Task List

### Task 1: Create a source connection and grant IAM permissions

#### Create an external source connection
You need to create a new external source connection in BigQuery to use multimodal embedding models from Vertex AI.

1. In the terminal, run the following `bq` command to create the connection:

```bash
bq mk --connection --location=$REGION --project_id=$PROJECT_ID --connection_type=CLOUD_RESOURCE vector_conn
```

2. After creating the connection, retrieve the service account ID:

```bash
export SERVICE_ACCOUNT=$(bq show --format=json --connection $PROJECT_ID.$REGION.vector_conn | jq -r '.cloudResource.serviceAccountId')
echo "Service Account: $SERVICE_ACCOUNT"
```

**Tips:**
- The connection ID must be `vector_conn`.
- The location should be set to your `$REGION` environment variable.

#### Grant IAM permissions
You need to grant the service account appropriate IAM permissions to access Vertex AI resources and BigQuery data.

1. In the terminal, run the following `gcloud` commands to grant the IAM roles:

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/bigquery.dataOwner"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/storage.objectViewer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/aiplatform.user"
```

#### Verification Steps
- Run `bq show --connection $PROJECT_ID.$REGION.vector_conn` and verify the `serviceAccountId` is displayed.
- Run `gcloud projects get-iam-policy $PROJECT_ID --filter="bindings.members:serviceAccount:$SERVICE_ACCOUNT"` and verify the service account has `roles/bigquery.dataOwner`, `roles/storage.objectViewer`, and `roles/aiplatform.user`.

### Task 2: Create an object table

#### Create an object table to store images
You need to create an object table in the pre-created BigQuery dataset to query unstructured data like images stored on Google Cloud Storage.

1. In the terminal, run the following `bq` command to create the object table:

```bash
bq query --use_legacy_sql=false \
"CREATE OR REPLACE EXTERNAL TABLE \`$PROJECT_ID.gcc_bqml_dataset.gcc_image_object_table\`
WITH CONNECTION \`$PROJECT_ID.$REGION.vector_conn\`
OPTIONS (
  object_metadata = 'SIMPLE',
  uris = ['gs://$PROJECT_ID/*']
);"
```

**Tips:**
- The dataset name is predefined as `gcc_bqml_dataset`
- The table name must be `gcc_image_object_table`

#### Verification Steps
- In BigQuery Explorer, expand the `gcc_bqml_dataset` dataset
- Check that the `gcc_image_object_table` table exists
- Run `bq query --use_legacy_sql=false "SELECT * FROM \`$PROJECT_ID.gcc_bqml_dataset.gcc_image_object_table\` LIMIT 5"` to verify the data

### Task 3: Generate embeddings

#### Connect to the multimodal embeddings model
You need to create a new BigQuery model to connect to the remote multimodal embedding model.

1. In the terminal, run the following `bq` command to create the model:

```bash
bq query --use_legacy_sql=false \
"CREATE OR REPLACE MODEL \`$PROJECT_ID.gcc_bqml_dataset.gcc_embedding\`
REMOTE WITH CONNECTION \`$PROJECT_ID.$REGION.vector_conn\`
OPTIONS (endpoint = 'multimodalembedding@001');"
```

**Tips:**
- The model name must be `gcc_embedding`
- The endpoint name is `multimodalembedding@001` (this is the Gemini multimodal embedding model)

#### Generate embeddings
You need to generate embeddings from images and save them to a table.

1. In the terminal, run the following `bq` command to generate embeddings:

```bash
bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE \`$PROJECT_ID.gcc_bqml_dataset.gcc_retail_store_embeddings\`
AS SELECT *, REGEXP_EXTRACT(uri, r'[^/]+$') AS product_name
FROM ML.GENERATE_EMBEDDING(
  MODEL \`$PROJECT_ID.gcc_bqml_dataset.gcc_embedding\`,
  TABLE \`$PROJECT_ID.gcc_bqml_dataset.gcc_image_object_table\`
);"
```

**Tips:**
- The table name must be `gcc_retail_store_embeddings`
- `REGEXP_EXTRACT(uri, r'[^/]+$')` extracts the filename from the URI as the product name

#### Optional Verification Steps
Run the following `bq` query to check the embedding results:
```bash
bq query --use_legacy_sql=false "SELECT * FROM \`$PROJECT_ID.gcc_bqml_dataset.gcc_retail_store_embeddings\` LIMIT 10"
```

The embedding results are floating-point numbers and may not be immediately interpretable, but you should see `uri`, `product_name`, and `ml_generate_embedding_result` columns.

#### Verification Steps
- Check that the `gcc_retail_store_embeddings` table has been created
- Verify that the table contains image URIs from the object table
- Ensure the `ml_generate_embedding_result` column contains vector data

### Task 4: Run a vector search

#### Execute vector search
You need to execute a vector search to find images most similar to the search term and save the results to a table.

1. In the terminal, run the following `bq` command to perform the vector search:

```bash
bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE \`$PROJECT_ID.gcc_bqml_dataset.gcc_vector_search_table\` AS
SELECT base.uri,
       base.product_name,
       base.content_type,
       distance
FROM VECTOR_SEARCH(
  TABLE \`$PROJECT_ID.gcc_bqml_dataset.gcc_retail_store_embeddings\`,
  'ml_generate_embedding_result',
  (
    SELECT ml_generate_embedding_result AS embedding_col
    FROM ML.GENERATE_EMBEDDING(
      MODEL \`$PROJECT_ID.gcc_bqml_dataset.gcc_embedding\`,
      (SELECT 'Men Sweaters' AS content),
      STRUCT(TRUE AS flatten_json_output)
    )
  ),
  top_k => 2,
  distance_type => 'COSINE'
);"
```

**Tips:**
- The table name must be `gcc_vector_search_table`
- The search term is `'Men Sweaters'`
- `top_k => 2` returns the top 2 most similar results
- Uses cosine distance for similarity calculation

#### Optional Verification Steps
Run the following `bq` query to check the search results:
```bash
bq query --use_legacy_sql=false "SELECT * FROM \`$PROJECT_ID.gcc_bqml_dataset.gcc_vector_search_table\`"
```

You should see 2 results, each containing URI, product name, content type, and distance score.

#### Verification Steps
- Check that the `gcc_vector_search_table` table has been created
- Verify that the table contains 2 rows of results
- Ensure results are sorted by distance (most similar first)
- Check that results are relevant to "Men Sweaters"

## Execution Guide

### Common Issues and Solutions

#### Connection creation failure
- **Issue**: Vertex AI API not enabled
- **Solution**: Enable Vertex AI API in APIs & Services

#### IAM permission issues
- **Issue**: Missing required roles
- **Solution**: Carefully check that all three roles have been granted to the service account

#### SQL syntax errors
- **Issue**: Variable references incorrect
- **Solution**:
  - Ensure environment variables `$PROJECT_ID` and `$REGION` are set correctly
  - Check that the variables contain the correct values

#### Embedding generation failure
- **Issue**: Incorrect model endpoint name
- **Solution**: Use the correct endpoint name `multimodalembedding@001`

#### Vector search returns no results
- **Issue**: Search parameters configured incorrectly
- **Solution**: Check the `top_k` value and distance type

### Tips and Tricks

#### Variable replacement
- Always carefully check and replace all bracketed placeholders `[]`
- Project ID can be found at the top of the console
- Region is usually specified in the lab instructions

#### Debugging techniques
- Use `SELECT * FROM table_name LIMIT 5` to check table contents
- Check BigQuery job history for detailed error information
- Ensure all resources are in the same region

#### Performance considerations
- Embedding generation may take some time, especially for large numbers of images
- Vector search is usually fast in BigQuery, but depends on dataset size

### Cleanup Steps

This lab doesn't require specific cleanup steps since it primarily involves querying data. However, if cleanup is needed:

1. Delete created tables:
   ```sql
   DROP TABLE `$PROJECT_ID.gcc_bqml_dataset.gcc_vector_search_table`;
   DROP TABLE `$PROJECT_ID.gcc_bqml_dataset.gcc_retail_store_embeddings`;
   DROP TABLE `$PROJECT_ID.gcc_bqml_dataset.gcc_image_object_table`;
   ```

2. Delete models:
   ```