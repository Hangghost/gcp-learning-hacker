# 使用 Gemini 模型構建聊天應用程式

## 實驗室概述

這個實驗室將教您如何使用 Google Cloud Vertex AI 上的 Gemini 生成式 AI 模型來構建一個聊天應用程式。您將學習如何連接到 Vertex AI、載入預訓練的 Gemini 模型、發送文字提示，並接收聊天回應。

## 先決條件

- Google Cloud 帳戶並啟用計費
- 基本的 Python 程式設計知識
- 熟悉 Google Cloud Console
- 已啟用 Vertex AI API

## 實驗室目標

完成這個實驗室後，您將能夠：

- **連接到 Vertex AI（Google Cloud AI 平台）**：學習如何使用 Vertex AI SDK 建立與 Google AI 服務的連線
- **載入預訓練的生成式 AI 模型 - Gemini**：學習如何使用強大的預訓練 AI 模型，而無需從頭構建
- **向 AI 模型發送文字**：了解如何提供輸入供 AI 處理
- **從 AI 提取聊天回應**：學習如何處理和解釋 AI 模型生成的聊天回應
- **了解構建 AI 應用程式的基礎知識**：深入了解將 AI 整合到軟體專案的核心概念

## 預估時間

45 分鐘

## 實驗室步驟

### 步驟 1：設定環境並連接到 Vertex AI

首先，您需要在 Google Cloud 專案中啟用必要的 API 並設定認證。

**操作指示：**

1. 在 Google Cloud Console 中，確保您處於正確的專案中
2. 啟用 Vertex AI API：
   - 導航至 "APIs & Services" > "Library"
   - 搜尋並啟用 "Vertex AI API"
3. 設定應用預設憑證（如果尚未設定）

**預期結果：**
- Vertex AI API 已啟用並可用
- 認證已正確設定

### 步驟 2：安裝必要的套件

您需要安裝 Google Cloud AI Python SDK 來與 Vertex AI 互動。

**操作指示：**

1. 在 Cloud Shell 或本地環境中安裝必要的套件：
```bash
pip install google-cloud-aiplatform
pip install google-generativeai
```

**預期結果：**
- 所有必要的套件已成功安裝

### 步驟 3：建立無串流聊天回應

這個步驟將展示如何建立一個簡單的聊天應用程式，該應用程式發送提示並接收非串流回應。

**操作指示：**

1. 建立一個新的 Python 檔案並貼上以下程式碼：

```python
from google import genai
from google.genai.types import HttpOptions, ModelContent, Part, UserContent

import logging
from google.cloud import logging as gcp_logging

# 初始化 GCP 日誌（供 Qwiklab 內部使用，請勿編輯/刪除）
gcp_logging_client = gcp_logging.Client()
gcp_logging_client.setup_logging()

# 初始化 Gemini 客戶端
client = genai.Client(
    vertexai=True,
    project="your-project-id",  # 請替換為您的專案 ID
    location="us-central1",      # 請替換為您的區域
    http_options=HttpOptions(api_version="v1")
)

# 建立聊天對話
chat = client.chats.create(
    model="gemini-2.0-flash-001",
    history=[
        UserContent(parts=[Part(text="Hello")]),
        ModelContent(
            parts=[Part(text="Great to meet you. What would you like to know?")],
        ),
    ],
)

# 發送訊息並獲取回應
response = chat.send_message("What are all the colors in a rainbow?")
print(response.text)

response = chat.send_message("Why does it appear when it rains?")
print(response.text)
```

2. 將檔案儲存為 `SendChatwithoutStream.py`
3. 執行程式碼以查看輸出結果

**預期結果：**
- 程式碼成功執行並顯示彩虹顏色的相關資訊

### 步驟 4：建立串流聊天回應

現在讓我們探索如何建立串流聊天回應，這會在產生時即時顯示回應。

**操作指示：**

1. 建立一個新的 Python 檔案並貼上以下程式碼：

