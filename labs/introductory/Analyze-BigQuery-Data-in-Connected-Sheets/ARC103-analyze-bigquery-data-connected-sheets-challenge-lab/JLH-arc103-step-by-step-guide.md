# ARC103 - Analyze BigQuery Data in Connected Sheets: Challenge Lab - 逐步操作指南

## 實驗室概述
這是基於 GSP072、GSP469 和 GSP870 實驗室內容，為 ARC103 挑戰實驗室創建的實際操作指南。本指南將引導您完成所有 5 個任務。

## 先決條件
- Google Cloud 帳戶與實驗室憑證
- 網際網路連線與 Chrome 瀏覽器
- 基本的 Google Sheets 操作知識

## 預估時間
60-90 分鐘

---

## 任務 1：開啟 Google Sheets 並連接到 BigQuery 數據集

### 步驟詳情
1. **開啟 Google Sheets**
   - 點擊實驗室的 **Start Lab** 按鈕獲取臨時憑證
   - 在新的無痕視窗中開啟 [Google Sheets 首頁](https://docs.google.com/spreadsheets/)
   - 使用實驗室提供的憑證登入

2. **建立新的試算表**
   - 在 Google Sheets 首頁點擊 **Blank Spreadsheet** 按鈕
   - 建立空白試算表並等待載入完成

3. **連接到 BigQuery 數據集**
   - 在試算表中選擇 **Data** > **Data Connectors** > **Connect to BigQuery**
   - 在彈出視窗中點擊 **Get Connected**
   - 導航到：**YOUR PROJECT ID** > **Public datasets** > **new_york_taxi_trips**
   - 選擇 **tlc_yellow_trips_2022** 並點擊 **Connect**
   - 等待約一分鐘直到看到成功訊息

### 驗證步驟
- 確認成功連接到 `new_york_taxi_trips.tlc_yellow_trips_2022` 數據集
- 應該能看到數據預覽

---

## 任務 2：使用公式計算包含機場費用的行程數量

### 步驟詳情
1. **建立新工作表進行計算**
   - 點擊試算表底部的 **+** 按鈕建立新工作表
   - 將工作表重新命名為 **"Airport Fee Analysis"**

2. **使用 COUNTIF 公式計算包含機場費用的行程**
   ```
   =COUNTIF(tlc_yellow_trips_2022!airport_fee, ">0")
   ```

3. **驗證公式結果**
   - 公式應該返回包含機場費用的行程總數
   - 確認結果為正數且合理

### 驗證步驟
- 確認公式正確計算並返回預期的行程數量
- 點擊 **Check my progress** 驗證任務 2

---

## 任務 3：建立圓餅圖顯示付款類型分佈

### 步驟詳情
1. **返回原始數據工作表**
   - 切換回 `tlc_yellow_trips_2022` 工作表

2. **建立圓餅圖**
   - 點擊試算表中的 **Chart** 按鈕
   - 選擇 **New Sheet** 並點擊 **Create**
   - 在 Chart editor 中選擇 **Pie chart** 作為圖表類型

3. **設定圖表數據**
   - 將 `payment_type` 欄位拖曳到 **Label** 欄位
   - 將任何數值欄位（如 `fare_amount`）拖曳到 **Value** 欄位
   - 在 **Value** 設定中，將彙總函數改為 **Count**

4. **套用圖表設定**
   - 點擊 **Apply** 產生圓餅圖

### 驗證步驟
- 確認圓餅圖正確顯示不同付款類型的分佈
- 圖表應該顯示信用卡、現金等付款方式的比例
- 點擊 **Check my progress** 驗證任務 3

---

## 任務 4：從 BigQuery 提取數據到 Connected Sheets

### 步驟詳情
1. **開啟數據提取工具**
   - 返回 `tlc_yellow_trips_2022` 工作表
   - 點擊試算表中的 **Extract** 按鈕
   - 選擇 **New sheet** 並點擊 **Create**

2. **設定提取參數**
   - 在 Extract editor 中點擊 **Columns** 區段的 **Edit**
   - 選擇以下欄位：
     - `pickup_datetime`
     - `dropoff_datetime`
     - `trip_distance`
     - `fare_amount`

3. **設定排序選項**
   - 在 **Sort** 區段點擊 **Add**
   - 選擇 `trip_distance` 欄位
   - 選擇 **Desc**（降冪排序）

4. **設定資料列數量限制**
   - 在 **Row limit** 設定為 **10000**（提取 10,000 行）

5. **執行數據提取**
   - 點擊 **Apply** 開始提取數據

### 驗證步驟
- 確認成功提取 10,000 行數據
- 驗證數據按行程距離降冪排序
- 確認包含所有指定的欄位
- 點擊 **Check my progress** 驗證任務 4

---

## 任務 5：計算過路費在車費中的百分比

### 步驟詳情
1. **開啟計算欄位工具**
   - 返回 `tlc_yellow_trips_2022` 工作表
   - 點擊試算表中的 **Calculated columns** 按鈕

2. **建立計算欄位**
   - 在 **Calculated column name** 欄位輸入 `toll_percentage`
   - 輸入以下公式：
     ```
     =IF(fare_amount>0, tolls_amount/fare_amount*100, 0)
     ```

3. **套用計算欄位**
   - 點擊 **Add** 新增計算欄位
   - 點擊 **Apply** 套用計算

### 驗證步驟
- 確認新欄位 `toll_percentage` 正確計算
- 驗證百分比計算邏輯正確
- 確認結果顯示為百分比格式
- 點擊 **Check my progress** 驗證任務 5

---

## 故障排除指南

### 常見問題與解決方案

**問題：無法連接到 BigQuery 數據集**
- 確認使用正確的實驗室憑證登入
- 檢查網路連線
- 確認選擇正確的公開數據集路徑：`new_york_taxi_trips.tlc_yellow_trips_2022`

**問題：公式顯示錯誤**
- 確認欄位名稱拼寫正確（注意區分大小寫）
- 檢查公式語法是否正確
- 確認數據類型匹配

**問題：圖表無法載入**
- 檢查網路連線
- 嘗試重新整理頁面
- 確認選擇了正確的數據欄位

**問題：數據提取失敗**
- 確認查詢語法正確
- 檢查 Row limit 是否設定合理
- 確認欄位名稱正確

**問題：計算欄位顯示錯誤**
- 確認公式邏輯正確
- 檢查分母為零的情況處理
- 確認欄位名稱與數據集匹配

---

## 清理步驟

實驗室結束後：
1. 關閉所有開啟的 Google Sheets 文件
2. 登出實驗室帳戶（特別是如果使用共用電腦）
3. 實驗環境會自動清理臨時資源

---

## 額外資源

- [BigQuery 官方文檔](https://cloud.google.com/bigquery/docs)
- [Connected Sheets 指南](https://cloud.google.com/bigquery/docs/connected-sheets)
- [Google Sheets 函數參考](https://support.google.com/docs/table/25273)
- [紐約計程車數據集說明](https://cloud.google.com/bigquery/public-data/new-york-taxi)

---

## 技術筆記

- 本實驗室使用公開的紐約計程車行程數據（2022年）
- Connected Sheets 允許直接在 Google Sheets 中查詢和分析 BigQuery 數據
- 所有操作都在 Google Sheets 介面中完成，不需要命令列操作
- 實驗室完成時間約為 60-90 分鐘

**祝實驗成功！** 🎉
