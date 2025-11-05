# GSP520 - 使用 Gemini 多模態和多模態 RAG 檢查豐富文檔：挑戰實驗室

## 實驗概述

Gemini 是一個多模態模型，可以處理文本、圖像和視頻輸入。在這個挑戰實驗室中，您將學習如何：

- 使用多模態提示從文本和視覺數據中提取信息，生成視頻描述，並使用 Gemini 的多模態能力檢索視頻以外的額外信息
- 構建包含文本和圖像的文檔元數據，使用多模態檢索增強生成 (RAG) 與 Gemini 來獲取所有相關文本塊並打印引用

**注意：** 如果運行 notebook 單元格時遇到認證錯誤，請轉到 **Vertex AI > Dashboard**，然後點擊 **Enable All Recommended APIs**。然後重新運行失敗的單元格，繼續實驗。

## 設定和需求

### 安裝 Vertex AI SDK for Python 和其他依賴

運行以下四個單元格在開始 Task 1 之前。請務必將您的當前專案 ID 添加到標題為 **Define Google Cloud project information** 的單元格中。

#### 1. 安裝必要的 Python 套件

```python
# 直接運行此單元格
%pip install --upgrade --user google-cloud-aiplatform
%pip install --upgrade --user google-cloud-aiplatform pymupdf
```

#### 2. 重新啟動當前運行時

您必須重新啟動內核以在新 Jupyter 運行時中使用新安裝的套件。您可以通過運行下面的單元格來做到這一點，這將重新啟動當前內核。

```python
# 直接運行此單元格
import IPython

# 在載入函式庫後重新啟動內核
app = IPython.Application.instance()
app.kernel.do_shutdown(True)
```

<div class="alert alert-block alert-warning">
<b>⚠️ 內核將重新啟動。請等到它完成後再繼續下一步。⚠️</b>
</div>

#### 3. 定義 Google Cloud 專案信息

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

import sys

# 定義專案信息，如果與實驗指示中指定的不同，請更新位置
PROJECT_ID = !gcloud config get project
PROJECT_ID = PROJECT_ID[0]  # @param {type:"string"}
LOCATION = !gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])"
LOCATION = LOCATION[0]  # @param {type:"string"}

# 嘗試自動獲取 PROJECT_ID
if "google.colab" not in sys.modules:
    import subprocess

    PROJECT_ID = subprocess.check_output(
        ["gcloud", "config", "get-value", "project"], text=True
    ).strip()

print(f"您的專案 ID 是: {PROJECT_ID}")
print(f"您的位置是: {LOCATION}")
```

#### 4. 初始化 Vertex AI

初始化 Vertex AI SDK for Python 用於您的專案：

```python
# 直接運行此單元格

# 初始化 Vertex AI
import vertexai
vertexai.init(project=PROJECT_ID, location=LOCATION)
```

## Task 1. 使用 Gemini 生成多模態洞察

Gemini 是一個多模態模型，支持多模態提示。您可以在提示請求中包含文本、圖像和視頻，並獲得文本回應。

要完成 Task 1，請遵循每個 notebook 單元格頂部的指示：
- 運行標記為 "直接運行此單元格" 的單元格
- 完成並運行標記為 "【需要挑戰者填寫】" 的單元格

**注意：** 確保在回應中可以看到天氣相關數據。

### Task 1 設定和需求

#### 匯入函式庫

```python
# 直接運行此單元格

from vertexai.generative_models import (
    GenerationConfig,
    GenerativeModel,
    Image,
    Part,
)
```

#### 載入 Gemini 2.0 Flash 模型

```python
# 直接運行此單元格

multimodal_model = GenerativeModel("gemini-2.0-flash-001")
```

#### 定義輔助函數

```python
# 直接運行此單元格

import http.client
import typing
import urllib.request

import IPython.display
from PIL import Image as PIL_Image
from PIL import ImageOps as PIL_ImageOps

