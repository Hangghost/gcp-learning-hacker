# GSP074 - Cloud Storage：Qwik Start - CLI/SDK

## 實驗概述
Cloud Storage 允許世界範圍內儲存和檢索任意數量的資料，無論何時何地。您可以使用 Cloud Storage 處理各種場景，包括為網站提供內容、用於歸檔和災難恢復的資料儲存，或通過直接下載將大型資料物件分發給用戶。

在本實作實驗中，您將學習如何使用 Google Cloud 命令列建立儲存桶，將物件上傳到其中，建立資料夾和子資料夾，並使用 Google Cloud 命令列使物件公開可訪問。

在本實驗過程中，您可以通過前往 **Navigation menu** > **Cloud Storage** 在控制台中驗證您的工作。您只需在每次命令執行後重新整理瀏覽器即可看到新建立的項目。

## 先決條件
- Google Cloud Platform 帳戶
- 基本熟悉 Google Cloud Console
- 了解 Cloud Storage 的基本概念

## 實驗目標
完成本實驗後，您將能夠：
- 建立 Cloud Storage 儲存桶
- 將物件上傳到儲存桶
- 在儲存桶中建立資料夾和子資料夾
- 使儲存桶中的物件公開可訪問

## 預估時間
30-45 分鐘

## 實驗步驟

### 步驟 1：設定區域
在本任務中，您將為此實驗設定專案區域。

**指令：**
1. 設定專案的運算區域：
   ```bash
   gcloud config set compute/region "REGION"
   ```

**預期結果：**
區域已成功設定。

