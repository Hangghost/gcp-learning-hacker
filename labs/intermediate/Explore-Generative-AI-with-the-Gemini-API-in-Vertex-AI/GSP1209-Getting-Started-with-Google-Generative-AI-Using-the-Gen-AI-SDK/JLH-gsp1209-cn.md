# GSP1209 - 開始使用 Google Gen AI SDK 進行生成式 AI

## Lab 概述

Google Gen AI SDK 提供了統一的介面來存取 Google 的生成式 AI API 服務。此 SDK 簡化了將生成式 AI 功能整合到應用程式和服務的過程，讓開發人員能夠利用 Google 進階 AI 模型來執行各種任務。在此 lab 中，您將探索 Google Gen AI SDK，學習連接到 AI 服務、發送各種提示，並微調來自 Gemini 的回應。您還將獲得使用更進階技術的實作經驗，為您為自己的專案運用生成式 AI 的力量做好準備。

## 先決條件

開始此 lab 之前，您應該熟悉：

- 基本 Python 程式設計
- 一般 API 概念
- 在 Vertex AI Workbench 上執行 Python 程式碼的 Jupyter notebook

## 目標

在此 lab 中，您將學習如何使用適用於 Python 的 Google Gen AI SDK 與 Google 的生成式 AI 服務和模型（包括 Gemini）進行互動。您將涵蓋以下內容：

- 安裝 Gen AI SDK
- 連接到 API 服務
- 發送文字和多模態提示
- 設定系統指令
- 配置模型參數和安全過濾器
- 管理模型互動（多輪對話、內容串流、非同步請求）
- 使用進階功能（token 計數、內容快取、函數呼叫、批次預測、文字嵌入）

## 預估時間

90 分鐘

## Lab 步驟

### 任務 1. 在 Vertex AI Workbench 中開啟 notebook

