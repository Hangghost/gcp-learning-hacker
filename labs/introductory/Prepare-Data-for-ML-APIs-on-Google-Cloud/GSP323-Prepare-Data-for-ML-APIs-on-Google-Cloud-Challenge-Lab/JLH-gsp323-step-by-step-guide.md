# GSP323 - Prepare Data for ML APIs on Google Cloud: Challenge Lab - 逐步操作指南

## 實驗室概述
這是基於 GSP097、GSP103、GSP119 和 GSP192 實驗室內容，為 GSP323 挑戰實驗室創建的實際操作指南。本指南將引導您完成所有 4 個任務。

## 先決條件
- Google Cloud 帳戶與實驗室憑證
- 網際網路連線與 Chrome 瀏覽器
- 基本的 GCP Console 操作知識
- 熟悉命令行操作

## 預估時間
60-90 分鐘

---

## 初始設定

### 設定環境變數
```bash
# 設定專案和區域資訊
export REGION="us-central1"
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="json" | jq -r '.projectNumber')

# 設定資源名稱
export BUCKET_NAME="${PROJECT_ID}-bucket"
export TEMP_BUCKET="${BUCKET_NAME}-temp"
export SPEECH_BUCKET="${BUCKET_NAME}-speech"
export NL_BUCKET="${BUCKET_NAME}-nl"
export DATASET_NAME="lab_dataset"
export TABLE_NAME="lab_table"
export CLUSTER_NAME="dataproc-cluster"

# 輸出檔案名稱
export SPEECH_OUTPUT="speech_output.json"
export NL_OUTPUT="nl_output.json"
```

### 啟用必要的 APIs
```bash
# 啟用所有需要的 APIs
gcloud services enable dataflow.googleapis.com
gcloud services enable dataproc.googleapis.com
gcloud services enable speech.googleapis.com
gcloud services enable language.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable apikeys.googleapis.com
```

---

## 任務 1：運行簡單的 Dataflow 作業

### 步驟詳情

#### 1. 創建 BigQuery 資料集
```bash
bq mk $DATASET_NAME
```

#### 2. 創建 Cloud Storage Buckets
```bash
gsutil mb -p $PROJECT_ID -l $REGION gs://$BUCKET_NAME
gsutil mb -p $PROJECT_ID -l $REGION gs://$TEMP_BUCKET
```

#### 3. 複製實驗室文件到本地
```bash
gsutil cp gs://spls/gsp323/lab.csv .
gsutil cp gs://spls/gsp323/lab.schema .
```

#### 4. 創建 BigQuery 表
```bash
# 定義表結構
cat > lab.schema << 'EOF'
[
    {"type":"STRING","name":"guid"},
    {"type":"BOOLEAN","name":"isActive"},
    {"type":"STRING","name":"firstname"},
    {"type":"STRING","name":"surname"},
    {"type":"STRING","name":"company"},
    {"type":"STRING","name":"email"},
    {"type":"STRING","name":"phone"},
    {"type":"STRING","name":"address"},
    {"type":"STRING","name":"about"},
    {"type":"TIMESTAMP","name":"registered"},
    {"type":"FLOAT","name":"latitude"},
    {"type":"FLOAT","name":"longitude"}
]
EOF

# 創建表
bq mk --table $DATASET_NAME.$TABLE_NAME lab.schema
```

#### 5. 運行 Dataflow 作業
```bash
gcloud dataflow jobs run dataflow-lab-job \
    --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_BigQuery \
    --region $REGION \
    --worker-machine-type e2-standard-2 \
    --staging-location gs://$TEMP_BUCKET/temp \
    --parameters \
"inputFilePattern=gs://spls/gsp323/lab.csv,\
outputTable=$PROJECT_ID:$DATASET_NAME.$TABLE_NAME,\
bigQueryLoadingTemporaryDirectory=gs://$TEMP_BUCKET/bq_temp,\
JSONPath=gs://spls/gsp323/lab.schema,\
javascriptTextTransformGcsPath=gs://spls/gsp323/lab.js,\
javascriptTextTransformFunctionName=transform"
```

