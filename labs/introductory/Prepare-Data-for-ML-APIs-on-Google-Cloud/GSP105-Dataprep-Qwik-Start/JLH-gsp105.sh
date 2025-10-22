#!/bin/bash

# GSP105-Dataprep: Qwik Start Automation Script

# --- Configuration Variables ---
# You can change these values if needed, or they will be prompted at runtime.
# For GSP labs, region and zone are usually not critical unless specified.
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

# Cleanup function (Dataprep is serverless, so minimal cleanup here)
cleanup() {
  log_message "開始清理 Lab 資源..."
  # Cloud Dataprep is a serverless service, no manual cleanup of Dataprep resources is required.
  # If a bucket was created, you might want to delete it here.
  # For this lab, the bucket is temporary and part of the lab setup.
  # If you wish to delete the GCS bucket created in Task 1, uncomment the following lines and
  # provide the BUCKET_NAME.
  # log_message "Deleting GCS bucket: gs://${BUCKET_NAME}"
  # gsutil -m rm -r "gs://${BUCKET_NAME}"
  log_message "清理完成。"
}

# Trap for cleanup on exit
trap cleanup EXIT

# --- Main Lab Steps ---

log_message "GSP105-Dataprep: Qwik Start - 自動化腳本開始執行"

# Task 1: Create a Cloud Storage bucket in your project
log_message "任務 1: 建立 Cloud Storage 儲存桶"
# The bucket name must be globally unique. Prompt the user for it.
read -p "請輸入您要建立的 Cloud Storage 儲存桶名稱 (必須是全球唯一，例如: my-dataprep-bucket-$(date +%s)): " BUCKET_NAME
if [ -z "$BUCKET_NAME" ]; then
  log_message "錯誤: 儲存桶名稱不可為空。腳本終止。"
  exit 1
fi
log_message "請手動在 Cloud Console 中建立儲存桶: '$BUCKET_NAME'。"
log_message "確認您已取消勾選「Enforce public access prevention on this bucket」。"
log_message "完成後請按任意鍵繼續..."
read -n 1 -s -r -p ""

# Task 2: Initialize Cloud Dataprep
log_message "任務 2: 初始化 Cloud Dataprep"
run_gcloud_command beta services identity create --service=dataprep.googleapis.com

log_message "請手動在 Cloud Console 中完成 Cloud Dataprep 的初始化步驟："
log_message "1. 前往導覽選單 > 檢視所有產品 > 分析 > Alteryx Designer Cloud。"
log_message "2. 接受服務條款，同意共享帳戶資訊，並允許存取專案資料。"
log_message "3. 點擊您的學生使用者名稱登入。"
log_message "4. 點擊允許授予存取權。"
log_message "5. 同意 Trifacta 服務條款並接受。"
log_message "6. 點擊繼續建立預設儲存位置。"
log_message "完成後請按任意鍵繼續..."
read -n 1 -s -r -p ""

# Tasks 3-8 involve UI interactions within Cloud Dataprep.
log_message "任務 3-8 需要在 Cloud Dataprep UI 中手動完成："
log_message " - 任務 3: 建立流程 'FEC-2016'"
log_message " - 任務 4: 匯入資料集 (cn-2016.txt, itcont-2016-orig.txt from gs://spls/gsp105/us-fec/)"
log_message " - 任務 5: 準備候選人檔案 (Candidate Master 2016)"
log_message " - 任務 6: 整理捐款檔案 (Campaign Contributions 2016) 並與候選人檔案合併"
log_message " - 任務 7: 資料摘要"
log_message " - 任務 8: 重新命名欄位"
log_message "請手動完成這些步驟。"
log_message "完成所有步驟後，請按任意鍵繼續以完成腳本並執行清理。"
read -n 1 -s -r -p ""

log_message "GSP105-Dataprep: Qwik Start - 自動化腳本執行完成"