def display_images(
    images: typing.Iterable[Image],
    max_width: int = 600,
    max_height: int = 350,
) -> None:
    for image in images:
        pil_image = typing.cast(PIL_Image.Image, image._pil_image)
        if pil_image.mode != "RGB":
            # RGB 被所有 Jupyter 環境支持（例如 RGBA 還沒有）
            pil_image = pil_image.convert("RGB")
        image_width, image_height = pil_image.size
        if max_width < image_width or max_height < image_height:
            # 調整大小以顯示較小的 notebook 圖像
            pil_image = PIL_ImageOps.contain(pil_image, (max_width, max_height))
        IPython.display.display(pil_image)

def get_image_bytes_from_url(image_url: str) -> bytes:
    with urllib.request.urlopen(image_url) as response:
        response = typing.cast(http.client.HTTPResponse, response)
        image_bytes = response.read()
    return image_bytes

def load_image_from_url(image_url: str) -> Image:
    image_bytes = get_image_bytes_from_url(image_url)
    return Image.from_bytes(image_bytes)

def display_content_as_image(content: str | Image | Part) -> bool:
    if not isinstance(content, Image):
        return False
    display_images([content])
    return True

def display_content_as_video(content: str | Image | Part) -> bool:
    if not isinstance(content, Part):
        return False
    part = typing.cast(Part, content)
    file_path = part.file_data.file_uri.removeprefix("gs://")
    video_url = f"https://storage.googleapis.com/{file_path}"
    IPython.display.display(IPython.display.Video(video_url, width=600))
    return True

def print_multimodal_prompt(contents: list[str | Image | Part]):
    """
    給定將發送給 Gemini 的內容，
    輸出完整的多模態提示以便於閱讀。
    """
    for content in contents:
        if display_content_as_image(content):
            continue
        if display_content_as_video(content):
            continue
        print(content)
```

### Task 1.1. 多圖像理解

#### 探索任務的變數

```python
# 直接運行此單元格

# 您將在此任務中使用提供的變數。
# 首先，查看並描述每個變數的內容/目的。

image_ask_first_1_url = "https://storage.googleapis.com/spls/gsp520/Google_Branding/Ask_first_1.png"
image_dont_do_this_1_url = "https://storage.googleapis.com/spls/gsp520/Google_Branding/Dont_do_this_1.png"
image_ask_first_1 = load_image_from_url(image_ask_first_1_url)
image_dont_do_this_1 = load_image_from_url(image_dont_do_this_1_url)

instructions = "Instructions: Consider the following image that contains text:"
prompt1 = "What is the title of this image"
prompt2 = """
Answer the question through these steps:
Step 1: Identify the title of each image by using the filename of each image.
Step 2: Describe the image.
Step 3: For each image, describe the actions that a user is expected to take.
Step 4: Extract the text from each image as a full sentence.
Step 5: Describe the sentiment for each image with an explanation.

Answer and describe the steps taken:
"""
```

#### 為多模態模型創建輸入

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 現在，您將為多模態模型創建輸入。使用上面的變數創建您的 contents 列表。
# 確保結構匹配多模態模型期望的格式。

contents = [
    instructions,
    image_ask_first_1,
    prompt1,
    image_dont_do_this_1,
    prompt2,
]
```

#### 從多模態模型生成回應

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 在此任務的下一部分，您將從多模態模型生成回應。
# 在 "responses" 變數中捕獲模型的輸出，通過使用您的 "contents" 列表。

responses = multimodal_model.generate_content(contents, stream=True)
```

#### 顯示提示和回應

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 在此任務的最後部分，您將打印您的 contents 和 responses，並提供提示和 responses 標題。使用描述性標題來幫助組織輸出（例如，"Prompts", "Model Responses"），然後通過使用 print() 函數顯示提示和回應。

# 提示："\\n" 插入換行符以獲得更清晰的分隔。

print("-------Prompt-------")
print_multimodal_prompt(contents)

print("\\n-------Response-------")
for response in responses:
    print(response.text, end="")
```