```python
from google import genai
from google.genai.types import HttpOptions

import logging
from google.cloud import logging as gcp_logging

# 初始化 GCP 日誌（供 Qwiklab 內部使用，請勿編輯/刪除）
gcp_logging_client = gcp_logging.Client()
gcp_logging_client.setup_logging()

# 初始化 Gemini 客戶端
client = genai.Client(
    vertexai=True,
    project="your-project-id",  # 請替換為您的專案 ID
    location="us-central1",      # 請替換為您的區域
    http_options=HttpOptions(api_version="v1")
)

# 建立聊天對話
chat = client.chats.create(model="gemini-2.0-flash-001")
response_text = ""

# 使用串流發送訊息並即時顯示回應
for chunk in chat.send_message_stream("What are all the colors in a rainbow?"):
    print(chunk.text, end="")
    response_text += chunk.text
```

2. 將檔案儲存為 `SendChatwithStream.py`
3. 執行程式碼以查看串流輸出結果

**預期結果：**
- 程式碼成功執行並以串流方式顯示回應

### 步驟 5：實驗不同的提示

嘗試使用不同的提示來探索 Gemini 的功能。

**操作指示：**

1. 修改程式碼中的提示文字，例如：
   - "寫一首關於雲端運算的詩"
   - "解釋量子運算的基本概念"
   - "提供學習 Python 的最佳實務建議"
2. 執行程式碼並觀察不同的回應

**預期結果：**
- 成功接收到各種主題的相關回應

## 驗證步驟

要驗證實驗室是否成功完成，請確認：

1. ✅ 能夠成功連接到 Vertex AI
2. ✅ 無串流聊天應用程式正常運作
3. ✅ 串流聊天應用程式正常運作並顯示即時回應
4. ✅ 可以接收到相關且有意義的 AI 回應

## 故障排除

常見問題與解決方案：

- **認證錯誤**：
  - 確保已正確設定應用預設憑證
  - 檢查專案 ID 和區域設定是否正確

- **API 未啟用**：
  - 確認 Vertex AI API 已啟用
  - 檢查專案是否有足夠的權限

- **匯入錯誤**：
  - 確保已安裝正確版本的套件
  - 檢查 Python 環境設定

- **網路連線問題**：
  - 確認網路連線正常
  - 檢查防火牆設定

## 清理指示

為了避免產生額外費用，請在實驗室結束後執行以下清理步驟：

1. 刪除任何建立的資源（如果適用）
2. 檢查並停止任何運行中的運算資源
3. 檢視計費頁面確認沒有意外費用

**注意**：這個實驗室主要使用現有的 API 和服務，通常不會產生額外的運算資源費用。

## 額外資源

- [Vertex AI 官方文件](https://cloud.google.com/vertex-ai/docs)
- [Gemini 模型文件](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini)
- [Google Cloud AI Python SDK 文件](https://cloud.google.com/python/docs/reference/aiplatform/latest)
- [生成式 AI 最佳實務](https://cloud.google.com/vertex-ai/docs/generative-ai/best-practices)

## 相關實驗室

- [bb-ide-genai-001：使用 Gemini 在 Vertex AI 上構建 AI 圖像識別應用](https://www.cloudskillsboost.google/course_templates/1076/labs/584318)
- [bb-ide-genai-002：使用 Imagen 在 Vertex AI 上構建 AI 圖像生成器應用](https://www.cloudskillsboost.google/course_templates/1076/labs/584319)

## 筆記

這個實驗室提供了使用 Google Cloud Vertex AI 和 Gemini 模型構建聊天應用程式的實作經驗。重點在於了解生成式 AI 的基本概念和 API 使用方式。

**程式碼注意事項：**
- 請記得替換程式碼中的專案 ID 和區域為您的實際值
- 確保 API 版本與您的需求相符
- 考慮實作錯誤處理來增強應用程式的穩定性
