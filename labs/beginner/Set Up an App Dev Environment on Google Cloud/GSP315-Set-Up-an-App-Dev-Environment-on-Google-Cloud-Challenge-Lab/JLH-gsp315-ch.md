# GSP315 - Set Up an App Dev Environment on Google Cloud: Challenge Lab - 挑戰實驗室

## 簡介 (Overview)
這是 GSP315 - Set Up an App Dev Environment on Google Cloud: Challenge Lab 挑戰實驗室的簡要概述。此實驗室旨在測試您在 Google Cloud 平台上的實作能力，特別是針對新開發團隊的應用程式開發環境配置。

## 任務列表 (Tasks)
在此實驗室中，您需要完成以下任務：
- 任務 1：建立用於存儲照片的 bucket
- 任務 2：建立 Pub/Sub 主題
- 任務 3：建立縮圖 Cloud Run Function
- 任務 4：移除前任雲端工程師的存取權限

## 挑戰實驗室摘要 (Challenge Lab Summary)

本節提供完成每個任務所需的指令。請按照以下步驟執行，確保您已設定所有必要的變數。

### 初始變數設定 (Initial Variable Settings)
```bash
# 設定您的 GCP 專案變數
export REGION="us-central1"  # 或您的指定區域
export ZONE="us-central1-a"  # 或您的指定區域
export PROJECT_ID=$(gcloud config get-value project)

# Lab 特定的變數（請根據實際 lab 環境設定）
export BUCKET_NAME=""  # Bucket Name - 從 lab 介面取得
export TOPIC_NAME=""   # Topic Name - 從 lab 介面取得
export FUNCTION_NAME="" # Cloud Run Function Name - 從 lab 介面取得
export USERNAME_2=""   # Username 2 (previous cloud engineer) - 從 lab 介面取得
```

### 任務步驟 (Task Steps)

#### 任務 1：建立用於存儲照片的 bucket (Create a bucket)
```bash
# 建立 Cloud Storage bucket 用於存儲照片
gcloud storage buckets create gs://$BUCKET_NAME \
  --location=$REGION \
  --uniform-bucket-level-access
```

#### 任務 2：建立 Pub/Sub 主題 (Create a Pub/Sub topic)
```bash
# 建立 Pub/Sub 主題供 Cloud Run Function 使用
gcloud pubsub topics create $TOPIC_NAME
```

#### 任務 3：建立縮圖 Cloud Run Function (Create the thumbnail Cloud Run Function)
```bash
# 建立 Cloud Run Function (第二代)
gcloud functions deploy $FUNCTION_NAME \
  --gen2 \
  --runtime=nodejs22 \
  --region=$REGION \
  --source=. \
  --entry-point=$FUNCTION_NAME \
  --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" \
  --trigger-event-filters="bucket=$BUCKET_NAME" \
  --allow-unauthenticated \
  --set-env-vars TOPIC_NAME=$TOPIC_NAME
```

**注意：** 您需要建立包含以下內容的 `index.js` 和 `package.json` 檔案：

**index.js:**
```javascript
const functions = require('@google-cloud/functions-framework');
const { Storage } = require('@google-cloud/storage');
const { PubSub } = require('@google-cloud/pubsub');
const sharp = require('sharp');

functions.cloudEvent('', async cloudEvent => {
  const event = cloudEvent.data;

  console.log(`Event: ${JSON.stringify(event)}`);
  console.log(`Hello ${event.bucket}`);

  const fileName = event.name;
  const bucketName = event.bucket;
  const size = "64x64";
  const bucket = new Storage().bucket(bucketName);
  const topicName = "";
  const pubsub = new PubSub();

  if (fileName.search("64x64_thumbnail") === -1) {
    // doesn't have a thumbnail, get the filename extension
    const filename_split = fileName.split('.');
    const filename_ext = filename_split[filename_split.length - 1].toLowerCase();
    const filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length - 1); // fix sub string to remove the dot

    if (filename_ext === 'png' || filename_ext === 'jpg' || filename_ext === 'jpeg') {
      // only support png and jpg at this point
      console.log(`Processing Original: gs://${bucketName}/${fileName}`);
      const gcsObject = bucket.file(fileName);
      const newFilename = `${filename_without_ext}_64x64_thumbnail.${filename_ext}`;
      const gcsNewObject = bucket.file(newFilename);

      try {
        const [buffer] = await gcsObject.download();
        const resizedBuffer = await sharp(buffer)
          .resize(64, 64, {
            fit: 'inside',
            withoutEnlargement: true,
          })
          .toFormat(filename_ext)
          .toBuffer();

        await gcsNewObject.save(resizedBuffer, {
          metadata: {
            contentType: `image/${filename_ext}`,
          },
        });

        console.log(`Success: ${fileName} → ${newFilename}`);

        await pubsub
          .topic(topicName)
          .publishMessage({ data: Buffer.from(newFilename) });

        console.log(`Message published to ${topicName}`);
      } catch (err) {
        console.error(`Error: ${err}`);
      }
    } else {
      console.log(`gs://${bucketName}/${fileName} is not an image I can handle`);
    }
  } else {
    console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
  }
});
```

**package.json:**
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
   "@google-cloud/storage": "^6.11.0",
   "sharp": "^0.32.1"
 },
 "devDependencies": {},
 "engines": {
   "node": ">=4.3.2"
 }
}
```

**測試函數：**
上傳 PNG 或 JPG 圖片到 bucket 中驗證函數是否正常運作。

#### 任務 4：移除前任雲端工程師的存取權限 (Remove the previous cloud engineer)
```bash
# 移除前任雲端工程師的專案存取權限
gcloud projects remove-iam-policy-binding $PROJECT_ID \
  --member="user:$USERNAME_2" \
  --role="roles/viewer"
```

## 清理 (Cleanup)
```bash
# 如需清理資源，請執行以下指令：
gcloud functions delete $FUNCTION_NAME --region=$REGION --quiet
gcloud pubsub topics delete $TOPIC_NAME --quiet
gcloud storage rm -r gs://$BUCKET_NAME --quiet
```