1. 在 Google Cloud 主控台中，於**導航選單**（）上，按一下 **Vertex AI > Workbench**。

    [導航選單圖示](https://cdn.qwiklabs.com/tkgw1TDgj4Q%2BYKQUW4jUFd0O5OEKlUMBRYbhlCrF0WY%3D)

2. 找到 `Workbench instance name` 執行個體，然後按一下 **Open JupyterLab** 按鈕。

JupyterLab 介面會在新瀏覽器分頁中開啟您的 Workbench 執行個體。

**注意：**如果您在 JupyterLab 中沒有看到 notebook，請按照以下額外步驟重設執行個體：

1. 關閉 JupyterLab 的瀏覽器分頁，然後返回 Workbench 首頁。
2. 選取執行個體名稱旁的核取方塊，然後按一下**重設**。
3. 待 **Open JupyterLab** 按鈕再次啟用後，請等候一分鐘，然後按一下 **Open JupyterLab**。

### 任務 2. 設定 notebook

1. 開啟 `notebook name` 檔案。
2. 在**選取核心**對話方塊中，從可用核心清單中選擇 **Python 3**。
3. 執行 notebook 的**開始使用**部分。專案 ID 和位置已為您預先設定。

**注意：**如果您從 notebook 儲存格執行時遇到 429 回應，請等候一分鐘再執行儲存格以繼續進行。

按一下**檢查我的進度**以驗證目標。

匯入程式庫並設定 notebook

### 任務 3. 與模型互動

如需進一步瞭解 Vertex AI 上的所有 AI 模型和 API，請參閱 [Google Models](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models#gemini-models) 和 [Model Garden](https://cloud.google.com/vertex-ai/docs/model-garden/explore-models)。

#### 選擇模型

- 執行 notebook 的**選擇模型**部分。

#### 發送文字提示

使用 `generate_content` 方法產生對您的提示的回應。您可以將文字傳遞給 `generate_content`，並使用 `.text` 屬性取得回應的文字內容。

- 執行 notebook 的**發送文字提示**部分。

#### 發送多模態提示

您可以在提示請求中加入文字、PDF 文件、圖片、音訊和影片，並取得文字或程式碼回應。

您也可以直接在請求中使用 `Part.from_uri` 將檔案 URL 傳遞給模型。

- 執行 notebook 的**發送多模態提示**部分。

#### 設定系統指令

[系統指令](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/system-instruction-introduction) 可讓您控制模型行為。設定系統指令為模型提供額外內容，以更好地理解任務、提供更客製化的回應，並在整個使用者互動中遵守準則。

- 執行 notebook 的**設定系統指令**部分。

按一下**檢查我的進度**以驗證目標。

與模型互動

### 任務 4. 配置和控制模型

#### 配置模型參數

您可以在傳送給模型的每個呼叫中加入參數值，以控制模型產生回應的方式。如需進一步瞭解，請參閱[試驗參數值](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/adjust-parameter-values)。

- 執行 notebook 的**配置模型參數**部分。

#### 配置安全過濾器

Gemini API 提供安全過濾器，您可以調整多個過濾器類別，以允許或限制特定類型的內容。您可以使用這些過濾器來調整適合您使用案例的內容。請參閱[配置安全過濾器](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/configure-safety-filters)頁面以取得詳細資訊。

當您向模型發出請求時，系統會分析內容並指派安全評分。您可以透過列印出模型回應來檢查產生內容的安全評分，如以下範例所示：

- 執行 notebook 的**配置安全過濾器**部分。

#### 開始多輪對話

Gemini API 可讓您進行多輪自由形式的對話。

- 執行 notebook 的**開始多輪對話**部分。

#### 控制產生輸出

Gemini API 中的[受控產生](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/control-generated-output)功能可讓您將模型輸出限制為結構化格式。您可以提供 Pydantic Models 或 JSON 字串的結構描述。

您也可以在 Python 字典中定義回應結構描述。您只能使用以下欄位。系統會忽略所有其他欄位。

- `enum`
- `items`
- `maxItems`
- `nullable`
- `properties`
- `required`

在此範例中，您會指示模型分析產品評論資料、擷取關鍵實體、執行情緒分類（多重選擇）、提供額外說明，並以 JSON 格式輸出結果。

- 執行 notebook 的**控制產生輸出**部分。

按一下**檢查我的進度**以驗證目標。

配置和控制模型

### 任務 5. 管理模型互動

#### 產生內容串流

根據預設，模型會在完成整個產生程序後傳回回應。您也可以使用 `generate_content_stream` 方法，在產生時串流回應。模型會在產生時傳回回應的區塊。

- 執行 notebook 的**產生內容串流**部分。

#### 發送非同步請求

您可以使用 `client.aio` 模組傳送非同步請求。此模組會公開 `client` 上可用的所有類似非同步方法。

例如，`client.aio.models.generate_content` 是 `client.models.generate_content` 的非同步版本。

- 執行 notebook 的**發送非同步請求**部分。

#### 計算 token 和計算 token

您可以使用 `count_tokens` 方法，在傳送請求給 Gemini API 之前計算輸入 token 數量。請參閱[列出和計數 token](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/list-token)頁面以取得詳細資訊。

##### **計算 token**

- 執行 notebook 的**計算 token** 部分。

##### **計算 token**

- 執行 notebook 的**計算 token** 部分。

按一下**檢查我的進度**以驗證目標。

管理模型互動

### 任務 6. 進階功能

#### 函數呼叫

[函數呼叫](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/function-calling) 可讓您提供一組工具供其用來回應用戶的提示。您可以在程式碼中建立函數描述，然後在請求中將該描述傳遞給語言模型。回應會包含符合描述的函數名稱，以及呼叫它的引數。

如需函數呼叫的更多範例，請參閱[此 lab](https://goo.gle/4jeQxBO)。

- 執行 notebook 的**函數呼叫**部分。

按一下**檢查我的進度**以驗證目標。

函數呼叫

#### 使用內容快取

[內容快取](https://cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview) 可讓您將經常使用的輸入 token 儲存在專用快取中，並在後續請求中參考它們。這消除了重複將相同 token 組傳遞給模型的需求。

##### **建立快取**

- 執行 notebook 的**建立快取**部分。

##### **使用快取**

- 執行 notebook 的**使用快取**部分。

##### **刪除快取**

- 執行 notebook 的**刪除快取**部分。

按一下**檢查我的進度**以驗證目標。

使用內容快取

#### 批次預測

與取得線上（同步）回應不同，其中您一次只能傳送一個輸入請求，[Vertex AI 上 Gemini API 的批次預測](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/batch-prediction-gemini) 可讓您以單一批次請求將大量請求傳送給 Gemini。然後，模型會以非同步方式將回應填入您的儲存輸出位置 [Cloud Storage](https://cloud.google.com/storage/docs/introduction) 或 [BigQuery](https://cloud.google.com/bigquery/docs/storage_overview)。

批次預測通常比線上預測更有效率且更具成本效益，因為處理大量不具延遲敏感性的輸入時。

##### **準備批次輸入**

批次請求的輸入會指定要傳送給模型進行預測的項目。

Gemini 的批次請求接受 BigQuery 儲存來源和 Cloud Storage 來源。您可以在[批次文字產生](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/batch-prediction-gemini#prepare_your_inputs)頁面中進一步瞭解批次輸入格式。

此 lab 使用 Cloud Storage 作為範例。Cloud Storage 輸入的要求如下：

- 檔案格式：[JSON Lines (JSONL)](https://jsonlines.org/)
- 位於 `us-central1`
- 服務帳戶適當的讀取權限

輸入 JSONL 檔案中的一個範例請求為 `batch_requests_for_multimodal_input_2.jsonl`：

`{"request":{"contents": [{"role": "user", "parts": [{"text": "List objects in this image."}, {"file_data": {"file_uri": "gs://cloud-samples-data/generative-ai/image/office-desk.jpeg", "mime_type": "image/jpeg"}}]}],"generationConfig":{"temperature": 0.4}}}`

- 執行 notebook 的**準備批次輸入**部分。

##### **準備批次輸出位置**

批次預測任務完成後，預測輸出會儲存在您的請求中指定的位置。

- 位置格式為 Cloud Storage 或 BigQuery URI 前綴，例如：`gs://path/to/output/data` 或 `bq://projectId.bqDatasetId`。
- 如果未指定，則會使用 `gs://STAGING_BUCKET/gen-ai-batch-prediction` 作為 Cloud Storage 來源，並使用 `bq://PROJECT_ID.gen_ai_batch_prediction.predictions_TIMESTAMP` 作為 BigQuery 來源。

此 lab 使用 Cloud Storage 儲存貯體作為輸出位置範例。

您可以在 `BUCKET_URI` 中指定 Cloud Storage 儲存貯體的 URI，或者如果未指定，系統會為您建立 `gs://PROJECT_ID-TIMESTAMP` 形式的 Cloud Storage 儲存貯體。

- 執行 notebook 的**準備批次輸出位置**部分。

##### **發送批次預測請求**

若要發送批次預測請求，您可以指定來源模型 ID、輸入來源和輸出位置，Vertex AI 會將批次預測結果儲存在其中。

如需詳細資訊，請參閱[批次預測 API](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/batch-prediction-api)頁面。您也可以在 https://console.cloud.google.com/vertex-ai/batch-predictions 控制台檢查狀態

- 執行 notebook 的**發送批次預測請求**部分。

**注意：**您的批次預測最多可能需要 10 分鐘才能完成。

##### **擷取批次預測結果**

批次預測任務完成後，預測輸出會儲存在您的請求中指定的位置。它也可在 `batch_job.dest.bigquery_uri` 或 `batch_job.dest.gcs_uri` 中取得。

範例輸出：

`{"status": "", "processed_time": "2024-11-13T14:04:28.376+00:00", "request": {"contents": [{"parts": [{"file_data": null, "text": "List objects in this image."}, {"file_data": {"file_uri": "gs://cloud-samples-data/generative-ai/image/gardening-tools.jpeg", "mime_type": "image/jpeg"}, "text": null}], "role": "user"}], "generationConfig": {"temperature": 0.4}}, "response": {"candidates": [{"avgLogprobs": -0.10394711927934126, "content": {"parts": [{"text": "Here's a list of the objects in the image:\n\n* **Watering can:** A green plastic watering can with a white rose head.\n* **Plant:** A small plant (possibly oregano) in a terracotta pot.\n* **Terracotta pots:** Two terracotta pots, one containing the plant and another empty, stacked on top of each other.\n* **Gardening gloves:** A pair of striped gardening gloves.\n* **Gardening tools:** A small trowel and a hand cultivator (hoe).  Both are green with black handles."}], "role": "model"}, "finishReason": "STOP"}], "modelVersion": "gemini-2.5-flash", "usageMetadata": {"candidatesTokenCount": 110, "promptTokenCount": 264, "totalTokenCount": 374}}}`

- 執行 notebook 的**擷取批次預測結果**部分。

按一下**檢查我的進度**以驗證目標。

擷取批次預測結果

#### 取得文字嵌入

您可以使用 `embed_content` 方法取得文字片段的文字嵌入。所有模型預設都會輸出 768 維度的內容。但是，某些模型可讓使用者選擇 1 到 768 之間的輸出維度。請參閱 [Vertex AI 文字嵌入 API](https://cloud.google.com/vertex-ai/generative-ai/docs/embeddings/get-text-embeddings) 以取得詳細資訊。

- 執行 notebook 的**取得文字嵌入**部分。

按一下**檢查我的進度**以驗證目標。

取得文字嵌入

## 驗證

完成所有 notebook 任務並成功執行所有儲存格後，您就成功完成了此 lab。

## 疑難排解

常見問題和解決方案：

- **429 回應錯誤**：如果遇到 API 速率限制，請等候一分鐘後重試
- **Notebook 未載入**：重設 Vertex AI Workbench 執行個體
- **權限錯誤**：確保您的服務帳戶具有適當的 Vertex AI 權限
- **記憶體不足**：減少批次大小或使用較小的模型

## 清理

此 lab 使用 Vertex AI Workbench managed 服務，大部分資源會在工作階段結束時自動清理。如需手動清理：

1. 關閉所有未使用的 Jupyter notebook
2. 刪除任何手動建立的 Cloud Storage 儲存貯體
3. 停止 Vertex AI Workbench 執行個體（如果不是臨時執行個體）

## 額外資源

- [Gemini 總覽](https://deepmind.google/technologies/gemini/)
- [Vertex AI 上的生成式 AI 文件](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [YouTube 上的生成式 AI](https://www.youtube.com/@googlecloudtech/)
- 探索 Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) 以取得生成式 AI 的精選、可搜尋 notebook 資源庫
- 探索 [Google Cloud 生成式 AI 存放區](https://github.com/GoogleCloudPlatform/generative-ai) 中的其他 notebook 和範例

## 恭喜！

恭喜！您已成功探索 Google Gen AI SDK，學習連接到 AI 服務、發送各種提示，並微調來自 Gemini 模型的回應。您還獲得使用更進階技術的實作經驗，像是管理互動、使用內容快取，甚至使用嵌入。現在您已準備好為自己的專案運用生成式 AI 的力量！

## 下一步 / 深入瞭解

查看以下資源以深入瞭解 Gemini：

- [Gemini 總覽](https://deepmind.google/technologies/gemini/)
- [Vertex AI 上的生成式 AI 文件](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [YouTube 上的生成式 AI](https://www.youtube.com/@googlecloudtech/)
- 探索 Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) 以取得生成式 AI 的精選、可搜尋 notebook 資源庫
- 探索 [Google Cloud 生成式 AI 存放區](https://github.com/GoogleCloudPlatform/generative-ai) 中的其他 notebook 和範例

---

**原始 Lab 連結**: https://www.skills.google/course_templates/959/labs/592557
**GSP 編號**: GSP1209
**完成日期**: 2025-11-05
**檔案位置**: intermediate/Explore-Generative-AI-with-the-Gemini-API-in-Vertex-AI/GSP1209-Getting-Started-with-Google-Generative-AI-Using-the-Gen-AI-SDK/
