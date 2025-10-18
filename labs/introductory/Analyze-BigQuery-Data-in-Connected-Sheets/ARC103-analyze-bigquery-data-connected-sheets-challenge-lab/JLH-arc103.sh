#!/bin/bash

# ARC103 - Analyze BigQuery Data in Connected Sheets: Challenge Lab
# 自動化腳本 - 實驗室記錄和指導工具

set -e

# 腳本開始時間
START_TIME=$(date +%s)

echo "==============================================="
echo "ARC103 - Analyze BigQuery Data in Connected Sheets: Challenge Lab"
echo "實驗室開始時間: $(date)"
echo "==============================================="

# 檢查必要工具
check_prerequisites() {
    echo "檢查必要工具..."

    # 檢查 gcloud CLI（雖然此實驗室不需要，但用於驗證登入狀態）
    if command -v gcloud &> /dev/null; then
        echo "✓ gcloud CLI 已安裝"
        # 檢查是否已登入
        if gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 > /dev/null 2>&1; then
            echo "✓ gcloud 已登入"
            PROJECT_ID=$(gcloud config get-value project)
            echo "✓ 目前專案: $PROJECT_ID"
        else
            echo "⚠ 警告: gcloud 未登入，但此實驗室不需要命令列操作"
        fi
    else
        echo "⚠ 警告: gcloud CLI 未安裝，但此實驗室不需要命令列操作"
    fi

    echo ""
}

# 實驗室任務記錄函數
record_task() {
    local task_num=$1
    local task_desc=$2

    echo "=== 任務 $task_num ==="
    echo "任務描述: $task_desc"
    echo "開始時間: $(date)"
    echo ""

    # 記錄任務開始
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 任務 $task_num 開始: $task_desc" >> arc103_progress.log
}

# 任務完成記錄函數
complete_task() {
    local task_num=$1

    echo "✓ 任務 $task_num 已完成"
    echo "完成時間: $(date)"
    echo ""

    # 記錄任務完成
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 任務 $task_num 完成" >> arc103_progress.log
}

# 顯示任務說明函數
show_task_details() {
    local task_num=$1
    local details=$2

    echo "任務詳情:"
    echo "$details"
    echo ""
}

# 主實驗室流程
run_lab() {
    echo "開始實驗室流程..."
    echo ""

    # 任務 1：開啟 Google Sheets 並連接到 BigQuery 數據集
    record_task "1" "開啟 Google Sheets 並連接到 BigQuery 數據集"
    show_task_details "1" "
步驟說明:
1. 使用實驗室提供的憑證登入 Google Sheets
2. 連接到 BigQuery 公共數據集：new_york_taxi_trips.tlc_yellow_trips_2022
3. 確認連線成功並能看到數據

驗證步驟:
- 點擊 'Check my progress' 來驗證目標
"
    read -p "請確認已完成任務 1 並按 Enter 繼續..."
    complete_task "1"

    # 任務 2：使用公式計算符合特定條件的行數
    record_task "2" "使用公式計算符合特定條件的行數"
    show_task_details "2" "
步驟說明:
1. 使用公式計算包含機場費用的計程車行程數量
2. 確認公式正確運作並返回正確結果

驗證步驟:
- 點擊 'Check my progress' 來驗證目標
"
    read -p "請確認已完成任務 2 並按 Enter 繼續..."
    complete_task "2"

    # 任務 3：建立圖表視覺化 BigQuery 數據
    record_task "3" "建立圖表視覺化 BigQuery 數據"
    show_task_details "3" "
步驟說明:
1. 建立圓餅圖，顯示哪種付款類型最常被用來支付車費金額
2. 使用付款類型代碼對應：
   - 1: Credit Card（信用卡）
   - 2: Cash（現金）
   - 3: No charge（免費）
   - 4: Dispute（爭議）
   - 5: Unknown（未知）
   - 6: Voided trip（取消行程）

驗證步驟:
- 點擊 'Check my progress' 來驗證目標
"
    read -p "請確認已完成任務 3 並按 Enter 繼續..."
    complete_task "3"

    # 任務 4：從 BigQuery 提取數據到 Connected Sheets
    record_task "4" "從 BigQuery 提取數據到 Connected Sheets"
    show_task_details "4" "
步驟說明:
1. 從以下欄位提取 10,000 行數據：
   - pickup_datetime（上車時間）
   - dropoff_datetime（下車時間）
   - trip_distance（行程距離）
   - fare_amount（車費金額）
2. 按最長行程優先排序

驗證步驟:
- 點擊 'Check my progress' 來驗證目標
"
    read -p "請確認已完成任務 4 並按 Enter 繼續..."
    complete_task "4"

    # 任務 5：計算新欄位以轉換現有欄位數據
    record_task "5" "計算新欄位以轉換現有欄位數據"
    show_task_details "5" "
步驟說明:
1. 計算新欄位，顯示每個車費金額中用於支付過路費的比例（基於 toll_amount 欄位）
2. 確認計算正確並顯示正確百分比

驗證步驟:
- 點擊 'Check my progress' 來驗證目標
"
    read -p "請確認已完成任務 5 並按 Enter 繼續..."
    complete_task "5"

    echo "恭喜！所有實驗室任務已完成！"
    echo ""
}

# 清理函數
cleanup() {
    echo "實驗室清理..."
    echo "此實驗室不需要特殊的清理步驟"
    echo "Connected Sheets 會自動處理暫存數據"
    echo "請確保在實驗室結束後登出所有服務"
    echo ""
}

# 顯示實驗室摘要
show_summary() {
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    echo "==============================================="
    echo "實驗室完成摘要"
    echo "開始時間: $(date -d @$START_TIME)"
    echo "完成時間: $(date)"
    echo "總耗時: $((DURATION / 60)) 分鐘 $((DURATION % 60)) 秒"
    echo ""
    echo "進度記錄檔案: arc103_progress.log"
    echo "==============================================="
}

# 主選單
main_menu() {
    echo "ARC103 實驗室自動化腳本"
    echo "1. 開始實驗室"
    echo "2. 檢查先決條件"
    echo "3. 顯示任務摘要"
    echo "4. 清理資源"
    echo "5. 退出"
    echo ""
    read -p "請選擇選項 (1-5): " choice

    case $choice in
        1)
            check_prerequisites
            run_lab
            show_summary
            ;;
        2)
            check_prerequisites
            ;;
        3)
            echo "實驗室任務摘要:"
            echo "任務 1: 開啟 Google Sheets 並連接到 BigQuery 數據集"
            echo "任務 2: 使用公式計算包含機場費用的行程數量"
            echo "任務 3: 建立圓餅圖顯示付款類型分佈"
            echo "任務 4: 提取並排序 10,000 行計程車數據"
            echo "任務 5: 計算過路費在車費中的百分比"
            echo ""
            ;;
        4)
            cleanup
            ;;
        5)
            echo "感謝使用 ARC103 實驗室腳本！"
            exit 0
            ;;
        *)
            echo "無效選項，請重新選擇"
            main_menu
            ;;
    esac
}

# 創建進度記錄檔案
touch arc103_progress.log

# 執行主選單
main_menu
