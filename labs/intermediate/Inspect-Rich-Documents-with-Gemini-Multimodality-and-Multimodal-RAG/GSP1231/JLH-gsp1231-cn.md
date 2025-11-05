# GSP1231 - 使用 Gemini API 在 Vertex AI 中進行多模態檢索增強生成 (RAG)

## 實驗概述
Gemini 是由 Google DeepMind 開發的生成式 AI 模型家族，專為多模態使用案例設計。

檢索增強生成 (RAG) 已成為一種流行範式，用於使 LLM 能夠訪問外部數據，並作為一種機制來防止幻覺。RAG 模型被訓練來從大型語料庫中檢索相關文檔，然後基於檢索到的文檔生成回應。在這個實驗中，您將學習如何執行多模態 RAG，其中您對一個充滿文本和圖像的財務文檔執行問答。

## 比較基於文本和多模態的 RAG

多模態 RAG 相對於基於文本的 RAG 提供了幾個優勢：

1. **增強知識訪問**：多模態 RAG 可以訪問和處理文本和視覺信息，為 LLM 提供更豐富和更全面的知識庫。

2. **改進推理能力**：通過整合視覺線索，多模態 RAG 可以跨不同類型的數據模態做出更好的推理。

這個實驗向您展示如何使用 Vertex AI 中的 Gemini API、文本嵌入和多模態嵌入來構建文檔搜索引擎。

## 先決條件
開始這個實驗之前，您應該熟悉：

- 基本的 Python 編程
- 一般的 API 概念
- 在 Vertex AI Workbench 上運行 Jupyter notebook 中的 Python 代碼

## 目標
在本實驗中，您將學習如何：

- 提取和存儲包含文本和圖像的文檔元數據，並為文檔生成嵌入
- 使用文本查詢搜索元數據以查找相似的文本或圖像
- 使用圖像查詢搜索元數據以查找相似的圖像
- 使用文本查詢作為輸入，使用文本和圖像搜索上下文答案

## 估計時間
90 分鐘

## 實驗步驟

### 步驟 1: 在 Vertex AI Workbench 中打開 notebook

