# GSP315 - Set Up an App Dev Environment on Google Cloud: Challenge Lab - 逐步操作指南

## 實驗室概述

GSP315 是一個挑戰實驗室，旨在測試您在 Google Cloud Platform 上配置應用程式開發環境的實作能力。本實驗室將整合多項 GCP 服務，建立一個自動化圖片處理的無伺服器應用程式環境。

## 先決條件

- 基本的 GCP 概念知識
- 熟悉 Cloud Storage、Cloud Functions、Pub/Sub 等服務
- 具備基本的 Linux 命令行操作能力
- Node.js 程式設計基礎知識

## 預估時間

- 完成時間：約 45-60 分鐘
- 難度等級：中級

## 任務列表

### 任務 1：建立用於存儲照片的 bucket

#### 步驟詳情

1. 設定必要的環境變數：
```bash
export ZONE=
export TOPIC_NAME=
export FUNCTION_NAME=
export USERNAME2=
export REGION="${ZONE%-*}"
```

2. 啟用必要的 GCP 服務：
```bash
gcloud services enable artifactregistry.googleapis.com cloudfunctions.googleapis.com cloudbuild.googleapis.com eventarc.googleapis.com run.googleapis.com logging.googleapis.com pubsub.googleapis.com
```

3. 設定 IAM 權限：
```bash
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')

gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com --role=roles/eventarc.eventReceiver

SERVICE_ACCOUNT="$(gsutil kms serviceaccount -p $PROJECT_ID)"

gcloud projects add-iam-policy-binding $PROJECT_ID --member="serviceAccount:${SERVICE_ACCOUNT}" --role='roles/pubsub.publisher'

gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator
```

4. 建立 Cloud Storage bucket：
```bash
gsutil mb -l $REGION gs://$PROJECT_ID-bucket
```

#### 驗證步驟
執行以下指令確認 bucket 已建立：
```bash
gsutil ls -L gs://$PROJECT_ID-bucket
```

### 任務 2：建立 Pub/Sub 主題

#### 步驟詳情

1. 設定 Pub/Sub 主題名稱變數（從 lab 介面取得實際名稱）：
```bash
export TOPIC_NAME="[從 lab 介面取得的實際主題名稱]"
```

2. 建立 Pub/Sub 主題：
```bash
gcloud pubsub topics create $TOPIC_NAME
```

#### 驗證步驟
確認主題已建立：
```bash
gcloud pubsub topics list | grep $TOPIC_NAME
```

### 任務 3：建立縮圖 Cloud Run Function

#### 步驟詳情

1. 設定函數相關變數：
```bash
export FUNCTION_NAME="[從 lab 介面取得的實際函數名稱]"
```

2. 建立工作目錄並進入：
```bash
mkdir quicklab
cd quicklab
```

3. 建立 `index.js` 檔案：
```javascript
const functions = require('@google-cloud/functions-framework');
const crc32 = require("fast-crc32c");
const { Storage } = require('@google-cloud/storage');
const gcs = new Storage();
const { PubSub } = require('@google-cloud/pubsub');
const imagemagick = require("imagemagick-stream");

functions.cloudEvent('$FUNCTION_NAME', cloudEvent => {
  const event = cloudEvent.data;

  console.log(`Event: ${event}`);
  console.log(`Hello ${event.bucket}`);

  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64"
  const bucket = gcs.bucket(bucketName);
  const topicName = "$TOPIC_NAME";
  const pubsub = new PubSub();
  if ( fileName.search("64x64_thumbnail") == -1 ){
    // doesn't have a thumbnail, get the filename extension
    var filename_split = fileName.split('.');
    var filename_ext = filename_split[filename_split.length - 1];
    var filename_without_ext = fileName.substring(0, filename_ext.length );
    if (filename_ext.toLowerCase() == 'png' || filename_ext.toLowerCase() == 'jpg'){
      // only support png and jpg at this point
      console.log(`Processing Original: gs://${bucketName}/${fileName}`);
      const gcsObject = bucket.file(fileName);
      let newFilename = filename_without_ext + size + '_thumbnail.' + filename_ext;
      let gcsNewObject = bucket.file(newFilename);
      let srcStream = gcsObject.createReadStream();
      let dstStream = gcsNewObject.createWriteStream();
      let resize = imagemagick().resize(size).quality(90);
      srcStream.pipe(resize).pipe(dstStream);
      return new Promise((resolve, reject) => {
        dstStream
          .on("error", (err) => {
            console.log(`Error: ${err}`);
            reject(err);
          })
          .on("finish", () => {
            console.log(`Success: ${fileName} → ${newFilename}`);
              // set the content-type
              gcsNewObject.setMetadata(
              {
                contentType: 'image/'+ filename_ext.toLowerCase()
              }, function(err, apiResponse) {});
              pubsub
                .topic(topicName)
                .publisher()
                .publish(Buffer.from(newFilename))
                .then(messageId => {
                  console.log(`Message ${messageId} published.`);
                })
                .catch(err => {
                  console.error('ERROR:', err);
                });
          });
      });
    }
    else {
      console.log(`gs://${bucketName}/${fileName} is not an image I can handle`);
    }
  }
  else {
    console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
  }
});
```

4. 使用 sed 指令替換變數：
```bash
sed -i "8c\functions.cloudEvent('$FUNCTION_NAME', cloudEvent => { " index.js
sed -i "18c\  const topicName = '$TOPIC_NAME';" index.js
```

5. 建立 `package.json` 檔案：
```json
{
    "name": "thumbnails",
    "version": "1.0.0",
    "description": "Create Thumbnail of uploaded image",
    "scripts": {
        "start": "node index.js"
    },
    "dependencies": {
        "@google-cloud/functions-framework": "^3.0.0",
        "@google-cloud/pubsub": "^2.0.0",
        "@google-cloud/storage": "^5.0.0",
        "fast-crc32c": "1.0.4",
        "imagemagick-stream": "4.1.1"
    },
    "devDependencies": {},
    "engines": {
        ">=4.3.2"
    }
}
```

6. 設定額外的 IAM 權限：
```bash
BUCKET_SERVICE_ACCOUNT="${PROJECT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID --member=serviceAccount:$BUCKET_SERVICE_ACCOUNT --role=roles/pubsub.publisher
```

7. 部署 Cloud Function：
```bash
gcloud functions deploy $FUNCTION_NAME --gen2 --runtime nodejs20 --trigger-resource $PROJECT_ID-bucket --trigger-event google.storage.object.finalize --entry-point $FUNCTION_NAME --region=$REGION --source . --quiet
```

8. 等待 Cloud Run 服務建立完成：
```bash
SERVICE_NAME="$FUNCTION_NAME"

