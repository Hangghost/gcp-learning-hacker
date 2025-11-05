# GSP527 - Kickstarting Application Development with Gemini Code Assist: Challenge Lab

## 挑戰概述

這是一個挑戰實驗室，您將面臨一個場景和一組任務。與其遵循逐步指示，您將使用課程中學到的技能自行找出完成任務的方法！自動評分系統（在此頁面上顯示）將提供您是否正確完成任務的回饋。

當您參加挑戰實驗室時，您不會學到新的 Google Cloud 概念。您應該擴展您學到的技能，例如更改預設值和閱讀和研究錯誤訊息來修復自己的錯誤。

要獲得 100% 分數，您必須在時間段內成功完成所有任務！

此實驗室推薦給已註冊 [Application Development with Gemini Code Assist](enter URL) 技能徽章的學生。您準備好迎接挑戰了嗎？

## 場景描述

### Cymbal Direct：為線上商店實作新功能

您最近加入了 Cymbal Superstore 的開發團隊，這是一個蓬勃發展的線上購物平台。需要一個新功能「Products Out of Stock」來通知補貨團隊。需要開發、部署和嚴格測試 `/outofstock` 端點的初始實作。

您的目標是利用 Gemini Code Assist 完成此功能，特別專注於開發後端邏輯、將其提取到微服務中、安全地公開它、除錯問題並確保它經過良好測試。

增加生成式 AI 協助編碼效率的一個好方法是進行測試驅動開發 (TDD)。在此方法中，您首先開發已完成程式碼應該通過的測試，然後相應地建置程式碼。由於 Gemini 將為您建立程式碼，您需要一種快速驗證該程式碼是否生產就緒的方法。

Cymbal Superstore 的所有必要現有程式碼和基礎設施服務將作為實驗室設定的一部分在 `cymbal-superstore` 資料夾中提供。您準備好迎接挑戰了嗎？

## 任務總覽

根據您在 GSP1328、GSP1329 和 GSP1330 中學到的技能，此挑戰要求您使用 Gemini Code Assist：

1. **設定開發環境並配置 Gemini 協助**
2. **開發和運行 `/outofstock` 功能的單元測試**
3. **在後端開發和測試 `/outofstock` 端點**
4. **將核心邏輯提取到新的 Cloud Function 並部署它**
5. **建立 API Gateway 來公開 outofstock Cloud Function**

## 詳細逐步指南

### 任務 1：設定開發環境並配置 Gemini 協助

#### 步驟 1.1：設定環境變數
```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=Lab Region
export ZONE=Lab Zone
```

#### 步驟 1.2：複製必要的檔案
```bash
gsutil -m cp -r gs://spls/gsp527/cymbal-superstore .
```

**注意：** 此處使用的 Cloud Storage bucket 與之前實驗室不同 (`gs://spls/gsp527/` 而不是 `gs://duet-appdev/`)。

#### 步驟 1.3：在編輯器中開啟專案並配置 Gemini
1. 開啟 Cloud Shell 編輯器
2. 開啟 `cymbal-superstore` 資料夾
3. 點擊 Gemini 圖示
4. 選取正確的 Google Cloud 專案進行 Gemini 協助

### 任務 2：開發和運行 `/outofstock` 功能的單元測試

#### 步驟 2.1：檢查現有測試
1. 在編輯器中開啟 `backend/index.test.ts` 檔案
2. 使用 Gemini Chat 解釋任何不清楚的現有測試部分

#### 步驟 2.2：使用 Gemini 生成新測試
1. 在 `index.test.ts` 檔案底部添加註釋：
```typescript
// Create unit tests for the GET /outofstock endpoint
// Test that it returns a 200 status code
// Test that it returns an array of 2 out of stock products
```

2. 選取註釋並使用 Gemini 生成程式碼

#### 步驟 2.3：運行測試
```bash
cd ~/cymbal-superstore/backend
npm run test
```

**預期結果：** 測試應該會失敗，因為 `/outofstock` 端點尚未實作。

### 任務 3：在後端開發和測試 `/outofstock` 端點

