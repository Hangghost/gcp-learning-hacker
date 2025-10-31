# GSP519 - Prompt Design in Vertex AI: Challenge Lab 完整指南

## 挑戰實驗室概述

這是一個 **Challenge Lab**，您不會獲得逐步指示，而是需要運用在課程中學到的技能來完成任務。自動評分系統會檢查您的任務是否正確完成。

### 挑戰場景
您是一家專注於自然世界教育內容的創業公司成員。您與 Cymbal Direct（一家線上零售商）合作，他們正在推出新系列的戶外裝備和服飾，旨在鼓勵年輕人探索並與自然連結。

您的任務是協助他們在 Google Cloud 的 Vertex AI 平台上開發一套工具，用於生成：
- **生動的產品描述**：使用圖像分析來啟發簡短、描述性的文字，捕捉產品的本質和置身自然的感覺
- **吸引人的標語**：專注於突出產品特點、目標受眾和期望的情感回應

### 測試主題
- 在 Vertex AI Studio 中製作有效提示並使用參數來指導生成式 AI 輸出
- 應用 Gemini 模型在真實世界行銷場景中創建產品描述和標語
- 檢查並執行從 Vertex AI Studio 匯出的 Python 程式碼，以獲得生成式 AI 實作的基本理解
- 使用 Jupyter Notebook 測試和修改生成式 AI 程式碼

## 環境準備

### 開始實驗室之前
1. 確保您使用 Incognito 或私人瀏覽器視窗
2. 僅使用學生帳戶進行此實驗室
3. 閱讀所有指示，因為實驗室一旦開始就無法暫停

### 必要的環境設定
- 標準網路瀏覽器（推薦 Chrome）
- Vertex AI Workbench 執行個體
- Vertex AI Studio 存取權限

## 任務 1：建立 Gemini 圖像分析工具

### 目標
使用 Vertex AI Studio 中的 Gemini 模型創建一個模板，用於分析 Cymbal Direct 產品圖像，生成受圖像啟發的描述性文字選項。

### 詳細步驟

1. **開啟 Vertex AI Studio**
   - 在 Google Cloud Console 中，前往 **Vertex AI > Studio**
   - 選擇適當的區域（通常是 `us-central1`）

2. **建立新的提示**
   - 點擊 **Create Prompt**
   - 選擇 **Gemini 1.5 Pro** 或 **Gemini 1.5 Flash** 作為模型
   - 將提示命名為 **Cymbal Product Analysis**

3. **設定圖像輸入**
   - 在提示編輯器中，點擊 **Add Media**
   - 選擇 **Image** 並輸入圖像 URL：
     ```
     gs://cloud-samples-data/generative-ai/image/gardening-tools.jpeg
     ```
     或其他提供的 Cymbal Direct 產品圖像

4. **撰寫分析提示**
   ```
   Analyze this product image and generate multiple descriptive text options inspired by the image.

   Generate three types of descriptions:
   1. Short, factual descriptions (under 10 words)
   2. Catchy advertising phrases (10-20 words)
   3. Poetic nature-focused descriptions (20-30 words)

   Focus on:
   - Colors and textures
   - The feeling of being outdoors
   - Connection with nature
   - Target audience (young adventurers)
   ```

5. **設定參數**
   - Temperature: 0.7 (平衡創造性和一致性)
   - Top-P: 0.8
   - Top-K: 40
   - Max output tokens: 256

6. **測試和迭代**
   - 點擊 **Generate** 測試提示
   - 根據結果調整提示文字
   - 嘗試不同的參數設定
   - 確保輸出涵蓋所有三種類型的描述

7. **儲存提示**
   - 點擊 **Save**
   - 確認名稱為 **Cymbal Product Analysis**
   - 選擇適當的區域

### 驗證步驟
- 確保提示生成三種不同風格的描述
- 確認輸出與戶外裝備主題相關
- 驗證提示已正確儲存

## 任務 2：建立 Gemini 標語生成器

### 目標
創建一個可自訂的標語生成器，使用 Vertex AI Studio 中的 Gemini 模型，基於產品屬性、目標受眾和情感共鳴來客製化標語風格。

### 詳細步驟