while true; do
  # Check if Cloud Run service is created
  if gcloud run services describe $SERVICE_NAME --region $REGION &> /dev/null; then
    echo "Cloud Run service is created. Exiting the loop."
    break
  else
    echo "Waiting for Cloud Run service to be created..."
    sleep 10
  fi
done
```

#### 驗證步驟

1. 下載測試圖片並上傳到 bucket：
```bash
curl -o map.jpg https://storage.googleapis.com/cloud-training/gsp315/map.jpg
gsutil cp map.jpg gs://$PROJECT_ID-bucket/map.jpg
```

2. 檢查是否生成了縮圖檔案：
```bash
gsutil ls gs://$PROJECT_ID-bucket/
```

應該會看到原始檔案 `map.jpg` 和生成的縮圖檔案 `map64x64_thumbnail.jpg`。

### 任務 4：移除前任雲端工程師的存取權限

#### 步驟詳情

1. 設定要移除的使用者名稱變數：
```bash
export USERNAME2="[從 lab 介面取得的實際使用者名稱]"
```

2. 移除使用者的專案存取權限：
```bash
gcloud projects remove-iam-policy-binding $PROJECT_ID --member=user:$USERNAME2 --role=roles/viewer
```

#### 驗證步驟
確認權限已被移除：
```bash
gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" --filter="bindings.role:roles/viewer" --format="value(bindings.members[])" | grep $USERNAME2 || echo "User access successfully removed"
```

## 執行指南

### 常見問題與解決方案

1. **Cloud Function 部署失敗**
   - 確保所有必要的服務都已啟用
   - 檢查 IAM 權限設定是否正確
   - 確認 package.json 中的依賴版本正確

2. **縮圖功能沒有觸發**
   - 檢查 Cloud Storage bucket 是否正確設定
   - 確認 Pub/Sub 主題名稱是否正確
   - 驗證 Cloud Function 的觸發器設定

3. **IAM 權限錯誤**
   - 確保使用正確的專案 ID 和服務帳戶
   - 檢查角色名稱拼寫是否正確
   - 確認使用者名稱格式正確（應為 user:email@domain.com）

### 提示與技巧

- 仔細閱讀 lab 介面提供的變數名稱，確保拼寫正確
- 部署 Cloud Function 可能需要一些時間，請耐心等待
- 測試時使用小檔案，避免上傳大圖片造成延遲
- 記得檢查 Cloud Function 的日誌來診斷問題

### 清理步驟

完成實驗室後，執行以下指令清理資源：
```bash
gcloud functions delete $FUNCTION_NAME --region=$REGION --quiet
gcloud pubsub topics delete $TOPIC_NAME --quiet
gsutil rm -r gs://$PROJECT_ID-bucket --quiet
```

## 額外資源

- [Cloud Functions 文件](https://cloud.google.com/functions/docs)
- [Cloud Storage 文件](https://cloud.google.com/storage/docs)
- [Pub/Sub 文件](https://cloud.google.com/pubsub/docs)
- [IAM 權限管理](https://cloud.google.com/iam/docs)

## 技術筆記

這個實驗室展示了 GCP 無伺服器架構的強大之處：
- **事件驅動架構**：Cloud Storage 的檔案上傳事件自動觸發 Cloud Function
- **非同步處理**：使用 Pub/Sub 進行鬆耦合的訊息傳遞
- **無伺服器運算**：不需要管理伺服器，只需關注程式碼邏輯
- **安全管理**：IAM 權限控制確保資源的安全存取

掌握這些概念對於設計現代雲端應用程式至關重要。
