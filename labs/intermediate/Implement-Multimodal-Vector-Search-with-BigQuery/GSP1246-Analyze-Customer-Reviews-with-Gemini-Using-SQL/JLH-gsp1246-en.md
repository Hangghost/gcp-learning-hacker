# GSP1246 - Analyze Customer Reviews with Gemini Using SQL

## Lab Overview
In this lab you learn how to use BigQuery Machine Learning with remote models (Gemini) in SQL to extract keywords, assess customer sentiment in customer reviews, and respond to customer reviews with zero-shot and few-shot prompts.

BigQuery is a fully managed, AI-ready data analytics platform that helps you maximize value from your data and is designed to be multi-engine, multi-format, and multi-cloud. One of its key features is BigQuery Machine Learning, which lets you create and run machine learning (ML) models by using SQL queries or with Colab Enterprise notebooks.

Gemini is a family of generative AI models developed by Google DeepMind that is designed for multimodal use cases. The Gemini API gives you access to the Gemini models.

Additionally, you'll use the Gemini model to generate summaries and extract relevant keywords from customer review images.

## Prerequisites
- Basic SQL knowledge
- Access to Google Cloud console
- Basic understanding of BigQuery concepts
- Access to Vertex AI APIs

## Learning Objectives
By the end of this lab, you will be able to:
- Create a Cloud Resource connection in BigQuery
- Create the dataset, and tables in BigQuery
- Create the Gemini remote models in BigQuery
- Prompt Gemini to analyze keywords and sentiment (positive, or negative) for text based customer reviews
- Generate a report with a count of positive, and negative reviews
- Respond to customer reviews
- Prompt Gemini to extract a summary and keywords for each customer review image

## Estimated Time
60 minutes

## Lab Steps

### Task 1: Create the cloud resource connection and grant IAM role

#### Create the cloud resource connection in BigQuery
1. In the Google Cloud Console, select Navigation menu > BigQuery
2. Click DONE on the Welcome dialog
3. In the Explorer pane, click + Add data, and in Search for data sources type Vertex AI
4. Click on the Vertex AI result then click on BigQuery Federation
5. In the Connection type list, select Vertex AI remote models, remote functions and BigLake (Cloud Resource)
6. In the Connection ID field, enter gemini_conn for your connection
7. For Location type select Multi-region and then, from dropdown select US multi-region
8. Use the defaults for the other settings
9. Click Create connection
10. Click Go to connection
11. In the Connection info pane, copy the service account ID to a text file for use in the next task

#### Grant Vertex AI User role to the connection's service account
1. In the console, on the Navigation menu, click IAM & Admin
2. Click Grant Access
3. In the New principals field, enter the service account ID that you copied earlier
4. In the Select a role field, enter Vertex AI, and then select Vertex AI User role
5. Click Save

### Task 2: Review images, and files, and grant IAM role to service account

#### Review the image files and customer reviews dataset on Cloud Storage
1. In the console, select the Navigation menu (), and then select Cloud Storage
2. Click on Buckets and Select the `set at lab start`-bucket bucket
3. The bucket contains the gsp1246 folder, open the folder. You will see two items in it:
   - The images folder contains all image files you will analyze. Feel free to access the images folder and review the image files
   - The customer_reviews.csv file is the dataset that contains the text based customer reviews

#### Grant IAM Storage Object Admin role to the connection's service account
1. Return to the root of the bucket
2. Click Permissions
3. Click Grant access
4. In the New principals field, enter the service account ID you copied earlier
5. In the Select a role field, enter Storage Object, and then select Storage Object Admin role
6. Click Save

### Task 3: Create the dataset, and tables in BigQuery

#### Create the dataset
1. In the console, select the Navigation menu (), and then select BigQuery
2. In the Explorer panel, for `set at lab start`, select View actions (), and then select Create dataset
3. In the Create dataset pane, enter the following information:
   - Field: Dataset ID, Value: gemini_demo
   - Location type: select Multi-region
   - Multi-region: select US
4. Click Create dataset

#### Create the table for the customer reviews
1. Click the + to Create a new SQL Query
2. In the query editor, paste the query below and run it:

