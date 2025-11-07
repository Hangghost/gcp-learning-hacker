# GSP1289 - Create a RAG Application with BigQuery

## Lab Overview
Concerned about AI hallucinations? While AI can be a valuable resource, it sometimes generates inaccurate, outdated, or overly general responses - a phenomenon known as "hallucination." This lab teaches you how to implement a Retrieval Augmented Generation (RAG) pipeline to address this issue. RAG improves large language models (LLMs) like Gemini by grounding their output in contextually relevant information from a specific dataset.

Assume you are helping Coffee-on-Wheels, a pioneering mobile coffee vendor, analyze customer feedback on its services. Without access to the latest data, Gemini's responses might be inaccurate. To solve this problem, you decide to build a RAG pipeline that includes three steps:

1. **Generate embeddings**: Convert customer feedback text into vector embeddings, which are numerical representations of data that capture semantic meaning.

2. **Search vector space**: Create an index of these vectors, search for similar items, and retrieve them.

3. **Generate improved answers**: Augment Gemini with the retrieved information to produce more accurate and relevant responses.

BigQuery allows seamless connection to remote generative AI models on Vertex AI. It also provides various functions for embeddings, vector search, and text generation directly through SQL queries or Python notebooks.

For a deeper dive, check out the course **Create Embeddings, Vector Search, and RAG with BigQuery** on Google Cloud Skills Boost.

## Prerequisites
To complete this lab, you should be familiar with BigQuery and SQL coding.

## Learning Objectives
By the end of this lab, you will be able to:
- Create a source connection and grant IAM permissions.
- Generate embeddings and convert text data to vector embeddings.
- Search the vector space and retrieve similar items.
- Generate an improved answer by augmenting Gemini with the search results.

## Estimated Time
45 minutes

## Lab Steps

### Task 1: Create a source connection and grant IAM permissions

#### Create a source connection
To use remote generative AI models on Vertex AI in BigQuery, like Gemini and an embedding model, create a new external source connection.

1. In the Google Cloud console, on the Navigation menu, click BigQuery.

2. Navigate to Explorer, click + Add, and select Connections to external data sources.

   Note: Alternatively, if you do not see the option for + Add followed by Connections to external data sources, you can click + Add data, and then use the search bar for data sources to search for Vertex AI. Click on the Vertex AI > BigQuery Federation result.

3. In the Connection type dropdown, select Vertex AI remote models, remote functions BigLake and Spanner (Cloud Resource).

4. In the Connection ID field, enter `embedding_conn`.

5. Click Create connection.

6. Once the connection is created, click on Go to connection in the pop-up confirmation to navigate to the connection and copy the Service account id value. You need it later to assign permissions to this account.

#### Grant IAM permissions
To use BigQuery data and Vertex AI resources, grant the service account the necessary IAM permissions.

1. Next, you need to grant permissions via IAM. Perform the steps that follow:

   - In the Google Cloud console, on the Navigation menu, navigate to IAM & Admin > IAM.

   - Click on Grant access.

   - In the Add principals section:

     - In the New principals text field, paste the Service account id value that you copied earlier.

     - Under Assign Role, select the following roles (search for them if you need to):

       - BigQuery Data Owner
       - Vertex AI User

2. Click Save to apply the changes.

3. Navigate to APIs and Services from the Navigation menu, click + Enable APIs and services, search `Vertex AI API`, click the Enable button.

### Task 2: Generate embeddings

1. In the Google Cloud console, on the Navigation menu, navigate to BigQuery.

2. In Explorer, navigate to the three dots besides the project, click Create dataset. For Dataset ID, enter `CustomerReview`. Keep the other option by default, and click Create dataset.

3. To connect to the embedding model, run the following SQL query in the query editor:

```sql
CREATE OR REPLACE MODEL `CustomerReview.Embeddings`
REMOTE WITH CONNECTION `us.embedding_conn`
OPTIONS (ENDPOINT = 'Gemini Embedding model ID | disablehighlight');
```

4. To upload the dataset from a CSV file, run the following SQL query:

```sql
LOAD DATA OVERWRITE CustomerReview.customer_reviews
(
    customer_review_id INT64,
    customer_id INT64,
    location_id INT64,
    review_datetime DATETIME,
    review_text STRING,
    social_media_source STRING,
    social_media_handle STRING
)
FROM FILES (
    format = 'CSV',
    uris = ['gs://spls/gsp1249/customer_reviews.csv']
);
```

5. (optional) To check the uploaded data in the table, click Go to table. Find the schema of the table and preview the data.

6. To generate embeddings from recent customer feedback and store them in a table, run the following SQL query in the query editor:

