# GSP1289 - 使用 BigQuery 創建 RAG 應用程序

## Lab 概述
擔心 AI 幻覺嗎？雖然 AI 可以是一個有價值的資源，但它有時會生成不準確、過時或過於籠統的回應，這種現象稱為"幻覺"。此實驗教您如何實現檢索增強生成 (RAG) 管道來解決這個問題。RAG 通過從特定數據集中檢索上下文相關信息來改進大型語言模型 (LLM) 如 Gemini 的輸出。

假設您正在幫助 Coffee-on-Wheels（一家開創性的移動咖啡供應商）分析客戶對其服務的反饋。如果沒有訪問最新數據，Gemini 的回應可能不準確。為了解決這個問題，您決定構建一個包含三個步驟的 RAG 管道：

1. **生成嵌入**：將客戶反饋文本轉換為向量嵌入，這是捕獲語義含義的數據數值表示。

2. **搜索向量空間**：創建這些向量的索引，搜索相似項目並檢索它們。

3. **生成改進的答案**：使用檢索到的信息增強 Gemini 以產生更準確和相關的回應。

BigQuery 允許無縫連接到 Vertex AI 上的遠程生成式 AI 模型。它還通過 SQL 查詢或 Python 筆記本直接提供各種嵌入、向量搜索和文本生成函數。

要深入了解，請查看 Google Cloud Skills Boost 上的課程 **Create Embeddings, Vector Search, and RAG with BigQuery**。

## 先決條件
要完成此實驗，您應該熟悉 BigQuery 和 SQL 編碼。

## 學習目標
完成此實驗後，您將能夠：
- 創建源連接和授予 IAM 權限。
- 生成嵌入並將文本數據轉換為向量嵌入。
- 搜索向量空間並檢索相似項目。
- 通過使用搜索結果增強 Gemini 來生成改進的答案。

## 預估時間
45 分鐘

## 實驗步驟

### 任務 1：創建源連接和授予 IAM 權限

#### 創建源連接
要使用 BigQuery 中的 Vertex AI 遠程生成式 AI 模型（如 Gemini 和嵌入模型），創建新的外部源連接。

1. 在 Google Cloud 控制台中，在 **Navigation menu** 上點擊 **BigQuery**。

2. 在 **Explorer** 中，點擊 **+ Add**，然後選擇 **Connections to external data sources**。

   **注意：**或者，如果您沒有看到 **+ Add** 後跟 **Connections to external data sources** 的選項，您可以點擊 **+ Add data**，然後使用數據源搜索欄搜索 **Vertex AI**。點擊 **Vertex AI > BigQuery Federation** 的結果。

3. 在 **Connection type** 下拉選單中，選擇 **Vertex AI remote models, remote functions BigLake and Spanner (Cloud Resource)**。

4. 在 **Connection ID** 字段中，輸入 `embedding_conn`。

5. 點擊 **Create connection**。

6. 連接創建後，在彈出確認中點擊 **Go to connection** 以導航到連接並複製 **Service account id** 值。您稍後需要它來為此帳戶分配權限。

#### 授予 IAM 權限
要使用 BigQuery 數據和 Vertex AI 資源，請授予服務帳戶必要的 IAM 權限。

1. 接下來，您需要通過 IAM 授予權限。執行以下步驟：

   - 在 Google Cloud 控制台中，在 **Navigation menu** 上導航到 **IAM & Admin > IAM**。

   - 點擊 **Grant access**。

   - 在 **Add principals** 部分：

     - 在 **New principals** 文本字段中，貼上您之前複製的 **Service account id** 值。

     - 在 **Assign Role** 下，選擇以下角色（如果需要，請搜索它們）：

       - **BigQuery Data Owner**
       - **Vertex AI User**

2. 點擊 **Save** 以應用更改。

3. 從 **Navigation menu** 導航到 **APIs and Services**，點擊 **+ Enable APIs and services**，搜索 `Vertex AI API`，點擊 **Enable** 按鈕。

### 任務 2：生成嵌入

1. 在 Google Cloud 控制台中，在 **Navigation menu** 上導航到 **BigQuery**。

2. 在 **Explorer** 中，在項目旁導航到三個點，點擊 **Create dataset**。對於 **Dataset ID**，輸入 `CustomerReview`。保持其他選項為默認值，然後點擊 **Create dataset**。

3. 要連接到嵌入模型，請在查詢編輯器中運行以下 SQL 查詢：