#### 步驟 3.1：檢查現有程式碼
1. 在編輯器中開啟 `backend/index.ts` 檔案
2. 查看現有的端點實作（特別是 `/products` 和 `/newproducts`）

#### 步驟 3.2：使用 Gemini 生成 `/outofstock` 端點
1. 找到 `/outofstock endpoint code goes here` 佔位符
2. 將其替換為描述性註釋：
```typescript
// Create a GET route for /outofstock that returns products that are out of stock (quantity = 0)
// The products should be retrieved from Firestore collection "inventory"
// Return the products as JSON array
```

3. 選取註釋並使用 Gemini 生成程式碼

#### 步驟 3.3：測試端點
1. 啟動後端服務：
```bash
cd ~/cymbal-superstore/backend
npm run start
```

2. 在另一個終端中測試端點：
```bash
curl localhost:8000/outofstock
```

3. 驗證返回的 JSON 包含 2 個缺貨產品
4. 運行測試以確保它們通過：
```bash
npm run test
```

### 任務 4：將核心邏輯提取到新的 Cloud Function 並部署它

#### 步驟 4.1：檢查 functions 目錄
1. 導航到 `cymbal-superstore/functions` 目錄
2. 查看現有的 `index.js` 檔案結構

#### 步驟 4.2：使用 Gemini 生成 Cloud Function 程式碼
1. 在 `functions/index.js` 中添加註釋：
```javascript
// Create an HTTP Cloud Function that returns products that are out of stock
// Route: /outofstock
// Query Firestore collection "inventory" for products where quantity = 0
// Return JSON array of out of stock products
```

2. 使用 Gemini 生成程式碼

#### 步驟 4.3：獲取部署命令
1. 開啟 Gemini Chat
2. 詢問正確的 gcloud 命令：
```
What is the gcloud command to deploy this /outofstock Cloud Function with HTTP trigger and allow unauthenticated access?
```

#### 步驟 4.4：授予 Cloud Functions 服務代理權限
在部署之前，請確保 Cloud Functions 服務帳戶具有必要的權限。服務帳戶 ID 的格式將為 `service-<PROJECT_NUMBER>@gcf-admin-robot.iam.gserviceaccount.com`。

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:service-PROJECT_NUMBER@gcf-admin-robot.iam.gserviceaccount.com" \
    --role="roles/cloudfunctions.serviceAgent"
```
**注意：** 請將 `PROJECT_NUMBER` 替換為您的實際 Google Cloud 專案編號。您可以在 Google Cloud Console 儀表板中找到它。

#### 步驟 4.5：部署 Cloud Function
執行 Gemini 提供的命令，類似：
```bash
gcloud functions deploy outofstock --runtime nodejs20 --trigger-http --allow-unauthenticated --region=$REGION
```

#### 步驟 4.5：測試已部署的 Cloud Function
1. 從部署輸出中獲取 Cloud Function URL
2. 在瀏覽器中開啟 URL
3. 驗證返回包含 2 個缺貨產品的 JSON

### 任務 5：建立 API Gateway 來公開 outofstock Cloud Function

#### 步驟 5.1：設定環境變數
```bash
export CONFIG_ID=outofstock-api-config
export API_ID=outofstock-api
export GATEWAY_ID=store
export OPENAPI_SPEC=outofstock.yaml
```

#### 步驟 5.2：建立 gateway 目錄和 OpenAPI 規範檔案
```bash
cd ~/cymbal-superstore
mkdir gateway
cd gateway
touch outofstock.yaml
```

#### 步驟 5.3：使用 Gemini 生成 OpenAPI 規範
1. 開啟 Gemini Chat
2. 提供 Cloud Function URL 並請求 OpenAPI 規範：
```
Create an OpenAPI 2.0 specification for a Cloud Function that returns out of stock products.
The function URL is: [YOUR_CLOUD_FUNCTION_URL]
The endpoint should be /outofstock and return a JSON array of products.
```

3. 將生成的規範貼到 `outofstock.yaml` 檔案中

#### 步驟 5.4：啟用 API Gateway 服務
```bash
gcloud services enable apigateway.googleapis.com
```

#### 步驟 5.5：建立 API 和配置
1. 詢問 Gemini Chat 建立 API 和配置的 gcloud 命令
2. 執行提供的命令：
```bash
gcloud api-gateway apis create $API_ID
gcloud api-gateway api-configs create $CONFIG_ID --api=$API_ID --openapi-spec=$OPENAPI_SPEC
```

#### 步驟 5.6：建立和部署 API Gateway
1. 詢問 Gemini Chat 建立 API Gateway 的命令
2. 執行提供的命令：
```bash
gcloud api-gateway gateways create $GATEWAY_ID --api=$API_ID --api-config=$CONFIG_ID --location=$REGION
```

#### 步驟 5.7：驗證 API Gateway
1. 檢查 gateway 狀態：
```bash
gcloud api-gateway gateways describe $GATEWAY_ID --location=$REGION
```

2. 記下 `defaultHostname`
3. 在瀏覽器中測試：`https://[defaultHostname]/outofstock`
4. 驗證返回 2 個缺貨產品的 JSON