### Task 1.2. 圖像間的相似性/差異

#### 探索任務的變數

```python
# 直接運行此單元格

# 您將在此任務中使用提供的變數。首先，查看並描述每個變數的內容/目的。

image_ask_first_3_url = "https://storage.googleapis.com/spls/gsp520/Google_Branding/Ask_first_3.png"
image_dont_do_this_3_url = "https://storage.googleapis.com/spls/gsp520/Google_Branding/Dont_do_this_3.png"
image_ask_first_3 = load_image_from_url(image_ask_first_3_url)
image_dont_do_this_3 = load_image_from_url(image_dont_do_this_3_url)

prompt1 = """
Consider the following two images:
Image 1:
"""
prompt2 = """
Image 2:
"""
prompt3 = """
1. What is shown in Image 1 and Image 2?
2. What is similar between the two images?
3. What is difference between Image 1 and Image 2 in terms of the text?
"""
```

#### 為多模態模型創建輸入

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 現在，您將為多模態模型創建輸入。使用上面的變數創建您的 contents 列表。
# 確保結構匹配多模態模型期望的格式。

contents = [prompt1, image_ask_first_3, prompt2, image_dont_do_this_3, prompt3]
```

#### 設定配置參數

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 現在，您將設定配置參數，這些參數將影響多模態模型如何生成文本。這些設定控制回應的創造性和重點等方面。
# Temperature: 控制隨機性。較低值意味著更可預測的結果，較高值意味著更令人驚訝和創造性的輸出
# Top p / Top k: 影響模型如何選擇單詞。探索不同的值以查看它們如何改變結果。
# 其他參數: 查看模型的文檔以獲取您可能想要調整的其他選項。

# 在 generation_config 變數中存儲您的配置參數。這提高了可重用性，允許您輕鬆地在任務之間應用相同的設定並根據需要進行調整。

generation_config = GenerationConfig(
    temperature=0.0,
    top_p=0.8,
    top_k=40,
    candidate_count=1,
    max_output_tokens=2048,
)
```

#### 從多模態模型生成回應

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 在此任務的下一部分，您將從多模態模型生成回應。捕獲模型的輸出在 "responses" 變數中，通過使用您的 "contents" 列表和配置設定。

responses = multimodal_model.generate_content(
    contents,
    generation_config=generation_config,
    stream=True,
)
```

#### 顯示提示和回應

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 在此任務的最後部分，您將打印您的 contents 和 responses，並提供提示和 responses 標題。使用描述性標題來幫助組織輸出（例如，"Prompts", "Model Responses"），然後通過使用 print() 函數顯示提示和回應。

# 提示："\\n" 插入換行符以獲得更清晰的分隔。

print("-------Prompt-------")
print_multimodal_prompt(contents)

print("\\n-------Response-------")
for response in responses:
    print(response.text, end="")
```

### Task 1.3. 生成視頻描述

#### 探索任務的變數

```python
# 直接運行此單元格

# 您將在此任務中使用提供的變數。
# 首先，查看並描述每個變數的內容/目的。

prompt = """
What is the product shown in this video?
What specific product features are highlighted in the video?
Where was this video filmed? Which cities around the world could potentially serve as the background in the video?
What is the sentiment of the video?
"""
video = Part.from_uri(
    uri="gs://spls/gsp520/google-pixel-8-pro.mp4",
    mime_type="video/mp4",
)
```

#### 為多模態模型創建輸入

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 現在，您將為多模態模型創建輸入。使用上面的變數創建您的 contents 列表。
# 確保結構匹配多模態模型期望的格式。

contents = [prompt, video]
```

#### 從多模態模型生成回應

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 在此任務的下一部分，您將從多模態模型生成回應。捕獲模型的輸出在 "responses" 變數中，通過使用您的 "contents" 列表。

responses = multimodal_model.generate_content(contents, stream=True)
```

#### 顯示提示和回應