```sql
CREATE OR REPLACE MODEL `CustomerReview.Embeddings`
REMOTE WITH CONNECTION `us.embedding_conn`
OPTIONS (ENDPOINT = 'Gemini Embedding model ID | disablehighlight');
```

4. 要從 CSV 文件上傳數據集，請運行以下 SQL 查詢：

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

5. （可選）要檢查表中的上傳數據，點擊 **Go to table**。查找表的 **schema** 和 **preview** 數據。

6. 要從最近的客戶反饋生成嵌入並將它們存儲在表中，請在查詢編輯器中運行以下 SQL 查詢：

```sql
CREATE OR REPLACE TABLE `CustomerReview.customer_reviews_embedded` AS
SELECT *
FROM ML.GENERATE_EMBEDDING(
    MODEL `CustomerReview.Embeddings`,
    (SELECT review_text AS content FROM `CustomerReview.customer_reviews`)
);
```

7. （可選）要檢查嵌入結果，點擊 **Go to table**。查找表的 **schema** 和 **preview** 數據。注意嵌入結果是浮點數，可能不會立即可解釋。

### 任務 3：搜索向量空間並檢索相似項目

1. 要創建向量搜索空間的索引，請運行以下 SQL 查詢：

   **注意：**對於少於 5,000 行的數據集，如此實驗，創建索引是不必要的。此步驟演示了為較大數據集創建向量空間索引時所需的代碼。

```sql
CREATE OR REPLACE VECTOR INDEX `CustomerReview.reviews_index`
ON `CustomerReview.customer_reviews_embedded`(ml_generate_embedding_result)
OPTIONS (distance_type = 'COSINE', index_type = 'IVF');
```

2. 要搜索向量空間並檢索相似項目，請運行以下 SQL 查詢：

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

3. （可選）要檢查查詢結果，點擊 **Go to table**。查找表的 **schema** 和 **preview** 數據。

### 任務 4：生成改進的答案

1. 要連接到 Gemini 模型，請運行以下 SQL 查詢：

```sql
CREATE OR REPLACE MODEL `CustomerReview.Gemini`
REMOTE WITH CONNECTION `us.embedding_conn`
OPTIONS (ENDPOINT = 'Gemini Model ID | disablehighlight');
```

2. 要通過從向量搜索檢索到的相關和最近數據來增強 Gemini 的回應，請運行以下查詢：

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

3. 在查詢編輯器下方的 **Query results** 部分檢查 Gemini 生成的結果。

#### 思考問題：
1. 您如何確定 Gemini 在使用 RAG 時是否生成比沒有 RAG 更好的答案？嘗試用代碼測試它。
2. 如何改進代碼？例如，不是將向量搜索結果保存到表（任務 3），而是可以將該過程直接嵌入到答案生成（任務 4）中以進行實時檢索？

在剩餘的實驗時間內探索這些問題。祝好運！

## 驗證
- 成功創建源連接並授予 IAM 權限
- 數據集和表已創建並填充了嵌入數據
- 向量搜索已執行並返回了相關結果
- Gemini 已使用 RAG 生成改進的答案

## 故障排除
- **連接創建失敗**：確保 Vertex AI API 已啟用並且您有適當的權限
- **模型創建失敗**：確保連接配置正確，並且端點名稱正確
- **嵌入生成失敗**：檢查輸入數據格式和模型參數
- **向量搜索失敗**：確保嵌入已正確生成，並且搜索參數合適
- **RAG 回應不相關**：檢查向量搜索是否返回了相關的上下文

## 清理
此實驗不需要特定的清理步驟，因為它主要涉及查詢數據。但是，如果需要清理：

1. 刪除創建的數據集：`DROP SCHEMA CustomerReview CASCADE`
2. 刪除連接：從 BigQuery 控制台中刪除 `embedding_conn` 連接
3. 移除 IAM 權限：從服務帳戶中移除授予的角色

## 額外資源
- [Create Embeddings, Vector Search, and RAG with BigQuery](https://www.cloudskillsboost.google/course_templates/1232)
- [BigQuery vector search introduction](https://cloud.google.com/bigquery/docs/vector-search-intro)
- [BigQuery ML embedding generation](https://cloud.google.com/bigquery/docs/generate-embedding)

## 筆記
- 此實驗演示了 BigQuery 中 RAG 管道的強大功能
- 學習將文本數據轉換為向量嵌入
- 理解向量相似性搜索的概念
- 掌握使用檢索上下文增強生成式 AI 的技術
- 實踐將 RAG 應用於真實商業場景（如客戶反饋分析）
