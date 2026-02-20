# website-hosting-gsutil - Configure Cloud Storage Bucket for Website Hosting using gsutil - 逐步操作指南

## 實驗室概述
本實驗室要求將現有的 Cloud Storage Bucket 配置為靜態網站代管環境。你需要設定首頁與錯誤頁面，並確保 Bucket 內的資源可供大眾存取，讓網站能夠透過 URL 直接訪問。

## 先決條件
- 基本的 Google Cloud 控制台操作經驗。
- 熟悉 Cloud Storage 的基本概念。
- 基本的 `gsutil` 指令操作能力。

## 預估時間
- 5 - 10 分鐘

---

## 任務列表

### 任務 1：設定 Bucket 為網站代管 (Website Hosting)

在此任務中，你需要將指定的 Bucket 設定為網站代管模式，並將權限開放給所有使用者。

1. **設定環境變數**：
   自動擷取目前專案中的 Bucket 名稱。
   ```bash
   export BUCKET_NAME=$(gcloud storage buckets list --format="value(name)")
   echo "目前的 Bucket 名稱: $BUCKET_NAME"
   ```

2. **設定首頁與錯誤頁面**：
   使用 `gsutil web set` 指令將 `index.html` 設定為首頁，`error.html` 設定為自定義錯誤頁面。
   ```bash
   gsutil web set -m index.html -e error.html gs://$BUCKET_NAME
   ```
   - `-m index.html`：指定當使用者存取根路徑時顯示的檔案。
   - `-e error.html`：指定當發生 404 錯誤時顯示的檔案。

3. **關閉統一 Bucket 層級存取 (Uniform Bucket-Level Access)**：
   要使用 ACL 控制個別物件權限，必須先關閉 UBLA。這是**關鍵步驟**！
   ```bash
   gcloud storage buckets update gs://$BUCKET_NAME --no-uniform-bucket-level-access
   ```
   - 此步驟允許您對 Bucket 內的個別物件設定不同的存取控制清單 (ACL)。
   - 如果啟用 UBLA，所有 ACL 相關的 `gsutil` 指令都會失敗。

4. **設定預設物件 ACL 為公開讀取**：
   為未來上傳到此 Bucket 的所有物件設定預設公開權限。
   ```bash
   gsutil defacl set public-read gs://$BUCKET_NAME
   ```
   - `public-read`：新上傳的檔案會自動擁有公開讀取權限。

5. **為現有檔案套用公開讀取 ACL**：
   將 Bucket 內現有的所有檔案設為公開可讀。**這是驗證通過的關鍵步驟！**
   ```bash
   gsutil -m acl set -a public-read gs://$BUCKET_NAME/*
   ```
   - `-m`：啟用多執行緒平行處理，加快批次操作。
   - `-a public-read`：套用預定義的公開讀取 ACL。
   - `gs://$BUCKET_NAME/*`：對 Bucket 內所有物件執行操作。

6. **驗證 ACL 設定**：
   確認 `index.html` 已正確設定公開讀取權限。
   ```bash
   gsutil acl get gs://$BUCKET_NAME/index.html
   ```
   應該會看到類似以下的輸出，確認 `allUsers` 擁有 `READER` 角色：
   ```json
   [
     {
       "entity": "allUsers",
       "role": "READER"
     }
   ]
   ```

### 驗證步驟

1. **使用 curl 測試公開存取**（推薦，最快速）：
   ```bash
   curl -I https://storage.googleapis.com/$BUCKET_NAME/index.html
   ```
   如果設定成功，應該會看到 `HTTP/2 200` 狀態碼。

2. **在瀏覽器中測試**：
   輸入以下 URL 進行測試：
   ```
   https://storage.googleapis.com/<你的-BUCKET-名稱>/index.html
   ```
   或是
   ```
   http://<你的-BUCKET-名稱>.storage.googleapis.com/index.html
   ```
   確認是否能正確看到 `index.html` 的內容以及圖片。

3. **測試錯誤頁面**：
   嘗試存取一個不存在的檔案（例如 `test.html`），確認是否顯示 `error.html`。

---

## 執行指南

### 常見問題與解決方案

#### 1. **ACL 指令失敗：「Cannot use ACL API when uniform bucket-level access is enabled」**
   **原因**：Bucket 啟用了統一 Bucket 層級存取 (UBLA)，無法使用 ACL 指令。
   
   **解決方案**：
   ```bash
   # 關閉 UBLA
   gcloud storage buckets update gs://$BUCKET_NAME --no-uniform-bucket-level-access
   
   # 然後再執行 ACL 相關指令
   gsutil defacl set public-read gs://$BUCKET_NAME
   gsutil -m acl set -a public-read gs://$BUCKET_NAME/*
   ```