**注意：** 如果下面單元格運行時遇到任何認證錯誤，請轉到 **Navigation menu**，點擊 **Vertex AI > Dashboard**，然後點擊 **"Enable all Recommended APIs"** 現在，返回單元格 16，並運行單元格 16、17 和下面單元格。

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 在此任務的最後部分，您將打印您的 contents 和 responses，並提供提示和 responses 標題。使用描述性標題來幫助組織輸出（例如，"Prompts", "Model Responses"），然後通過使用 print() 函數顯示提示和回應。

# 提示："\\n" 插入換行符以獲得更清晰的分隔。

print("-------Prompt-------")
print_multimodal_prompt(contents)

print("\\n-------Response-------")
for response in responses:
    print(response.text, end="")
```

### Task 1.4. 在整個視頻中提取對象標籤

#### 探索任務的變數

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 您將在此任務中使用提供的變數。首先，查看並描述每個變數的內容/目的。

prompt = """
Answer the following questions using the video only:

Which particular sport is highlighted in the video?
What values or beliefs does the advertisement communicate about the brand?
What emotions or feelings does the advertisement evoke in the audience?
Which tags associated with objects featured throughout the video could be extracted?
"""
video = Part.from_uri(
    uri="gs://spls/gsp520/google-pixel-8-pro.mp4",
    mime_type="video/mp4",
)
```

#### 為多模態模型創建輸入

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 現在，您將為多模態模型創建輸入。使用上面的變數創建您的 contents 列表。
# 確保結構匹配多模態模型期望的格式。

contents = [prompt, video]
```

#### 從多模態模型生成回應

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 在此任務的下一部分，您將從多模態模型生成回應。捕獲模型的輸出在 "responses" 變數中，通過使用您的 "contents" 列表和視頻輸入。

responses = multimodal_model.generate_content(contents, stream=True)
```

#### 顯示提示和回應

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 在此任務的最後部分，您將打印您的 contents 和 responses，並提供提示和 responses 標題。使用描述性標題來幫助組織輸出（例如，"Prompts", "Model Responses"），然後通過使用 print() 函數顯示提示和回應。

# 提示："\\n" 插入換行符以獲得更清晰的分隔。

print("-------Prompt-------")
print_multimodal_prompt(contents)

print("\\n-------Response-------")
for response in responses:
    print(response.text, end="")
```

### Task 1.5. 詢問視頻的更多問題

**注意：** 雖然此視頻包含音頻，但 Gemini 目前不支持音頻輸入，只會基於視頻回答。

#### 探索任務的變數

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 您將在此任務中使用提供的變數。
# 首先，查看並描述每個變數的內容/目的。

prompt = """
Answer the following questions using the video only:

How does the advertisement portray the use of technology, specifically AI, in capturing and preserving memories?
What visual cues or storytelling elements contribute to the nostalgic atmosphere of the advertisement?
How does the advertisement depict the role of friendship and social connections in enhancing experiences and creating memories?
Are there any specific features or functionalities of the phone highlighted in the advertisement, besides its AI capabilities?

Provide the answer JSON.
"""
video = Part.from_uri(
    uri="gs://spls/gsp520/google-pixel-8-pro.mp4",
    mime_type="video/mp4",
)
```

#### 為多模態模型創建輸入

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 現在，您將為多模態模型創建輸入。使用上面的變數創建您的 contents 列表。
# 確保結構匹配多模態模型期望的格式。

contents = [prompt, video]
```

#### 從多模態模型生成回應

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 在此任務的下一部分，您將從多模態模型生成回應。捕獲模型的輸出在 "responses" 變數中，通過使用您的 "contents" 列表和視頻輸入。

responses = multimodal_model.generate_content(contents, stream=True)
```

#### 顯示提示和回應

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 在此任務的最後部分，您將打印您的 contents 和 responses，並提供提示和 responses 標題。使用描述性標題來幫助組織輸出（例如，"Prompts", "Model Responses"），然後通過使用 print() 函數顯示提示和回應。

