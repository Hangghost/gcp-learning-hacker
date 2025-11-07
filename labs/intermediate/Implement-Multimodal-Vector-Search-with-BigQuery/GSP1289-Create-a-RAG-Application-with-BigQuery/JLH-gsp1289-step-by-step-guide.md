# GSP1289 - Create a RAG Application with BigQuery - 逐步操作指南

## 實驗室概述
這是 GSP1289 挑戰實驗室的逐步操作指南。本實驗室將引導您使用 BigQuery 實現一個完整的 RAG (Retrieval Augmented Generation) 管道，通過嵌入生成、向量搜索和增強回答生成來解決 AI 幻覺問題。

## 先決條件
- Google Cloud 帳戶與實驗室憑證
- BigQuery 基本知識
- SQL 查詢基礎
- Vertex AI API 訪問權限

## 預估時間
45-60 分鐘

---

## 任務 1：創建來源連接和授予 IAM 權限

### 步驟詳情

1. **開啟 BigQuery 控制台**
   - 在 Google Cloud 控制台中，點擊 Navigation menu > BigQuery
   - 點擊 DONE 關閉歡迎對話框

2. **創建外部數據源連接**
   - 在 Explorer 面板中，點擊 + Add > Connections to external data sources
   - 在 Connection type 下拉選單中選擇 "Vertex AI remote models, remote functions BigLake and Spanner (Cloud Resource)"
   - 在 Connection ID 字段中輸入 `embedding_conn`
   - 點擊 Create connection
   - 點擊 Go to connection 並複製 Service account ID

3. **授予 IAM 權限**
   - 在控制台中，前往 Navigation menu > IAM & Admin > IAM
   - 點擊 Grant access
   - 在 New principals 字段中貼上剛剛複製的服務帳戶 ID
   - 在 Assign roles 中選擇：
     - BigQuery Data Owner
     - Vertex AI User
   - 點擊 Save

4. **啟用 Vertex AI API**
   - 前往 Navigation menu > APIs & Services > + Enable APIs and services
   - 搜索 "Vertex AI API" 並點擊 Enable

### 驗證步驟
- 確認連接 `embedding_conn` 出現在 BigQuery Explorer 的 External connections 下
- 確認服務帳戶具有 BigQuery Data Owner 和 Vertex AI User 角色
- 確認 Vertex AI API 已啟用

---

## 任務 2：生成嵌入

### 步驟詳情

1. **創建數據集**
   - 在 BigQuery Explorer 中，點擊項目名稱旁的 View actions > Create dataset
   - Dataset ID: `CustomerReview`
   - Location type: Multi-region
   - Multi-region: US
   - 點擊 Create dataset

2. **創建嵌入模型連接**
   - 點擊 + Create SQL query
   - 運行以下 SQL 查詢：
   ```sql
   CREATE OR REPLACE MODEL `CustomerReview.Embeddings`
   REMOTE WITH CONNECTION `us.embedding_conn`
   OPTIONS (ENDPOINT = 'textembedding-gecko@003');
   ```

3. **加載客戶評論數據**
   - 點擊 + Create SQL query
   - 運行以下 SQL 查詢：
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

4. **生成嵌入向量**
   - 點擊 + Create SQL query
   - 運行以下 SQL 查詢：
   ```sql
   CREATE OR REPLACE TABLE `CustomerReview.customer_reviews_embedded` AS
   SELECT *
   FROM ML.GENERATE_EMBEDDING(
       MODEL `CustomerReview.Embeddings`,
       (SELECT review_text AS content FROM `CustomerReview.customer_reviews`)
   );
   ```

### 驗證步驟
- 確認 `CustomerReview` 數據集已創建
- 確認 `customer_reviews` 表包含數據
- 確認 `customer_reviews_embedded` 表已創建並包含嵌入向量

---

## 任務 3：搜索向量空間並檢索相似項目

### 步驟詳情

1. **創建向量索引**
   - 點擊 + Create SQL query
   - 運行以下 SQL 查詢：
   ```sql
   CREATE OR REPLACE VECTOR INDEX `CustomerReview.reviews_index`
   ON `CustomerReview.customer_reviews_embedded`(ml_generate_embedding_result)
   OPTIONS (distance_type = 'COSINE', index_type = 'IVF');
   ```

2. **執行向量搜索**
   - 點擊 + Create SQL query
   - 運行以下 SQL 查詢：
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

### 驗證步驟
- 確認 `reviews_index` 向量索引已創建
- 確認 `vector_search_result` 表包含搜索結果
- 結果應顯示與 "service" 相關的評論內容

---

## 任務 4：生成改進的回答

### 步驟詳情

1. **創建 Gemini 模型連接**
   - 點擊 + Create SQL query
   - 運行以下 SQL 查詢：
   ```sql
   CREATE OR REPLACE MODEL `CustomerReview.Gemini`
   REMOTE WITH CONNECTION `us.embedding_conn`
   OPTIONS (ENDPOINT = 'gemini-1.5-flash-002');
   ```

2. **使用檢索結果生成增強回答**
   - 點擊 + Create SQL query
   - 運行以下 SQL 查詢：
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

### 驗證步驟
- 確認 Gemini 模型已創建
- 確認查詢返回基於檢索內容的總結回答
- 回答應反映客戶對服務的真實反饋

---

## 執行指南

### 常見問題與解決方案

**連接創建失敗**
- 確保 Vertex AI API 已啟用
- 檢查連接 ID 是否正確
- 確認您有足夠的權限創建連接

**模型創建失敗**
- 驗證連接名稱正確 (`us.embedding_conn`)
- 確保端點名稱正確
- 檢查 Vertex AI User 角色是否正確分配

**嵌入生成失敗**
- 確認數據已正確加載到表中
- 檢查嵌入模型名稱是否正確
- 確保內容字段映射正確

**向量搜索失敗**
- 確認向量索引已創建並可用
- 檢查距離類型和索引類型參數
- 驗證嵌入維度匹配

**Gemini 生成失敗**
- 確保 Gemini 模型端點正確
- 檢查提示格式
- 驗證參數設置合理

### 提示與技巧

- **處理時間**: 嵌入生成和向量搜索可能需要幾分鐘，請耐心等待
- **資源檢查**: 定期檢查 BigQuery 查詢歷史記錄以監控進度
- **錯誤排查**: 如果遇到權限錯誤，請重新檢查 IAM 角色分配
- **性能優化**: 對於大型數據集，考慮調整 `fraction_lists_to_search` 參數

### 清理步驟

完成實驗室後，執行以下清理步驟：

```sql
-- 刪除數據集和所有內容
DROP SCHEMA `CustomerReview` CASCADE;

-- 刪除連接（在 BigQuery 控制台中手動刪除）
-- 移除 IAM 權限（在 IAM 控制台中手動移除）
```

## 額外資源
- [BigQuery ML 嵌入生成文檔](https://cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-generate-embedding)
- [BigQuery 向量搜索文檔](https://cloud.google.com/bigquery/docs/vector-search)
- [Vertex AI Gemini API 文檔](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini)

## 技術筆記
- RAG 管道通過檢索相關信息來增強生成式 AI 的準確性
- 餘弦距離適用於大多數文本嵌入相似性比較
- IVF 索引類型提供了良好的搜索性能和準確性平衡
- Gemini 1.5 Flash 模型提供了快速的文本生成能力
- 適當的溫度設置 (0.4) 有助於平衡創造性和一致性
