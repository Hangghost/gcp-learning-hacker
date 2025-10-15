#!/bin/bash

# Connected Sheets: Qwik Start - GSP870
# 自動化腳本 - 主要用於記錄和檢查進度

set -e  # 遇到錯誤時停止執行

LAB_ID="GSP870"
LAB_TITLE="Connected Sheets: Qwik Start"

echo "======================================"
echo "   ${LAB_ID}: ${LAB_TITLE}"
echo "======================================"
echo ""
echo "此腳本用於記錄和檢查實驗進度。"
echo "大部分步驟需要手動在瀏覽器中執行。"
echo ""

# 檢查是否設定了必要環境變數
if [ -z "$PROJECT_ID" ]; then
    echo "警告: PROJECT_ID 未設定"
    echo "請設定您的 GCP 專案 ID:"
    echo "export PROJECT_ID=\"your-project-id\""
    echo ""
fi

# 步驟 1：開啟 Google Sheets
echo "步驟 1：開啟 Google Sheets"
echo "請在新的無痕視窗中開啟 Google Sheets："
echo "https://docs.google.com/spreadsheets/"
echo ""
echo "請登入並建立新的空白試算表"
echo ""
read -p "按 Enter 鍵繼續..."

# 步驟 2：連接到 BigQuery 資料集
echo "步驟 2：連接到 BigQuery 資料集"
echo "在 Google Sheets 中："
echo "1. 選擇 Data > Data Connectors > Connect to BigQuery"
echo "2. 選擇 Public datasets > chicago_taxi_trips"
echo "3. 選擇 taxi_trips 並點擊 Connect"
echo ""
echo "等待連線完成（約 1 分鐘）"
echo ""
read -p "連線完成後按 Enter 鍵繼續..."

# 步驟 3：使用公式
echo "步驟 3：使用公式"
echo "建立新工作表並使用公式："
echo ""
echo "建立新工作表並執行以下公式："
echo "A1: =COUNTUNIQUE(taxi_trips!company)"
echo "D1: =COUNTIF(taxi_trips!tips,\">0\")"
echo "E1: =COUNTIF(taxi_trips!fare,\">0\")"
echo "F1: =D1/E1"
echo ""
read -p "公式執行完成後按 Enter 鍵繼續..."

# 步驟 4：使用圖表
echo "步驟 4：使用圖表"
echo "1. 返回 taxi_trips 標籤頁"
echo "2. 點擊 Chart 按鈕建立圓餅圖"
echo "3. 設定 payment_type 為 Label，fare 為 Value"
echo "4. 將 Sum 改為 Count"
echo ""
echo "然後建立折線圖："
echo "1. 建立新圖表，選擇 Line 類型"
echo "2. 設定 trip_start_timestamp 為 X-axis（Year-Month）"
echo "3. 設定 fare 為 Series"
echo "4. 加入篩選條件：payment_type 包含 'mobile'"
echo ""
read -p "圖表建立完成後按 Enter 鍵繼續..."

# 步驟 5：使用樞紐分析表
echo "步驟 5：使用樞紐分析表"
echo "1. 返回 taxi_trips 標籤頁"
echo "2. 點擊 Pivot table 按鈕"
echo "3. 設定 trip_start_timestamp 為 Rows（Hour）"
echo "4. 設定 fare 為 Values（COUNTA）"
echo ""
echo "細分按星期幾："
echo "1. 設定 trip_start_timestamp 為 Columns（Day of the week）"
echo "2. 套用條件式格式（白色到綠色）"
echo "3. 將 Summarize by 改為 Average"
echo ""
read -p "樞紐分析表建立完成後按 Enter 鍵繼續..."

# 步驟 6：使用資料提取
echo "步驟 6：使用資料提取"
echo "1. 返回 taxi_trips 標籤頁"
echo "2. 點擊 Extract 按鈕"
echo "3. 選擇欄位：trip_start_timestamp, fare, tips, tolls"
echo "4. 排序：trip_start_timestamp (降冪)"
echo "5. Row limit：25000"
echo ""
read -p "資料提取完成後按 Enter 鍵繼續..."

# 步驟 7：計算欄位
echo "步驟 7：計算欄位"
echo "1. 返回 taxi_trips 標籤頁"
echo "2. 點擊 Calculated columns 按鈕"
echo "3. 欄位名稱：tip_percentage"
echo "4. 公式：=IF(fare>0,tips/fare*100,0)"
echo ""
read -p "計算欄位建立完成後按 Enter 鍵繼續..."

# 步驟 8：重新整理與排程重新整理
echo "步驟 8：重新整理與排程重新整理"
echo "1. 選取圖表或表格，點擊 Refresh 按鈕"
echo "2. 或者選擇 Refresh options > Refresh all"
echo "3. 設定排程重新整理（Schedule refresh）"
echo ""
read -p "重新整理設定完成後按 Enter 鍵繼續..."

# 檢查點驗證
echo ""
echo "======================================"
echo "檢查點驗證"
echo "======================================"
echo ""
echo "請確認以下項目："
echo "✓ 已連接到 BigQuery 資料集"
echo "✓ 已建立並執行公式"
echo "✓ 已建立圓餅圖和折線圖"
echo "✓ 已建立樞紐分析表"
echo "✓ 已執行資料提取"
echo "✓ 已建立計算欄位"
echo "✓ 已設定重新整理選項"
echo ""

# 完成訊息
echo "======================================"
echo "實驗完成！"
echo "======================================"
echo ""
echo "恭喜！您已經完成了 ${LAB_ID}: ${LAB_TITLE}"
echo ""
echo "此實驗展示了如何將 BigQuery 的強大資料分析功能"
echo "與 Google Sheets 的熟悉介面結合。"
echo ""
echo "請記得清理資源並登出 Google 帳戶。"
echo ""

# 記錄完成時間
echo "$(date): ${LAB_ID} 實驗完成" >> ~/.gcp_lab_completion.log

echo "實驗進度已記錄到 ~/.gcp_lab_completion.log"