# 提示："\\n" 插入換行符以獲得更清晰的分隔。

print("-------Prompt-------")
print_multimodal_prompt(contents)

print("\\n-------Response-------")
for response in responses:
    print(response.text, end="")
```

### Task 1.6. 檢索視頻以外的額外信息

#### 探索任務的變數

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 您將在此任務中使用提供的變數。
# 首先，查看並描述每個變數的內容/目的。

prompt = """
Answer the following questions using the video only:

How does the advertisement appeal to its target audience through its messaging and imagery?
What overall message or takeaway does the advertisement convey about the brand and its products?
Are there any symbolic elements or motifs used throughout the advertisement to reinforce its central themes?
What is the best hashtag for this video based on the description?
"""
video = Part.from_uri(
    uri="gs://spls/gsp520/google-pixel-8-pro.mp4",
    mime_type="video/mp4",
)
```

#### 為多模態模型創建輸入

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 現在，您將為多模態模型創建輸入。使用上面的變數創建您的 contents 列表。
# 確保結構匹配多模態模型期望的格式。

contents = [prompt, video]
```

#### 從多模態模型生成回應

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 在此任務的下一部分，您將從多模態模型生成回應。捕獲模型的輸出在 "responses" 變數中，通過使用您的 "contents" 列表和視頻輸入。

responses = multimodal_model.generate_content(contents, stream=True)
```

#### 顯示提示和回應

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 在此任務的最後部分，您將打印您的 contents 和 responses，並提供提示和 responses 標題。使用描述性標題來幫助組織輸出（例如，"Prompts", "Model Responses"），然後通過使用 print() 函數顯示提示和回應。

# 提示："\\n" 插入換行符以獲得更清晰的分隔。

print("-------Prompt-------")
print_multimodal_prompt(contents)

print("\\n-------Response-------")
for response in responses:
    print(response.text, end="")
```

## Task 2. 使用多模態檢索增強生成 (RAG) 檢索和整合知識

要完成 Task 2，請遵循每個 notebook 單元格頂部的指示：
- 運行標記為 "直接運行此單元格" 的單元格
- 完成並運行標記為 "【需要挑戰者填寫】" 的單元格

對於 Task 2 的附加信息，請查看實驗指示中名為 __Available data and helper functions for Task 2__ 的部分。

### Task 2 設定和需求

#### 匯入函式庫

```python
# 直接運行此單元格

# 匯入必要的套件和函式庫。

from IPython.display import Markdown, display
from vertexai.generative_models import (
    Content,
    GenerationConfig,
    GenerationResponse,
    GenerativeModel,
    HarmCategory,
    HarmBlockThreshold,
    Image,
    Part,
)
```

#### 載入 Gemini 2.0 Flash 模型

```python
# 直接運行此單元格

# 載入 Gemini 2.0 Flash 模型。

multimodal_model = GenerativeModel("gemini-2.0-flash-001")
```

#### 下載自訂 Python 模組和工具

下面的單元格將下載此 notebook 需要的輔助函數，以改善可讀性。您也可以直接在 [GitHub](https://raw.githubusercontent.com/GoogleCloudPlatform/generative-ai/main/gemini/use-cases/retrieval-augmented-generation/utils/intro_multimodal_rag_utils.py) 上查看代碼 (`intro_multimodal_rag_utils.py`)。

```python
# 直接運行此單元格

# 匯入必要的套件和函式庫。
import os
import urllib.request
import sys

if not os.path.exists("utils"):
    os.makedirs("utils")

# 從 utils 文件夾下載腳本。
url_prefix = "https://raw.githubusercontent.com/GoogleCloudPlatform/generative-ai/main/gemini/use-cases/retrieval-augmented-generation/utils/"
files = ["intro_multimodal_rag_utils.py"]

for fname in files:
    urllib.request.urlretrieve(f"{url_prefix}/{fname}", filename=f"utils/{fname}")
