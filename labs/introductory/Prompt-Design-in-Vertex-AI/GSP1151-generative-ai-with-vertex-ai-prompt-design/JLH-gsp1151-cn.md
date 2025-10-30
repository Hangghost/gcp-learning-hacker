# GSP1151 - 使用 Vertex AI 的生成式 AI：提示設計

## 實驗概述
此實驗探討了提示工程和設計有效提示的最佳實踐，以改善您的 LLM 生成回應的品質。您將學習如何設計簡潔、具體且定義良好的提示，專注於一次處理一個任務。本實驗還涵蓋了進階技巧，如將生成性任務轉換為分類任務，並使用範例來增強回應品質。如需進一步探索，請參考[官方提示設計文件](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/introduction-prompt-design)。

## Gemini 介紹

[Gemini](https://deepmind.google/technologies/gemini/) 是 Google DeepMind 開發的強大生成式 AI 模型系列，能夠理解和生成各種形式的內容，包括文字、程式碼、影像、音訊和影片。

### Vertex AI 中的 Gemini API

Vertex AI 中的 Gemini API 提供統一介面，可讓開發人員輕鬆整合這些強大的 AI 功能到他們的應用程式。如需最新詳細資訊和具體功能，請參考官方 [Gemini 文件](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models#gemini-models)。

### Gemini 模型

- [**Gemini Pro**](https://deepmind.google/technologies/gemini/pro/)：專為複雜推理設計，包括：
  - 分析和總結大量資訊
  - 複雜跨模態推理（跨文字、程式碼、影像等）
  - 處理複雜程式碼庫的有效問題解決

- [**Gemini Flash**](https://deepmind.google/technologies/gemini/flash/)：針對速度和效率進行優化，提供：
  - 亞秒級回應時間和高吞吐量
  - 廣泛任務的較低成本下高品質
  - 增強的多模態功能，包括改善的空間理解、新輸出模態（文字、音訊、影像）和原生工具使用（Google 搜尋、程式碼執行和第三方功能）

## 先決條件

開始此實驗前，您應熟悉：

- Python 程式設計基礎
- 一般 API 概念
- 在 [Vertex AI Workbench](https://cloud.google.com/vertex-ai/docs/workbench/introduction) 上執行 Python 程式碼的 Jupyter notebook

## 學習目標

在此實驗中，您將學習如何：

- 使用 Google Gen AI SDK 開始提示工程
- 應用提示設計的最佳實踐，包括簡潔性、具體性和任務定義
- 探索使用 Google Gen AI SDK 的各種文字生成使用案例，例如：
  - 創意發想
  - 問題解答
  - 文字分類
  - 文字提取
  - 文字總結

## 估計時間
45 分鐘

## 實驗步驟

### 任務 1. 在 Vertex AI Workbench 中開啟 notebook

1. 在 Google Cloud 主控台的**導覽選單**() 中，按一下 **Vertex AI > Workbench**。

2. 找到 `Workbench instance name` 實例並按一下 **Open JupyterLab** 按鈕。

JupyterLab 介面會在新瀏覽器分頁中開啟此 Workbench 實例。

**注意：**如果您在 JupyterLab 中沒有看到 notebooks，請遵循這些額外步驟來重設實例：

1. 關閉 JupyterLab 的瀏覽器分頁，並返回 Workbench 首頁。

2. 選取實例名稱旁邊的核取方塊，並按一下**重設**。

3. 在 **Open JupyterLab** 按鈕重新啟用後，等待一分鐘，然後按一下 **Open JupyterLab**。

### 任務 2. 設定 notebook

1. 開啟 `notebook name` 檔案。

2. 在**選取核心**對話方塊中，從可用核心列表中選擇 **Python 3**。

3. 執行 notebook 的**開始**區段。專案 ID 和位置已為您預先設定。

**注意：**如果您從 notebook 單元格執行時遇到 429 回應，請等待一分鐘後重新執行單元格以繼續。

按一下**檢查我的進度**來驗證目標。

安裝套件和匯入程式庫

### 任務 3. 提示工程最佳實踐

提示工程就是如何設計您的提示，讓回應確實是您希望看到的。使用「不花俏」提示的想法是將提示中的雜訊降到最低，以減少 LLM 誤解提示意圖的可能性。下面是在設計提示時的一些指導原則。

在本區段中，您將涵蓋以下設計提示的最佳實踐：

- 保持簡潔
- 保持具體且定義良好
- 一次只問一個任務
- 透過包含範例來改善回應品質
- 將生成性任務轉換為分類任務以改善安全性

1. 執行 notebook 的**保持簡潔**區段。

按一下**檢查我的進度**來驗證目標。

保持簡潔

1. 執行 notebook 的**保持具體且定義良好**區段。

按一下**檢查我的進度**來驗證目標。

保持具體且定義良好

1. 執行 notebook 的**一次只問一個任務**區段。

按一下**檢查我的進度**來驗證目標。

一次只問一個任務

1. 執行 notebook 的**注意幻覺**區段。

按一下**檢查我的進度**來驗證目標。

注意幻覺

### 任務 4. 減少輸出變異性

如何嘗試減少無關回應和幻覺的機會？一種方法是為 LLM 提供[系統指令](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/prompts/system-instruction-introduction)。在本區段中，您將看到系統指令如何運作，以及如何使用它們來防止模型產生無關問題或幻覺，以保護旅行聊天機器人。

1. 執行 notebook 的**使用系統指令來保護模型免於產生無關回應**區段。

按一下**檢查我的進度**來驗證目標。

使用系統指令來保護模型免於產生無關回應

1. 執行 notebook 的**將生成性任務轉換為分類任務以減少輸出變異性**區段。

按一下**檢查我的進度**來驗證目標。

生成性任務導致較高的輸出變異性

1. 執行 notebook 的**分類任務減少輸出變異性**區段。

按一下**檢查我的進度**來驗證目標。

分類任務減少輸出變異性

### 任務 5. 透過包含範例來改善回應品質

改善回應品質的另一種方法是在您的提示中加入範例。LLM 會從範例中進行情境學習，了解如何回應。通常，一到五個範例（shots）就足以改善回應品質。包含太多範例可能會導致模型過度擬合資料並降低回應品質。

與傳統模型訓練類似，範例的品質和分佈非常重要。挑選代表您需要模型學習的場景的範例，並保持範例分佈（例如分類情況下的每個類別範例數）與您的實際分佈一致。

1. 執行 notebook 的**透過包含範例來改善回應品質**區段。

按一下**檢查我的進度**來驗證目標。

透過包含範例來改善回應品質

## 驗證
完成所有 notebook 區段的執行，並成功通過所有檢查點。

## 故障排除

### 常見問題
- **429 錯誤回應**：如果遇到 API 速率限制，請等待 1 分鐘後重試
- **核心未啟動**：確保在 JupyterLab 中選擇 Python 3 核心
- **套件安裝失敗**：檢查網路連線並重試

## 清理
此實驗主要在 Vertex AI Workbench 中執行 notebook，不需要特別的清理步驟。Workbench 實例將在一段時間後自動停止以節省成本。

## 額外資源

- [Gemini 總覽](https://deepmind.google/technologies/gemini/)
- [Vertex AI 上的生成式 AI 文件](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview)
- [YouTube 上的生成式 AI](https://www.youtube.com/@googlecloudtech/)
- 探索 Vertex AI [食譜](https://cloud.google.com/vertex-ai/generative-ai/docs/cookbook)，尋找生成式 AI 的精選、可搜尋 notebooks 圖書館
- 在 [Google Cloud 生成式 AI 儲存庫](https://github.com/GoogleCloudPlatform/generative-ai)中探索其他 notebooks 和範例

## 筆記
- 此實驗專注於提示工程的最佳實踐
- Gemini 模型提供了文字和多模態功能
- 系統指令有助於減少幻覺和無關回應
- 範例可以顯著改善模型回應品質
