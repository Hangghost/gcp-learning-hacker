#!/bin/bash

# GSP207-Dataflow: Qwik Start - Python Automation Script

# --- Configuration Variables ---
# You can change these values if needed, or they will be prompted at runtime.
GCP_REGION="us-central1"
BUCKET_SUFFIX="bucket"

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

# Function to run docker commands with error checking
run_docker_command() {
  log_message "執行命令: docker $@"
  docker "$@"
  if [ $? -ne 0 ]; then
    log_message "錯誤: docker 命令失敗: $@"
    exit 1
  fi
}

# Cleanup function
cleanup() {
  log_message "開始清理 Lab 資源..."

  # Stop any running Dataflow jobs
  log_message "停止 Dataflow 作業..."
  gcloud dataflow jobs list --region=$GCP_REGION --filter="name:wordcount" --format="value(job_id)" | while read job_id; do
    if [ ! -z "$job_id" ]; then
      log_message "停止作業 ID: $job_id"
      gcloud dataflow jobs cancel $job_id --region=$GCP_REGION 2>/dev/null || log_message "無法取消作業 $job_id"
    fi
  done

  # Delete Cloud Storage bucket
  if [ ! -z "$BUCKET_NAME" ]; then
    log_message "刪除 Cloud Storage bucket: gs://$BUCKET_NAME"
    gsutil -m rm -r "gs://$BUCKET_NAME" 2>/dev/null || log_message "Cloud Storage bucket 可能已被刪除或不存在"
  fi

  # Clean up Docker containers
  log_message "清理 Docker 容器..."
  docker ps -a --filter "ancestor=python:3.9" --format "table {{.ID}}\t{{.Names}}" | tail -n +2 | while read container_id container_name; do
    if [ ! -z "$container_id" ]; then
      log_message "停止並刪除容器: $container_id"
      docker stop $container_id 2>/dev/null || true
      docker rm $container_id 2>/dev/null || true
    fi
  done

  log_message "清理完成。"
}

# Trap for cleanup on exit
trap cleanup EXIT

# --- Main Lab Steps ---

log_message "GSP207-Dataflow: Qwik Start - Python - 自動化腳本開始執行"

# Prompt for configuration
prompt_for_input "GCP_REGION" "請輸入 GCP 區域" "$GCP_REGION"
log_message "使用區域: $GCP_REGION"

# Set bucket name
BUCKET_NAME="${GOOGLE_CLOUD_PROJECT}-${BUCKET_SUFFIX}"
log_message "使用 bucket 名稱: $BUCKET_NAME"

# Task 1: Set the region
log_message "任務 1: 設置區域"
run_gcloud_command config set compute/region "$GCP_REGION"

# Task 2: Ensure Dataflow API is re-enabled
log_message "任務 2: 確保 Dataflow API 重新啟用"
log_message "停用 Dataflow API..."
run_gcloud_command services disable dataflow.googleapis.com --project $GOOGLE_CLOUD_PROJECT --force
log_message "重新啟用 Dataflow API..."
run_gcloud_command services enable dataflow.googleapis.com --project $GOOGLE_CLOUD_PROJECT

# Task 3: Create Cloud Storage bucket
log_message "任務 3: 創建 Cloud Storage bucket"
log_message "創建 bucket: gs://$BUCKET_NAME"
run_gsutil_command mb -p $GOOGLE_CLOUD_PROJECT -l us gs://$BUCKET_NAME

# Task 4: Install Apache Beam SDK and run local example
log_message "任務 4: 安裝 Apache Beam SDK 並運行本地示例"

# Start Docker container
log_message "啟動 Python 3.9 Docker 容器..."
run_docker_command run -dit --name gsp207-beam-container \
  -e DEVSHELL_PROJECT_ID=$GOOGLE_CLOUD_PROJECT \
  python:3.9 /bin/bash

# Install Apache Beam inside container
log_message "在容器中安裝 Apache Beam SDK..."
run_docker_command exec gsp207-beam-container pip install 'apache-beam[gcp]'==2.42.0

