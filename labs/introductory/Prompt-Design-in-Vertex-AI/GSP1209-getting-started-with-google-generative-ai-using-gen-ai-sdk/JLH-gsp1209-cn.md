# GSP1209 - 使用 Gen AI SDK 開始 Google 生成式 AI 之旅

## 實驗室概述

Google Gen AI SDK 提供統一的介面來存取 Google 的生成式 AI API 服務。此 SDK 簡化了將生成式 AI 功能整合到應用程式和服務中的過程，使開發人員能夠運用 Google 進階 AI 模型進行各種任務。在這個實驗室中，您將探索 Google Gen AI SDK，學習連接 AI 服務、傳送多樣化的提示，並微調 Gemini 的回應。您還將獲得使用更進階技術的實作經驗，為您自己的專案運用生成式 AI 的力量做好準備。

## 先決條件

開始這個實驗室之前，您應該熟悉：

- Python 程式設計基礎
- 一般 API 概念
- 在 Vertex AI Workbench 上執行 Python 程式碼的 Jupyter notebook

## 學習目標

在此實驗室中，您將學習如何使用 Google Gen AI SDK for Python 與 Google 的生成式 AI 服務和模型（包括 Gemini）進行互動。您將涵蓋以下內容：

- 安裝 Gen AI SDK
- 連接 API 服務
- 傳送文字和多模態提示
- 設定系統指示
- 設定模型參數和安全篩選器
- 管理模型互動（多輪對話、內容串流、非同步請求）
- 使用進階功能（token 計數、內容快取、函數呼叫、批次預測、文字嵌入）

## 預估時間

90 分鐘

## 實驗室步驟

### 任務 1. 在 Vertex AI Workbench 中開啟 notebook