```sql
LOAD DATA OVERWRITE gemini_demo.customer_reviews
(customer_review_id INT64, customer_id INT64, location_id INT64, review_datetime DATETIME, review_text STRING, social_media_source STRING, social_media_handle STRING)
FROM FILES (
  format = 'CSV',
  uris = ['gs://set at lab start-bucket/gsp1246/customer_reviews.csv']);
```

3. Click Run
4. In the Explorer pane, click on the customer_reviews table and review the schema and details

#### Create the object table for the review images
1. Click the + to Create new SQL query
2. In the query editor, paste the query below and run it:

```sql
CREATE OR REPLACE EXTERNAL TABLE
  `gemini_demo.review_images`
WITH CONNECTION `us.gemini_conn`
OPTIONS (
  object_metadata = 'SIMPLE',
  uris = ['gs://set at lab start-bucket/gsp1246/images/*']
  );
```

3. Run the Query
4. In the Explorer, click on the review_images table and review the schema and details

### Task 4: Create the Gemini models in BigQuery

#### Create the Gemini Flash model
1. Click the + to Create a new SQL Query
2. In the query editor, paste the query below and run it:

```sql
CREATE OR REPLACE MODEL `gemini_demo.gemini_flash`
REMOTE WITH CONNECTION `us.gemini_conn`
OPTIONS (endpoint = 'model_id | disablehighlight')
```

3. In the Explorer, click on the gemini_flash model and review the details and schema

### Task 5: Prompt Gemini to analyze customer reviews for keywords and sentiment

#### Analyze the customer reviews for keywords
1. Click the + to Create a new SQL Query
2. In the query editor, paste the query below, and run it:

```sql
CREATE OR REPLACE TABLE
`gemini_demo.customer_reviews_keywords` AS (
SELECT ml_generate_text_llm_result, social_media_source, review_text, customer_id, location_id, review_datetime
FROM
ML.GENERATE_TEXT(
MODEL `gemini_demo.gemini_flash`,
(
   SELECT social_media_source, customer_id, location_id, review_text, review_datetime, CONCAT(
      'For each review, provide keywords from the review. Answer in JSON format with one key: keywords. Keywords should be a list.', review_text) AS prompt
   FROM `gemini_demo.customer_reviews`
),
STRUCT(0.2 AS temperature, TRUE AS flatten_json_output)));
```

3. In the Explorer, click on the customer_reviews_keywords table and review the schema and details
4. Click the + to Create a new SQL Query
5. In the query editor, paste and run the query below:

```sql
SELECT * FROM `gemini_demo.customer_reviews_keywords`
```

#### Analyze the customer reviews for positive and negative sentiment
1. Click the + to Create a new SQL Query
2. In the query editor, paste the query below, and run it:

```sql
CREATE OR REPLACE TABLE
`gemini_demo.customer_reviews_analysis` AS (
SELECT ml_generate_text_llm_result, social_media_source, review_text, customer_id, location_id, review_datetime
FROM
ML.GENERATE_TEXT(
MODEL `gemini_demo.gemini_flash`,
(
   SELECT social_media_source, customer_id, location_id, review_text, review_datetime, CONCAT(
      'Classify the sentiment of the following text as positive or negative.',
      review_text, "In your response don't include the sentiment explanation. Remove all extraneous information from your response, it should be a boolean response either positive or negative.") AS prompt
   FROM `gemini_demo.customer_reviews`
),
STRUCT(0.2 AS temperature, TRUE AS flatten_json_output)));
```

3. In the Explorer, click on the customer_reviews_analysis table and review the schema and details
4. Click the + to Create a new SQL Query
5. In the query editor, paste and run the query below:

```sql
SELECT * FROM `gemini_demo.customer_reviews_analysis`
ORDER BY review_datetime
```

#### Create a view to sanitize the records
1. Click the + to Create a new SQL Query
2. In the query editor, paste and run the query below:

```sql
CREATE OR REPLACE VIEW gemini_demo.cleaned_data_view AS
SELECT
REPLACE(REPLACE(REPLACE(LOWER(ml_generate_text_llm_result), '.', ''), ' ', ''), '\n', '') AS sentiment,
REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(social_media_source, r'Google(\+|\sReviews|\sLocal|\sMy\sBusiness|\sreviews|\sMaps)?',
      'Google'), 'YELP', 'Yelp'), r'SocialMedia1?', 'Social Media') AS social_media_source,
review_text,
customer_id,
location_id,
review_datetime
FROM
gemini_demo.customer_reviews_analysis;
```

