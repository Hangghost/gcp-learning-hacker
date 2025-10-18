# GSP080 - Cloud Run Functions：快速開始 - 命令列

## 實驗概述
Cloud Run Functions 是一個程式碼片段，可回應事件執行，例如 HTTP 請求、訊息服務的訊息，或檔案上傳。Cloud Events 是*發生*在您的雲端環境中的事情，例如資料庫中的資料變更、儲存系統中新增的檔案，或建立新的虛擬機器實例。

由於 Cloud Run Functions 是事件驅動的，它們只在發生事件時執行。這使它們成為需要快速完成或不需要一直運行的任務的理想選擇。

例如，您可以使用 Cloud Run Functions：

- 自動為上傳到 Cloud Storage 的圖片生成縮圖
- 當 Pub/Sub 中收到新訊息時，向使用者的手機發送通知
- 處理 Cloud Firestore 資料庫的資料並生成報告

您可以用支援 Node.js 的任何語言編寫程式碼，並且只需按幾下即可將程式碼部署到雲端。一旦部署 Cloud Run Functions，它將自動開始回應事件執行。

本實作實驗將向您展示如何使用 Google Cloud Shell 命令列建立、部署和測試 Cloud Run Functions。

## 先決條件
- Google Cloud Platform 帳戶
- 基本熟悉 Google Cloud Shell 和命令列操作
- 了解基本程式設計概念
- 熟悉 Node.js 和 JavaScript

## 實驗目標
完成本實驗後，您將能夠：
- 使用命令列建立 Cloud Run Functions
- 部署和測試 Functions
- 查看 Functions 日誌
- 了解 Pub/Sub 觸發器的工作原理

## 預估時間
45-60 分鐘

## 實驗步驟

### 步驟 1：建立 Functions
在本任務中，您將建立一個名為 `helloWorld` 的簡單 Functions。此 Functions 會將訊息寫入 Cloud Run Functions 日誌，並由 Pub/Sub 主題事件觸發。

**指令：**
1. 在 Cloud Shell 中執行以下命令來設定預設區域：

   ```bash
   gcloud config set run/region REGION
   ```

2. 建立 Functions 程式碼的目錄：

   ```bash
   mkdir gcf_hello_world && cd $_
   ```

3. 建立並開啟 `index.js` 進行編輯：

   ```bash
   nano index.js
   ```

4. 將以下程式碼複製到 `index.js` 檔案中：

   ```javascript
   const functions = require('@google-cloud/functions-framework');

   // Register a CloudEvent callback with the Functions Framework that will
   // be executed when the Pub/Sub trigger topic receives a message.
   functions.cloudEvent('helloPubSub', cloudEvent => {
     // The Pub/Sub message is passed as the CloudEvent's data payload.
     const base64name = cloudEvent.data.message.data;

     const name = base64name
       ? Buffer.from(base64name, 'base64').toString()
       : 'World';

     console.log(`Hello, ${name}!`);
   });
   ```

5. 要儲存檔案並退出 nano，按 CTRL+X，然後按 Y，然後按 ENTER。

6. 建立並開啟 `package.json` 進行編輯：

   ```bash
   nano package.json
   ```

7. 將以下程式碼複製到 `package.json` 檔案中：

   ```json
   {
     "name": "gcf_hello_world",
     "version": "1.0.0",
     "main": "index.js",
     "scripts": {
       "start": "node index.js",
       "test": "echo \"Error: no test specified\" && exit 1"
     },
     "dependencies": {
       "@google-cloud/functions-framework": "^3.0.0"
     }
   }
   ```

8. 要儲存檔案並退出 nano，按 CTRL+X，然後按 Y，然後按 ENTER。

9. 安裝套件依賴項：

   ```bash
   npm install
   ```

**預期結果：**
npm 安裝成功，顯示已新增 140 個套件。

### 步驟 2：部署 Functions
在本任務中，您將部署 Functions 到名為 `cf-demo` 的 Pub/Sub 主題。

