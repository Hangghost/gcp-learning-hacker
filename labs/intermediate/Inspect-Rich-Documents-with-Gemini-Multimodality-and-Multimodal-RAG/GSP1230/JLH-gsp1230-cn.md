# GSP1230 - 使用 Gemini 進行多模態零售推薦

## 實驗概述
Gemini 是由 Google DeepMind 開發的生成式 AI 模型家族，專為多模態使用案例設計。

對於零售公司，推薦系統可以改善客戶體驗，從而增加銷售。在這個實驗中，您將學習如何使用 Gemini 模型快速建立多模態推薦系統。Gemini 模型可以使用多模態模型提供推薦和解釋。

在本實驗中，您將從一個場景（例如客廳）開始，使用 Gemini 模型執行視覺理解。您還將調查如何使用 Gemini 模型從家具項目列表中推薦一個項目（例如椅子）作為輸入。

## Gemini 概述

### Gemini API 在 Vertex AI 中
Vertex AI 中的 Gemini API 提供統一介面來與 Gemini 模型互動。這允許開發人員輕鬆整合這些強大的 AI 功能到他們的應用程式。有關最新版本的詳細資訊和具體功能，請參考官方 [Gemini 文檔](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models#gemini-models)。

### Gemini 模型

- [**Gemini Pro**](https://deepmind.google/technologies/gemini/pro): 專為複雜推理設計，包括：
  - 分析和總結大量資訊
  - 複雜的跨模態推理（跨文本、代碼、圖像等）
  - 使用複雜代碼庫的有效問題解決

- [**Gemini Flash**](https://deepmind.google/technologies/gemini/flash): 針對速度和效率優化，提供：
  - 亞秒級回應時間和高吞吐量
  - 廣泛任務的較低成本的高品質
  - 增強的多模態功能，包括改進的空間理解、新輸出模態（文本、音頻、圖像）和原生工具使用（Google 搜尋、代碼執行和第三方功能）

## 先決條件
開始這個實驗之前，您應該熟悉：

- 基本的 Python 編程
- 一般的 API 概念
- 在 [Vertex AI Workbench](https://cloud.google.com/vertex-ai/docs/workbench/introduction) 上運行 Python 代碼在 Jupyter notebook 中

## 目標
在本實驗中，您將學習如何：

- 使用 Gemini 模型 (`model_id`) 執行視覺理解
- 在提示 Gemini 模型時考慮多模態
- 使用 Gemini 模型建立零售推薦應用程式

## 估計時間
60 分鐘

## 實驗步驟

### 步驟 1: 在 Vertex AI Workbench 中打開 notebook

1. 在 Google Cloud 主控台中，在 **導航選單** () 上點擊 **Vertex AI > Workbench**。

    [導航選單圖標](https://cdn.qwiklabs.com/tkgw1TDgj4Q%2BYKQUW4jUFd0O5OEKlUMBRYbhlCrF0WY%3D)

2. 找到 `Workbench instance name` 實例並點擊 **Open JupyterLab** 按鈕。

JupyterLab 介面為您的 Workbench 實例在新瀏覽器標籤中打開。

**注意：** 如果您在 JupyterLab 中沒有看到 notebooks，請遵循以下額外步驟重置實例：

1. 關閉 JupyterLab 的瀏覽器標籤，並返回 Workbench 主頁。

2. 選取實例名稱旁邊的核取方塊，然後點擊 **Reset**。

3. 在 **Open JupyterLab** 按鈕重新啟用後，等待一分鐘，然後點擊 **Open JupyterLab**。

### 步驟 2: 設定 notebook

1. 打開 `notebook name` 文件。

2. 在 **Select Kernel** 對話框中，從可用內核列表中選擇 **Python 3**。

3. 運行 notebook 的 **Getting Started** 部分。專案 ID 和位置已為您預先配置。

**注意：** 如果您遇到任何 notebook 單元執行中的 429 回應，請等待一分鐘然後重新運行單元以繼續。

點擊 **Check my progress** 來驗證目標。

安裝 Gen AI SDK for Python 並匯入函式庫

在以下部分，您將運行 notebook 單元來查看如何使用 Gemini 模型的多模態功能。

### 步驟 3: 使用 Gemini 模型

Gemini 模型 (`model_id`) 是一個多模態模型，支持在文本或聊天提示中添加圖像和視頻以獲取文本回應。

1. 在這個任務中，運行 notebook 單元來查看如何使用 Gemini 模型詳細描述房間從其圖像，結合單個提示中的文本和圖像。

點擊 **Check my progress** 來驗證目標。

使用 Gemini 模型描述房間

### 步驟 4: 基於內建知識生成開放推薦

使用相同的圖像，您可以要求模型推薦一個適合的家具件以及房間的描述。請注意，在這種情況下，模型可以**推薦任何家具**，並且可以僅從其內建知識中這樣做。

1. 使用相同的圖像，運行 notebook 單元來查看如何使用 Gemini 模型推薦一個適合房間的家具件，以及房間的描述。

點擊 **Check my progress** 來驗證目標。

使用 Gemini 模型推薦一個家具件

### 步驟 5: 基於提供的圖像生成推薦

除了保持推薦開放之外，您還可以提供項目列表供模型從中選擇。這對於零售公司特別有用，他們希望根據用戶的房間和商店提供的可用項目為用戶提供推薦。

1. 在這個任務中，運行 notebook 單元來查看如何使用 Gemini 模型從項目列表中推薦一個家具件。

點擊 **Check my progress** 來驗證目標。

使用 Gemini 模型從選擇中推薦一個項目

## 驗證
完成所有 notebook 任務並成功運行所有單元格。

## 故障排除
- **429 錯誤**: 如果遇到 API 速率限制，等待一分鐘後重試
- **內核問題**: 如果 JupyterLab 有問題，重置 Workbench 實例
- **權限錯誤**: 確保您有 Vertex AI API 的適當權限

## 清理
1. 關閉 JupyterLab 標籤
2. 如果需要，停止 Workbench 實例以避免費用

## 額外資源
- [Gemini 概述](https://deepmind.google/technologies/gemini/)
- [Vertex AI 中的生成式 AI 文檔](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [YouTube 上的生成式 AI](https://www.youtube.com/@googlecloudtech/)
- 探索 Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) 以獲取生成式 AI 的精選、可搜尋的 notebooks 圖書館
- 探索 Google Cloud 生成式 AI 儲存庫中的其他 notebooks 和樣本 (https://github.com/GoogleCloudPlatform/generative-ai)

## 筆記
這個實驗展示了如何使用 Gemini 的多模態功能建立零售推薦系統。您可以使用類似方法來：
- 基於場合或場地圖像推薦衣服
- 基於房間和設定推薦壁紙