#### 2. **權限錯誤：「Failed to set acl...Please ensure you have OWNER-role access」**
   **原因**：可能 UBLA 仍然啟用，或您沒有足夠的權限。
   
   **解決方案**：
   - 確認 UBLA 已關閉：`gcloud storage buckets describe gs://$BUCKET_NAME --format="default(iamConfiguration)"`
   - 使用批次設定 ACL：`gsutil -m acl set -a public-read gs://$BUCKET_NAME/*`

#### 3. **Qwiklabs 驗證無法通過**
   **原因**：驗證腳本檢查的是物件層級的 ACL，而非 Bucket 層級的 IAM 權限。
   
   **解決方案**：必須執行步驟 5「為現有檔案套用公開讀取 ACL」：
   ```bash
   gsutil -m acl set -a public-read gs://$BUCKET_NAME/*
   ```
   
   **驗證是否設定成功**：
   ```bash
   gsutil acl get gs://$BUCKET_NAME/index.html
   ```
   應該會看到 `"entity": "allUsers"` 和 `"role": "READER"`。

#### 4. **找不到 Bucket**
   如果專案中有多個 Bucket，自動擷取的指令可能會抓到多個。請手動檢查 `gsutil ls` 並指定正確的 `BUCKET_NAME`。

#### 5. **網頁可以訪問但驗證失敗**
   僅設定 IAM 權限 (`gsutil iam ch` 或 `gcloud storage buckets add-iam-policy-binding`) 可能不足以通過驗證。Qwiklabs 的驗證腳本通常檢查 **物件層級的 ACL**，因此必須執行：
   ```bash
   gsutil -m acl set -a public-read gs://$BUCKET_NAME/*
   ```

### 提示與技巧
- **靜態網站 URL 格式**：Cloud Storage 提供兩種主要的存取網址格式：
  - `storage.googleapis.com/BUCKET_NAME/index.html` (API 存取格式)
  - `BUCKET_NAME.storage.googleapis.com/index.html` (CNAME/網站存取格式)
- **快取機制**：如果你修改了檔案但網頁沒更新，可能是瀏覽器快取或 Cloud Storage 的快取設定。測試時建議使用無痕模式。

### 清理步驟
若需移除公開權限並取消網站設定：
```bash
# 移除公開存取權限
gsutil iam ch -d allUsers:objectViewer gs://$BUCKET_NAME

# 清除網站設定
gsutil web set gs://$BUCKET_NAME
```

## 額外資源
- [Google Cloud 官方文件：託管靜態網站](https://cloud.google.com/storage/docs/hosting-static-website)
- [gsutil web 指令說明](https://cloud.google.com/storage/docs/gsutil/commands/web)

## 技術筆記

### gsutil vs gcloud storage
- 本 Lab 使用 `gsutil` 工具。雖然 `gcloud storage` 是較新的工具，但在許多既有的挑戰實驗室中，`gsutil` 仍然是設定網站代管屬性（如 `-m` 和 `-e`）最直接的方式。

### IAM 權限 vs ACL (Access Control List)
這是本 Lab 最容易混淆的地方：

- **IAM 權限**（Bucket 層級）：
  - 使用 `gsutil iam ch` 或 `gcloud storage buckets add-iam-policy-binding`
  - 在整個 Bucket 層級設定權限
  - 當 UBLA 啟用時，只能使用這種方式
  - **但是**：Qwiklabs 驗證腳本通常不檢查 IAM 權限

- **ACL**（物件層級）：
  - 使用 `gsutil acl ch` 或 `gsutil acl set`
  - 直接在每個物件上設定權限
  - 只有在 UBLA **關閉**時才能使用
  - **重要**：Qwiklabs 驗證腳本通常檢查物件的 ACL

### Uniform Bucket-Level Access (UBLA)
- **啟用 UBLA**：統一使用 IAM，無法設定個別物件的 ACL（更現代、更安全）
- **關閉 UBLA**：可以使用 ACL 對個別物件設定權限（傳統方式，但更靈活）
- 許多 Qwiklabs 實驗的驗證腳本是在 UBLA 出現之前設計的，因此期待使用 ACL
- 這就是為什麼必須先關閉 UBLA，然後設定物件層級的 ACL

### 成功通過驗證的完整流程
1. 設定網站配置（`gsutil web set`）
2. **關閉 UBLA**（`gcloud storage buckets update --no-uniform-bucket-level-access`）
3. 設定預設 ACL（`gsutil defacl set public-read`）
4. **為現有物件套用 ACL**（`gsutil -m acl set -a public-read gs://$BUCKET_NAME/*`）← 關鍵！
5. 驗證設定（`gsutil acl get gs://$BUCKET_NAME/index.html`）