### 驗證步驟
```bash
# 檢查 Dataflow 作業狀態
gcloud dataflow jobs list --region=$REGION --filter="name:dataflow-lab-job"

# 檢查 BigQuery 表是否創建
bq ls $DATASET_NAME

# 點擊 Check my progress 驗證任務 1
```

---

## 任務 2：運行簡單的 Dataproc 作業

### 步驟詳情

#### 1. 設定 IAM 權限
```bash
# 為服務帳戶分配權限
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member "serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role "roles/storage.admin"

# 設定用戶權限
export USER_EMAIL=$(gcloud config get-value account)
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:$USER_EMAIL \
    --role=roles/dataproc.editor

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member=user:$USER_EMAIL \
    --role=roles/storage.objectViewer
```

#### 2. 更新 VPC 子網路設定
```bash
# 啟用私有 IP 存取
gcloud compute networks subnets update default \
    --region $REGION \
    --enable-private-ip-google-access
```

#### 3. 創建 Dataproc 集群
```bash
gcloud dataproc clusters create $CLUSTER_NAME \
    --enable-component-gateway \
    --region $REGION \
    --master-machine-type e2-standard-2 \
    --master-boot-disk-type pd-balanced \
    --master-boot-disk-size 100 \
    --num-workers 2 \
    --worker-machine-type e2-standard-2 \
    --worker-boot-disk-type pd-balanced \
    --worker-boot-disk-size 100 \
    --image-version 2.2-debian12 \
    --project $PROJECT_ID
```

#### 4. 複製數據文件到集群
```bash
# 獲取集群主節點名稱
VM_NAME=$(gcloud compute instances list --project="$PROJECT_ID" --format=json | jq -r '.[0].name')
ZONE=$(gcloud compute instances list $VM_NAME --format 'csv[no-heading](zone)')

# 複製數據文件到 HDFS
gcloud compute ssh --zone "$ZONE" "$VM_NAME" --project "$PROJECT_ID" --quiet --command="hdfs dfs -cp gs://spls/gsp323/data.txt /data.txt"
```

#### 5. 提交 Spark 作業
```bash
gcloud dataproc jobs submit spark \
    --cluster=$CLUSTER_NAME \
    --region=$REGION \
    --class=org.apache.spark.examples.SparkPageRank \
    --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
    --project=$PROJECT_ID \
    -- /data.txt
```

### 驗證步驟
```bash
# 檢查 Dataproc 作業狀態
gcloud dataproc jobs list --region=$REGION --cluster=$CLUSTER_NAME

# 點擊 Check my progress 驗證任務 2
```

---

## 任務 3：使用 Google Cloud Speech-to-Text API

### 步驟詳情

#### 1. 創建 API 金鑰
```bash
# 創建 API 金鑰
gcloud alpha services api-keys create --display-name="speech-api-key"
API_KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=speech-api-key")
API_KEY=$(gcloud alpha services api-keys get-key-string $API_KEY_NAME --format="value(keyString)")
```

#### 2. 創建用於存儲結果的 Cloud Storage Bucket
```bash
gsutil mb -p $PROJECT_ID -l $REGION gs://$SPEECH_BUCKET
```

#### 3. 創建 Speech-to-Text API 請求文件
```bash
cat > request.json <<EOF
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://spls/gsp323/task3.flac"
  }
}
EOF
```

#### 4. 調用 Speech-to-Text API
```bash
curl -s -X POST -H "Content-Type: application/json" \
    --data-binary @request.json \
    "https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > speech_result.json
```

#### 5. 上傳結果到 Cloud Storage
```bash
gsutil cp speech_result.json gs://$SPEECH_BUCKET/$SPEECH_OUTPUT
```

### 驗證步驟
```bash
# 檢查結果文件
gsutil cat gs://$SPEECH_BUCKET/$SPEECH_OUTPUT

# 點擊 Check my progress 驗證任務 3
```

---

## 任務 4：使用 Cloud Natural Language API

