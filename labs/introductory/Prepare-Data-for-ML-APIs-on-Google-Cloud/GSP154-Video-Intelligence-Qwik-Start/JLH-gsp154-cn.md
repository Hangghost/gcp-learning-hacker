# GSP154 - Video Intelligence: Qwik Start

## 實驗室標題
學習如何使用 Google Cloud Video Intelligence API 為影片添加註解，使影片內容可搜尋和可發現。

## 先決條件
- Google Cloud Platform 帳戶
- 基本的 GCP 知識
- 熟悉命令列操作

## 目標
完成此實驗室後，您將能夠：
- 設定自訂服務帳戶的授權
- 向 Video Intelligence API 發送註解影片請求

## 預計時間
45 分鐘

## 實驗室步驟

### 步驟 1：啟動 Cloud Shell
Cloud Shell 是載有開發工具的虛擬機器，提供持續的 5GB 家目錄，並在 Google Cloud 上運行。

**說明：**
1. 在 Google Cloud 主控台頂部點擊 **啟動 Cloud Shell**
2. 按照以下視窗操作：
   - 繼續通過 Cloud Shell 資訊視窗
   - 授權 Cloud Shell 使用您的憑證進行 Google Cloud API 呼叫

**預期結果：**
您已連接到 Cloud Shell，並已通過驗證。

### 步驟 2：設定授權
為此實驗室建立並使用綁定到您的 Google Cloud 專案的服務帳戶進行授權。

**說明：**
1. 在 Cloud Shell 中執行以下命令建立新的服務帳戶 `quickstart`：
   ```bash
   gcloud iam service-accounts create quickstart
   ```

2. 建立服務帳戶金鑰檔案，將 `<your-project-123>` 替換為您的專案 ID：
   ```bash
   gcloud iam service-accounts keys create key.json --iam-account quickstart@<your-project-123>.iam.gserviceaccount.com
   ```

3. 使用您的服務帳戶金鑰檔案驗證服務帳戶：
   ```bash
   gcloud auth activate-service-account --key-file key.json
   ```

4. 使用您的服務帳戶取得授權權杖：
   ```bash
   gcloud auth print-access-token
   ```

**預期結果：**
您已成功建立服務帳戶並取得授權權杖。

### 步驟 3：發送註解影片請求
使用 Video Intelligence API 對影片進行註解處理。

**說明：**
1. 執行以下命令建立 JSON 請求檔案 `request.json`：
   ```bash
   cat > request.json <<EOF
   {
      "inputUri":"gs://spls/gsp154/video/train.mp4",
      "features": [
          "LABEL_DETECTION"
      ]
   }
   EOF
   ```

2. 使用 `curl` 發送 `videos:annotate` 請求：
   ```bash
   curl -s -H 'Content-Type: application/json' \
       -H 'Authorization: Bearer '$(gcloud auth print-access-token)'' \
       'https://videointelligence.googleapis.com/v1/videos:annotate' \
       -d @request.json
   ```

3. 記下回應中的操作名稱，用於後續查詢。

4. 使用操作名稱查詢處理狀態，將 `PROJECTS`、`LOCATIONS` 和 `OPERATION_NAME` 替換為實際值：
   ```bash
   curl -s -H 'Content-Type: application/json' \
       -H 'Authorization: Bearer '$(gcloud auth print-access-token)'' \
       'https://videointelligence.googleapis.com/v1/projects/PROJECTS/locations/LOCATIONS/operations/OPERATION_NAME'
   ```

5. 等待約一分鐘後重新執行查詢命令，您應該會看到處理完成的結果。

**預期結果：**
您已成功向 Video Intelligence API 發送註解請求並收到處理結果。

## 驗證
檢查您的操作是否成功完成：
- 確認 API 回應包含 `done: true`
- 驗證 `annotationResults` 包含影片標籤資訊
- 檢查回應中包含實體 ID 和信心分數

## 故障排除
常見問題和解決方案：
- **授權失敗**：確保服務帳戶金鑰檔案正確建立且未過期
- **API 請求失敗**：檢查專案 ID 和權杖是否正確
- **操作逾時**：影片處理可能需要幾分鐘，請耐心等待
- **權限錯誤**：確保 Video Intelligence API 已為您的專案啟用

## 清理
為避免產生額外費用，請執行以下清理步驟：
1. 刪除建立的服務帳戶金鑰檔案：
   ```bash
   rm key.json
   ```

2. 刪除服務帳戶（如果不再需要）：
   ```bash
   gcloud iam service-accounts delete quickstart@<your-project-123>.iam.gserviceaccount.com
   ```

## 額外資源
- [Video Intelligence API 官方文件](https://cloud.google.com/video-intelligence/docs/)
- [Google Cloud Storage 文件](https://cloud.google.com/storage/docs/)
- [IAM 服務帳戶指南](https://cloud.google.com/iam/docs/service-accounts)
- 相關實驗室：GSP097 (Cloud Natural Language API), GSP119 (Speech-to-Text API)

## 筆記
- Video Intelligence API 可以處理儲存在 Cloud Storage 中的影片
- 支援多種註解功能，包括標籤檢測、物件追蹤等
- API 是非同步的，需要輪詢操作狀態
- 處理時間取決於影片長度和複雜度
