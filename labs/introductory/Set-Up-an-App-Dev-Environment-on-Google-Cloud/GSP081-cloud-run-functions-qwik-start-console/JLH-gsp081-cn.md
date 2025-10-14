# GSP081 - Cloud Run Functions：快速開始 - 主控台

## 實驗概述
Cloud Run Functions 是一個程式碼片段，可回應事件執行，例如 HTTP 請求、訊息服務的訊息，或檔案上傳。Cloud Events 是*發生*在您的雲端環境中的事情，例如資料庫中的資料變更、儲存系統中新增的檔案，或建立新的虛擬機器實例。

由於 Cloud Run Functions 是事件驅動的，它們只在發生事件時執行。這使它們成為需要快速完成或不需要一直運行的任務的理想選擇。

例如，您可以使用 Cloud Run Functions：

- 自動為上傳到 Cloud Storage 的圖片生成縮圖
- 當 Pub/Sub 中收到新訊息時，向使用者的手機發送通知
- 處理 Cloud Firestore 資料庫的資料並生成報告

您可以用支援 Node.js 的任何語言編寫程式碼，並且只需按幾下即可將程式碼部署到雲端。一旦部署 Cloud Run Functions，它將自動開始回應事件執行。

本實作實驗將向您展示如何使用 Google Cloud 主控台建立、部署和測試 Cloud Run Functions。

## 先決條件
- Google Cloud Platform 帳戶
- 基本熟悉 Google Cloud Console
- 了解基本程式設計概念

## 實驗目標
完成本實驗後，您將能夠：
- 建立 Cloud Run Functions
- 部署和測試 Functions
- 查看 Functions 日誌

## 預估時間
30-45 分鐘

## 實驗步驟

### 步驟 1：建立 Functions
在本任務中，您將使用主控台建立 Cloud Run Functions。

**指令：**
1. 在主控台中，按一下**導覽選單 ()**，然後按一下**Cloud Run**。

2. 按一下**WRITE A FUNCTION**。

3. 在**Functions**對話方塊中，輸入以下值：

   | **欄位** | **值** |
   | --- | --- |
   | Service name | gcfunction |
   | Region | `REGION` |
   | Authentication | Allow public access |
   | Memory allocated (In Containers, Volumes, Networking, Security Settings) | 保留預設值 |
   | Execution environment (In Containers, Volumes, Networking, Security Settings) | Second generation |
   | Revision scaling (In Containers, Volumes, Networking, Security Settings) | 將**Maximum number of instance**設為**5**，然後按一下**Create** |

**注意：**可能會出現一個有用的快顯視窗來驗證專案中已啟用必要的 API。出現時按一下**ENABLE**按鈕。

您將在下一節部署 Functions。

**預期結果：**
Functions 已成功建立並準備部署。

### 步驟 2：部署 Functions
在本任務中，您將部署 Cloud Run Functions。

**指令：**
1. 仍在**Create function**對話方塊中，在**Inline editor**的 Source code 中，使用已為 index.js 提供的預設`helloHttp` Functions 實作。

2. 按一下**SAVE and REDEPLOY**來部署 Functions。

**注意：**Functions 部署時，其旁邊的圖示是一個小的旋轉器。部署完成後，旋轉器會變成綠色勾選標記。

**預期結果：**
Functions 已成功部署並準備測試。

### 步驟 3：測試 Functions
在本任務中，您將測試已部署的 Functions。

**指令：**
1. 在 Functions 詳細資訊儀表板中，按一下**TEST**來測試 Functions。

2. 在 Triggering event 欄位中，在大括號`{}`之間輸入以下文字：

   `"message":"Hello World!"`

3. 複製**CLI test command**並在 Cloud Shell 中執行它。

4. 您將看到 "Hello World!" 訊息作為輸出。

**預期結果：**
Functions 成功執行並返回 "Hello World!" 訊息。

### 步驟 4：查看日誌
在本任務中，您將查看 Functions 的日誌。

**指令：**
1. 在**Service Details**頁面中，按一下**Observability**並選取**Logs**。

**預期結果：**
您可以看到 Functions 的日誌歷史記錄。

### 步驟 5：測試您的理解
以下是多選題，用於強化您對本實驗概念的理解。請盡可能回答。

Cloud Run Functions 是 Google Cloud 上事件驅動服務的無伺服器執行環境。
- 正確
- 錯誤

在實驗中建立 Cloud Run Functions 時使用哪種觸發器類型？
- HTTP
- Pub/Sub
- Cloud Storage
- Firebase

## 驗證
要驗證實驗是否成功完成：
- Functions 已建立並部署
- Functions 測試成功返回 "Hello World!" 訊息
- 能夠查看 Functions 日誌

## 故障排除
常見問題和解決方案：
- **API 未啟用**：如果收到 API 未啟用的錯誤，請按一下提供的**ENABLE**按鈕來啟用必要的 API
- **部署失敗**：檢查您的網路連線並確保您有適當的權限
- **測試失敗**：確保 JSON 格式正確，並且 Functions 已完全部署

## 清理
要清理資源以避免費用：
1. 前往 Cloud Run 主控台
2. 選取您的 Functions
3. 按一下**Delete**來刪除 Functions
4. 確認刪除

## 額外資源
- [Cloud Run Functions 文件](https://cloud.google.com/functions/docs)
- [事件和觸發器](https://cloud.google.com/functions/docs/concepts/events-triggers)
- [Cloud Run Functions：使用命令列快速開始](https://google.qwiklabs.com/catalog_lab/924)
- Google Cloud Skill Boost 中的 "Qwik Starts" 系列實驗

## 筆記
- Cloud Run Functions 是 Google Cloud 的無伺服器 Functions 服務
- Functions 只在事件發生時執行，節省成本
- 可以與各種 GCP 服務整合
- 支援多種程式語言和執行環境
