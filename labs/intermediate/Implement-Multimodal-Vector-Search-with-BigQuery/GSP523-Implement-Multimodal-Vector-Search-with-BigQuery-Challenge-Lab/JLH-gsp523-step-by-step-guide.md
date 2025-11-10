# GSP523 - Implement Multimodal Vector Search with BigQuery: Challenge Lab - 逐步操作指南

## 實驗室概述

此挑戰實驗室將測試您使用 BigQuery 實現多模態向量搜索的能力。您將扮演 Cymbal 在線零售商店的數據科學家角色，需要構建一個管道來持續搜索市場上的相似產品，以為營銷比較研究提供信息。

您面臨的挑戰包括：
- 如何處理多模態數據（包括 Cloud Storage 中的文本、圖像和視頻）
- 如何執行語義相似性搜索而不是關鍵字搜索
- 如何使用 BigQuery 來實現這些功能

## 先決條件

- 熟悉 BigQuery 和 Cloud Storage
- 已完成 Gemini in BigQuery 學習路徑中的課程：
  - Boost Productivity with Gemini in BigQuery（入門級）
  - Work with Gemini Models in BigQuery（中級）
  - Create Embeddings, Vector Search, and RAG with BigQuery（高級）

## 預估時間

60 分鐘

## 任務列表

### 任務 1：創建源連接和授予 IAM 權限

#### 創建外部源連接
您需要在 BigQuery 中創建一個新的外部源連接，以便從 Vertex AI 使用多模態嵌入模型。

1. 在 Google Cloud 控制台中，點擊 **Navigation menu** > **BigQuery**
2. 在 **Explorer** 中，點擊 **+ Add** > **Connections to external data sources**
   - 或者點擊 **+ Add data**，然後搜索 **Vertex AI**，點擊 **BigQuery Federation** 結果
3. 在 **Connection type** 下拉選單中選擇 **Vertex AI remote models, remote functions BigLake and Spanner (Cloud Resource)**
4. 在 **Connection ID** 字段中輸入 `vector_conn`
5. 對於 **Location type**，選擇 **Region**，然後從下拉選單選擇 **`Region`**（lab 環境中指定的區域）
6. 點擊 **Create connection**
7. 創建連接後，點擊 **Go to connection** 並複製 **Service account id** 值

#### 授予 IAM 權限
您需要授予服務帳戶訪問 Vertex AI 資源和 BigQuery 數據的適當 IAM 權限。

1. 在控制台中，導航到 **IAM & Admin** > **IAM**
2. 點擊 **Grant access**
3. 在 **New principals** 字段中貼上您複製的服務帳戶 ID
4. 為以下角色點擊 **Add another role**：
   - **BigQuery Data Owner**
   - **Storage Object Viewer**
   - **Vertex AI User**
5. 點擊 **Save**

#### 驗證步驟
- 在 BigQuery 中檢查 **External connections** 部分是否顯示 `vector_conn` 連接
- 在 IAM 中驗證服務帳戶是否具有上述三個角色

### 任務 2：創建對象表

#### 創建對象表來存儲圖像
您需要在預創建的 BigQuery 數據集中創建一個對象表來查詢存儲在 Cloud Storage 上的圖像等非結構化數據。

1. 在 BigQuery 中，打開 SQL 編輯器
2. 運行以下 SQL 代碼（替換括號中的佔位符）：

```sql
CREATE OR REPLACE EXTERNAL TABLE `[PROJECT_ID].gcc_bqml_dataset.gcc_image_object_table`
WITH CONNECTION `[PROJECT_ID].[REGION].vector_conn`
OPTIONS (
  object_metadata = 'SIMPLE',
  uris = ['gs://[PROJECT_ID]/*']
);
```

**提示：**
- `[PROJECT_ID]` 是您的 GCP 項目 ID
- `[REGION]` 是 lab 中指定的區域（通常是 `us-central1` 或類似）
- 數據集名稱是預定義的 `gcc_bqml_dataset`
- 表名稱必須是 `gcc_image_object_table`