1. **建立新提示**
   - 在 Vertex AI Studio 中點擊 **Create Prompt**
   - 選擇相同的 Gemini 模型
   - 將提示命名為 **Cymbal Tagline Generator Template**

2. **設定系統指示**
   ```
   Cymbal Direct is partnering with an outdoor gear retailer. They're launching a new line of products designed to encourage young people to explore the outdoors. Help them create catchy taglines for this product line.
   ```

3. **新增範例**
   點擊 **Add Example** 並輸入以下範例：

   **範例 1：**
   - Input: `Write a tagline for a durable backpack designed for hikers that makes them feel prepared. Consider styles like minimalist.`
   - Output: `Built for the Journey: Your Adventure Essentials.`

   **範例 2：**
   - Input: `Create a tagline for lightweight hiking boots that emphasize freedom and exploration for young adventurers.`
   - Output: `Step into Freedom: Explore Beyond Limits.`

4. **撰寫主要提示**
   ```
   Generate a catchy tagline for a {product_type} designed for {target_audience}.

   Product attributes: {attributes}
   Desired emotional response: {emotion}
   Style preferences: {style}

   Make it memorable, under 8 words, and inspiring.
   ```

5. **設定參數**
   - Temperature: 0.8 (較高的創造性)
   - Top-P: 0.9
   - Top-K: 40
   - Max output tokens: 50

6. **測試不同組合**
   嘗試以下參數組合：

   | 產品類型 | 目標受眾 | 屬性 | 情感 | 風格 |
   |---------|---------|------|------|------|
   | backpack | young hikers | durable, waterproof | empowered | adventurous |
   | jacket | outdoor enthusiasts | lightweight, warm | connected | minimalist |
   | boots | nature explorers | comfortable, rugged | free | poetic |

7. **迭代和優化**
   - 根據輸出調整提示文字
   - 新增更多範例以改善一致性
   - 測試邊界情況

8. **儲存提示**
   - 確認名稱為 **Cymbal Tagline Generator Template**
   - 選擇適當的區域

### 驗證步驟
- 確保標語簡潔（少於 8 字）
- 確認標語與戶外主題相關
- 驗證不同參數組合產生不同結果

## 任務 3：實驗圖像分析程式碼

### 目標
探索從 Vertex AI Studio 匯出的圖像分析提示 Python 程式碼，然後修改提示使其更具體，並在 notebook 中測試新提示。

### 詳細步驟

1. **開啟 Vertex AI Workbench**
   - 在 Google Cloud Console 中前往 **Vertex AI > Workbench**
   - 找到您的 Workbench 執行個體並點擊 **Open JupyterLab**

2. **開啟 notebook**
   - 在 JupyterLab 中開啟 `image-analysis.ipynb`
   - 設定 kernel 為 **Python 3**
   - 執行所有儲存格以確保環境設定正確

3. **從 Vertex AI Studio 匯出程式碼**
   - 返回 **Cymbal Product Analysis** 提示
   - 在右側點擊 **Code**
   - 選擇 **Python** 作為語言
   - 複製**第二個程式碼儲存格**（包含提示的儲存格）

4. **貼上程式碼到 notebook**
   - 在 notebook 的指定儲存格中貼上程式碼
   - 替換 API 金鑰認證區塊為使用 PROJECT_ID 和 LOCATION 的版本：
   ```python
   import vertexai
   from vertexai.generative_models import GenerativeModel

   # Initialize Vertex AI
   vertexai.init(project="your-project-id", location="us-central1")

   model = GenerativeModel("gemini-1.5-pro")
   ```

5. **修改提示**
   - 找到三個引號之間的提示文字
   - 將其修改為：
   ```
   Describe this image in less than 10 words, focusing on the most creative and unusual aspects.
   ```
   - 調整參數以增加創造性：
   ```python
   response = model.generate_content(
       [image, prompt],
       generation_config=genai.types.GenerationConfig(
           temperature=1.0,  # 增加創造性
           top_p=0.9,
           top_k=40,
           max_output_tokens=50,
       ),
   )
   ```

6. **測試修改後的程式碼**
   - 儲存 notebook
   - 重新執行程式碼儲存格
   - 驗證新描述是否更短（少於 10 字）且更具創造性

### 驗證步驟
- 確認輸出少於 10 字
- 檢查描述是否具有創造性和不尋常的特點
- 確保程式碼執行無錯誤