```sql
CREATE OR REPLACE TABLE `CustomerReview.customer_reviews_embedded` AS
SELECT *
FROM ML.GENERATE_EMBEDDING(
    MODEL `CustomerReview.Embeddings`,
    (SELECT review_text AS content FROM `CustomerReview.customer_reviews`)
);
```

7. (Optional) To examine the embedding results, click Go to table. Find the schema of the table and preview the data. Note that the embedding results are floating-point numbers and may not be immediately interpretable.

### Task 3: Search the vector space and retrieve the similar items

1. To create an index of the vector search space, run the following SQL query:

   Note: For datasets with fewer than 5,000 rows, as in this lab, creating an index is unnecessary. This step demonstrates the code required to create a vector space index when needed for larger datasets.

```sql
CREATE OR REPLACE VECTOR INDEX `CustomerReview.reviews_index`
ON `CustomerReview.customer_reviews_embedded`(ml_generate_embedding_result)
OPTIONS (distance_type = 'COSINE', index_type = 'IVF');
```

2. To search the vector space and retrieve the similar items, run the following SQL query:

```sql
CREATE OR REPLACE TABLE `CustomerReview.vector_search_result` AS
SELECT
    query.query,
    base.content
FROM
    VECTOR_SEARCH(
        TABLE `CustomerReview.customer_reviews_embedded`,
        'ml_generate_embedding_result',
        (
            SELECT
                ml_generate_embedding_result,
                content AS query
            FROM
                ML.GENERATE_EMBEDDING(
                    MODEL `CustomerReview.Embeddings`,
                    (SELECT 'service' AS content)
                )
        ),
        top_k => 5,
        options => '{"fraction_lists_to_search": 0.01}'
    );
```

3. (Optional) To check the query results, click Go to table. Find the schema of the table and preview the data.

### Task 4: Generate an improved answer

1. To connect to the Gemini model, run the following SQL query:

```sql
CREATE OR REPLACE MODEL `CustomerReview.Gemini`
REMOTE WITH CONNECTION `us.embedding_conn`
OPTIONS (ENDPOINT = 'Gemini Model ID | disablehighlight');
```

2. To enhance Gemini's responses, provide it with relevant and recent data retrieved from the vector search by running the following query:

```sql
SELECT
    ml_generate_text_llm_result AS generated
FROM
    ML.GENERATE_TEXT(
        MODEL `CustomerReview.Gemini`,
        (
            SELECT
                CONCAT(
                    'Summarize what customers think about our services',
                    STRING_AGG(FORMAT('review text: %s', base.content), ',\n')
                ) AS prompt
            FROM
                `CustomerReview.vector_search_result` AS base
        ),
        STRUCT(
            0.4 AS temperature,
            300 AS max_output_tokens,
            0.5 AS top_p,
            5 AS top_k,
            TRUE AS flatten_json_output
        )
    );
```

3. Check the Gemini-generated results in the Query results section below the query editor.

**Questions for you:**
1. How do you determine whether Gemini generates better answers with RAG than without it? Try testing it with code.
2. How can the code be improved? For example, instead of saving vector search results to a table (Task 3), could that process be embedded directly into answer generation (Task 4) for real-time retrieval?

Explore these questions with any remaining lab time. Good luck!

## Verification
- Successfully created source connection and granted IAM permissions
- Dataset and tables created and populated with embedding data
- Vector search executed and returned relevant results
- Gemini generated improved answers using RAG

## Troubleshooting
- Connection creation fails: Ensure Vertex AI API is enabled and you have proper permissions
- Model creation fails: Ensure connection is configured correctly and endpoint name is correct
- Embedding generation fails: Check input data format and model parameters
- Vector search fails: Ensure embeddings were generated correctly and search parameters are appropriate
- RAG responses not relevant: Check if vector search returns relevant context

## Cleanup
No specific cleanup required for this lab as it primarily involves querying data. However, if cleanup is needed:

1. Delete the created dataset: `DROP SCHEMA CustomerReview CASCADE`
2. Delete the connection: Remove the `embedding_conn` connection from BigQuery console
3. Remove IAM permissions: Remove the granted roles from the service account

## Additional Resources
- [Create Embeddings, Vector Search, and RAG with BigQuery](https://www.cloudskillsboost.google/course_templates/1232)
- [BigQuery vector search introduction](https://cloud.google.com/bigquery/docs/vector-search-intro)
- [BigQuery ML embedding generation](https://cloud.google.com/bigquery/docs/generate-embedding)

## Notes
- This lab demonstrates the power of RAG pipelines in BigQuery
- Learn to convert text data into vector embeddings
- Understand the concept of vector similarity search
- Master the technique of augmenting generative AI with retrieved context
- Practice applying RAG to real business scenarios like customer feedback analysis