#### 驗證步驟
- 在 BigQuery Explorer 中，展開 `gcc_bqml_dataset` 數據集
- 檢查 `gcc_image_object_table` 表是否存在
- 運行 `SELECT * FROM \`[PROJECT_ID].gcc_bqml_dataset.gcc_image_object_table\` LIMIT 5` 來驗證數據

### 任務 3：生成嵌入

#### 連接到多模態嵌入模型
您需要創建一個新的 BigQuery 模型來連接到遠程多模態嵌入模型。

1. 在 BigQuery SQL 編輯器中運行以下 SQL 代碼：

```sql
CREATE OR REPLACE MODEL `[PROJECT_ID].gcc_bqml_dataset.gcc_embedding`
REMOTE WITH CONNECTION `[PROJECT_ID].[REGION].vector_conn`
OPTIONS (endpoint = 'multimodalembedding@001');
```

**提示：**
- 模型名稱必須是 `gcc_embedding`
- 端點名稱是 `multimodalembedding@001`（這是 Gemini 多模態嵌入模型）

#### 生成嵌入
您需要從圖像生成嵌入並將它們保存到表中。

1. 在 SQL 編輯器中運行以下 SQL 代碼：

```sql
CREATE OR REPLACE TABLE `[PROJECT_ID].gcc_bqml_dataset.gcc_retail_store_embeddings`
AS SELECT *, REGEXP_EXTRACT(uri, r'[^/]+$') AS product_name
FROM ML.GENERATE_EMBEDDING(
  MODEL `[PROJECT_ID].gcc_bqml_dataset.gcc_embedding`,
  TABLE `[PROJECT_ID].gcc_bqml_dataset.gcc_image_object_table`
);
```

**提示：**
- 表名稱必須是 `gcc_retail_store_embeddings`
- `REGEXP_EXTRACT(uri, r'[^/]+$')` 從 URI 中提取文件名作為產品名稱

#### 可選驗證步驟
運行以下查詢來檢查嵌入結果：
```sql
SELECT * FROM `[PROJECT_ID].gcc_bqml_dataset.gcc_retail_store_embeddings` LIMIT 10;
```

嵌入結果是浮點數，可能不容易解釋，但您應該看到 `uri`、`product_name` 和 `ml_generate_embedding_result` 列。

#### 驗證步驟
- 檢查 `gcc_retail_store_embeddings` 表是否已創建
- 驗證表包含來自對象表的圖像 URI
- 確保 `ml_generate_embedding_result` 列包含向量數據

### 任務 4：運行向量搜索

#### 執行向量搜索
您需要執行向量搜索來查找與搜索詞最相似的圖像，並將結果保存到表中。

1. 在 SQL 編輯器中運行以下 SQL 代碼：

```sql
CREATE OR REPLACE TABLE `[PROJECT_ID].gcc_bqml_dataset.gcc_vector_search_table` AS
SELECT base.uri,
       base.product_name,
       base.content_type,
       distance
FROM VECTOR_SEARCH(
  TABLE `[PROJECT_ID].gcc_bqml_dataset.gcc_retail_store_embeddings`,
  'ml_generate_embedding_result',
  (
    SELECT ml_generate_embedding_result AS embedding_col
    FROM ML.GENERATE_EMBEDDING(
      MODEL `[PROJECT_ID].gcc_bqml_dataset.gcc_embedding`,
      (SELECT 'Men Sweaters' AS content),
      STRUCT(TRUE AS flatten_json_output)
    )
  ),
  top_k => 2,
  distance_type => 'COSINE'
);
```

**提示：**
- 表名稱必須是 `gcc_vector_search_table`
- 搜索詞是 `'Men Sweaters'`
- `top_k => 2` 返回前 2 個最相似的结果
- 使用餘弦距離進行相似性計算

#### 可選驗證步驟
運行以下查詢來檢查搜索結果：
```sql
SELECT * FROM `[PROJECT_ID].gcc_bqml_dataset.gcc_vector_search_table`;
```

您應該看到 2 個結果，每個包含 URI、產品名稱、內容類型和距離分數。

#### 驗證步驟
- 檢查 `gcc_vector_search_table` 表是否已創建
- 驗證表包含 2 行結果
- 確保結果按距離排序（最相似的排在前面）
- 檢查結果是否與 "Men Sweaters" 相關

