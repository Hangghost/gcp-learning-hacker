# GSP073 - Cloud Storage: Qwik Start - Cloud Console

## 概述

Cloud Storage 允許在全球範圍內儲存和檢索任何數量的資料，隨時隨地存取。您可以使用 Cloud Storage 處理各種場景，包括提供網站內容、儲存資料以供歸檔和災難恢復，或透過直接下載向用戶分發大型資料物件。

## 先決條件

- 具備基本的 Google Cloud Platform 知識
- 已啟用 Cloud Storage API
- 具備 Cloud Console 的基本操作知識

## 學習目標

完成本實驗後，您將能夠：
- 建立 Cloud Storage bucket
- 上傳物件到 bucket
- 在 bucket 中建立資料夾和子資料夾
- 讓 bucket 中的物件公開存取

## 預估時間

30-45 分鐘

## 實驗步驟

### 步驟 1：建立 Bucket

Bucket 是 Cloud Storage 中保存資料的基本容器。

**指示：**

1. 在 Cloud Console 中，前往 **導航選單** > **Cloud Storage** > **Buckets**
2. 點擊 **+ 建立**
3. 輸入您的 bucket 資訊並點擊 **繼續** 完成每個步驟：
   - **命名您的 bucket**：為您的 bucket 輸入唯一名稱。對於本實驗，您可以使用您的 **專案 ID** 作為 bucket 名稱，因為它總是唯一的。
   
   **Bucket 命名規則：**
   - 不要在 bucket 名稱中包含敏感資訊，因為 bucket 命名空間是全域且公開可見的
   - Bucket 名稱只能包含小寫字母、數字、連字號 (-)、底線 (_) 和點 (.)
   - Bucket 名稱必須以數字或字母開頭和結尾
   - Bucket 名稱必須包含 3 到 63 個字元
   - Bucket 名稱不能表示為點分十進位記法的 IP 位址
   - Bucket 名稱不能以 "goog" 前綴開頭
   - 選擇 **區域** 作為 **位置類型** 和 `<filled in at lab start>` 作為 **位置**
   - 選擇 **標準** 作為 **預設儲存類別**
   - 選擇 **統一** 作為 **存取控制** 並 **取消勾選** *在此 bucket 上強制執行公開存取預防* 以將其關閉

4. 保留其餘欄位為預設值並點擊 **建立**

**預期結果：**
您應該看到新建立的 bucket 出現在 bucket 清單中。

**注意：** 如果系統提示「將防止公開存取」，請取消勾選 *在此 bucket 上強制執行公開存取預防* 並點擊 **確認**。

### 步驟 2：上傳物件到 Bucket

**指示：**

1. 右鍵點擊實驗中的小貓圖片並下載到您的電腦。將圖片另存為 **kitten.png**，在下載時重新命名
2. 在 Cloud Storage 瀏覽器頁面中，點擊您建立的 bucket 名稱
3. 在 **物件** 標籤中，點擊 **上傳** > **上傳檔案**
4. 在檔案對話框中，前往您下載的檔案並選擇它
5. 確保檔案名為 **kitten.png**。如果不是，點擊檔案的 **三點** 圖示，從下拉選單中選擇 **重新命名**，並將檔案重新命名為 **kitten.png**

**預期結果：**
上傳完成後，您應該看到檔案名稱和檔案資訊，例如其大小和類型。

### 步驟 3：公開分享 Bucket

**指示：**

1. 點擊檔案清單上方的 **權限** 標籤
2. 確保檢視設定為 **主體**。點擊 **授予存取權** 以檢視 **新增主體** 窗格
3. 在 **新主體** 方塊中，輸入 *allUsers*
4. 在 **選擇角色** 下拉選單中，選擇 **Cloud Storage** > **Storage Object Viewer**
5. 點擊 **儲存**
6. 在 **您確定要讓此資源公開嗎？** 視窗中，點擊 **允許公開存取**

**驗證：**
1. 點擊 **物件** 標籤返回物件清單。您物件的 **公開存取** 欄位應顯示 **對網際網路公開**
2. 按 **複製 URL** 按鈕並貼到新分頁中以檢視您的圖片

**注意：** 如果您的物件在執行上述步驟後沒有顯示為公開，您可能需要重新整理瀏覽器頁面。

### 步驟 4：建立資料夾

**指示：**

1. 在 **物件** 標籤中，點擊 **建立資料夾**
2. 輸入 **folder1** 作為 **名稱** 並點擊 **建立**

**建立子資料夾並上傳檔案：**

1. 點擊 **folder1**
2. 點擊 **建立資料夾**
3. 輸入 **folder2** 作為 **名稱** 並點擊 **建立**
4. 點擊 **folder2**
5. 點擊 **上傳** > **上傳檔案**
6. 在檔案對話框中，導航到您下載的截圖並選擇它

**預期結果：**
您應該在 bucket 中看到帶有資料夾圖示的資料夾，以區分它與物件。

### 步驟 5：刪除資料夾

**指示：**

1. 點擊 **Bucket 詳細資訊** 旁的箭頭返回 bucket 層級
2. 選擇 bucket
3. 點擊 **刪除** 按鈕
4. 在開啟的視窗中，輸入 `DELETE` 以確認刪除資料夾
5. 點擊 **刪除** 以永久刪除資料夾及其中的所有物件和子資料夾

## 驗證

完成以下檢查以確認實驗成功：

1. **Bucket 建立**：bucket 出現在 Cloud Storage 瀏覽器中
2. **物件上傳**：kitten.png 檔案出現在 bucket 的物件清單中
3. **公開存取**：物件的公開存取狀態顯示為「對網際網路公開」
4. **資料夾結構**：成功建立 folder1/folder2 的巢狀結構
5. **URL 存取**：可以透過公開 URL 存取圖片

## 故障排除

常見問題及其解決方案：

- **Bucket 名稱衝突**：確保使用唯一的 bucket 名稱，建議使用專案 ID
- **公開存取失敗**：確認已取消勾選「強制執行公開存取預防」選項
- **上傳失敗**：檢查檔案大小限制和網路連線
- **權限錯誤**：確保您有適當的 IAM 權限來管理 Cloud Storage

## 清理

為避免產生費用，請清理建立的資源：

1. 返回 Cloud Storage 瀏覽器
2. 選擇您建立的 bucket
3. 點擊 **刪除**
4. 在確認對話框中輸入 `DELETE`
5. 點擊 **刪除** 以永久刪除 bucket 和所有內容

## 額外資源

- [Cloud Storage 文件](https://cloud.google.com/storage/docs)
- [Cloud Storage 最佳實務](https://cloud.google.com/storage/docs/best-practices)
- [Cloud Storage 安全指南](https://cloud.google.com/storage/docs/security)
- [Cloud Storage 定價](https://cloud.google.com/storage/pricing)

## 相關實驗

- GSP074: Cloud Storage: Qwik Start - CLI
- GSP075: Cloud Storage: Qwik Start - gsutil
- GSP076: Cloud Storage: Qwik Start - Cloud Console

## 筆記

在此記錄您的個人筆記和觀察：

- Bucket 命名的重要性
- 公開存取的安全性考量
- 資料夾結構的最佳實務
- 成本優化建議
