# Connected Sheets: Qwik Start

## Lab 標題
Connected Sheets 快速開始：將 BigQuery 資料倉儲與 Google Sheets 連結

## 先決條件
- 標準網際網路瀏覽器（建議使用 Chrome）
- 存取 Google Cloud 帳戶的權限
- Google Sheets 基本知識

## 目標
完成此實驗後，您將能夠：
- 將 BigQuery 資料集連接到 Google Sheets
- 使用公式計算小費百分比
- 使用圖表分析付款類型趨勢
- 使用樞紐分析表找出計程車費用最高的時間
- 使用資料提取功能從 BigQuery 匯入資料到 Connected Sheets
- 使用計算欄位建立新欄位
- 設定排程自動更新資料

## 預估時間
60 分鐘

## Lab 步驟

### 步驟 1：開啟 Google Sheets
開始實驗並開啟 Google Sheets。

**指示：**
1. 點擊 **Start Lab** 按鈕。在左側面板中會顯示您在此實驗期間必須使用的臨時憑證。
2. 在新的無痕視窗中，開啟 [Google Sheets 首頁](https://docs.google.com/spreadsheets/)
3. 在 Google **Sign in** 頁面中，貼上來自 **Connection Details** 面板的使用者名稱，然後複製並貼上密碼
4. 如果看到 **Choose an account** 頁面，請點擊 **Use another account**
5. 點擊並通過後續頁面：
   - 接受條款和條件
   - 不要新增復原選項或雙重驗證（因為這是臨時帳戶）
   - 不要註冊免費試用
6. 在 **Google Sheets** 首頁中，點擊 **Blank Spreadsheet** 按鈕建立新的試算表

**預期結果：**
您將看到空白的 Google Sheets 試算表，並準備好連接到 BigQuery 資料集。

### 步驟 2：連接到 BigQuery 資料集
將芝加哥計程車行程的公開資料集連接到 Google Sheets。

**指示：**
1. 選擇 **Data** > **Data Connectors** > **Connect to BigQuery**
2. 如果看到 **Connect and Analyze big data in Sheets** 彈出視窗，請點擊 **Get Connected**
3. 選擇 **YOUR PROJECT ID** > **Public datasets** > **chicago_taxi_trips**
4. 選擇 **taxi_trips** 並點擊 **Connect**
5. 等待約一分鐘，直到看到成功訊息

**預期結果：**
您已經成功將 BigQuery 資料集連接到 Google Sheets！

### 步驟 3：使用公式
學習如何在 Connected Sheets 中使用公式。首先找出芝加哥有多少家計程車公司。

**指示：**
1. 選擇 **Function** > **COUNTUNIQUE** 並將其新增到新工作表
2. 確保選擇 **New Sheet** 並點擊 **Create**
3. 修改儲存格 A1 的值為：
   ```
   =COUNTUNIQUE(taxi_trips!company)
   ```
4. 點擊 **Apply**

接下來找出包含小費的計程車行程百分比：

5. 使用 `COUNTIF` 函數找出包含小費的行程總數。複製並貼上此函數到 D1 儲存格：
   ```
   =COUNTIF(taxi_trips!tips,">0")
   ```
6. 點擊 **Apply**
7. 使用 `COUNTIF` 函數找出車資大於 0 的行程總數。將此函數新增到 E1 儲存格：
   ```
   =COUNTIF(taxi_trips!fare,">0")
   ```
8. 點擊 **Apply**
9. 比較前兩個步驟的值。將此函數新增到 F1 儲存格：
   ```
   =D1/E1
   ```

**預期結果：**
芝加哥約有 38.6% 的計程車行程包含小費（結果可能因資料日期而異）。

### 步驟 4：使用圖表
分析人們使用哪些付款方式，以及行動支付收入如何隨時間變化。

**指示：**
1. 返回 **taxi_trips** 標籤頁
2. 點擊 **Chart** 按鈕，確保選擇 **New Sheet** 並點擊 **Create**
3. 在 Chart editor 視窗中，於 Chart type 下選擇 **Pie chart**
4. 將 **payment_type** 拖曳到 **Label** 欄位，然後將 **fare** 拖曳到 **Value** 欄位並點擊 **Apply**
5. 在 **Value** > **Fare** 下，將 Sum 變更為 **Count**，然後點擊 **Apply**

接下來分析行動支付隨時間的變化：

6. 返回 **taxi_trips** 標籤頁
7. 選擇 **Chart** 按鈕，確保選擇 **New Sheet** 並點擊 **Create**
8. 點擊 **Chart Type** 下拉選單，選擇 **Line** 下的第一個選項
9. 將 **trip_start_timestamp** 拖曳到 **X-axis** 欄位
10. 勾選 **Group by** 選項並從下拉選單中選擇 **Year-Month**
11. 將 **fare** 拖曳到 **Series** 欄位
12. 點擊 **Apply**
13. 在 **Filter** 下點擊 **Add > payment_type**
14. 選擇 **Showing all items** 狀態下拉選單
15. 點擊 **Filter by Condition** 下拉選單並選擇 **Text contains**
16. 在 **Value** 欄位輸入 **mobile**
17. 點擊 **OK**
18. 點擊 **Apply** 產生新的折線圖

**預期結果：**
您可以看到行動支付呈現整體上升趨勢。

### 步驟 5：使用樞紐分析表
分析一天中什麼時間計程車行程最多，以及什麼時間最貴。

**指示：**
1. 返回 **taxi_trips** 標籤頁
2. 點擊 **Pivot table** 按鈕
3. 確保選擇 **New sheet** 並點擊 **Create**
4. 將 **trip_start_timestamp** 拖曳到 **Rows** 欄位
5. 選擇 **Hour** 作為 Group By 選項
6. 將 **fare** 拖曳到 **Values** 欄位
7. 選擇 **COUNTA** 作為 **Summarize by** 選項
8. 點擊 **Apply**

接下來按星期幾細分：

9. 將 **trip_start_timestamp** 拖曳到 **Columns** 欄位
10. 選擇 **Day of the week** 作為 Group by 選項
11. 點擊 **Apply**
12. 選擇資料範圍 B3:H26，選擇 **Format** > **Number** > **Number**
13. 點擊減少小數位數按鈕兩次，使資料更容易閱讀

套用條件式格式：

14. 選擇所有資料儲存格（從第一個 Sunday 值到最後一個 Saturday 值）
15. 點擊 **Format** > **Conditional formatting**
16. 選擇 **Color scale**
17. 在 **Preview** 下選擇顏色並選擇 **White to Green**
18. 點擊 **Done**
19. 關閉 **Conditional Formatting** 視窗

分析最貴的時間：

20. 在 **Values** 欄位，將 **Summarize by** 選項變更為 **Average**
21. 點擊 **Apply**

**預期結果：**
週一早上的計程車費用最貴！

### 步驟 6：使用資料提取
從 BigQuery 匯入特定資料子集到 Connected Sheets。

**指示：**
1. 返回 **taxi_trips** 標籤頁
2. 點擊 **Extract** 按鈕
3. 確保選擇 **New sheet** 並點擊 **Create**
4. 在 **Extract editor** 視窗中，點擊 Columns 區段下的 **Edit**，選擇 **trip_start_timestamp**、**fare**、**tips** 和 **tolls** 欄位
5. 點擊 **Sort** 區段下的 **Add**，選擇 **trip_start_timestamp**，點擊 **Desc** 切換為降冪排序
6. 在 **Row limit** 下維持 25000 匯入 25000 列資料
7. 點擊 **Apply**

**預期結果：**
您已經從 BigQuery 提取了數千列原始資料到 Connected Sheets！

### 步驟 7：計算欄位
建立計算欄位來計算小費百分比。

**指示：**
1. 返回 **taxi_trips** 標籤頁
2. 點擊 **Calculated columns** 按鈕
3. 在 **Calculated column name** 欄位輸入 `tip_percentage`
4. 複製並貼上以下公式到公式欄位：
   ```
   =IF(fare>0,tips/fare*100,0)
   ```
5. 點擊 **Add**
6. 點擊 **Apply**

**預期結果：**
您現在可以在 **tip_percentage** 欄位中看到車資的小費百分比。

### 步驟 8：重新整理與排程重新整理
學習如何更新資料或設定自動更新。

**指示：**
1. 要更新圖表或表格，請選取它然後點擊 **Refresh** 按鈕
2. 或者點擊資料集名稱旁的 **Refresh options** 按鈕，然後選擇 **Refresh all** 更新所有 Connected Sheets 分析
3. 要設定排程重新整理，請點擊 **Schedule refresh**
4. 選擇所需的頻率和時間進行自動資料重新整理
5. 點擊 **Save**

## 驗證
點擊每個任務中的 *Check my progress* 按鈕來驗證目標達成。

## 故障排除
常見問題與解決方案：
- **連接到 BigQuery 失敗**：確保使用正確的專案 ID 和公開資料集路徑
- **公式顯示錯誤**：確認語法正確，並檢查欄位名稱拼寫
- **圖表無法載入**：檢查網路連線，並嘗試重新整理頁面
- **資料提取逾時**：減少資料列數量或簡化查詢條件

## 清理
實驗結束後：
1. 關閉所有開啟的 Google Sheets 文件
2. 登出 Google 帳戶（特別是如果使用共用電腦）
3. 實驗環境會自動清理臨時資源

## 額外資源
- [Connected Sheets 官方文件](https://cloud.google.com/bigquery/docs/connected-sheets)
- [Google Sheets 公式參考](https://support.google.com/docs/table/25273)
- [BigQuery 公開資料集](https://cloud.google.com/bigquery/public-data)

## 備註
此實驗展示了如何將 BigQuery 的強大資料分析功能與 Google Sheets 的熟悉介面結合，讓非資料分析師也能輕鬆處理大規模資料集。
