# GSP1210 - 使用 Gemini 進行多模態處理

## Lab 概述

此 lab 介紹 [Gemini](https://deepmind.google/technologies/gemini/#introduction)，這是由 Google 開發的多模態生成式 AI 模型系列。您將使用 Gemini API 探索 Gemini Flash 如何基於文字、圖像和視頻理解並生成回應。

Gemini 的多模態功能使其能夠：

- **分析圖像**：檢測物件、理解使用者介面、解釋圖表，並比較視覺相似性和差異。
- **處理視頻**：生成描述、提取標籤和重點，並回答有關視頻內容的問題。

您將通過在 Vertex AI 中使用 Gemini API 的實際任務來體驗這些功能。

## 先決條件

開始此 lab 之前，您應該熟悉：

- 基本 Python 程式設計。
- 一般 API 概念。
- 在 [Vertex AI Workbench](https://cloud.google.com/vertex-ai/docs/workbench/introduction) 上執行 Python 程式碼的 Jupyter notebook。

## 目標

在此 lab 中，您將：

- 在 Vertex AI 中與 Gemini API 互動。
- 使用 Gemini Flash 模型分析圖像和視頻。
- 為 Gemini 提供文字、圖像和視頻提示以生成有資訊的回應。
- 探索 Gemini 多模態功能的實用應用。

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

### 任務 3. 使用 Gemini Flash 模型

Gemini Flash 是一個多模態模型，支援多模態提示。您可以在提示請求中加入文字、圖像和視頻，並取得文字或程式碼回應。

在此任務中，執行指定的 notebook 儲存格以了解如何使用 Gemini Flash 模型。在完成目標時返回此處檢查您的進度。

#### 跨多個圖像的圖像理解

Gemini 的功能之一是能夠跨多個圖像進行推理。在此範例中，您使用 Gemini 通過水果圖像和價格清單計算雜貨總成本。

執行 notebook 的**跨多個圖像的圖像理解**部分。

按一下**檢查我的進度**以驗證目標。

跨多個圖像的圖像理解

#### 生成視頻描述

Gemini 還可以提取整個視頻的標籤，並檢索超出視頻內容的額外資訊。在此範例中，您使用 Gemini 從不同視頻中提取標籤並檢索額外資訊：

執行 notebook 的**生成視頻描述**部分。

按一下**檢查我的進度**以驗證目標。

生成視頻描述

#### 音頻理解

Gemini 可以直接處理音頻以進行長語境理解。在此範例中，您使用 Gemini 處理音頻以進行長語境理解：

執行 notebook 的**音頻理解**部分。

按一下**檢查我的進度**以驗證目標。

音頻理解

#### 跨程式碼庫推理

Gemini 可以直接處理音頻以進行長語境理解。在此範例中，您使用 Gemini 處理音頻以進行長語境理解：

執行 notebook 的**跨程式碼庫推理**部分。

按一下**檢查我的進度**以驗證目標。

跨程式碼庫推理

#### 視頻和音頻理解

在此範例中，您體驗 Gemini 在視頻與音頻輸入交錯上的原生多模態和長語境功能。：

執行 notebook 的**視頻和音頻理解**部分。

按一下**檢查我的進度**以驗證目標。

視頻和音頻理解

#### 一次處理所有模態（圖像、視頻、音頻、文字）

Gemini 原生就是多模態的，並支援在相同輸入序列中交錯來自不同模態的資料。在此範例中，您在相同輸入序列中嘗試混合音頻、視覺、文字和程式碼輸入。

執行 notebook 的**一次處理所有模態（圖像、視頻、音頻、文字）**部分。

按一下**檢查我的進度**以驗證目標。

一次處理所有模態（圖像、視頻、音頻、文字）

#### 基於提供的圖像生成推薦

Gemini 能夠進行圖像比較並提供推薦。這對於希望根據使用者當前設定提供產品推薦的零售公司特別有用。

執行 notebook 的**基於提供的圖像生成推薦**部分。

按一下**檢查我的進度**以驗證目標。

基於提供的圖像生成推薦

#### 理解技術圖表中的實體關係

Gemini 具備多模態功能，使其能夠理解圖表並採取行動步驟，例如最佳化或程式碼生成。在此範例中，您將看到 Gemini 如何解密實體關係 (ER) 圖表，理解表格之間的關係，識別在特定環境（如 BigQuery）中的最佳化需求，甚至生成相應的程式碼。

執行 notebook 的**理解技術圖表中的實體關係**部分。

按一下**檢查我的進度**以驗證目標。

理解技術圖表中的實體關係

#### 比較圖像相似性和差異

Gemini 可以比較圖像並識別物件之間的相似性或差異。在此範例中，您使用 Gemini 比較同一地點的兩張圖像，並識別它們之間的差異。

執行 notebook 的**比較圖像相似性和差異**部分。

按一下**檢查我的進度**以驗證目標。

比較圖像相似性和差異

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
2. 刪除任何手動建立的 Cloud Storage 儲存貯體（如果有）
3. 停止 Vertex AI Workbench 執行個體（如果不是臨時執行個體）

## 額外資源

- [Gemini 總覽](https://deepmind.google/technologies/gemini/)
- [Vertex AI 上的生成式 AI 文件](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [YouTube 上的生成式 AI](https://www.youtube.com/@googlecloudtech/)
- 探索 Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) 以取得生成式 AI 的精選、可搜尋 notebook 資源庫
- 探索 [Google Cloud 生成式 AI 存放區](https://github.com/GoogleCloudPlatform/generative-ai) 中的其他 notebook 和範例

## 恭喜！

您現在已經完成了 lab！在此 lab 中，您學習了如何使用 Vertex AI 中的 Gemini API 從文字和圖像提示生成文字。

## 下一步 / 深入瞭解

查看以下資源以深入瞭解 Gemini：

- [Gemini 總覽](https://deepmind.google/technologies/gemini/)
- [Vertex AI 上的生成式 AI 文件](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [YouTube 上的生成式 AI](https://www.youtube.com/@googlecloudtech/)
- 探索 Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) 以取得生成式 AI 的精選、可搜尋 notebook 資源庫
- 探索 [Google Cloud 生成式 AI 存放區](https://github.com/GoogleCloudPlatform/generative-ai) 中的其他 notebook 和範例

---

**原始 Lab 連結**: https://www.skills.google/paths/1284/course_templates/981/labs/597908
**GSP 編號**: GSP1210
**完成日期**: 2025-11-05
**檔案位置**: intermediate/Explore-Generative-AI-with-the-Gemini-API-in-Vertex-AI/GSP1210-Multimodality-with-Gemini/
