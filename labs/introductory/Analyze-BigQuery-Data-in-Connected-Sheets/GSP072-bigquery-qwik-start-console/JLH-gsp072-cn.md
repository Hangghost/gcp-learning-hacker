# BigQuery：快速起步 - 控制台

## 實驗標題
BigQuery：快速起步 - 控制台

## 實驗簡述
本實驗將引導您使用 BigQuery 查詢公開資料集並載入範例資料。BigQuery 是 Google Cloud 的企業級資料倉儲服務，能夠使用 Google 基礎設施的處理能力進行超快速 SQL 查詢。

## 先決條件
- Google Cloud 帳戶並啟用 BigQuery API
- 基本的 SQL 知識
- Google Cloud Console 存取權限

## 實驗目標
完成本實驗後，您將能夠：
- 查詢公開資料集
- 建立新的資料集
- 將資料載入至新表格
- 查詢自訂表格

## 預估時間
30 分鐘

## 實驗步驟

### 步驟 1：開啟 BigQuery

1. 在 Google Cloud Console 中，選擇**導航選單** > **BigQuery**
2. 點擊**完成**關閉歡迎訊息

**預期結果：** BigQuery 控制台開啟並可供使用。

### 步驟 2：查詢公開資料集

1. 點擊 **+**（SQL 查詢）建立新查詢
2. 複製並貼上以下查詢到 BigQuery 查詢編輯器：

```sql
#standardSQL
SELECT
 weight_pounds, state, year, gestation_weeks
FROM
 `bigquery-public-data.samples.natality`
ORDER BY weight_pounds DESC LIMIT 10;
```

3. 點擊**執行**按鈕

**預期結果：** 查詢結果顯示美國出生率資料的前 10 筆記錄（按出生體重降序排列）。

### 步驟 3：建立新資料集

1. 在**資源管理器**窗格中，點擊您的專案 ID 旁的**檢視動作**圖示（三點選單）
2. 選擇**建立資料集**
3. 設定**資料集 ID**為 `babynames`
4. 保留所有其他欄位為預設值
5. 點擊**建立資料集**

**預期結果：** 成功建立 `babynames` 資料集並顯示在資源管理器中。

### 步驟 4：將資料載入新表格

1. 在資源管理器中，找到 `babynames` 資料集
2. 點擊資料集旁的**檢視動作**圖示（三點選單）
3. 選擇**建立表格**
4. 在建立表格對話框中設定以下欄位：

| **欄位** | **值** |
|----------|--------|
| 從 Google Cloud Storage 建立表格 | 選取 |
| 從 GCS 儲存桶選擇檔案 | `spls/gsp072/baby-names/yob2014.txt` |
| 檔案格式 | CSV |
| 表格名稱 | `names_2014` |
| 結構描述 > 以文字編輯 | 開啟，然後在文字框中新增：`name:string,gender:string,count:integer` |

5. 點擊**建立表格**按鈕

**預期結果：** BigQuery 完成表格建立和資料載入後，`names_2014` 表格會顯示在 `babynames` 資料集下。

### 步驟 5：預覽表格

1. 在資源管理器中點擊 `names_2014` 表格
2. 點擊**預覽**標籤

**預期結果：** 顯示表格的前幾行資料，確認資料已正確載入。

### 步驟 6：查詢自訂資料集

1. 在 BigQuery 中點擊頂部的 **+**（SQL 查詢）圖示
2. 貼上或輸入以下查詢到查詢編輯器：

```sql
#standardSQL
SELECT
 name, count
FROM
 `babynames.names_2014`
WHERE
 gender = 'M'
ORDER BY count DESC LIMIT 5;
```

3. 點擊**執行**按鈕

**預期結果：** 查詢顯示 2014 年最受歡迎的 5 個男孩姓名及其出現次數。

## 驗證步驟

### 檢查點 1：查詢公開資料集
- 確認成功執行公開資料集查詢
- 驗證查詢結果顯示出生體重、州別、年份和懷孕週數等欄位

### 檢查點 2：建立資料集
- 確認 `babynames` 資料集已成功建立並顯示在資源管理器中

### 檢查點 3：載入資料
- 確認 `names_2014` 表格已成功建立並載入資料

### 檢查點 4：查詢自訂資料集
- 確認成功查詢自訂表格並顯示 2014 年最受歡迎的男孩姓名

## 故障排除

### 常見問題與解決方案

**問題：查詢執行失敗**
- 確認 BigQuery API 已啟用
- 檢查查詢語法是否正確
- 確認公開資料集存取權限

**問題：無法載入資料**
- 確認 Cloud Storage 檔案路徑正確：`spls/gsp072/baby-names/yob2014.txt`
- 確認檔案格式設定為 CSV
- 確認結構描述定義正確：`name:string,gender:string,count:integer`

**問題：資料集建立失敗**
- 確認專案 ID 正確
- 確認沒有使用保留字作為資料集名稱
- 檢查專案配額和權限

**問題：預覽表格時發生錯誤**
- 確認表格已成功建立並載入資料
- 檢查網路連線
- 重新整理 BigQuery 控制台

## 清理指示

完成實驗後，請執行以下步驟清理資源以避免產生費用：

1. **刪除資料集**：
   - 在資源管理器中找到 `babynames` 資料集
   - 點擊資料集旁的**檢視動作**圖示（三點選單）
   - 選擇**刪除**
   - 在確認對話框中輸入 `babynames` 確認刪除

2. **確認清理完成**：
   - 確認 `babynames` 資料集已從資源管理器中移除
   - 檢查不會產生額外費用

## 額外資源

### 官方文件
- [BigQuery 快速起步指南](https://cloud.google.com/bigquery/docs/quickstarts/quickstart-web-ui)
- [BigQuery 公開資料集](https://cloud.google.com/bigquery/public-data)
- [BigQuery 查詢參考](https://cloud.google.com/bigquery/docs/reference/standard-sql/query-syntax)

### 相關實驗
- [Cloud Storage 快速起步系列](../Set-Up-an-App-Dev-Environment-on-Google-Cloud/cloud-storage-qwik-start-series.md)
- [Pub/Sub 快速起步 - 控制台](../Set-Up-an-App-Dev-Environment-on-Google-Cloud/GSP096-Pub-Sub-Qwik-Start-Console/)

### 進階學習資源
- [BigQuery 最佳實務](https://cloud.google.com/bigquery/docs/best-practices)
- [BigQuery 效能調校](https://cloud.google.com/bigquery/docs/performance)
- [BigQuery 安全性考量](https://cloud.google.com/bigquery/docs/security)

## 筆記
- 本實驗使用的公開資料集 `bigquery-public-data.samples.natality` 包含美國出生率統計資料
- 自訂資料使用美國社會安全局提供的 2014 年嬰兒姓名資料
- BigQuery 使用標準 SQL 語法，並支援巢狀和重複欄位等進階功能
- 實驗中載入的資料約 7MB，適合學習用途