```

#### 從 Cloud Storage 獲取文檔和圖像

```python
# 直接運行此單元格

# 下載此 notebook 中使用的文檔和圖像。

!gsutil -m rsync -r gs://spls/gsp520 .
print("Download completed")
```

### Task 2.1. 構建包含文本和圖像的文檔元數據

**注意：** 這些步驟可能需要幾分鐘完成。

#### 匯入構建元數據的輔助函數

```python
# 直接運行此單元格

# 從 utils 匯入輔助函數。
from utils.intro_multimodal_rag_utils import get_document_metadata
```

#### 探索任務的變數

```python
# 直接運行此單元格

# 您將在此任務中使用提供的變數。
# 首先，查看並描述每個變數的內容/目的。

# 指定 "PDF 文件夾路徑" 與單個 PDF 和 "PDF 文件夾" 與多個 PDF。

pdf_folder_path = "Google_Branding/"  # 如果在 Vertex AI Workbench 中運行。

# 指定圖像描述提示。如果需要的話，更改它

image_description_prompt = """Explain what is going on in the image.
If it's a table, extract all elements of the table.
If it's a graph, explain the findings in the graph.
Do not include any numbers that are not mentioned in the image.
"""
```

#### 提取和存儲文檔中文本和圖像的元數據

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 從 utils 文件調用 "get_document_metadata" 函數以從 PDF 文檔中提取文本和圖像元數據。將結果存儲在兩個不同的 DataFrame 中： "text_metadata_df" 和 "image_metadata_df"。
# text_metadata_df: 這將包含提取的文本片段，它們對應的頁碼，以及潛在的其他相關信息。
# image_metadata_df: 這將包含 PDF 中找到的圖像描述（如果有的話），以及它們在文檔中的位置。

text_metadata_df, image_metadata_df = get_document_metadata(
    multimodal_model, # we are passing gemini 1.0 pro vision model
    pdf_folder_path,
    image_save_dir="images",
    image_description_prompt=image_description_prompt,
    embedding_size=1408,
)

print("\\n\\n --- Completed processing. ---")
```

#### 檢查處理的文本元數據

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 通過顯示 DataFrame 的前幾行來探索 text_metadata_df DataFrame。

text_metadata_df.head()
```

#### 匯入實現 RAG 的輔助函數

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 從 utils 匯入輔助函數。

from utils.intro_multimodal_rag_utils import (
    get_similar_text_from_query,
    print_text_to_text_citation,
    get_similar_image_from_query,
    print_text_to_image_citation,
    get_gemini_response,
    display_images,
)
```

### Task 2.2. 創建用戶查詢

#### 探索任務的變數

```python
# 直接運行此單元格

# 您將在此任務中使用提供的變數。
# 首先，查看並描述每個變數的內容/目的。

query = """Questions:
 - What are the key expectations that users can have from Google regarding the provision and development of its services?
- What specific rules and guidelines are established for users when using Google services?
- How does Google handle intellectual property rights related to the content found within its services, including content owned by users, Google, and third parties?
- What legal rights and remedies are available to users in case of problems or disagreements with Google?
- How do the service-specific additional terms interact with these general Terms of Service, and which terms take precedence in case of any conflicts?
 """
```

### Task 2.3. 獲取所有相關文本塊

#### 基於查詢檢索相關的文本塊

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 從 utils 文件調用 "get_similar_text_from_query" 函數以基於查詢檢索相關的文本塊。將結果存儲在名為 "matching_results_chunks_data" 的字典中。
# matching_results_chunks_data: 此字典將包含 file_name, page_num, cosine_score, chunk_number 和 chunk_score。此字典表示與 text_metadata_df 相關的查詢的搜索結果。

matching_results_chunks_data = get_similar_text_from_query(
    query,
    text_metadata_df,
    column_name="text_embedding_chunk",
    top_n=10,
    chunk_text=True,
)
```

#### 顯示文本塊字典的第一項

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 通過顯示第一項來探索您的 matching_results_chunks_data 字典中的第一項。

print_text_to_text_citation(
    matching_results_chunks_data,
    print_top=False,
    chunk_text=True,
)
```