3. You can query the view with the query below, to see the rows created:

```sql
SELECT * FROM `gemini_demo.cleaned_data_view`
ORDER BY review_datetime
```

#### Create a report of positive and negative review counts
1. You can use BigQuery to create a bar chart report of the counts of positive and negative reviews. Start with the query below:

```sql
SELECT sentiment, COUNT(*) AS count
FROM `gemini_demo.cleaned_data_view`
WHERE sentiment IN ('positive', 'negative')
GROUP BY sentiment;
```

2. To create the bar chart report of these counts, click CHART in the Query results section of BigQuery

#### Create a count of positive and negative reviews by social media source
1. You can use BigQuery to list the count of positive and negative reviews per social media source using the query below:

```sql
SELECT sentiment, social_media_source, COUNT(*) AS count
FROM `gemini_demo.cleaned_data_view`
WHERE sentiment IN ('positive') OR sentiment IN ('negative')
GROUP BY sentiment, social_media_source
ORDER BY sentiment, count;
```

### Task 6: Respond to customer reviews

#### Marketing response
The customer with customer_id 5576 responded with a positive review. Use Gemini to create a marketing response to incentivize this customer.

1. In the query editor, paste the query below and run it:

```sql
CREATE OR REPLACE TABLE
`gemini_demo.customer_reviews_marketing` AS (
SELECT ml_generate_text_llm_result, social_media_source, review_text, customer_id, location_id, review_datetime
FROM
ML.GENERATE_TEXT(
MODEL `gemini_demo.gemini_flash`,
(
   SELECT social_media_source, customer_id, location_id, review_text, review_datetime, CONCAT(
      'You are a marketing representative. How could we incentivise this customer with this positive review? Provide a single response, and should be simple and concise, do not include emojis. Answer in JSON format with one key: marketing. Marketing should be a string.', review_text) AS prompt
   FROM `gemini_demo.customer_reviews`
   WHERE customer_id = 5576
),
STRUCT(0.2 AS temperature, TRUE AS flatten_json_output)));
```

2. You can view the details of the customer_reviews_marketing table by running the SQL query below:

```sql
SELECT * FROM `gemini_demo.customer_reviews_marketing`
```

3. You can make this easier to read, and take action on the response by using the SQL query below:

```sql
CREATE OR REPLACE TABLE
`gemini_demo.customer_reviews_marketing_formatted` AS (
SELECT
   review_text,
   JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.marketing") AS marketing,
   social_media_source, customer_id, location_id, review_datetime
FROM
   `gemini_demo.customer_reviews_marketing` results )
```

4. You can view the details of the table by running the SQL query below:

```sql
SELECT * FROM `gemini_demo.customer_reviews_marketing_formatted`
```

#### Customer service response
The customer with customer_id 8844 responded with a negative review. Use Gemini to create a customer service response and suggest improvements.

1. In the query editor, paste the query below and run it:

```sql
CREATE OR REPLACE TABLE
`gemini_demo.customer_reviews_cs_response` AS (
SELECT ml_generate_text_llm_result, social_media_source, review_text, customer_id, location_id, review_datetime
FROM
ML.GENERATE_TEXT(
MODEL `gemini_demo.gemini_flash`,
(
   SELECT social_media_source, customer_id, location_id, review_text, review_datetime, CONCAT(
      'How would you respond to this customer review? If the customer says the coffee is weak or burnt, respond stating "thank you for the review we will provide your response to the location that you did not like the coffee and it could be improved." Or if the review states the service is bad, respond to the customer stating, "the location they visited has been notified and we are taking action to improve our service at that location." From the customer reviews provide actions that the location can take to improve. The response and the actions should be simple, and to the point. Do not include any extraneous or special characters in your response. Answer in JSON format with two keys: Response, and Actions. Response should be a string. Actions should be a string.', review_text) AS prompt
   FROM `gemini_demo.customer_reviews`
   WHERE customer_id = 8844
),
STRUCT(0.2 AS temperature, TRUE AS flatten_json_output)));
```