1. 在 Google Cloud 主控台中，在導航選單 () 上點擊 Vertex AI > Workbench。

    [導航選單圖標](https://cdn.qwiklabs.com/tkgw1TDgj4Q%2BYKQUW4jUFd0O5OEKlUMBRYbhlCrF0WY%3D)

2. 找到 `Workbench instance name` 實例並點擊 Open JupyterLab 按鈕。

JupyterLab 介面為您的 Workbench 實例在新瀏覽器標籤中打開。

**注意：** 如果您在 JupyterLab 中沒有看到 notebooks，請遵循以下額外步驟來重置實例：

1. 關閉 JupyterLab 的瀏覽器標籤，並返回 Workbench 主頁。

2. 選取實例名稱旁邊的核取方塊，然後點擊 Reset。

3. 在 Open JupyterLab 按鈕重新啟用後，等待一分鐘，然後點擊 Open JupyterLab。

### 步驟 2: 設定 notebook

1. 打開 `notebook name` 文件。

2. 在 Select Kernel 對話框中，從可用內核列表中選擇 Python 3。

3. 運行 notebook 的 Getting Started 部分。專案 ID 和位置已為您預先配置。

**注意：** 如果您遇到任何 notebook 單元執行中的 429 回應，請等待一分鐘然後重新運行單元以繼續。

點擊 Check my progress 來驗證目標。

安裝 Gen AI SDK for Python 並匯入函式庫

在以下部分，您將運行 notebook 單元來查看如何使用 Gemini API 構建多模態 RAG 系統。

### 步驟 3: 下載自定義 Python 實用工具和所需文件

在本節中，您將下載一些幫助函數來改進 notebook 的可讀性。這些函數使用 `model name` (`model id`) 模型，該模型專為自然語言任務、多輪文本和代碼聊天以及代碼生成設計。您也可以直接在 GitHub 上查看代碼 (`intro_multimodal_rag_utils.py`)。

1. 在這個任務中，運行 notebook 單元來加載模型並下載幫助函數，並從 Cloud Storage 獲取文檔和圖像。

點擊 Check my progress 來驗證目標。

從 Cloud Storage 下載圖像和文檔

### 步驟 4: 構建包含文本和圖像的文檔元數據

您在本實驗中使用的源數據是 Google-10K 的修改版本，它提供了公司財務績效、業務運營、管理和風險因素的全面概述。由於原始文檔相當大，您將使用只有 14 頁的修改版本，分成兩部分 - Part 1 和 Part 2。雖然被截斷，但示例文檔仍然包含文本以及圖表、圖表和圖形等圖像。

1. 在這個任務中，運行 notebook 單元來從文檔中提取和存儲文本和圖像的元數據。

**注意：** 提取和存儲文檔中文本和圖像元數據的單元可能需要幾分鐘才能完成。

點擊 Check my progress 來驗證目標。

從文檔中提取和存儲文本和圖像的元數據

### 步驟 5: 文本搜索

讓我們從一個簡單的問題開始，看看簡單的文本搜索使用文本嵌入是否能回答它。預期答案是顯示 Google 不同股份類型的每股基本和稀釋淨收入價值。

1. 在這個任務中，運行 notebook 單元來使用文本查詢搜索相似的文本和圖像。

點擊 Check my progress 來驗證目標。

文本搜索

### 步驟 6: 圖像搜索

想像一下搜索圖像，但不是輸入單詞，而是使用實際圖像作為線索。您有一個表格顯示兩年的收入成本數字，您想要從同一文檔或多個文檔中找到看起來像它的其他圖像。

使用 Gemini 和嵌入驅動的基於用戶輸入識別相似文本和圖像的能力，形成多模態 RAG 系統的關鍵基礎，您將在下一個任務中探索它。

1. 在這個任務中，運行 notebook 單元來使用圖像查詢搜索相似的圖像。

**注意：** 您可能需要等待幾分鐘來獲得這個任務的分數。

點擊 Check my progress 來驗證目標。

圖像搜索

### 比較推理

想像我們有一個圖表顯示 Class A Google 股份如何與 S&P 500 或其他科技公司等其他事物進行比較。您想要知道 Class C 股份與該圖表相比表現如何。不是僅僅找到另一個相似的圖像，您可以要求 Gemini 比較相關圖像並告訴您哪種股票可能對您來說更好投資。Gemini 會解釋它為什麼這樣想。

1. 在這個任務中，運行 notebook 單元來比較兩個圖像並找到最相似的圖像。

點擊 Check my progress 來驗證目標。

比較推理

### 步驟 7: 多模態檢索增強生成 (RAG)

讓我們將所有內容整合起來來實現多模態 RAG。您使用在前幾節中探索的所有元素來實現多模態 RAG。這些是步驟：

- **步驟 1：** 用戶以文本格式給出查詢，其中預期信息可在文檔中獲得，並嵌入在圖像和文本中。

- **步驟 2：** 使用類似於您在 `Text Search` 中探索的方法，從文檔頁面中找到所有文本塊。

- **步驟 3：** 基於用戶查詢與 `image_description` 匹配，使用與您在 `Image Search` 中探索的相同方法，從頁面中找到所有相似的圖像。

- **步驟 4：** 將在步驟 2 和 3 中找到的所有相似文本和圖像作為 `context_text` 和 `context_images` 組合。

- **步驟 5：** 在 Gemini 的幫助下，我們可以將用戶查詢與在步驟 2 和 3 中找到的文本和圖像上下文一起傳遞。您也可以添加模型在回答用戶查詢時應該記住的特定指示。

- **步驟 6：** Gemini 產生答案，您可以打印引用來檢查用於解決查詢的所有相關文本和圖像。

1. 在這個任務中，運行 notebook 單元來執行多模態 RAG。

**注意：** 您可能需要等待幾分鐘來獲得這個任務的分數。

點擊 Check my progress 來驗證目標。

打印引用來檢查所有相關文本和圖像

## 驗證
完成所有 notebook 任務並成功運行所有單元格。

## 故障排除
- **429 錯誤**: 如果遇到 API 速率限制，等待一分鐘後重試
- **內核問題**: 如果 JupyterLab 有問題，重置 Workbench 實例
- **權限錯誤**: 確保您有 Vertex AI API 的適當權限
- **記憶體問題**: RAG 處理可能需要大量記憶體，確保實例有足夠資源

## 清理
1. 關閉 JupyterLab 標籤
2. 如果需要，停止 Workbench 實例以避免費用
3. 刪除任何臨時創建的 Cloud Storage 桶

## 額外資源
- [Gemini 概述](https://deepmind.google/technologies/gemini/)
- [文本嵌入文檔](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/text-embeddings)
- [多模態嵌入文檔](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/multimodal-embeddings)
- [Google-10K 示例文檔 Part 1](https://storage.googleapis.com/github-repo/rag/intro_multimodal_rag/intro_multimodal_rag_old_version/data/google-10k-sample-part1.pdf)
- [Google-10K 示例文檔 Part 2](https://storage.googleapis.com/github-repo/rag/intro_multimodal_rag/intro_multimodal_rag_old_version/data/google-10k-sample-part2.pdf)
- [多模態 RAG 實用工具 GitHub](https://raw.githubusercontent.com/GoogleCloudPlatform/generative-ai/main/gemini/use-cases/retrieval-augmented-generation/utils/intro_multimodal_rag_utils.py)
- [Generative AI on Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [Generative AI on YouTube](https://www.youtube.com/@googlecloudtech/)
- Explore the Vertex AI [Cookbook](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook) for a curated, searchable gallery of notebooks for Generative AI
- Explore other notebooks and samples in the Google Cloud Generative AI repository (https://github.com/GoogleCloudPlatform/generative-ai)

## 筆記
這個實驗展示了如何使用 Gemini API 構建多模態 RAG 系統。重點包括：
- 文本和圖像元數據提取
- 嵌入生成和相似性搜索
- 多模態上下文整合
- 使用 Gemini 進行增強的問答

RAG 系統通過整合外部知識來顯著改進 LLM 的準確性和可靠性。