**指令：**
1. 將 nodejs-pubsub-function 部署到名為 cf-demo 的 pub/sub 主題：

   ```bash
   gcloud functions deploy nodejs-pubsub-function \
     --gen2 \
     --runtime=nodejs20 \
     --region=REGION \
     --source=. \
     --entry-point=helloPubSub \
     --trigger-topic cf-demo \
     --stage-bucket PROJECT_ID-bucket \
     --service-account cloudfunctionsa@PROJECT_ID.iam.gserviceaccount.com \
     --allow-unauthenticated
   ```

   **注意：**如果收到服務帳戶 serviceAccountTokenCreator 通知，請選擇 "n"。

2. 驗證 Functions 的狀態：

   ```bash
   gcloud functions describe nodejs-pubsub-function \
     --region=REGION
   ```

**預期結果：**
Functions 狀態顯示為 ACTIVE，表示已成功部署。

### 步驟 3：測試 Functions
在本任務中，您將測試已部署的 Functions 是否能在偵測到事件後將訊息寫入雲端日誌。

**指令：**
1. 使用一些資料調用 PubSub：

   ```bash
   gcloud pubsub topics publish cf-demo --message="Cloud Function Gen2"
   ```

**預期結果：**
訊息成功發佈，並返回訊息 ID。

### 步驟 4：查看日誌
在本任務中，您將檢查日誌以查看訊息。

**指令：**
1. 檢查日誌以查看歷史記錄中的訊息：

   ```bash
   gcloud functions logs read nodejs-pubsub-function \
     --region=REGION
   ```

   **注意：**日誌可能需要約 10 分鐘才會出現。您也可以前往 Logging > Logs Explorer 查看日誌。

**預期結果：**
您可以看到類似以下的 Functions 輸出：
```
LEVEL:
NAME: nodejs-pubsub-function
EXECUTION_ID: h4v6akxf4sxt
TIME_UTC: 2024-08-05 15:15:25.723
LOG: Hello, Cloud Function Gen2!
```

### 步驟 5：測試您的理解
以下是多選題，用於強化您對本實驗概念的理解。請盡可能回答。

無伺服器讓您可以編寫和部署程式碼，而無需管理基礎架構的麻煩。
- 正確
- 錯誤

## 驗證
要驗證實驗是否成功完成：
- Functions 已建立並包含正確的程式碼
- Functions 已成功部署並處於 ACTIVE 狀態
- Functions 測試成功觸發並記錄訊息
- 能夠查看 Functions 日誌

## 故障排除
常見問題和解決方案：
- **npm install 失敗**：檢查網路連線並確保您有適當的權限
- **部署失敗**：檢查您的專案 ID 和區域設定是否正確
- **Pub/Sub 發佈失敗**：確保主題名稱正確且您有發佈權限
- **日誌未出現**：等待幾分鐘，日誌可能需要時間來顯示

## 清理
要清理資源以避免費用：
1. 刪除 Functions：
   ```bash
   gcloud functions delete nodejs-pubsub-function --region=REGION
   ```

2. 刪除 Pub/Sub 主題：
   ```bash
   gcloud pubsub topics delete cf-demo
   ```

3. 刪除儲存桶：
   ```bash
   gsutil rm -r gs://PROJECT_ID-bucket
   ```

## 額外資源
- [Cloud Run Functions 文件](https://cloud.google.com/functions/docs)
- [Pub/Sub：Google 規模的訊息服務](https://cloud.google.com/pubsub/architecture)
- [背景 Functions](https://cloud.google.com/functions/docs/writing/background)
- [事件和觸發器](https://cloud.google.com/functions/docs/concepts/events-triggers)
- [Cloud Run Functions：快速開始 - 主控台](https://google.qwiklabs.com/catalog_lab/704)
- Google Cloud Skill Boost 中的 "Qwik Starts" 系列實驗

## 筆記
- Cloud Run Functions Gen 2 使用新的執行環境
- Pub/Sub 是事件驅動架構的核心元件
- Functions 只在事件發生時執行，節省成本
- 支援多種程式語言和執行環境
- 可以與各種 GCP 服務整合