2. You can view the details of the table by running the SQL query below:

```sql
SELECT * FROM `gemini_demo.customer_reviews_cs_response`
```

3. You can make this easier to read, by using the SQL query below two separate the response and the actions into two columns in a new table called customer_reviews_cs_response_formatted:

```sql
CREATE OR REPLACE TABLE
`gemini_demo.customer_reviews_cs_response_formatted` AS (
SELECT
   review_text,
   JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.Response") AS Response,
   JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.Actions") AS Actions,
   social_media_source, customer_id, location_id, review_datetime
FROM
   `gemini_demo.customer_reviews_cs_response` results )
```

4. You can view the details of the table by running the SQL query below:

```sql
SELECT * FROM `gemini_demo.customer_reviews_cs_response_formatted`
```

### Task 7: Prompt Gemini to provide keywords and summaries for each image

#### Analyze the images with Gemini model
1. Click the + to Create a new SQL Query
2. In the query editor, paste the query below, and run it:

```sql
CREATE OR REPLACE TABLE
`gemini_demo.review_images_results` AS (
SELECT
    uri,
    ml_generate_text_llm_result
FROM
    ML.GENERATE_TEXT( MODEL `gemini_demo.gemini_flash`,
    TABLE `gemini_demo.review_images`,
    STRUCT( 0.2 AS temperature,
        'For each image, provide a summary of what is happening in the image and keywords from the summary. Answer in JSON format with two keys: summary, keywords. Summary should be a string, keywords should be a list.' AS PROMPT,
        TRUE AS FLATTEN_JSON_OUTPUT)));
```

3. In the Explorer, click on the review_image_results table and review the schema and details
4. Click the + to Create a new SQL Query
5. In the query editor, paste and run the query below:

```sql
SELECT * FROM `gemini_demo.review_images_results`
```

6. Click the + to Create a new SQL Query
7. In the query editor, paste and run the query below:

```sql
CREATE OR REPLACE TABLE
  `gemini_demo.review_images_results_formatted` AS (
  SELECT
    uri,
    JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.summary") AS summary,
    JSON_QUERY(RTRIM(LTRIM(results.ml_generate_text_llm_result, " ```json"), "```"), "$.keywords") AS keywords
  FROM
    `gemini_demo.review_images_results` results )
```

8. You can query the table with the query below, to see the rows created:

```sql
SELECT * FROM `gemini_demo.review_images_results_formatted`
```

## Verification
- Successfully created Cloud Resource connection
- Dataset and tables created and populated with data
- Gemini model created and available
- Customer review analysis completed and reports generated
- Marketing and customer service responses generated
- Image analysis completed with summaries and keywords provided

## Troubleshooting
- Connection creation fails: Ensure Vertex AI API is enabled and you have proper permissions
- Data loading fails: Check Cloud Storage bucket permissions and CSV file format
- Model creation fails: Ensure connection is configured correctly and endpoint name is correct
- ML generation fails: Check prompt format and model parameters
- JSON parsing errors: Ensure Gemini response format is correct

## Cleanup
No specific cleanup required for this lab as it primarily involves querying data. However, if cleanup is needed:

1. Delete the created dataset: `DROP SCHEMA gemini_demo CASCADE`
2. Delete the connection: Remove the `gemini_conn` connection from BigQuery console
3. Remove IAM permissions: Remove the granted roles from the service account

## Additional Resources
- [Introduction to BigQuery ML](https://cloud.google.com/bigquery/docs/bqml-introduction)
- [Scaling machine learning with BigQuery ML inference engine - Blog](https://cloud.google.com/blog/products/data-analytics/bigquery-ml-inference-engine-is-now-ga)
- [Gemini Models](https://deepmind.google/technologies/gemini/#introduction)
- [Generative AI](https://cloud.google.com/bigquery/docs/generative-ai-overview#generative_ai)

## Notes
- This lab demonstrates the powerful combination of BigQuery ML with Gemini
- Learn to use SQL for sentiment analysis and keyword extraction
- Understand the difference between zero-shot and few-shot prompting
- Master multimodal analysis (text and images)
- Practice real-world applications of generative AI in business