1. 在 Google Cloud 主控台中，在 **導覽選單** () 中，按一下 **Vertex AI > Workbench**。

    [導覽選單圖示](https://cdn.qwiklabs.com/tkgw1TDgj4Q%2BYKQUW4jUFd0O5OEKlUMBRYbhlCrF0WY%3D)

2. 找到 `Workbench instance name` 執行個體並按一下 **Open JupyterLab** 按鈕。

JupyterLab 介面會在新的瀏覽器分頁中開啟。

**注意：** 如果您在 JupyterLab 中沒有看到 notebooks，請遵循以下額外步驟來重設執行個體：

1. 關閉 JupyterLab 的瀏覽器分頁，並返回 Workbench 首頁。
2. 選取執行個體名稱旁邊的核取方塊，然後按一下 **Reset**。
3. 等待 **Open JupyterLab** 按鈕再次啟用後，等待一分鐘，然後按一下 **Open JupyterLab**。

### 任務 2. 設定 notebook

1. 開啟 `notebook name` 檔案。
2. 在 **Select Kernel** 對話方塊中，從可用核心列表中選擇 **Python 3**。
3. 執行 notebook 的 **Getting Started** 區段。專案 ID 和位置已為您預先設定。

**注意：** 如果您遇到任何 notebook 儲存格執行時的 429 回應，請等待一分鐘後重新執行儲存格以繼續。

按一下 **Check my progress** 來驗證目標。

**匯入程式庫並設定 notebook**

### 任務 3. 與模型互動

有關 Vertex AI 上所有 AI 模型和 API 的更多資訊，請參考 [Google Models](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models#gemini-models) 和 [Model Garden](https://cloud.google.com/vertex-ai/generative-ai/docs/model-garden/explore-models)。

#### 選擇模型

- 執行 notebook 的 **Choose a model** 區段。

#### 傳送文字提示

使用 `generate_content` 方法來為您的提示生成回應。您可以將文字傳遞給 `generate_content`，並使用 `.text` 屬性來取得回應的文字內容。

- 執行 notebook 的 **Send text prompts** 區段。

#### 傳送多模態提示

您可以在提示請求中包含文字、PDF 文件、影像、音訊和影片，並取得文字或程式碼回應。

您也可以將檔案 URL 直接傳遞到模型中的 `Part.from_uri`。

- 執行 notebook 的 **Send multimodal prompts** 區段。

#### 設定系統指示

[系統指示](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/system-instruction-introduction) 允許您控制模型行為。設定系統指示來為模型提供額外的背景，以更好地理解任務、提供更客製化的回應，並在使用者互動期間遵守準則。

- 執行 notebook 的 **Set system instruction** 區段。

按一下 **Check my progress** 來驗證目標。

**與模型互動**

### 任務 4. 設定和控制模型

#### 設定模型參數

您可以在傳送到模型的每個呼叫中包含參數值，以控制模型生成回應的方式。要了解更多資訊，請參考[試驗參數值](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/adjust-parameter-values)。

- 執行 notebook 的 **Configure model parameters** 區段。

#### 設定安全篩選器

Gemini API 提供安全篩選器，您可以調整多個篩選器類別，以允許或限制某些類型的內容。您可以使用這些篩選器來調整適合您使用案例的內容。請參考[設定安全篩選器](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/configure-safety-filters)頁面以取得詳細資訊。

當您向模型發出請求時，內容會被分析並指派安全評分。您可以透過列印模型回應來檢查生成內容的安全評分，如以下範例所示：

- 執行 notebook 的 **Configure safety filters** 區段。

#### 開始多輪對話

Gemini API 讓您能夠進行多輪的自由形式對話。

- 執行 notebook 的 **Start a multi-turn chat** 區段。

#### 控制生成的輸出

Gemini API 中的[受控生成](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/control-generated-output)功能允許您將模型輸出限制為結構化格式。您可以提供 Pydantic Models 或 JSON 字串作為結構描述。

您也可以在 Python 字典中定義回應結構描述。您只能使用以下欄位。所有其他欄位都會被忽略。

- `enum`
- `items`
- `maxItems`
- `nullable`
- `properties`
- `required`

在此範例中，您將指示模型分析產品評論資料、擷取關鍵實體、執行情緒分類（多重選擇）、提供額外說明，並以 JSON 格式輸出結果。

- 執行 notebook 的 **Control generated output** 區段。

按一下 **Check my progress** 來驗證目標。

**設定和控制模型**

### 任務 5. 管理模型互動

#### 生成內容串流

預設情況下，模型會在完成整個生成過程後返回回應。您也可以使用 `generate_content_stream` 方法來串流回應，因為它正在生成。模型會在生成時返回回應的區塊。

- 執行 notebook 的 **Generate content stream** 區段。

#### 傳送非同步請求

您可以使用 `client.aio` 模組來傳送非同步請求。此模組公開了 `client` 上可用的所有類似非同步方法。

例如，`client.aio.models.generate_content` 是 `client.models.generate_content` 的非同步版本。

- 執行 notebook 的 **Send asynchronous requests** 區段。

#### 計算 tokens 和計算 tokens

您可以使用 `count_tokens` 方法在傳送請求到 Gemini API 之前計算輸入 tokens 的數量。請參考[List and count tokens](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/list-token)頁面以取得詳細資訊。

##### **計算 tokens**

- 執行 notebook 的 **Count tokens** 區段。

##### **計算 tokens**

- 執行 notebook 的 **Compute tokens** 區段。

按一下 **Check my progress** 來驗證目標。

**管理模型互動**

### 任務 6. 進階功能

#### 函數呼叫

[函數呼叫](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/function-calling)讓您提供一組工具供其用來回應用戶的提示。您在程式碼中建立函數描述，然後在請求中將該描述傳遞給語言模型。模型的回應包括匹配描述的函數名稱和呼叫它的參數。

有關函數呼叫的更多範例，請參考[這個實驗室](https://goo.gle/4jeQxBO)。

- 執行 notebook 的 **Function calling** 區段。

按一下 **Check my progress** 來驗證目標。

**函數呼叫**

#### 使用內容快取

[內容快取](https://cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview)讓您將經常使用的輸入 tokens 儲存在專用快取中，並在後續請求中參考它們。這消除了重複將相同 token 集合傳遞給模型的需要。

##### **建立快取**

- 執行 notebook 的 **Create a cache** 區段。

##### **使用快取**

- 執行 notebook 的 **Use a cache** 區段。

##### **刪除快取**

- 執行 notebook 的 **Delete a cache** 區段。

按一下 **Check my progress** 來驗證目標。

**使用內容快取**

#### 批次預測

與取得線上（同步）回應不同，其中您一次只能傳送一個輸入請求，[Vertex AI 上 Gemini API 的批次預測](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/batch-prediction-gemini)允許您以單一批次請求將大量請求傳送到 Gemini。然後，模型會非同步將批次預測結果填入您的儲存輸出位置（[Cloud Storage](https://cloud.google.com/storage/docs/introduction) 或 [BigQuery](https://cloud.google.com/bigquery/docs/storage_overview)）。

批次預測通常比線上預測更有效率且更具成本效益，當處理不具延遲敏感性的大量輸入時。

##### **準備批次輸入**

批次請求的輸入指定要傳送到模型進行預測的項目。

Gemini 的批次請求接受 BigQuery 儲存來源和 Cloud Storage 來源。您可以在[批次文字生成](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/batch-prediction-gemini#prepare_your_inputs)頁面中了解更多關於批次輸入格式的資訊。

這個實驗室使用 Cloud Storage 作為範例。Cloud Storage 輸入的要求是：

- 檔案格式：[JSON Lines (JSONL)](https://jsonlines.org/)
- 位於 `us-central1`
- 服務帳戶具有適當的讀取權限

每個您傳送到模型的請求可以包含參數，以控制模型生成回應的方式。在[試驗參數值](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/adjust-parameter-values)頁面中了解更多關於 Gemini 參數的資訊。

這是輸入 JSONL 檔案 `batch_requests_for_multimodal_input_2.jsonl` 中的一個範例請求：

`{"request":{"contents": [{"role": "user", "parts": [{"text": "List objects in this image."}, {"file_data": {"file_uri": "gs://cloud-samples-data/generative-ai/image/office-desk.jpeg", "mime_type": "image/jpeg"}}]}],"generationConfig":{"temperature": 0.4}}}`

- 執行 notebook 的 **Prepare batch inputs** 區段。

##### **準備批次輸出位置**

批次預測任務完成時，預測輸出會儲存在請求中指定的位置。

- 位置是 Cloud Storage 或 BigQuery URI 前綴的形式，例如：`gs://path/to/output/data` 或 `bq://projectId.bqDatasetId`。
- 如果未指定，`gs://STAGING_BUCKET/gen-ai-batch-prediction` 用於 Cloud Storage 來源，`bq://PROJECT_ID.gen_ai_batch_prediction.predictions_TIMESTAMP` 用於 BigQuery 來源。

這個實驗室使用 Cloud Storage 儲存貯體作為輸出位置的範例。

您可以在 `BUCKET_URI` 中指定 Cloud Storage 儲存貯體的 URI，或者，如果未指定，將為您建立一個 `gs://PROJECT_ID-TIMESTAMP` 形式的 Cloud Storage 儲存貯體。

- 執行 notebook 的 **Prepare batch output location** 區段。

##### **傳送批次預測請求**

要發出批次預測請求，您指定來源模型 ID、輸入來源和輸出位置，其中 Vertex AI 會儲存批次預測結果。

如需更多資訊，請參考[批次預測 API](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/batch-prediction-api)頁面。您也可以在 https://console.cloud.google.com/vertex-ai/batch-predictions 檢查主控台中的狀態

- 執行 notebook 的 **Send a batch prediction request** 區段。

**注意：** 您的批次預測可能需要最多 10 分鐘才能完成。

##### **擷取批次預測結果**

批次預測任務完成時，預測輸出會儲存在請求中指定的位置。它也可在 `batch_job.dest.bigquery_uri` 或 `batch_job.dest.gcs_uri` 中取得。

範例輸出：

`{"status": "", "processed_time": "2024-11-13T14:04:28.376+00:00", "request": {"contents": [{"parts": [{"file_data": null, "text": "List objects in this image."}, {"file_data": {"file_uri": "gs://cloud-samples-data/generative-ai/image/gardening-tools.jpeg", "mime_type": "image/jpeg"}, "text": null}], "role": "user"}], "generationConfig": {"temperature": 0.4}}, "response": {"candidates": [{"avgLogprobs": -0.10394711927934126, "content": {"parts": [{"text": "Here's a list of the objects in the image:\n\n* **Watering can:** A green plastic watering can with a white rose head.\n* **Plant:** A small plant (possibly oregano) in a terracotta pot.\n* **Terracotta pots:** Two terracotta pots, one containing the plant and another empty, stacked on top of each other.\n* **Gardening gloves:** A pair of striped gardening gloves.\n* **Gardening tools:** A small trowel and a hand cultivator (hoe).  Both are green with black handles."}], "role": "model"}, "finishReason": "STOP"}], "modelVersion": "gemini-2.5-flash", "usageMetadata": {"candidatesTokenCount": 110, "promptTokenCount": 264, "totalTokenCount": 374}}}`

- 執行 notebook 的 **Retrieve batch prediction results** 區段。

按一下 **Check my progress** 來驗證目標。

**擷取批次預測結果**

#### 取得文字嵌入

您可以使用 `embed_content` 方法取得文字片段的文字嵌入。所有模型預設產生 768 維度的輸出。但是，有些模型讓使用者可以選擇 1 到 768 之間的輸出維度。請參考 [Vertex AI 文字嵌入 API](https://cloud.google.com/vertex-ai/generative-ai/docs/embeddings/get-text-embeddings) 以取得詳細資訊。

- 執行 notebook 的 **Get text embeddings** 區段。

按一下 **Check my progress** 來驗證目標。

**取得文字嵌入**

## 驗證

成功完成此實驗室的驗證方法：

1. 確認您已完成所有 notebook 區段的執行
2. 驗證模型回應正確生成
3. 檢查所有進階功能（函數呼叫、內容快取、批次預測等）都能正常運作
4. 確認資源已正確清理

## 故障排除

常見問題和解決方案：

- **429 回應錯誤**：等待一分鐘後重新執行儲存格。API 有速率限制。
- **權限錯誤**：確保您的服務帳戶具有必要的 Vertex AI 和 Cloud Storage 權限。
- **模組匯入錯誤**：確保使用 Python 3 核心並已安裝所有必要的程式庫。
- **批次預測逾時**：批次預測可能需要最多 10 分鐘才能完成，請耐心等待。

## 清理

為避免產生額外費用，請清理在此實驗室中建立的資源：

1. 刪除任何建立的 Cloud Storage 儲存貯體
2. 刪除內容快取（如果已建立）
3. 停止任何執行中的 Vertex AI Workbench 執行個體（如果不是預設執行個體）

## 額外資源

- [Gemini 概述](https://deepmind.google/technologies/gemini/)
- [Vertex AI 上的生成式 AI 文件](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [YouTube 上的生成式 AI](https://www.youtube.com/@googlecloudtech/)
- 探索 Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) 以取得生成式 AI 的精選、可搜尋 notebook 圖書館。
- 探索 [Google Cloud Generative AI repository](https://github.com/GoogleCloudPlatform/generative-ai) 中的其他 notebooks 和範例。

## 筆記

此實驗室提供了使用 Google Gen AI SDK 的全面介紹，涵蓋從基本文字提示到進階功能的各種主題。特別注意安全篩選器和模型參數的設定，這些對於生產環境中的應用至關重要。

記住，這個實驗室依賴於 Vertex AI Workbench 環境中的 notebook，因此請確保您有適當的 GCP 專案設定和權限。
