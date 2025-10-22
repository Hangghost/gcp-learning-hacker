#!/bin/bash

# GSP192-Dataflow: Qwik Start - Templates Automation Script

# --- Configuration Variables ---
# You can change these values if needed, or they will be prompted at runtime.
GCP_REGION="us-central1"
GCP_ZONE="us-central1-a"

# --- Functions ---

# Function to display messages
log_message() {
  echo "--- $(date +'%Y-%m-%d %H:%M:%S') --- $1"
}

# Function to prompt for user input with a default value
prompt_for_input() {
  local var_name="$1"
  local prompt_text="$2"
  local default_value="$3"
  read -p "$prompt_text [$default_value]: " input
  eval "$var_name=\${input:-\$default_value}"
}

# Function to run gcloud commands with error checking
run_gcloud_command() {
  log_message "執行命令: gcloud $@"
  gcloud "$@"
  if [ $? -ne 0 ]; then
    log_message "錯誤: gcloud 命令失敗: $@"
    exit 1
  fi
}

# Function to run gsutil commands with error checking
run_gsutil_command() {
  log_message "執行命令: gsutil $@"
  gsutil "$@"
  if [ $? -ne 0 ]; then
    log_message "錯誤: gsutil 命令失敗: $@"
    exit 1
  fi
}

# Function to run bq commands with error checking
run_bq_command() {
  log_message "執行命令: bq $@"
  bq "$@"
  if [ $? -ne 0 ]; then
    log_message "錯誤: bq 命令失敗: $@"
    exit 1
  fi
}

# Cleanup function
cleanup() {
  log_message "開始清理 Lab 資源..."

  # Stop Dataflow job
  log_message "停止 Dataflow 作業..."
  gcloud dataflow jobs list --region=$GCP_REGION --filter="name:iotflow" --format="value(job_id)" | while read job_id; do
    if [ ! -z "$job_id" ]; then
      log_message "停止作業 ID: $job_id"
      gcloud dataflow jobs cancel $job_id --region=$GCP_REGION
    fi
  done

  # Delete BigQuery dataset
  log_message "刪除 BigQuery 資料集: taxirides"
  bq rm -r -f taxirides 2>/dev/null || log_message "BigQuery 資料集可能已被刪除或不存在"

  # Delete Cloud Storage bucket
  if [ ! -z "$BUCKET_NAME" ]; then
    log_message "刪除 Cloud Storage bucket: gs://$BUCKET_NAME"
    gsutil -m rm -r "gs://$BUCKET_NAME" 2>/dev/null || log_message "Cloud Storage bucket 可能已被刪除或不存在"
  fi

  log_message "清理完成。"
}

# Trap for cleanup on exit
trap cleanup EXIT

# --- Main Lab Steps ---

log_message "GSP192-Dataflow: Qwik Start - Templates - 自動化腳本開始執行"

# Prompt for configuration
prompt_for_input "GCP_REGION" "請輸入 GCP 區域" "$GCP_REGION"
log_message "使用區域: $GCP_REGION"

# Set bucket name to project ID for uniqueness
BUCKET_NAME=$GOOGLE_CLOUD_PROJECT
log_message "使用專案 ID 作為 bucket 名稱: $BUCKET_NAME"

# Prompt for method choice
echo ""
echo "請選擇創建 BigQuery 資源和 Cloud Storage bucket 的方法:"
echo "1. Cloud Shell (命令行)"
echo "2. Cloud Console (網頁介面)"
read -p "請輸入選擇 (1 或 2) [1]: " method_choice
method_choice=${method_choice:-1}

# Task 1: Ensure Dataflow API is re-enabled
log_message "任務 1: 確保 Dataflow API 重新啟用"
run_gcloud_command services disable dataflow.googleapis.com --project $GOOGLE_CLOUD_PROJECT --force
run_gcloud_command services enable dataflow.googleapis.com --project $GOOGLE_CLOUD_PROJECT

if [ "$method_choice" = "1" ]; then
  # Task 2: Create resources using Cloud Shell

  log_message "任務 2: 使用 Cloud Shell 創建 BigQuery 資料集和表"

  # Create BigQuery dataset
  log_message "建立 BigQuery 資料集: taxirides"
  run_bq_command mk taxirides

  # Create BigQuery table
  log_message "建立 BigQuery 表: realtime"
  run_bq_command mk \
  --time_partitioning_field timestamp \
  --schema ride_id:string,point_idx:integer,latitude:float,longitude:float,\
timestamp:timestamp,meter_reading:float,meter_increment:float,ride_status:string,\
passenger_count:integer -t taxirides.realtime

  # Create Cloud Storage bucket
  log_message "建立 Cloud Storage bucket: gs://$BUCKET_NAME/"
  run_gsutil_command mb gs://$BUCKET_NAME/

elif [ "$method_choice" = "2" ]; then
  # Task 3: Create resources using Cloud Console

  log_message "任務 3: 使用 Cloud Console 創建資源"

  echo ""
  echo "請手動在 Cloud Console 中完成以下步驟:"
  echo "1. 前往 BigQuery > 點擊專案名稱旁的三个點 > Create dataset"
  echo "   - 資料集 ID: taxirides"
  echo "   - 資料位置: us (multiple regions in United States)"
  echo ""
  echo "2. 點擊 taxirides 資料集 > CREATE TABLE"
  echo "   - 表名稱: realtime"
  echo "   - Schema (Edit as text):"
  echo "     ride_id:string,point_idx:integer,latitude:float,longitude:float,timestamp:timestamp,"
  echo "     meter_reading:float,meter_increment:float,ride_status:string,passenger_count:integer"
  echo ""
  echo "3. 前往 Cloud Storage > Buckets > Create bucket"
  echo "   - Bucket 名稱: $BUCKET_NAME"
  echo ""
  read -n 1 -s -r -p "完成後請按任意鍵繼續..."
  echo ""

else
  log_message "錯誤: 無效選擇。腳本終止。"
  exit 1
fi

# Task 4: Run the pipeline
log_message "任務 4: 運行 Dataflow 管道"

run_gcloud_command dataflow jobs run iotflow \
    --gcs-location gs://dataflow-templates-$GCP_REGION/latest/PubSub_to_BigQuery \
    --region $GCP_REGION \
    --worker-machine-type e2-medium \
    --staging-location gs://$BUCKET_NAME/temp \
    --parameters inputTopic=projects/pubsub-public-data/topics/taxirides-realtime,outputTableSpec=$GOOGLE_CLOUD_PROJECT:taxirides.realtime

log_message "Dataflow 作業已啟動。等待 2 分鐘讓管道完全啟動..."
sleep 120

# Task 5: Submit a query
log_message "任務 5: 提交查詢以驗證資料"

# Wait a bit more for data to start flowing
log_message "等待資料填充到 BigQuery 表中..."
sleep 60

# Run the query
log_message "運行查詢檢索前 1000 條記錄..."
bq query --use_legacy_sql=false "SELECT * FROM \`$GOOGLE_CLOUD_PROJECT.taxirides.realtime\` LIMIT 1000"

log_message "GSP192-Dataflow: Qwik Start - Templates - 自動化腳本執行完成"
log_message "您可以在 Dataflow Console 中查看作業狀態"
log_message "腳本退出時將自動清理資源"