## 任務 4：實驗標語生成程式碼

### 目標
探索從 Vertex AI Studio 匯出的標語提示 Python 程式碼，然後修改提示以包含特定關鍵字，並在 notebook 中測試新提示。

### 詳細步驟

1. **開啟標語生成器 notebook**
   - 在 Workbench 中開啟 `tagline-generator.ipynb`
   - 設定 kernel 為 **Python 3**

2. **從 Vertex AI Studio 匯出程式碼**
   - 返回 **Cymbal Tagline Generator Template** 提示
   - 點擊 **Code** 並選擇 **Python**
   - 複製第二個程式碼儲存格

3. **貼上並修改認證**
   - 將程式碼貼到 notebook 的指定儲存格
   - 替換為使用 PROJECT_ID 和 LOCATION 的認證

4. **修改提示**
   - 找到最後一個輸入
   - 修改為：
   ```
   Write a tagline for a durable backpack designed for hikers that makes them feel prepared. Consider styles like minimalist. Make sure to include the keyword "nature".
   ```

5. **測試修改後的程式碼**
   - 儲存 notebook
   - 重新執行程式碼儲存格
   - 驗證新標語是否包含關鍵字 "nature"

### 驗證步驟
- 確認標語包含關鍵字 "nature"
- 確保程式碼執行成功
- 檢查標語的整體品質和相關性

## 常見問題與故障排除

### Vertex AI Studio 問題
- **無法存取 Studio**：確保您的帳戶有 Vertex AI API 存取權限
- **模型不可用**：檢查您使用的區域是否支援所選模型
- **提示未儲存**：確認名稱正確且區域已選擇

### Notebook 問題
- **Kernel 錯誤**：重新啟動 kernel 並重新執行設定儲存格
- **匯入錯誤**：確保所有必要的程式庫已安裝
- **認證錯誤**：確認 PROJECT_ID 和 LOCATION 正確設定

### 程式碼執行問題
- **API 錯誤**：檢查配額和權限
- **輸出格式錯誤**：調整提示文字和參數
- **圖像載入錯誤**：確認圖像 URL 正確且可存取

## 評分驗證

### 自動評分檢查點
- **任務 1**：檢查 **Cymbal Product Analysis** 提示是否存在且正確設定
- **任務 2**：檢查 **Cymbal Tagline Generator Template** 提示是否存在
- **任務 3**：檢查圖像分析 notebook 是否已修改並儲存
- **任務 4**：檢查標語生成器 notebook 是否包含 "nature" 關鍵字

### 手動驗證步驟
1. 測試所有提示是否生成預期的輸出
2. 確認 notebook 程式碼執行無錯誤
3. 驗證所有檔案已正確儲存

## 清理

此實驗室主要使用 Vertex AI Studio 和 notebook，不需要特殊的清理步驟。但是，如果您建立了任何測試資源：

1. 刪除任何測試用的 Cloud Storage 檔案（如果有）
2. 關閉不需要的 Workbench 執行個體
3. 清除任何暫時的提示版本

## 相關資源

- [Vertex AI Studio 說明文件](https://cloud.google.com/vertex-ai/docs/generative-ai/studio)
- [Gemini API 指南](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/gemini)
- [Prompt Design 最佳實務](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/prompts)
- [Vertex AI Workbench](https://cloud.google.com/vertex-ai/docs/workbench/introduction)

## 提示與技巧

### 有效的 Prompt Design
- **具體性**：提供清晰、具體的指示
- **範例**：使用 2-3 個範例來指導風格
- **參數調整**：Temperature 控制創造性，Top-P/Top-K 控制多樣性
- **迭代**：測試、評估、調整、重複

### Vertex AI Studio 使用技巧
- **儲存頻繁**：使用自動儲存功能
- **版本控制**：保留成功的提示版本
- **測試迭代**：在最終儲存前徹底測試

### Notebook 最佳實務
- **儲存定期**：避免工作遺失
- **錯誤檢查**：執行前檢查程式碼語法
- **輸出驗證**：確保結果符合期望

記住：Challenge Lab 旨在測試您的問題解決能力和從課程中學到的技能應用。仔細閱讀每個任務的要求，並運用您在 Prompt Design in Vertex AI 課程中學到的概念！

