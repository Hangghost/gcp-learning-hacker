# GSP1227 - 使用 Gemini 進行函數呼叫簡介

## Lab 概述

函數呼叫讓開發人員能夠在程式碼中建立函數描述，然後在請求中將該描述傳遞給語言模型。模型的回應會包含符合描述的函數名稱以及呼叫它的引數。

函數呼叫類似於 Vertex AI Extensions，因為它們都會生成有關函數的資訊。兩者之間的差異在於函數呼叫會傳回包含函數名稱和要在程式碼中使用的引數的 JSON 資料，而 Vertex AI Extensions 會傳回函數並為您呼叫它。

## Gemini 介紹

[Gemini](https://deepmind.google/technologies/gemini/) 是由 Google DeepMind 開發的強大生成式 AI 模型系列，能夠理解和生成各種形式的內容，包括文字、程式碼、圖像、音頻和視頻。

### Vertex AI 中的 Gemini API

Vertex AI 中的 Gemini API 提供了與 Gemini 模型互動的統一介面。這讓開發人員能夠輕鬆將這些強大的 AI 功能整合到他們的應用程式中。如需最新版本的最詳細資訊和具體功能，請參閱官方 [Gemini 文件](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models#gemini-models)。

### Gemini 模型

- [**Gemini Pro**](https://deepmind.google/technologies/gemini/pro/)：專為複雜推理設計，包括：
  - 分析和總結大量資訊。
  - 複雜的跨模態推理（跨文字、程式碼、圖像等）。
  - 使用複雜程式碼庫進行有效的問題解決。

- [**Gemini Flash**](https://deepmind.google/technologies/gemini/flash/)：針對速度和效率進行最佳化，提供：
  - 亞秒級回應時間和高吞吐量。
  - 針對廣泛任務以更低的成本提供高品質。
  - 增強的多模態功能，包括改進的空間理解、新輸出模態（文字、音頻、圖像）和原生工具使用（Google 搜尋、程式碼執行和第三方函數）。

## 先決條件

開始此 lab 之前，您應該熟悉：

- 基本 Python 程式設計。
- 一般 API 概念。
- 在 [Vertex AI Workbench](https://cloud.google.com/vertex-ai/docs/workbench/introduction) 上執行 Python 程式碼的 Jupyter notebook。

## 目標

在此 lab 中，您將學習如何：

- 安裝適用於 Python 的 Google Gen AI SDK
- 在 Vertex AI 中使用 Gemini API 與 Gemini 2.0 Flash (`gemini-2.0-flash`) 模型互動：
  - 從文字提示生成函數呼叫，以幫助客戶獲取 Google Store 中產品的資訊
  - 從文字提示生成函數呼叫並呼叫外部 API 以地理編碼地址
  - 從文字提示生成函數呼叫以從日誌資料中提取實體

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
3. 執行 notebook 的**開始使用**和**匯入程式庫**部分。
   - 對於**專案 ID**，使用 `Project ID`，對於**位置**，使用 `Region`。

**注意：**您可以跳過任何標記為 *Colab only* 的 notebook 儲存格。如果您從 notebook 儲存格執行時遇到 429 回應，請等候 1 分鐘再執行儲存格以繼續進行。

在以下部分中，您將執行 notebook 儲存格以了解如何在 Vertex AI 中搭配 Google Gen AI SDK for Python 使用 Gemini API。

按一下**檢查我的進度**以驗證目標。

安裝 Gen AI SDK for Python 和匯入程式庫

### 任務 3. 使用函數呼叫進行結構化 Google Store 查詢

在使用生成式文字模型時，很難強制 LLM 以 JSON 等結構化格式提供一致的回應。函數呼叫讓使用 LLM 變得容易，可以通過提示和非結構化輸入，並讓 LLM 傳回可用於呼叫外部函數的結構化回應。

您可以將函數呼叫視為一種從使用者提示和函數定義中獲取結構化輸出的方式，使用該結構化輸出向外部系統發出 API 請求，然後將函數回應傳回給 LLM 以生成對使用者的回應。換言之，Gemini 中的函數呼叫從使用者傳來的非結構化文字或訊息中提取結構化參數。在此範例中，您將使用函數呼叫搭配 Gemini 模型中的聊天模態來幫助客戶獲取 Google Store 中產品的資訊。

1. 在此任務中，執行 notebook 儲存格以了解如何使用 Gemini 模型來幫助客戶獲取 Google Store 中產品的資訊。

按一下**檢查我的進度**以驗證目標。

生成簡單的函數呼叫

### 任務 4. 使用函數呼叫通過地圖 API 地理編碼地址

在此範例中，您將使用 Gemini API 中的文字模態來定義一個函數，該函數將多個參數作為輸入。您將使用函數呼叫回應來發出即時 API 呼叫，將地址轉換為緯度和經度座標。

1. 在此任務中，執行 notebook 儲存格以了解如何使用 Gemini Flash 模型生成函數呼叫來地理編碼地址。

此處我們使用了 [OpenStreetMap Nominatim API](https://nominatim.openstreetmap.org/ui/search.html) 來地理編碼地址，以便在此 notebook 中輕鬆使用和學習。如果您處理大量地圖或地理位置資料，可以使用 [Google Maps Geocoding API](https://developers.google.com/maps/documentation/geocoding)。

按一下**檢查我的進度**以驗證目標。

生成複雜的函數呼叫

### 任務 5. 使用函數呼叫進行實體提取

在前面的範例中，您使用了 Gemini Function Calling 中的實體提取功能，以便將產生的參數傳遞給 REST API 或用戶端程式庫。然而，您可能只想使用 Gemini Function Calling 執行實體提取步驟，而不實際呼叫 API。您可以將此功能視為一種便利的方式，將非結構化文字資料轉換為結構化欄位。

在此範例中，您將建置一個日誌提取器，它將原始日誌資料轉換為結構化資料，其中包含錯誤訊息的詳細資訊。

1. 在此任務中，執行 notebook 儲存格以了解如何使用 Gemini Flash 模型生成函數呼叫來從日誌資料中提取實體。

按一下**檢查我的進度**以驗證目標。

從聊天提示生成函數呼叫

## 驗證

完成所有 notebook 任務並成功執行所有儲存格後，您就成功完成了此 lab。

## 疑難排解

常見問題和解決方案：

- **429 回應錯誤**：如果遇到 API 速率限制，請等候一分鐘後重試
- **Notebook 未載入**：重設 Vertex AI Workbench 執行個體
- **權限錯誤**：確保您的服務帳戶具有適當的 Vertex AI 權限
- **函數呼叫失敗**：檢查函數定義是否正確，並確保參數匹配

## 清理

此 lab 使用 Vertex AI Workbench managed 服務，大部分資源會在工作階段結束時自動清理。如需手動清理：

1. 關閉所有未使用的 Jupyter notebook
2. 刪除任何手動建立的測試資料
3. 停止 Vertex AI Workbench 執行個體（如果不是臨時執行個體）

## 額外資源

- [Gemini 總覽](https://deepmind.google/technologies/gemini/)
- [Vertex AI 上的生成式 AI 文件](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [YouTube 上的生成式 AI](https://www.youtube.com/@googlecloudtech/)
- 探索 Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) 以取得生成式 AI 的精選、可搜尋 notebook 資源庫
- 探索 [Google Cloud 生成式 AI 存放區](https://github.com/GoogleCloudPlatform/generative-ai) 中的其他 notebook 和範例

## 恭喜！

恭喜！在此 lab 中，您學習了如何使用 Vertex AI 中的 Gemini API 從文字提示生成函數呼叫。您使用了 Gemini Flash 模型來生成函數呼叫，以幫助客戶獲取 Google Store 中產品的資訊、地理編碼地址以及從日誌資料中提取實體。

## 下一步 / 深入瞭解

查看以下資源以深入瞭解 Gemini：

- [Gemini 總覽](https://deepmind.google/technologies/gemini/)
- [Vertex AI 上的生成式 AI 文件](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [YouTube 上的生成式 AI](https://www.youtube.com/@googlecloudtech/)
- 探索 Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) 以取得生成式 AI 的精選、可搜尋 notebook 資源庫
- 探索 [Google Cloud 生成式 AI 存放區](https://github.com/GoogleCloudPlatform/generative-ai) 中的其他 notebook 和範例

---

**原始 Lab 連結**: https://www.skills.google/paths/1284/course_templates/981/labs/597908
**GSP 編號**: GSP1227
**完成日期**: 2025-11-05
**檔案位置**: intermediate/Explore-Generative-AI-with-the-Gemini-API-in-Vertex-AI/GSP1227-Introduction-to-Function-Calling-with-Gemini/
