# GSP1246 - 使用 Gemini 和 SQL 分析客戶評論

## Lab 概述
在此實驗中，您將學習如何使用 BigQuery Machine Learning 與遠端模型（Gemini）來分析客戶評論。您將提取關鍵字、評估客戶評論情感，並使用零樣本和少樣本提示回應客戶評論。

BigQuery 是一個功能齊全的 AI 就緒數據分析平台，專為多引擎、多格式和多雲環境設計。其中一個關鍵功能是 BigQuery Machine Learning，讓您能夠使用 SQL 查詢創建和運行機器學習模型。

Gemini 是 Google DeepMind 開發的生成式 AI 模型系列，專為多模態用例設計。Gemini API 讓您能夠訪問 Gemini 模型。

此外，您將使用 Gemini 模型為客戶評論圖片生成摘要和提取相關關鍵字。

## 先決條件
- 基本 SQL 知識
- Google Cloud 控制台訪問權限
- BigQuery 基本概念了解
- Vertex AI API 訪問權限

## 學習目標
完成此實驗後，您將能夠：
- 在 BigQuery 中創建 Cloud Resource 連接
- 在 BigQuery 中創建數據集和表
- 在 BigQuery 中創建 Gemini 遠端模型
- 提示 Gemini 分析文本客戶評論的關鍵字和情感（正面或負面）
- 生成正面和負面評論計數的報告
- 回應客戶評論
- 提示 Gemini 為每個客戶評論圖片提取摘要和關鍵字

## 預估時間
60 分鐘

## 實驗步驟

### 任務 1：創建雲資源連接和授予 IAM 角色

#### 在 BigQuery 中創建雲資源連接
1. 在 Google Cloud 控制台中，點擊 **Navigation menu** > **BigQuery**
2. 點擊 **DONE** 關閉歡迎對話框
3. 在 **Explorer** 面板中，點擊 **+ Add data**，在 **Search for data sources** 中輸入 **Vertex AI**
4. 點擊 **Vertex AI** 結果，然後點擊 **BigQuery Federation**
5. 在 Connection type 列表中，選擇 **Vertex AI remote models, remote functions and BigLake (Cloud Resource)**
6. 在 Connection ID 字段中輸入 **gemini_conn**
7. 對於 **Location type** 選擇 **Multi-region**，然後從下拉選單選擇 **US** 多區域
8. 使用其他設置的默認值
9. 點擊 **Create connection**
10. 點擊 **Go to connection**
11. 在 Connection info 窗格中，複製服務帳戶 ID 到文本文件以用於下一個任務

#### 授予連接服務帳戶 Vertex AI User 角色
1. 在控制台中，在 **Navigation menu** 上點擊 **IAM & Admin**
2. 點擊 **Grant Access**
3. 在 **New principals** 字段中，輸入您之前複製的服務帳戶 ID
4. 在 Select a role 字段中，輸入 **Vertex AI**，然後選擇 **Vertex AI User** 角色
5. 點擊 **Save**

### 任務 2：檢查圖片和文件，並授予服務帳戶 IAM 角色

#### 查看 Cloud Storage 上的圖片文件和客戶評論數據集
1. 在控制台中，選擇 **Navigation menu** > **Cloud Storage**
2. 點擊 **Buckets** 並選擇 **`set at lab start`-bucket** bucket
3. 打開 `gsp1246` 文件夾，您會看到兩個項目：
   - `images` 文件夾包含您將分析的所有圖片文件
   - `customer_reviews.csv` 文件是數據集，包含文本客戶評論

#### 授予連接服務帳戶 Storage Object Admin 角色
1. 返回到 bucket 的根目錄
2. 點擊 **Permissions**
3. 點擊 **Grant access**
4. 在 **New principals** 字段中，輸入您之前複製的服務帳戶 ID
5. 在 Select a role 字段中，輸入 **Storage Object**，然後選擇 **Storage Object Admin** 角色
6. 點擊 **Save**

### 任務 3：在 BigQuery 中創建數據集和表

#### 創建數據集
1. 在控制台中，選擇 **Navigation menu** > **BigQuery**
2. 在 **Explorer** 面板中，為 **`set at lab start`** 選擇 **View actions** > **Create dataset**
3. 在 **Create dataset** 窗格中輸入以下信息：
   - Dataset ID: **gemini_demo**
   - Location type: 選擇 **Multi-region**
   - Multi-region: 選擇 **US**
4. 點擊 **Create dataset**

#### 創建客戶評論表
1. 點擊 **+** 創建新的 SQL Query
2. 在查詢編輯器中貼上以下查詢：

```sql
LOAD DATA OVERWRITE gemini_demo.customer_reviews
(customer_review_id INT64, customer_id INT64, location_id INT64, review_datetime DATETIME, review_text STRING, social_media_source STRING, social_media_handle STRING)
FROM FILES (
  format = 'CSV',
  uris = ['gs://set at lab start-bucket/gsp1246/customer_reviews.csv']);
```

3. 點擊 **Run**
4. 在 Explorer 窗格中，點擊 **customer_reviews** 表並查看架構和詳情

#### 創建評論圖片對象表
1. 點擊 **+** 創建新的 SQL Query
2. 在查詢編輯器中貼上以下查詢：

```sql
CREATE OR REPLACE EXTERNAL TABLE
  `gemini_demo.review_images`
WITH CONNECTION `us.gemini_conn`
OPTIONS (
  object_metadata = 'SIMPLE',
  uris = ['gs://set at lab start-bucket/gsp1246/images/*']
  );
```

3. 點擊 **Run**
4. 在 Explorer 中，點擊 **review_images** 表並查看架構和詳情

### 任務 4：在 BigQuery 中創建 Gemini 模型

