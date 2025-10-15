# BigQuery: Qwik Start - Console

## Lab Title
BigQuery: Qwik Start - Console

## Lab Description
This hands-on lab shows you how to query public tables and load sample data into BigQuery. BigQuery is Google's fully managed, petabyte-scale data warehouse that enables super-fast SQL queries using the processing power of Google's infrastructure.

## Prerequisites
- A Google Cloud account with BigQuery API enabled
- Basic knowledge of SQL
- Access to Google Cloud Console

## Lab Objectives
By the end of this lab, you will be able to:
- Query a public dataset
- Create a new dataset
- Load data into a new table
- Query a custom table

## Estimated Time
30 minutes

## Lab Steps

### Step 1: Open BigQuery

1. In the Google Cloud Console, select **Navigation menu** > **BigQuery**
2. Click **Done** to dismiss the welcome message

**Expected Result:** BigQuery console opens and is ready for use.

### Step 2: Query a public dataset

1. Click **+** (SQL query) to create a new query
2. Copy and paste the following query into the BigQuery Query editor:

```sql
#standardSQL
SELECT
 weight_pounds, state, year, gestation_weeks
FROM
 `bigquery-public-data.samples.natality`
ORDER BY weight_pounds DESC LIMIT 10;
```

3. Click the **Run** button

**Expected Result:** Query results display the top 10 records from the US natality dataset ordered by birth weight in descending order.

### Step 3: Create a new dataset

1. In the **Explorer** pane, click the **View actions** icon (three dots) next to your project ID
2. Click **Create dataset**
3. Set **Dataset ID** to `babynames`
4. Leave all other fields at their default values
5. Click **Create dataset**

**Expected Result:** The `babynames` dataset is successfully created and appears in the Explorer.

### Step 4: Load data into a new table

1. In the Explorer, locate the `babynames` dataset
2. Click the **View actions** icon (three dots) next to the dataset
3. Click **Create table**
4. In the Create table dialog, set the following fields:

| **Field** | **Value** |
|-----------|-----------|
| Create table from | Google Cloud Storage |
| Select file from GCS bucket | `spls/gsp072/baby-names/yob2014.txt` |
| File format | CSV |
| Table name | `names_2014` |
| Schema > Edit as text | Turn on, then add: `name:string,gender:string,count:integer` |

5. Click **Create table** button

**Expected Result:** BigQuery finishes creating the table and loading the data, and the `names_2014` table appears under the `babynames` dataset.

### Step 5: Preview the table

1. Click the `names_2014` table in the Explorer
2. Click the **Preview** tab

**Expected Result:** Display the first few rows of the table data, confirming the data was loaded correctly.

### Step 6: Query a custom dataset

1. In BigQuery, click the **+** (SQL query) icon at the top
2. Paste or type the following query into the query editor:

```sql
#standardSQL
SELECT
 name, count
FROM
 `babynames.names_2014`
WHERE
 gender = 'M'
ORDER BY count DESC LIMIT 5;
```

3. Click the **Run** button

**Expected Result:** Query displays the top 5 most popular boys' names for 2014 along with their occurrence counts.

## Verification Steps

### Checkpoint 1: Query a public dataset
- Verify successful execution of public dataset query
- Confirm query results show birth weight, state, year, and gestation weeks columns

### Checkpoint 2: Create a new dataset
- Confirm the `babynames` dataset was created successfully and appears in Explorer

### Checkpoint 3: Load data into table
- Confirm the `names_2014` table was created successfully and data was loaded

### Checkpoint 4: Query custom dataset
- Confirm successful query of custom table showing top 5 boys' names for 2014

## Troubleshooting

### Common Issues and Solutions

**Issue: Query execution fails**
- Ensure BigQuery API is enabled
- Verify query syntax is correct
- Confirm access to public datasets

**Issue: Data loading fails**
- Verify Cloud Storage file path is correct: `spls/gsp072/baby-names/yob2014.txt`
- Ensure file format is set to CSV
- Confirm schema definition is correct: `name:string,gender:string,count:integer`

**Issue: Dataset creation fails**
- Verify project ID is correct
- Ensure dataset name doesn't use reserved words
- Check project quotas and permissions

**Issue: Table preview error**
- Confirm table was created and loaded successfully
- Check network connectivity
- Refresh BigQuery console

## Cleanup Instructions

To avoid charges after completing the lab, follow these steps:

1. **Delete the dataset**:
   - In the Explorer, locate the `babynames` dataset
   - Click the **View actions** icon (three dots) next to the dataset
   - Select **Delete**
   - Type `babynames` in the confirmation dialog to confirm deletion

2. **Verify cleanup**:
   - Confirm the `babynames` dataset is removed from the Explorer
   - Ensure no additional charges will be incurred

## Additional Resources

### Official Documentation
- [BigQuery Quickstart Guide](https://cloud.google.com/bigquery/docs/quickstarts/quickstart-web-ui)
- [BigQuery Public Datasets](https://cloud.google.com/bigquery/public-data)
- [BigQuery Query Reference](https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax)

### Related Labs
- [Cloud Storage Qwik Start Series](../Set-Up-an-App-Dev-Environment-on-Google-Cloud/cloud-storage-qwik-start-series.md)
- [Pub/Sub: Qwik Start - Console](../Set-Up-an-App-Dev-Environment-on-Google-Cloud/GSP096-Pub-Sub-Qwik-Start-Console/)

### Further Learning
- [BigQuery Best Practices](https://cloud.google.com/bigquery/docs/best-practices)
- [BigQuery Performance Tuning](https://cloud.google.com/bigquery/docs/performance)
- [BigQuery Security Considerations](https://cloud.google.com/bigquery/docs/security)

## Notes
- The public dataset used `bigquery-public-data.samples.natality` contains US birth rate statistics
- Custom data uses 2014 baby names data provided by the US Social Security Administration
- BigQuery uses standard SQL syntax and supports advanced features like nested and repeated fields
- The loaded dataset is approximately 7MB, suitable for learning purposes
