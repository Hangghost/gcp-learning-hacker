# GSP515 - Explore Generative AI with the Gemini API in Vertex AI: Challenge Lab

## 任務 1: 使用 Gemini 生成文字

### 1.1 設定環境變數

在 Cloud Shell 中執行以下命令：

```bash
PROJECT_ID=
LOCATION=
API_ENDPOINT=${LOCATION}-aiplatform.googleapis.com
MODEL_ID=""
```

### 1.2 啟用必要 API

前往 Cloud Console 中的 Vertex AI 部分

確保 Vertex AI API 已啟用

如果需要，在 API 程式庫中搜尋並啟用 Vertex AI API

### 1.3 使用 curl 呼叫 Gemini 模型

使用以下 curl 命令呼叫 Gemini API：

```bash
curl -X POST \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
-H "Content-Type: application/json" \
"https://${API_ENDPOINT}/v1/projects/${PROJECT_ID}/locations/${LOCATION}/publishers/google/models/${MODEL_ID}:generateContent" \
-d '{
  "contents": [{
    "role": "user",
    "parts": [{"text": "Why is the sky blue?"}]
  }]
}'
```

預期結果：您應該收到一個 JSON 回應，其中包含 Gemini 對問題 "Why is the sky blue?" 的解釋。

### 驗證

檢查是否收到有效的 JSON 回應

確認回應包含文字解釋

點擊檢查我的進度按鈕以驗證任務完成

## 任務 2: 在 Vertex AI Workbench 中開啟 notebook

### 2.1 開啟 Vertex AI Workbench

在 Google Cloud Console 中，點擊導航選單 (≡)

前往 Vertex AI > Workbench

找到名為 Workbench instance name 的執行個體

點擊 Open JupyterLab 按鈕

### 2.2 如果 JupyterLab 沒有載入

如果您在 JupyterLab 中沒有看到 notebooks，請按照以下額外步驟重設執行個體：

關閉 JupyterLab 的瀏覽器分頁

返回 Workbench 首頁

選取執行個體名稱旁的核取方塊

點擊 Reset

等待一分鐘，讓 Open JupyterLab 按鈕再次啟用

點擊 Open JupyterLab

## 任務 3: 使用 Gemini 創建函數呼叫

### 3.1 開啟並設定 notebook

在 JupyterLab 中開啟 notebook name 檔案

在 Select Kernel 對話方塊中選擇 Python 3

確認 Project ID 和 Location 已預先設定

```python
model_id = ""
```

### 3.2 完成函數呼叫實作

找到標記為 INSERT 的儲存格並完成缺失的部分：

```python
get_current_weather_func = FunctionDeclaration(
    name="get_current_weather",
    description="Get the current weather in a given location",
    parameters={
        "type": "object",
        "properties": {
            "location": {
                "type": "string",
                "description": "Location"
            }
        }
    },
)
```

### 3.3 常見的實作模式

```python
weather_tool = Tool(
    function_declarations=[get_current_weather_func],
)
```

### 3.4 測試函數呼叫

```python
prompt = "What is the weather like in Boston?"

response = client.models.generate_content(
    model=model_id,
    contents=prompt,
    config=GenerateContentConfig(
        tools=[weather_tool],
        temperature=0,
    ),
)

response
```

執行包含函數呼叫的儲存格

確保回應包含天氣相關資料

驗證函數呼叫的 JSON 結構正確

## 任務 4: 使用 Gemini 描述視頻內容

### 4.1 找到任務 4 的儲存格

在 Vertex AI Workbench 中保持在同一個 notebook

找到包含註釋 # Task 4 的儲存格

```python
multimodal_model = "gemini-2.5-flash"
```

### 4.2 完成視頻內容描述程式碼

完成 notebook notebook name 中任務 4 的必要部分：

提示：您需要：

載入視頻檔案或提供視頻 URL

使用 Gemini 的多模態功能處理視頻

生成對視頻內容的描述

### 4.3 常見的實作模式

```python
prompt = """
What is shown in this video?
Where should I go to see it?
What are the top 5 places in the world that look like this?
"""

video = Part.from_uri(
    file_uri="gs://github-repo/img/gemini/multimodality_usecases_overview/mediterraneansea.mp4",
    mime_type="video/mp4",
)

contents = [prompt, video]

responses = client.models.generate_content_stream(
    model=multimodal_model,
    contents=contents
)

print("-------Prompt--------")
print_multimodal_prompt(contents)

print("\n-------Response--------")
for response in responses:
    print(response.text, end="")
```

祝實驗順利完成 🎉

保持學習，保持駭客精神！
