# CORS-001 - Configure Secure CORS for Cloud Storage - 逐步操作指南

## 實驗室概述

此 Challenge Lab 的目的是在 Google Cloud Storage bucket 上配置安全的跨域資源共享 (CORS) 設定。您的研究夥伴需要從其網頁應用程式 http://example.com 訪問存放在 Cloud Storage 中的公開數據，但目前遇到跨域訪問錯誤。

您需要配置 CORS 設定，僅允許來自 http://example.com 的 GET 請求，遵循最小權限原則。

## 先決條件

- 基本了解 Google Cloud Storage 和 CORS 概念
- 熟悉 gcloud/gsutil 指令
- 已創建的 Cloud Storage bucket（由 Lab 環境提供）

## 預估時間

15-20 分鐘

## 任務列表

### 任務 1：檢查現有的 CORS 配置

首先，您需要檢查目標 bucket 的當前 CORS 配置，了解現狀。

**步驟詳情：**

1. 確認您所在的專案：
   ```
   gcloud config get-value project
   ```

**驗證步驟：**
- 指令執行成功，並顯示當前專案 ID

### 任務 2：取得 bucket 名稱並設定變數

**步驟詳情：**

1. 列出專案中的所有 Cloud Storage buckets，並將目標 bucket 名稱記錄到變數：
   ```
   BUCKET_NAME=$(gsutil ls | grep -o 'gs://[^ ]*' | head -1)
   echo "使用 bucket: $BUCKET_NAME"
   ```

**驗證步驟：**
- 變數已設定：`echo $BUCKET_NAME`
- 顯示正確的 gs:// URL

### 任務 3：檢查現有的 CORS 配置

**步驟詳情：**

1. 檢查目標 bucket 的當前 CORS 配置：
   ```
   gsutil cors get $BUCKET_NAME
   ```

   如果沒有設定 CORS，您會看到空的回應或錯誤訊息。

**驗證步驟：**
- 指令執行成功，並顯示當前 CORS 配置（可能是空的）

### 任務 4：創建 CORS 配置文件

根據任務要求，您需要創建一個 CORS 配置，只允許來自 http://example.com 的 GET 請求。

**步驟詳情：**

1. 創建 CORS 配置文件。使用以下指令直接創建 `cors-config.json` 文件：
   ```
   cat > cors-config.json << 'EOF'
   [
     {
       "origin": ["http://example.com"],
       "method": ["GET"],
       "responseHeader": ["Content-Type"],
       "maxAgeSeconds": 3600
     }
   ]
   EOF
   ```

   **替代方案**：如果上面的 heredoc 指令複製貼上時出現問題，請使用以下單行指令：
   ```
   printf '[\n  {\n    "origin": ["http://example.com"],\n    "method": ["GET"],\n    "responseHeader": ["Content-Type"],\n    "maxAgeSeconds": 3600\n  }\n]\n' > cors-config.json
   ```

   此指令會直接創建包含正確 JSON 內容的文件，無需編輯器。

**解釋說明：**
- `origin`: 只允許來自 http://example.com 的請求
- `method`: 只允許 GET 請求
- `responseHeader`: 允許的回應標頭
- `maxAgeSeconds`: 預檢請求的快取時間（1小時）

**驗證步驟：**
- 配置文件已創建：`ls -la cors-config.json`
- 配置文件內容正確：`cat cors-config.json`

### 任務 5：應用 CORS 配置到 Cloud Storage Bucket

現在將創建的 CORS 配置應用到目標 bucket。

**步驟詳情：**

1. 將 CORS 配置應用到 bucket：
   ```
   gsutil cors set cors-config.json $BUCKET_NAME
   ```

   此指令會將您定義的 CORS 規則設置到指定的 bucket。

**解釋說明：**
- `gsutil cors set`: 設置 bucket 的 CORS 配置
- 第一個參數是配置文件路徑
- 第二個參數是目標 bucket 的 gs:// URI

**驗證步驟：**
- 指令執行成功，沒有錯誤訊息
- 檢查配置是否正確應用：
  ```
  gsutil cors get $BUCKET_NAME
  ```

  應該能看到您設置的 CORS 配置。

### 任務 6：最終驗證

**步驟詳情：**

1. 再次檢查 CORS 配置：
   ```
   gsutil cors get $BUCKET_NAME
   ```

   確認配置正確應用。

2. 測試配置是否允許來自指定來源的請求（可選，但建議）：
   ```
   curl -H "Origin: http://example.com" -H "Access-Control-Request-Method: GET" -X OPTIONS -v $BUCKET_NAME/test-file 2>&1 | grep -i "access-control-allow-origin"
   ```

**驗證步驟：**
- CORS 配置正確顯示
- 來自 http://example.com 的請求被允許

## 執行指南

### 常見問題與解決方案

1. **找不到 bucket**：確保使用正確的 bucket 名稱，可以通過 `gsutil ls` 查看所有可用的 buckets。

2. **權限錯誤**：確保您有足夠的權限來修改 bucket 的 CORS 配置。在 Lab 環境中，這通常已經配置好了。

3. **JSON 格式錯誤**：確保 `cors-config.json` 文件的 JSON 格式正確。使用 `cat cors-config.json` 檢查內容。

4. **配置沒有生效**：等待幾分鐘讓配置完全生效，然後重新檢查。

### 提示與技巧

- **最小權限原則**：此配置只允許必要的來源 (http://example.com) 和方法 (GET)，符合安全最佳實踐。
- **預檢請求**：對於某些瀏覽器，複雜的 CORS 請求會先發送預檢請求 (OPTIONS)，確保您的配置包含必要的標頭。
- **多來源支援**：如果需要支援多個來源，可以在 `origin` 陣列中添加更多 URL。

### 清理步驟

完成 Lab 後，如果需要清理資源：

1. 移除 CORS 配置（如果需要）：
   ```
   gsutil cors set '[]' $BUCKET_NAME
   ```

2. 刪除臨時配置文件：
   ```
   rm cors-config.json
   ```

## 額外資源

- [Cloud Storage CORS 官方文檔](https://cloud.google.com/storage/docs/configuring-cors)
- [跨域資源共享 (CORS) 概念](https://developer.mozilla.org/zh-TW/docs/Web/HTTP/CORS)
- [gsutil cors 指令參考](https://cloud.google.com/storage/docs/gsutil/commands/cors)

## 技術筆記

- CORS 是瀏覽器安全機制的一部分，防止惡意網站訪問其他來源的資源
- Cloud Storage 的 CORS 配置通過 `gsutil cors` 指令管理
- 最小權限原則在此情境中意味著只允許必要的來源和 HTTP 方法
- 預檢請求 (preflight requests) 用於檢查複雜 CORS 請求的安全性
- `maxAgeSeconds` 參數控制瀏覽器快取預檢請求結果的時間