# Run wordcount example locally
log_message "在本地運行 wordcount 示例..."
run_docker_command exec gsp207-beam-container \
  python -m apache_beam.examples.wordcount --output local_output.txt

# Show local results
log_message "本地 wordcount 結果:"
run_docker_command exec gsp207-beam-container cat local_output.txt | head -20
log_message "(只顯示前 20 行)"

# Task 5: Run Dataflow pipeline remotely
log_message "任務 5: 遠程運行 Dataflow pipeline"

# Set environment variable in container
run_docker_command exec gsp207-beam-container bash -c "export BUCKET=gs://$BUCKET_NAME"

# Run remote Dataflow job
log_message "啟動遠程 Dataflow 作業..."
run_docker_command exec gsp207-beam-container \
  python -m apache_beam.examples.wordcount \
  --project $GOOGLE_CLOUD_PROJECT \
  --runner DataflowRunner \
  --staging_location gs://$BUCKET_NAME/staging \
  --temp_location gs://$BUCKET_NAME/temp \
  --output gs://$BUCKET_NAME/results/output \
  --region $GCP_REGION

# Wait for job to start
log_message "等待 Dataflow 作業啟動..."
sleep 30

# Task 6: Monitor Dataflow job
log_message "任務 6: 監控 Dataflow 作業"

# Check job status
log_message "檢查 Dataflow 作業狀態..."
run_gcloud_command dataflow jobs list --region=$GCP_REGION --filter="name:wordcount" --format="table[no-heading](name, state, create_time)"

# Wait for job to complete (with timeout)
log_message "等待作業完成 (最多等待 10 分鐘)..."
TIMEOUT=600  # 10 minutes
START_TIME=$(date +%s)

while true; do
  CURRENT_TIME=$(date +%s)
  ELAPSED=$((CURRENT_TIME - START_TIME))

  if [ $ELAPSED -gt $TIMEOUT ]; then
    log_message "作業等待超時。請手動檢查 Dataflow Console。"
    break
  fi

  # Check if job is succeeded
  JOB_STATUS=$(gcloud dataflow jobs list --region=$GCP_REGION --filter="name:wordcount" --format="value(state)" | head -1)

  if [ "$JOB_STATUS" = "Done" ] || [ "$JOB_STATUS" = "Succeeded" ]; then
    log_message "Dataflow 作業成功完成！"
    break
  elif [ "$JOB_STATUS" = "Failed" ] || [ "$JOB_STATUS" = "Cancelled" ]; then
    log_message "Dataflow 作業失敗或被取消。狀態: $JOB_STATUS"
    exit 1
  fi

  log_message "作業狀態: $JOB_STATUS - 等待中... ($ELAPSED/$TIMEOUT 秒)"
  sleep 30
done

# Task 7: Verify results
log_message "任務 7: 驗證結果"

# List bucket contents
log_message "檢查 Cloud Storage bucket 內容..."
run_gsutil_command ls -r gs://$BUCKET_NAME/

# Show sample results
log_message "顯示示例結果文件內容..."
RESULT_FILES=$(gsutil ls gs://$BUCKET_NAME/results/output* 2>/dev/null | head -1)
if [ ! -z "$RESULT_FILES" ]; then
  log_message "下載並顯示結果文件內容..."
  gsutil cp $RESULT_FILES ./remote_output.txt 2>/dev/null || log_message "無法下載結果文件"
  if [ -f "./remote_output.txt" ]; then
    head -20 ./remote_output.txt
    rm ./remote_output.txt
  fi
else
  log_message "未找到結果文件。請檢查 Dataflow 作業狀態。"
fi

# Cleanup Docker container
log_message "清理 Docker 容器..."
docker stop gsp207-beam-container 2>/dev/null || true
docker rm gsp207-beam-container 2>/dev/null || true

log_message "GSP207-Dataflow: Qwik Start - Python - 自動化腳本執行完成"
log_message "您可以在 Dataflow Console 和 Cloud Storage 中查看結果"
log_message "腳本退出時將自動清理資源"