#### 創建 Gemini Flash 模型
1. 點擊 **+** 創建新的 SQL Query
2. 在查詢編輯器中貼上並運行以下查詢：

```sql
CREATE OR REPLACE MODEL `gemini_demo.gemini_flash`
REMOTE WITH CONNECTION `us.gemini_conn`
OPTIONS (endpoint = 'model_id | disablehighlight')
```

3. 在 Explorer 中，點擊 **gemini_flash** 模型並查看詳情和架構

### 任務 5：提示 Gemini 分析客戶評論的關鍵字和情感

#### 分析客戶評論的關鍵字
1. 點擊 **+** 創建新的 SQL Query
2. 在查詢編輯器中貼上並運行以下查詢：

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

3. 在 Explorer 中，點擊 **customer_reviews_keywords** 表並查看架構和詳情
4. 運行以下查詢查看結果：

```sql
SELECT * FROM `gemini_demo.customer_reviews_keywords`
```

#### 分析客戶評論的正面和負面情感
1. 點擊 **+** 創建新的 SQL Query
2. 在查詢編輯器中貼上並運行以下查詢：

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

3. 在 Explorer 中，點擊 **customer_reviews_analysis** 表並查看架構和詳情
4. 運行以下查詢查看結果：

```sql
SELECT * FROM `gemini_demo.customer_reviews_analysis`
ORDER BY review_datetime
```

#### 創建清理數據的視圖
1. 點擊 **+** 創建新的 SQL Query
2. 在查詢編輯器中貼上並運行以下查詢：

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

3. 運行以下查詢查看清理後的數據：

```sql
SELECT * FROM `gemini_demo.cleaned_data_view`
ORDER BY review_datetime
```

#### 創建正面和負面評論計數報告
1. 使用以下查詢生成柱狀圖報告：

```sql
SELECT sentiment, COUNT(*) AS count
FROM `gemini_demo.cleaned_data_view`
WHERE sentiment IN ('positive', 'negative')
GROUP BY sentiment;
```

2. 點擊 **CHART** 在查詢結果部分創建柱狀圖

#### 按社交媒體來源創建正面和負面評論計數
1. 使用以下查詢：

```sql
SELECT sentiment, social_media_source, COUNT(*) AS count
FROM `gemini_demo.cleaned_data_view`
WHERE sentiment IN ('positive') OR sentiment IN ('negative')
GROUP BY sentiment, social_media_source
ORDER BY sentiment, count;
```

### 任務 6：回應客戶評論

#### 營銷回應
1. 使用以下查詢為客戶 ID 5576 生成營銷回應：

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

2. 查看營銷表結果：

```sql
SELECT * FROM `gemini_demo.customer_reviews_marketing`
```

3. 格式化營銷回應：

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

4. 查看格式化的營銷回應：

```sql
SELECT * FROM `gemini_demo.customer_reviews_marketing_formatted`
```

#### 客戶服務回應
1. 使用以下查詢為客戶 ID 8844 生成客戶服務回應：

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

2. 查看客戶服務回應表：

```sql
SELECT * FROM `gemini_demo.customer_reviews_cs_response`
```

3. 格式化客戶服務回應：

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

4. 查看格式化的客戶服務回應：

```sql
SELECT * FROM `gemini_demo.customer_reviews_cs_response_formatted`
```

### 任務 7：提示 Gemini 為每個圖片提供關鍵字和摘要

#### 使用 Gemini 模型分析圖片
1. 點擊 **+** 創建新的 SQL Query
2. 在查詢編輯器中貼上並運行以下查詢：

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

3. 在 Explorer 中，點擊 **review_image_results** 表並查看架構和詳情
4. 運行以下查詢查看結果：

```sql
SELECT * FROM `gemini_demo.review_images_results`
```

5. 創建格式化的結果表：

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

6. 查看格式化的結果：

```sql
SELECT * FROM `gemini_demo.review_images_results_formatted`
```

## 驗證
- 成功創建了 Cloud Resource 連接
- 數據集和表已創建並填充了數據
- Gemini 模型已創建並可用
- 客戶評論分析已完成並生成了報告
- 營銷和客戶服務回應已生成
- 圖片分析已完成並提供了摘要和關鍵字

## 故障排除
- **連接創建失敗**：確保 Vertex AI API 已啟用，並且您有適當的權限
- **數據加載失敗**：檢查 Cloud Storage bucket 權限和 CSV 文件格式
- **模型創建失敗**：確保連接配置正確，並且端點名稱正確
- **ML 生成失敗**：檢查提示格式和模型參數
- **JSON 解析錯誤**：確保 Gemini 回應格式正確

## 清理
此實驗不需要特定的清理步驟，因為它主要涉及查詢數據。但是，如果需要清理：

1. 刪除創建的數據集：`DROP SCHEMA gemini_demo CASCADE`
2. 刪除連接：從 BigQuery 控制台中刪除 `gemini_conn` 連接
3. 移除 IAM 權限：從服務帳戶中移除授予的角色

## 額外資源
- [Introduction to BigQuery ML](https://cloud.google.com/bigquery/docs/bqml-introduction)
- [Scaling machine learning with BigQuery ML inference engine - Blog](https://cloud.google.com/blog/products/data-analytics/bigquery-ml-inference-engine-is-now-ga)
- [Gemini Models](https://deepmind.google/technologies/gemini/#introduction)
- [Generative AI](https://cloud.google.com/bigquery/docs/generative-ai-overview#generative_ai)

## 筆記
- 此實驗演示了 BigQuery ML 與 Gemini 的強大組合
- 學習使用 SQL 進行情感分析和關鍵字提取
- 理解零樣本和少樣本提示的區別
- 掌握多模態分析（文本和圖片）
- 實踐生成式 AI 在商業應用中的實際用法
