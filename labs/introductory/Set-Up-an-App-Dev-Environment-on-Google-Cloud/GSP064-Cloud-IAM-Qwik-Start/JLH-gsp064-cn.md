# GSP064 - Cloud IAM：Qwik Start

## 實驗概述
Google Cloud 的 Identity and Access Management (IAM) 服務讓您能夠為 Google Cloud 資源建立和管理權限。Cloud IAM 將 Google Cloud 服務的存取控制統一到單一系統中，並提供一致的操作集。

在本實作實驗中，您將使用 2 組不同的認證登入，體驗授予和撤銷權限的工作原理，從 Google Cloud 專案擁有者和檢視者角色。

## 先決條件
- Google Cloud Platform 帳戶
- 基本熟悉 Google Cloud Console
- 了解 Cloud IAM 的基本概念（建議但非必要）
- 準備一個 .txt 或 .html 檔案（如果您想深入學習 Cloud IAM，請參考以下 Google Cloud Skills Boost 實驗室：[IAM Custom Roles](https://www.cloudskillsboost.google/catalog_lab/955)）

## 實驗目標
完成本實驗後，您將能夠：
- 為第二個使用者指派角色
- 移除與 Cloud IAM 相關聯的已指派角色

## 預估時間
30-45 分鐘

## 實驗步驟

### 步驟 1：探索 IAM 主控台和專案層級角色
在本任務中，您將探索 IAM 主控台並了解專案層級角色。

**指令：**
1. 返回 **Username 1** Cloud Console 頁面。
2. 選取 **Navigation menu** > **IAM & Admin** > **IAM**。您現在位於 "IAM & Admin" 主控台。
3. 點擊頁面頂部的 **+GRANT ACCESS** 按鈕。
4. 向下捲動到 **Basic** 在 Select a role 區段並將滑鼠移到上方。

您會看到三個角色：

- Editor
- Owner
- Viewer

這些是 Google Cloud 中的*原始角色*。原始角色在專案層級設定權限，除非另有指定，否則它們控制所有 Google Cloud 服務的存取和管理。

以下表格從 Google Cloud IAM 文章 [Basic roles](https://cloud.google.com/iam/docs/understanding-roles#primitive_roles) 摘錄，簡要概述瀏覽器、檢視者、編輯者和擁有者角色權限：

| **角色名稱** | **權限** |
| --- | --- |
| roles/viewer | 唯讀動作的權限，不會影響狀態，例如檢視（但不修改）現有資源或資料。 |
| roles/editor | 所有檢視者權限，加上修改狀態的動作權限，例如變更現有資源。 |
| roles/owner | 所有編輯者權限，加上以下動作的權限：<br>• 管理專案及其所有資源的角色和權限。<br>• 設定專案的計費。 |

由於您能夠管理此專案的角色和權限，Username 1 擁有專案擁有者權限。

**預期結果：**
您可以看到三個基本角色及其權限說明。

### 步驟 2：探索編輯者角色
現在切換到 **Username 2** 主控台。

**指令：**
1. 導覽到 IAM & Admin 主控台，選取 **Navigation menu** > **IAM & Admin** > **IAM**。
2. 搜尋表格以找到 Username 1 和 Username 2，並檢查他們被授予的角色。在每個使用者右側的行內和右側會列出 Username 1 和 Username 2 的角色。

您應該看到：

- Username 2 被授予 "Viewer" 角色。
- **+GRANT ACCESS** 按鈕在頁面頂部變灰色—if 您試圖點擊它，您會收到訊息："You need permissions for this action. Required permission(s): resource manager.projects.setIamPolicy"。

這是一個範例，說明 IAM 角色如何影響您在 Google Cloud 中能夠做什麼和不能做什麼。

**預期結果：**
Username 2 只能看到檢視者權限，並且無法授予存取權限。

### 步驟 3：準備 Cloud Storage 儲存桶以進行存取測試
確保您位於 **Username 1** Cloud Console。

#### 建立儲存桶

**指令：**
1. 從 Cloud Console 選取 **Navigation menu** > **Cloud Storage** > **Buckets** 建立 Cloud Storage 儲存桶。
2. 點擊 **+CREATE**。

**注意：**如果您收到權限錯誤建立儲存桶，請登出然後重新登入 Username 1 認證。

1. 更新以下欄位，將所有其他欄位保留為預設值：

| **屬性** | **值** |
| --- | --- |
| **Name**: | *全域唯一名稱（自行建立！）並點擊 **CONTINUE**。* |
| **Location Type:** | Multi-Region |

記下儲存桶名稱。您將在稍後步驟中使用它。

1. 點擊 **CREATE**。
2. 如果出現提示，Public access will be prevented，點擊 **Confirm**。

**注意：**如果您收到權限錯誤建立儲存桶，請登出然後重新登入 Username 1 認證。

#### 上傳範例檔案

**指令：**
1. 在 Bucket Details 頁面點擊 **UPLOAD FILES**。
2. 瀏覽您的電腦以找到要使用的檔案。任何文字或 html 檔案都可以。
3. 點擊包含檔案的行末尾的三個點，然後點擊 **Rename**。
4. 將檔案重新命名為 'sample.txt'。
5. 點擊 **RENAME**。

**預期結果：**
儲存桶已建立並上傳了 sample.txt 檔案。

### 步驟 4：驗證專案檢視者存取權限

**指令：**
1. 切換到 **Username 2** 主控台。
2. 從 Console 選取 **Navigation menu** > **Cloud Storage** > **Buckets**。驗證此使用者可以查看儲存桶。

Username 2 擁有 "Viewer" 角色，這允許他們進行唯讀動作，不會影響狀態。這範例說明了此功能—they 可以查看 Cloud Storage 儲存桶和檔案，這些檔案託管在他們已被授予存取權限的 Google Cloud 專案中。

**預期結果：**
Username 2 可以查看儲存桶內容。

### 步驟 5：移除專案存取權限
切換到 **Username 1** 主控台。

#### 移除 Username 2 的專案檢視者權限

**指令：**
1. 選取 **Navigation menu** > **IAM & Admin** > **IAM**。然後點擊 **Username 2** 右側行內的鉛筆圖示。

**注意：**您可能需要放大螢幕才能看到鉛筆圖示。

1. 通過點擊角色名稱旁邊的垃圾桶圖示來移除 **Username 2** 的專案檢視者存取權限。然後點擊 **SAVE**。

請注意，使用者已從成員清單中消失！使用者現在沒有存取權限。

**注意：**此變更可能需要長達 80 秒才能生效，因為它會在整個系統中傳播。請參閱 Google Cloud IAM 資源文件 [Frequently asked questions](https://cloud.google.com/iam/docs/faq) 了解更多資訊。

#### 驗證 Username 2 已失去存取權限

**指令：**
1. 切換到 **Username 2** Cloud Console。確保您仍以 Username 2 的認證登入，並且在權限被撤銷後沒有被登出專案。如果已登出，請重新以正確認證登入。
2. 通過選取 **Navigation menu** > **Cloud Storage** > **Buckets** 重新導覽到 Cloud Storage。

您應該會看到權限錯誤。

**注意**：如前所述，此權限撤銷可能需要長達 80 秒。如果您沒有收到權限錯誤，請等待 2 分鐘然後重新整理控制台。

**預期結果：**
Username 2 無法再存取 Cloud Storage 資源。

### 步驟 6：新增 Cloud Storage 權限

**指令：**
1. 從 **Lab Connection** 面板複製 **Username 2** 名稱。
2. 切換到 **Username 1** 主控台。確保您仍以 Username 1 的認證登入。如果您已登出，請重新以正確認證登入。
3. 在 Console 中選取 **Navigation menu** > **IAM & Admin** > **IAM**。
4. 點擊 **+GRANT ACCESS** 按鈕並將 **Username 2** 名稱貼上到 **New principals** 欄位。
5. 在 **Select a role** 欄位中，從下拉式選單選取 **Cloud Storage** > **Storage Object Viewer**。
6. 點擊 **SAVE**。

#### 驗證存取權限

**指令：**
1. 切換到 **Username 2** 主控台。您仍會在 Storage 頁面。

**Username 2** 沒有專案檢視者角色，所以該使用者無法在 Console 中查看專案或其任何資源。然而，此使用者對 Cloud Storage 有特定存取權限，Storage Object Viewer 角色 - 現在就來檢查它。

1. 點擊 **Activate Cloud Shell** 開啟 Cloud Shell 命令列。如果出現提示請點擊 **Continue**。

   [啟動 cloud shell 的圖示](https://cdn.qwiklabs.com/ep8HmqYGdD%2FkUncAAYpV47OYoHwC8%2Bg0WK%2F8sidHquE%3D)

2. 開啟 Cloud Shell 工作階段，然後輸入以下命令，將 `[YOUR_BUCKET_NAME]` 替換為您稍早建立的儲存桶名稱：

`gsutil ls gs://[YOUR_BUCKET_NAME]`

您應該會收到類似輸出：

`gs://[YOUR_BUCKET_NAME]/sample.txt`

**注意：**如果您看到 `AccessDeniedException`，請稍等一分鐘然後重新執行上述命令。

**預期結果：**
Username 2 現在可以通過 gsutil 命令查看 Cloud Storage 儲存桶內容。

## 驗證
成功完成實驗的驗證步驟：

1. **步驟 3**：儲存桶建立並上傳檔案
2. **步驟 4**：Username 2 可以查看儲存桶
3. **步驟 5**：Username 2 失去專案存取權限
4. **步驟 6**：Username 2 獲得 Cloud Storage 特定權限

## 故障排除
常見問題和解決方案：
- **權限錯誤建立儲存桶**：請確認您使用的是 Username 1 認證，並重新登入
- **IAM 變更未立即生效**：等待 80 秒讓權限傳播
- **Cloud Shell 存取被拒絕**：確保您使用的是 Username 2 認證並有正確權限
- **gsutil 命令失敗**：檢查儲存桶名稱拼寫並確保區域設定正確

## 清理
清理資源以避免費用：
1. 刪除 Cloud Storage 儲存桶：
   ```bash
   gsutil rm -r gs://[YOUR_BUCKET_NAME]
   ```
2. 移除 IAM 權限（如果需要）：
   - 返回 IAM 主控台移除任何測試權限

## 額外資源
- [Google Cloud IAM 文件](https://cloud.google.com/iam/docs)
- [IAM 基本角色](https://cloud.google.com/iam/docs/understanding-roles#primitive_roles)
- [IAM 自訂角色實驗室](https://www.cloudskillsboost.google/catalog_lab/955)
- [IAM 常見問題](https://cloud.google.com/iam/docs/faq)

## 注意
此實驗室演示了 IAM 角色的基本概念：
- 原始角色（Viewer、Editor、Owner）在專案層級運作
- 特定服務角色可以提供更精細的權限控制
- IAM 變更可能需要時間傳播
- 權限可以動態授予和撤銷
