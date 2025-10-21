# 使用 Vertex AI 的 Imagen 建立 AI 圖片生成器應用程式

## 實驗室概述
這個實驗室將教您如何使用 Google Cloud 的 Vertex AI 平台上的生成式 AI 服務來建立 AI 圖片生成器應用程式。您將學習如何連接到 Vertex AI、使用預訓練的圖片生成模型、發送文字提示並接收 AI 生成的圖片回應。

## 先決條件
- Google Cloud 帳戶和專案
- 啟用 Vertex AI API
- Python 3.7 或更新版本
- Google Cloud SDK (gcloud)
- 基本的 Python 程式設計知識

## 實驗目標
完成這個實驗後，您將能夠：
- **連接到 Vertex AI (Google Cloud AI 平台)**：學習如何使用 Vertex AI SDK 建立與 Google AI 服務的連線
- **載入預訓練的圖片生成模型**：了解如何使用強大的預訓練 AI 模型而無需從頭開始建置
- **向 AI 模型發送文字**：了解如何提供輸入供 AI 處理
- **從 AI 提取圖片回應**：學習處理和解釋 AI 模型生成的圖片回應
- **了解建立 AI 應用程式的基礎知識**：深入了解將 AI 整合到軟體專案的核心概念

## 預估時間
45 分鐘

## 實驗步驟

### 步驟 1：設定環境並連接到 Vertex AI
首先，您需要設定環境並連接到 Vertex AI 服務。

**操作說明：**
1. 開啟 Google Cloud Console
2. 確保您在正確的專案中
3. 啟用 Vertex AI API（如果尚未啟用）
4. 設定驗證憑據

**預期結果：**
能夠成功連接到 Vertex AI 服務並準備使用 AI 模型。

### 步驟 2：建立 Python 腳本
在程式碼編輯器中建立新的 Python 檔案來實作圖片生成器。

**操作說明：**
1. 點擊 **File->New File** 開啟新檔案
2. 複製並貼上提供的程式碼片段到您的檔案中

```python
import argparse

import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

def generate_image(
    project_id: str, location: str, output_file: str, prompt: str
) -> vertexai.preview.vision_models.ImageGenerationResponse:
    """Generate an image using a text prompt.
    Args:
      project_id: Google Cloud project ID, used to initialize Vertex AI.
      location: Google Cloud region, used to initialize Vertex AI.
      output_file: Local path to the output image file.
      prompt: The text prompt describing what you want to see."""

    vertexai.init(project=project_id, location=location)

    model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")

    images = model.generate_images(
        prompt=prompt,
        # Optional parameters
        number_of_images=1,
        seed=1,
        add_watermark=False,
    )

    images[0].save(location=output_file)

    return images

generate_image(
    project_id='"project-id"',
    location='"REGION"',
    output_file='image.jpeg',
    prompt='Create an image of a cricket ground in the heart of Los Angeles',
    )
```

3. 點擊 **File > Save**，輸入 `GenerateImage.py` 作為檔案名稱並點擊 **Save**

**預期結果：**
成功建立包含圖片生成邏輯的 Python 腳本。

### 步驟 3：執行圖片生成腳本
執行 Python 腳本來生成圖片。

**操作說明：**
1. 在程式碼編輯器中點擊三角形圖示執行 Python 檔案
2. 或者在終端機中執行以下命令：
   ```bash
   /usr/bin/python3 /GenerateImage.py
   ```

**預期結果：**
腳本成功執行並生成名為 `image.jpeg` 的圖片檔案。

### 步驟 4：查看生成的圖片
檢查生成的圖片結果。

**操作說明：**
1. 點擊 **EXPLORER > image.jpeg** 查看生成的圖片

**預期結果：**
能夠看到根據文字提示生成的 AI 圖片。

## 驗證
要驗證實驗室是否成功完成：
1. 確認 Python 腳本執行無錯誤
2. 確認生成了 `image.jpeg` 檔案
3. 確認能夠查看生成的圖片
4. 嘗試不同的文字提示來測試 AI 模型的功能

## 故障排除
常見問題與解決方案：
- **API 權限錯誤**：確保已啟用 Vertex AI API 並且帳戶具有適當權限
- **模型載入失敗**：檢查網路連線和專案設定
- **圖片儲存錯誤**：確認輸出目錄存在且具有寫入權限
- **記憶體錯誤**：嘗試減少圖片數量或調整參數

## 清理
為了避免產生費用，請執行以下清理步驟：
1. 刪除生成的圖片檔案（如果不需要保留）
2. 如果建立任何額外資源，請刪除它們
3. 檢查並關閉任何不必要的服務

## 額外資源
- [Vertex AI 官方文檔](https://cloud.google.com/vertex-ai/docs)
- [Imagen 模型文檔](https://cloud.google.com/vertex-ai/docs/generative-ai/image/overview)
- [Python SDK 參考](https://cloud.google.com/python/docs/reference/aiplatform/latest)
- [SynthID 水印技術](https://deepmind.google/technologies/synthid/)

## 程式碼解釋
- 此程式碼載入預訓練的 AI 模型（imagen-3.0-generate-002）
- 呼叫載入模型的 `generate_image` 方法
- 輸入為文字提示
- 程式碼利用 Gemini 的能力理解文字提示並用來建置 AI 圖片

**注意：** 預設會為圖片添加 SynthID 水印，但您可以透過指定選用參數 `add_watermark=False` 來停用它。您無法同時使用種子值和水印。了解更多關於 [SynthID 水印](https://deepmind.google/technologies/synthid/)

**自己嘗試！** 嘗試不同的提示來探索 Gemini 的功能。

## 筆記
這個實驗室展示了如何使用 Google Cloud 的生成式 AI 服務來建立強大的圖片生成應用程式。透過簡單的 Python 程式碼，您可以利用先進的 AI 模型來根據文字描述產生圖片。這是現代 AI 應用程式開發的一個重要基礎。