### 步驟 2：建立儲存桶
在本實驗中，您將使用 [gcloud storage](https://cloud.google.com/sdk/gcloud/reference/storage) 和 [gsutil](https://cloud.google.com/storage/docs/gsutil) 命令。

建立儲存桶時，您必須遵循以下通用儲存桶命名規則。

**儲存桶命名規則**
- 不要在儲存桶名稱中包含敏感資訊，因為儲存桶命名空間是全球性的且公開可見。
- 儲存桶名稱只能包含小寫字母、數字、破折號 (-)、底線 (_) 和點 (.)。包含點的名稱需要[驗證](https://cloud.google.com/storage/docs/domain-name-verification)。
- 儲存桶名稱必須以數字或字母開頭和結尾。
- 儲存桶名稱必須包含 3 到 63 個字元。包含點的名稱最多可包含 222 個字元，但每個點分隔的元件不能超過 63 個字元。
- 儲存桶名稱不能以點陣表示法表示為 IP 位址（例如，192.168.5.4）。
- 儲存桶名稱不能以 "goog" 前綴開頭。
- 儲存桶名稱不能包含 "google" 或類似的拼寫錯誤。
- 此外，為了 DNS 相容性和未來相容性，您不應該在點或破折號旁邊使用底線 (_) 或有點。舉例來說，".." 或 "-." 或 ".-" 在 DNS 名稱中是無效的。

使用 make bucket (`buckets create`) 命令建立儲存桶，將 `<YOUR_BUCKET_NAME>` 替換為遵循儲存桶命名規則的唯一名稱：

```bash
gcloud storage buckets create gs://<YOUR-BUCKET-NAME>
```

此命令使用預設設定建立儲存桶。要查看這些預設設定是什麼，請使用 Cloud console **Navigation menu** > **Cloud Storage**，然後點擊您的儲存桶名稱，並點擊 **Configuration** 標籤。

就是這樣 — 您剛剛建立了 Cloud Storage 儲存桶！

**注意：** 如果儲存桶名稱已被佔用，無論是由您還是其他人，命令將返回：
`Creating gs://YOUR-BUCKET-NAME/...`
`ServiceException: 409 Bucket YOUR-BUCKET-NAME already exists.` 請使用不同的儲存桶名稱重試。

**預期結果：**
Cloud Storage 儲存桶已成功建立。

### 步驟 3：將物件上傳到您的儲存桶
使用 Cloud Shell 將物件上傳到儲存桶。

**指令：**
1. 要將此圖片 (ada.jpg) 下載到您的儲存桶，請在 Cloud Shell 中輸入此命令：

   ```bash
   curl https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Ada_Lovelace_portrait.jpg/800px-Ada_Lovelace_portrait.jpg --output ada.jpg
   ```

2. 使用 `gcloud storage cp` 命令將圖片從您儲存它的位置上傳到您建立的儲存桶：

   ```bash
   gcloud storage cp ada.jpg gs://YOUR-BUCKET-NAME
   ```

   **注意：** 輸入您的儲存桶名稱時，您可以使用 Tab 鍵自動完成。

您可以從命令列看到圖片載入到您的儲存桶。

您剛剛在您的儲存桶中儲存了一個物件！

3. 現在移除下載的圖片：

   ```bash
   rm ada.jpg
   ```

**預期結果：**
物件已成功上傳到 Cloud Storage 儲存桶。

### 步驟 4：從您的儲存桶下載物件
- 使用 `gcloud storage cp` 命令從您儲存的儲存桶下載圖片到 Cloud Shell：

  ```bash
  gcloud storage cp -r gs://YOUR-BUCKET-NAME/ada.jpg .
  ```

如果成功，命令將返回：

`Copying gs://YOUR-BUCKET-NAME/ada.jpg...
/ [1 files][360.1 KiB/2360.1 KiB]
Operation completed over 1 objects/360.1 KiB.`

您剛剛從您的儲存桶下載了圖片。

**預期結果：**
物件已成功從 Cloud Storage 儲存桶下載。

### 步驟 5：將物件複製到儲存桶中的資料夾
- 使用 `gcloud storage cp` 命令建立名為 `image-folder` 的資料夾並將圖片 (ada.jpg) 複製到其中：

  ```bash
  gcloud storage cp gs://YOUR-BUCKET-NAME/ada.jpg gs://YOUR-BUCKET-NAME/image-folder/
  ```

  **注意：** 與本地檔案系統相比，[Cloud Storage 中的資料夾](https://cloud.google.com/sdk/gcloud/reference/storage/folders) 有一些限制，但支援大多數相同的操作。

如果成功，命令將返回：

`Copying gs://YOUR-BUCKET-NAME/ada.jpg [Content-Type=image/png]...
- [1 files] [ 360.1 KiB/ 360.1 KiB]
Operation completed over 1 objects/360.1 KiB`

圖片檔案已複製到您的儲存桶中的新資料夾。

**預期結果：**
物件已成功複製到儲存桶中的資料夾。

### 步驟 6：列出儲存桶或資料夾的內容
- 使用 `gcloud storage ls` 命令列出儲存桶的內容：

  ```bash
  gcloud storage ls gs://YOUR-BUCKET-NAME
  ```

如果成功，命令將返回類似以下的訊息：

`gs://YOUR-BUCKET-NAME/ada.jpg
gs://YOUR-BUCKET-NAME/image-folder/`

這是目前在您的儲存桶中的所有內容。

**預期結果：**
儲存桶內容已成功列出。

### 步驟 7：列出物件的詳細資訊
- 使用 `gcloud storage ls` 命令，使用 `l` 標記取得您上傳到儲存桶的圖片檔案的一些詳細資訊：

  ```bash
  gcloud storage ls -l gs://YOUR-BUCKET-NAME/ada.jpg
  ```

如果成功，命令將返回類似以下的訊息：

`306768  2017-12-26T16:07:570Z  gs://YOUR-BUCKET-NAME/ada.jpg
TOTAL: 1 objects, 30678 bytes (360.1 KiB)`

現在您知道圖片的大小和建立日期。

**預期結果：**
物件詳細資訊已成功檢索。

### 步驟 8：使您的物件公開可訪問
- 使用 `gsutil acl ch` 命令授予所有用戶對儲存在您儲存桶中的物件的讀取權限：

  ```bash
  gsutil acl ch -u AllUsers:R gs://YOUR-BUCKET-NAME/ada.jpg
  ```

如果成功，命令將返回：

`Updated ACL on gs://YOUR-BUCKET-NAME/ada.jpg`

您的圖片現在是公開的，並且可以提供給任何人訪問。

**預期結果：**
物件權限已成功設定為公開。

### 步驟 9：驗證物件公開可訪問
- 前往 **Navigation menu** > **Cloud Storage**，然後點擊儲存桶的名稱。

您應該看到您的圖片帶有 **Public link** 框。點擊 **Copy URL** 並在新瀏覽器標籤中開啟 URL。

**注意：** 您在看誰？這是 [Ada Lovelace](https://en.wikipedia.org/wiki/Ada_Lovelace)，被稱為第一位電腦程式設計師。她與數學家兼電腦先驅 Charles Babbage 合作，後者提出了 [Analytical Engine](https://en.wikipedia.org/wiki/Analytical_Engine)。

**預期結果：**
物件已成功設為公開可訪問，並且可以通過公共 URL 訪問。

### 步驟 10：移除公開訪問
1. 要移除此權限，請使用命令：

   ```bash
   gsutil acl ch -d AllUsers gs://YOUR-BUCKET-NAME/ada.jpg
   ```

如果成功，命令將返回：

`Updated ACL on gs://YOUR-BUCKET-NAME/ada.jpg`

您已移除對此物件的公開訪問。

2. 通過點擊控制台中的 **Refresh** 按鈕驗證您已移除公開訪問。核取標記將被移除。

**預期結果：**
物件的公開訪問已成功移除。

### 步驟 11：刪除物件
1. 使用 `gcloud storage rm` 命令刪除儲存桶中的圖片檔案：

   ```bash
   gcloud storage rm gs://YOUR-BUCKET-NAME/ada.jpg
   ```

如果成功，命令將返回：

`Removing gs://YOUR-BUCKET-NAME/ada.jpg...`

2. 重新整理控制台。圖片檔案的副本不再儲存在 Cloud Storage 上（不過您在 `image-folder/` 資料夾中建立的副本仍然存在）。

**預期結果：**
物件已成功從 Cloud Storage 儲存桶刪除。

## 驗證
要驗證實驗已成功完成：
1. 確認儲存桶已建立
2. 確認物件已上傳並可訪問
3. 確認資料夾結構正確
4. 確認公開訪問權限正確設定和移除
5. 確認物件已正確刪除

## 故障排除
常見問題及其解決方案：
- **儲存桶名稱衝突**：選擇一個唯一的儲存桶名稱
- **權限錯誤**：確保您有足夠的 GCP 權限
- **物件未找到**：檢查物件路徑和名稱是否正確
- **公開訪問失敗**：驗證 ACL 命令語法正確
- **刪除失敗**：確保物件存在且您有刪除權限

## 清理
為避免費用，請按照以下步驟清理資源：
1. 刪除儲存桶中的所有物件：
   ```bash
   gcloud storage rm -r gs://YOUR-BUCKET-NAME/**
   ```

2. 刪除儲存桶：
   ```bash
   gcloud storage buckets delete gs://YOUR-BUCKET-NAME
   ```

## 其他資源
- [Cloud Storage 文件](https://cloud.google.com/storage/docs/)
- [gcloud storage 命令參考](https://cloud.google.com/sdk/gcloud/reference/storage)
- [gsutil 工具指南](https://cloud.google.com/storage/docs/gsutil)
- [Cloud Storage 安全最佳實務](https://cloud.google.com/storage/docs/best-practices)
- [Ada Lovelace Wikipedia 頁面](https://en.wikipedia.org/wiki/Ada_Lovelace)

## 筆記
此實驗演示了 Cloud Storage 的基本操作。關鍵學習點包括：
- Cloud Storage 儲存桶命名規則和限制
- 使用 gcloud 和 gsutil 命令進行物件操作
- ACL 權限管理和公開訪問控制
- 物件版本控制和生命週期管理
- Cloud Storage 在災難恢復和歸檔中的作用