### 步驟詳情

#### 1. 創建服務帳戶
```bash
# 創建服務帳戶
gcloud iam service-accounts create nl-service-account \
    --display-name "Natural Language Service Account"
```

#### 2. 創建服務帳戶金鑰
```bash
gcloud iam service-accounts keys create ~/nl-key.json \
    --iam-account nl-service-account@$PROJECT_ID.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS="/home/$USER/nl-key.json"
```

#### 3. 設定認證
```bash
gcloud auth activate-service-account nl-service-account@$PROJECT_ID.iam.gserviceaccount.com \
    --key-file=$GOOGLE_APPLICATION_CREDENTIALS
```

#### 4. 創建用於存儲結果的 Cloud Storage Bucket
```bash
gsutil mb -p $PROJECT_ID -l $REGION gs://$NL_BUCKET
```

#### 5. 運行 Natural Language 實體分析
```bash
gcloud ml language analyze-entities \
    --content="Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat." \
    > nl_result.json
```

#### 6. 上傳結果到 Cloud Storage
```bash
gsutil cp nl_result.json gs://$NL_BUCKET/$NL_OUTPUT
```

### 驗證步驟
```bash
# 檢查結果文件
gsutil cat gs://$NL_BUCKET/$NL_OUTPUT

# 點擊 Check my progress 驗證任務 4
```

---

## 清理資源

完成所有任務後，運行以下指令清理資源以避免額外費用：

```bash
# 刪除 Dataproc 集群
gcloud dataproc clusters delete $CLUSTER_NAME --region=$REGION --quiet

# 刪除 Cloud Storage buckets
gsutil rm -r gs://$BUCKET_NAME
gsutil rm -r gs://$TEMP_BUCKET
gsutil rm -r gs://$SPEECH_BUCKET
gsutil rm -r gs://$NL_BUCKET

# 刪除 BigQuery 資料集
bq rm -r -f $DATASET_NAME

# 刪除服務帳戶
gcloud iam service-accounts delete nl-service-account@$PROJECT_ID.iam.gserviceaccount.com --quiet

# 刪除 API 金鑰
gcloud alpha services api-keys delete $API_KEY_NAME --quiet

# 清理本地文件
rm -f lab.csv lab.schema request.json speech_result.json nl_result.json
rm -f ~/speech-key.json ~/nl-key.json
```

## 故障排除

### 常見問題

1. **Dataflow 作業失敗**
   - 檢查區域設定是否正確
   - 確保 Cloud Storage bucket 存在
   - 驗證 BigQuery 資料集權限

2. **Dataproc 集群創建失敗**
   - 檢查網路設定
   - 確保服務帳戶有足夠權限
   - 驗證區域配額

3. **Speech-to-Text API 錯誤**
   - 檢查 API 是否已啟用
   - 驗證服務帳戶金鑰
   - 確保音頻文件格式正確

4. **Natural Language API 錯誤**
   - 檢查 API 是否已啟用
   - 驗證服務帳戶權限
   - 確認文本格式正確

### 參考資源
- [Dataflow 文檔](https://cloud.google.com/dataflow/docs)
- [Dataproc 文檔](https://cloud.google.com/dataproc/docs)
- [Speech-to-Text API 文檔](https://cloud.google.com/speech-to-text/docs)
- [Natural Language API 文檔](https://cloud.google.com/natural-language/docs)

---

## 恭喜！

恭喜您完成了 GSP323 Prepare Data for ML APIs on Google Cloud: Challenge Lab！

在此實驗室中，您已經展示了您的技能：
- ✅ 運行簡單的 Dataflow 作業
- ✅ 運行簡單的 Dataproc 作業
- ✅ 使用 Google Cloud Speech-to-Text API
- ✅ 使用 Cloud Natural Language API

**重要提醒**：
- 記得運行清理資源部分以避免額外費用
- 所有操作都是通過命令行完成的，熟悉這些指令將有助於您的 GCP 學習之旅

繼續您的 Google Cloud 學習之旅！