### Task 2.4. 創建 context_text

#### 創建一個列表來存儲組合的文本塊

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 創建一個名為 "context_text" 的空列表。此列表將用於存儲組合的文本塊。
context_text = list()
```

#### 遍歷文本塊字典中的每個項目

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 創建一個 for 循環來遍歷 matching_results_chunks_data 字典中的每個項目，以便組合所有選定的相關文本塊

for key, value in matching_results_chunks_data.items():
    context_text.append(value["chunk_text"])
```

#### 連接所有文本塊並存儲在列表中

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 取所有存儲在 context_text 列表中的單個文本塊並將它們連接在一起成為一個名為 final_context_text 的字符串。使用 "\\n" 部分插入一個換行符，有效地創建單獨的行或段落。

final_context_text = "\\n".join(context_text)
```

### Task 2.5. 將上下文傳遞給 Gemini

#### 探索任務的變數

```python
# 直接運行此單元格

# 您將在此任務中使用提供的變數。首先，查看並描述每個變數的內容/目的。

prompt = f""" Instructions: Compare the images and the text provided as Context: to answer multiple Question:
Make sure to think thoroughly before answering the question and put the necessary steps to arrive at the answer in bullet points for easy explainability.
If unsure, respond, "Not enough context to answer".

Context:
 - Text Context:
 {final_context_text}


{query}

Answer:
"""
```

#### 生成帶流輸出的 Gemini 回應

```python
# 【需要挑戰者填寫】完成缺失部分並運行此單元格

# 從 utils 模組調用 "get_gemini_response" 函數以生成帶流輸出的 Gemini 回應。此函數使用多模態 Gemini 模型、文本提示和配置參數，並指示 Gemini 模型使用提供的提示生成回應。由於 Gemini 模型啟用流式傳輸，您將接收作為生成的塊。
# 使用 Markdown 語法格式化流輸出以便於閱讀和轉換為 HTML。

Markdown(
    get_gemini_response(
        multimodal_model,
        model_input=[prompt],
        stream=True,
        generation_config=GenerationConfig(temperature=0.2, max_output_tokens=2048),
    )
)
```

## 驗證

要驗證您的實驗完成：

1. **Task 1.1**: 確保在回應中看到圖像標題和描述
2. **Task 1.2**: 確保看到圖像比較和差異分析
3. **Task 1.3**: 確保生成視頻描述
4. **Task 1.4**: 確保提取視頻中的對象標籤
5. **Task 1.5**: 確保回答視頻相關問題
6. **Task 1.6**: 確保檢索視頻以外的額外信息
7. **Task 2.1**: 確保成功處理文檔元數據
8. **Task 2.2**: 確保創建用戶查詢
9. **Task 2.3**: 確保檢索相關文本塊
10. **Task 2.4**: 確保創建上下文文本
11. **Task 2.5**: 確保從 Gemini 獲取回應

## 故障排除

- **429 錯誤**: 如果遇到 API 速率限制，等待一分鐘後重試
- **認證錯誤**: 確保在 Vertex AI Dashboard 中啟用所有推薦 API
- **內核問題**: 如果 JupyterLab 有問題，重置 Workbench 實例
- **權限錯誤**: 確保您有 Vertex AI API 的適當權限

## 清理

1. 關閉 JupyterLab 標籤
2. 如果需要，停止 Workbench 實例以避免費用

## 額外資源

- [Gemini 多模態概述](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/overview)
- [Vertex AI 中的生成式 AI 文檔](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [檢索增強生成 (RAG) 指南](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/retrieval-augmented-generation)
- 探索 Google Cloud 生成式 AI 儲存庫中的其他 notebooks 和樣本 (https://github.com/GoogleCloudPlatform/generative-ai)