## 故障排除指南

### 常見問題

#### Gemini 無法生成程式碼
- 確保正確選取了 GCP 專案
- 檢查 Cloud AI Companion API 已啟用
- 驗證註釋格式正確且描述性強

#### Cloud Function 部署失敗
- 檢查區域設定
- 確保程式碼語法正確
- 驗證權限設定

#### API Gateway 建立失敗
- 檢查 OpenAPI 規範格式
- 確保 Cloud Function URL 正確
- 驗證 API Gateway 服務已啟用

#### 測試失敗
- 檢查測試資料是否與預期匹配
- 驗證端點邏輯
- 檢查回應格式

### 除錯技巧

#### 使用 Gemini Chat 進行除錯
1. 複製錯誤訊息
2. 在 Gemini Chat 中貼上錯誤
3. 提供相關程式碼片段
4. 詢問具體的解決方案

#### Firestore 查詢問題
- 記得 Firestore 不支援多個不等式篩選器
- 使用應用程式邏輯進行後續篩選
- 考慮複合索引

#### 測試驅動開發 (TDD) 方法
1. 先寫測試
2. 使用 Gemini 生成使測試通過的程式碼
3. 重構和優化
4. 再次運行測試

## 評分標準

此挑戰實驗室使用自動評分系統。以下是關鍵檢查點：

- ✅ **任務 2**：單元測試已建立並可以運行
- ✅ **任務 3**：`/outofstock` 端點在後端工作
- ✅ **任務 4**：Cloud Function 已部署並運行
- ✅ **任務 5**：API Gateway 已建立並公開 Cloud Function

## 學習成果

完成此挑戰後，您將證明能夠：

1. **獨立工作**：在沒有逐步指導的情況下應用學到的技能
2. **問題解決**：使用 Gemini 有效除錯和修復問題
3. **架構設計**：將單體應用邏輯提取到微服務中
4. **API 管理**：使用 API Gateway 安全地公開服務
5. **測試實務**：實作全面的單元測試覆蓋

## 資源和參考

### 相關 Labs
- **GSP1328**：Create API Gateways with Gemini
- **GSP1329**：Code Generation with Gemini
- **GSP1330**：Unit Testing with Gemini

### GCP 服務文檔
- [Cloud Functions](https://cloud.google.com/functions/docs)
- [API Gateway](https://cloud.google.com/api-gateway/docs)
- [Gemini for Developers](https://cloud.google.com/gemini/docs)

### 最佳實務
- 使用描述性註釋與 Gemini 合作
- 先寫測試，然後實作功能 (TDD)
- 定期測試變更
- 使用適當的錯誤處理

## 下一步

恭喜完成此挑戰！您現在已經證明了在沒有指導的情況下使用 Gemini Code Assist 開發完整功能的技能。

考慮探索：
- 更複雜的微服務架構
- 持續整合/持續部署 (CI/CD) 管道
- 進階測試技術
- 生產環境部署實務
