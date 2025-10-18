# ARC103-Analyze BigQuery data in Connected Sheets: Challenge Lab - 挑戰實驗室

## 簡介 (Overview)
這是 **ARC103-Analyze BigQuery data in Connected Sheets: Challenge Lab** 挑戰實驗室的完整指南。本實驗室旨在測試您在 Google Cloud 平台上分析 BigQuery 數據並使用 Connected Sheets 的實作能力。

## 任務列表 (Tasks)
在此實驗室中，您需要完成以下任務：
- **任務 1：開啟 Google Sheets 並連接到 BigQuery 數據集**
- **任務 2：使用公式計算符合特定條件的行數**
- **任務 3：建立圖表視覺化 BigQuery 數據**
- **任務 4：從 BigQuery 提取數據到 Connected Sheets**
- **任務 5：計算新欄位以轉換現有欄位數據**

## 挑戰實驗室摘要 (Challenge Lab Summary)

本節提供完成每個任務所需的指令。請按照以下步驟執行，確保您已設定所有必要的變數。

### 初始變數設定 (Initial Variable Settings)
```bash
# 此挑戰實驗室不需要特定的環境變數設定
# 但請確保您已登入正確的 Google Cloud 專案
# export PROJECT_ID=$(gcloud config get-value project)
```

### 任務步驟 (Task Steps)

#### 任務 1：開啟 Google Sheets 並連接到 BigQuery 數據集
1. 登入 Google Sheets（使用實驗室提供的憑證）
2. 連接到 BigQuery 公共數據集：`new_york_taxi_trips.tlc_yellow_trips_2022`
3. 確認連線成功並能看到數據

#### 任務 2：使用公式計算符合特定條件的行數
1. 使用公式計算包含機場費用的計程車行程數量
2. 確認公式正確運作並返回正確結果

#### 任務 3：建立圖表視覺化 BigQuery 數據
1. 建立圓餅圖，顯示哪種付款類型最常被用來支付車費金額
2. 使用以下付款類型代碼對應：
   - 1: Credit Card（信用卡）
   - 2: Cash（現金）
   - 3: No charge（免費）
   - 4: Dispute（爭議）
   - 5: Unknown（未知）
   - 6: Voided trip（取消行程）

#### 任務 4：從 BigQuery 提取數據到 Connected Sheets
1. 從以下欄位提取 10,000 行數據：
   - pickup_datetime（上車時間）
   - dropoff_datetime（下車時間）
   - trip_distance（行程距離）
   - fare_amount（車費金額）
2. 按最長行程優先排序

#### 任務 5：計算新欄位以轉換現有欄位數據
1. 計算新欄位，顯示每個車費金額中用於支付過路費的比例（基於 toll_amount 欄位）
2. 確認計算正確並顯示正確百分比

## 驗證步驟 (Verification Steps)

每個任務完成後，請點擊 "Check my progress" 按鈕來驗證目標：

1. **任務 1 驗證**：確認 BigQuery 連線成功
2. **任務 2 驗證**：確認公式計算正確的機場費用行程數量
3. **任務 3 驗證**：確認圓餅圖正確顯示付款類型分佈
4. **任務 4 驗證**：確認成功提取並排序 10,000 行數據
5. **任務 5 驗證**：確認新欄位正確計算過路費百分比

## 故障排除 (Troubleshooting)

### 常見問題與解決方案：
- **BigQuery 連線失敗**：確認使用正確的實驗室憑證，並檢查網路連線
- **公式計算錯誤**：仔細檢查公式語法，並確認欄位名稱正確
- **圖表顯示異常**：確認數據類型正確，並檢查圖表設定
- **數據提取失敗**：確認查詢語法正確，並檢查配額限制

## 清理指示 (Cleanup Instructions)
```bash
# 此實驗室不需要特殊的清理步驟
# Connected Sheets 會自動處理暫存數據
# 請確保在實驗室結束後登出所有服務
```

## 額外資源 (Additional Resources)
- [BigQuery 官方文檔](https://cloud.google.com/bigquery/docs)
- [Connected Sheets 指南](https://cloud.google.com/bigquery/docs/connected-sheets)
- [Google Sheets 函數參考](https://support.google.com/docs/table/25273)
- [紐約計程車數據集說明](https://cloud.google.com/bigquery/public-data/new-york-taxi)

## 技術筆記 (Technical Notes)
- 本實驗室使用公開的紐約計程車行程數據
- Connected Sheets 允許直接在 Google Sheets 中查詢 BigQuery 數據
- 實驗室完成時間約為 60-90 分鐘
- 所有操作都在 Google Sheets 介面中完成，不需要命令列操作
