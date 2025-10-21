# 使用 Gemini on Vertex AI 構建 AI 圖像識別應用

## 實驗室標題
使用 Gemini on Vertex AI 構建 AI 圖像識別應用

## 先決條件
- Google Cloud 帳戶並啟用相關 API
- 基本的 Python 知識
- 熟悉 Google Cloud Console
- 網路連線（用於訪問外部圖像資源）

## 目標
完成此實驗室後，您將能夠：
- **連接到 Vertex AI（Google Cloud AI 平台）**：學習如何使用 Vertex AI SDK 建立與 Google AI 服務的連線
- **載入預訓練的生成式 AI 模型 - Gemini**：了解如何使用強大的預訓練 AI 模型，而無需從頭構建
- **向 AI 模型發送圖像 + 文字問題**：理解如何為 AI 提供輸入進行處理
- **從 AI 提取基於文字的答案**：學習處理和解釋 AI 模型生成的文字回應
- **理解構建 AI 應用程式的基礎知識**：深入了解將 AI 整合到軟體專案的核心概念

## 預估時間
30 分鐘

## 實驗室步驟

### 步驟 1: 設定環境並連接到 Vertex AI
在開始使用 Vertex AI Python SDK 之前，您需要設定適當的環境變數。

**說明：**
1. 在終端機中執行以下命令來設定環境變數：
   ```bash
   export GOOGLE_CLOUD_PROJECT="your-project-id"
   export GOOGLE_CLOUD_LOCATION="your-region"
   export GOOGLE_GENAI_USE_VERTEXAI=True
   ```

**預期結果：**
環境變數已正確設定，為後續的 Python 程式碼執行做好準備。

### 步驟 2: 創建並執行 Python 腳本
使用 Vertex AI Python SDK 與 Gemini 模型互動。

**說明：**
1. 打開程式碼編輯器並創建一個新檔案
2. 複製並貼上以下程式碼片段到您的檔案中：

```python
from google import genai
from google.genai.types import HttpOptions, Part

client = genai.Client(http_options=HttpOptions(api_version="v1"))
response = client.models.generate_content(
    model="gemini-2.0-flash-001",
    contents=[
        "What is shown in this image?",
        Part.from_uri(
            file_uri="https://storage.googleapis.com/cloud-samples-data/generative-ai/image/scones.jpg",
            mime_type="image/jpeg",
        ),
    ],
)
print(response.text)
```

3. 將檔案儲存為 `genai.py`
4. 在程式碼編輯器窗格內的終端機中執行以下命令來查看輸出：
   ```bash
   /usr/bin/python3 genai.py
   ```

**注意事項：** 如果遇到 400 錯誤，請嘗試重新執行程式碼。

**預期結果：**
程式將輸出 Gemini 模型對圖像內容的描述性分析。

## 程式碼說明

- 程式碼片段載入了稱為 Gemini (gemini-2.0-flash-001) 的預訓練 AI 模型到 Vertex AI
- 程式碼呼叫載入的 Gemini 模型的 `generate_content` 方法
- 方法的輸入是一個圖像 URI 和一個包含圖像相關問題的提示
- 程式碼利用 Gemini 同時理解圖像和文字的能力。它使用提示中提供的文字來描述圖像內容

**親自嘗試！** 嘗試使用不同的圖像 URI 和提示問題來探索 Gemini 的功能。

## 驗證
點擊 **Check my progress** 來驗證目標：為圖像生成內容

## 故障排除
常見問題及其解決方案：
- **400 錯誤**：重新執行程式碼，此錯誤通常是暫時性的
- **環境變數問題**：確保正確設定了 `GOOGLE_CLOUD_PROJECT`、`GOOGLE_CLOUD_LOCATION` 和 `GOOGLE_GENAI_USE_VERTEXAI` 環境變數
- **Python 依賴項錯誤**：確保已安裝必要的 Python 套件，包括 `google-genai`

## 清理
此實驗室不需要特殊的清理步驟，因為它僅涉及 API 呼叫，不會建立持久資源。

## 額外資源
- [Vertex AI 文件](https://cloud.google.com/vertex-ai/docs)
- [Gemini 模型文件](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini)
- [Python SDK 參考](https://cloud.google.com/python/docs/reference/aiplatform/latest)
- [相關實驗室：Cloud Run Functions 快速入門系列](https://cloud.google.com/run/docs/quickstarts)

## 筆記
這個實驗室展示了使用 Google 的生成式 AI 模型進行圖像分析的強大功能。Gemini 能夠理解圖像內容並提供有意義的文字回應，這為各種 AI 應用開啟了大門。