## 執行指南

### 常見問題與解決方案

#### 連接創建失敗
- **問題**：Vertex AI API 未啟用
- **解決方案**：在 APIs & Services 中啟用 Vertex AI API

#### IAM 權限問題
- **問題**：缺少必要的角色
- **解決方案**：仔細檢查所有三個角色都已授予服務帳戶

#### SQL 語法錯誤
- **問題**：佔位符未正確替換
- **解決方案**：
  - 確保 `[PROJECT_ID]` 替換為您的實際項目 ID
  - 確保 `[REGION]` 替換為 lab 中指定的區域

#### 嵌入生成失敗
- **問題**：模型端點名稱錯誤
- **解決方案**：使用正確的端點名稱 `multimodalembedding@001`

#### 向量搜索無結果
- **問題**：搜索參數配置錯誤
- **解決方案**：檢查 `top_k` 值和距離類型

### 提示與技巧

#### 變數替換
- 始終仔細檢查並替換所有括號中的佔位符 `[]`
- 項目 ID 可以在控制台頂部找到
- 區域通常在 lab 說明中指定

#### 調試技巧
- 使用 `SELECT * FROM table_name LIMIT 5` 來檢查表內容
- 檢查 BigQuery 作業歷史記錄以獲取詳細錯誤信息
- 確保所有資源在同一區域中

#### 性能考慮
- 嵌入生成可能需要一些時間，特別是對於大量圖像
- 向量搜索通常很快，但取決於數據集大小

### 清理步驟

此實驗室不需要特定的清理步驟，因為它主要涉及查詢數據。但是，如果需要清理：

1. 刪除創建的表：
   ```sql
   DROP TABLE `[PROJECT_ID].gcc_bqml_dataset.gcc_vector_search_table`;
   DROP TABLE `[PROJECT_ID].gcc_bqml_dataset.gcc_retail_store_embeddings`;
   DROP TABLE `[PROJECT_ID].gcc_bqml_dataset.gcc_image_object_table`;
   ```

2. 刪除模型：
   ```sql
   DROP MODEL `[PROJECT_ID].gcc_bqml_dataset.gcc_embedding`;
   ```

3. 刪除連接（從 BigQuery 控制台）：
   - 移除 `vector_conn` 連接

4. 移除 IAM 權限：
   - 從服務帳戶中移除授予的角色

## 額外資源

- [BigQuery vector search introduction](https://cloud.google.com/bigquery/docs/vector-search-intro)
- [BigQuery ML embedding generation](https://cloud.google.com/bigquery/docs/generate-embedding)
- [Create Embeddings, Vector Search, and RAG with BigQuery](https://www.cloudskillsboost.google/course_templates/1210)
- [Boost Productivity with Gemini in BigQuery](https://www.cloudskillsboost.google/course_templates/1169)
- [Work with Gemini Models in BigQuery](https://www.cloudskillsboost.google/course_templates/1133)

## 技術筆記

### 多模態向量搜索架構

此實驗室演示了完整的多模態向量搜索管道：

1. **數據存儲**：使用 BigQuery 對象表存儲 Cloud Storage 中的圖像元數據
2. **嵌入生成**：使用 Gemini 多模態嵌入模型將圖像轉換為向量表示
3. **向量索引**：向量存儲在 BigQuery 表中，支持高效相似性搜索
4. **語義搜索**：使用向量相似性（餘弦距離）查找相關圖像

### 關鍵概念

- **多模態嵌入**：能夠處理文本、圖像、視頻等多種數據類型的嵌入
- **語義相似性**：基於含義而不是關鍵字的相似性搜索
- **向量數據庫**：使用 BigQuery 作為向量數據庫的替代方案
- **RAG 應用**：向量搜索是檢索增強生成 (RAG) 的關鍵組件

### 擴展應用

此技術可以用於：
- 產品推薦系統
- 視覺搜索應用
- 內容審核管道
- 多模態數據分析

### 性能注意事項

- 嵌入生成是計算密集型的操作
- 向量搜索在 BigQuery 中通常很快
- 對於大型數據集，考慮使用向量索引進行優化
- 餘弦距離適用於大多數相似性搜索用例
