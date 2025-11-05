# GSP644 - 開發 Cloud Run 上的無伺服器應用程式

## Lab 概述

Pet Theory 是一家獸醫診所鏈，在過去 12 年間，他們一直以 DOCX 格式向客戶發送發票。然而，許多客戶抱怨無法開啟這些文件。為了改善客戶滿意度，IT 經理 Patrick 被要求調查一個替代方案來改善現狀。

Pet Theory 的營運團隊只有一個人，因此他們希望投資一個經濟高效的解決方案，不需要大量的持續維護。在分析各種處理選項後，Patrick 決定使用 Cloud Run。

Cloud Run 是無伺服器的，它抽象化了所有基礎設施管理，讓您專注於建構應用程式而不是擔心開銷。它作為 Google 無伺服器產品，可以擴展到零，這意味著未使用時不會產生成本。它還允許使用自訂二進位套件，基於容器，這使得建構一致的隔離成品成為可能。

在此 lab 中，您將在 Cloud Run 上建構一個 PDF 轉換器網路應用程式，自動將儲存在 Cloud Storage 中的文件轉換為儲存在單獨資料夾中的 PDF 文件。

## 先決條件

這是一個中級 lab，需要熟悉控制台和 shell 環境。Firebase 經驗會有幫助，但不是必需的。在參加此 lab 之前，建議您先完成以下 Google Cloud Skills Boost labs：

- [將資料匯入 Firestore 資料庫](https://google.qwiklabs.com/catalog_lab/2163)
- [使用 Firebase 建構無伺服器網路應用程式](https://google.qwiklabs.com/catalog_lab/2166)

準備就緒後，向下捲動並按照以下步驟設定您的 lab 環境。

## 架構

此圖表概述了您將使用的服務以及它們如何相互連接：

*架構圖表：Cloud Storage → Pub/Sub → Cloud Run → Cloud Storage*

## 學習目標

在此 lab 中，您將學習如何：

- 將 Node.js 應用程式轉換為容器
- 使用 Google Cloud Build 建構容器
- 在雲端建立一個將文件轉換為 PDF 文件的 Cloud Run 服務
- 使用 Cloud Storage 進行事件處理

## 任務 1. 了解任務

Pet Theory 希望將其發票轉換為 PDF，以便客戶可以可靠地開啟它們。團隊希望自動化此轉換以盡量減少辦公室經理 Lisa 的工作量。

Ruby，Pet Theory 的電腦顧問，從 IT 的 Patrick 收到一封訊息...

Patrick 發送 Ruby 一個程式碼片段，他用來從文件產生 PDF：

```javascript
const {promisify} = require('util');
const exec        = promisify(require('child_process').exec);

const cmd = 'libreoffice --headless --convert-to pdf --outdir ' +
            `/tmp "/tmp/${fileName}"`;

const { stdout, stderr } = await exec(cmd);
if (stderr) {
  throw stderr;
}
```

Ruby 回覆 Patrick...

建構容器將需要整合多個元件：

*元件圖表：index.js、LibreOffice、Express、body-parser、child_process 和 @google-cloud/storage*

## 任務 2. 啟用 Cloud Run API

1. 開啟導覽選單 () 並點擊 **APIs & Services** > **Library**。在搜尋欄中輸入 "Cloud Run" 並從結果清單中選取 **Cloud Run Admin API**。

   *Cloud Run API 圖表*

2. 點擊 **Enable** 然後在您的瀏覽器中按兩次返回按鈕。您的控制台現在應該類似以下：

   *控制台圖表*

## 任務 3. 部署簡單的 Cloud Run 服務

Ruby 為 Cloud Run 開發了一個原型，並希望 Patrick 將其部署到 Google Cloud。現在幫助 Patrick 為 Pet Theory 建立 PDF Cloud Run 服務。

1. 開啟新的 Cloud Shell 工作階段並執行以下命令來複製 Pet Theory 儲存庫：

```bash
git clone https://github.com/rosera/pet-theory.git
```

2. 然後將您的目前工作目錄變更為 lab03：

```bash
cd pet-theory/lab03
```

3. 使用 Cloud Shell 程式碼編輯器或您偏好的文字編輯器編輯 `package.json`。在 "scripts" 區段中，新增 `"start": "node index.js",` 如下所示：

```json
...
"scripts": {
    "start": "node index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
...
```

4. 現在在 Cloud Shell 中執行以下命令來安裝您的轉換腳本將使用的套件：

```bash
npm install express
npm install body-parser
npm install child_process
npm install @google-cloud/storage
```

5. 現在開啟 `lab03/index.js` 檔案並檢閱程式碼。

應用程式將作為一個接受 HTTP POST 的 Cloud Run 服務部署。如果 POST 請求是一個關於已上傳文件的 Pub/Sub 通知，服務會將文件詳細資訊寫入日誌。如果不是，服務只會傳回字串 "OK"。

6. 檢閱名為 `lab03/Dockerfile` 的檔案。

上述檔案稱為資訊清單，並為 Docker 命令提供建構映像的配方。每行以一個命令開頭，告訴 Docker 如何處理以下資訊：

- 第一個清單表示基底映像應該使用 node 作為映像的模板。
- 最後一行表示命令，在此情況下是指 "npm start"。

7. 要建構並部署 REST API，請使用 Google Cloud Build。執行此命令來啟動建構過程：

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter
```

此命令建構包含您的程式碼的容器，並將其放入您專案的 Artifact Registry 中。

8. 返回 Cloud Console，在導覽選單 () 中點擊 **VIEW ALL PRODUCTS**。在 CI/CD 區段中，選取 **Artifact Registry** > **Repositories**。您應該會看到您的容器已託管：

   *容器註冊圖表*

9. 開啟 `gcr.io` 儲存庫。您應該會看到您的容器已託管：

   *容器註冊圖表*

**測試完成任務**

點擊 **Check my progress** 來驗證您已執行上述任務。

建構簡單的 REST API

返回您的程式碼編輯器分頁，並在 Cloud Shell 中執行以下命令來部署您的應用程式：

```bash
gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region Region \
  --no-allow-unauthenticated \
  --max-instances=1
```

部署完成時，您會看到類似以下的訊息：

```
Service [pdf-converter] revision [pdf-converter-00001] has been deployed and is serving 100 percent of traffic at https://pdf-converter-[hash].a.run.app
```

10. 為應用程式建立環境變數 `$SERVICE_URL`，以便您輕鬆存取它：

```bash
SERVICE_URL=$(gcloud beta run services describe pdf-converter --platform managed --region Lab Region --format="value(status.url)")
echo $SERVICE_URL
```

**測試完成任務**

點擊 **Check my progress** 來驗證您已執行上述任務。

建立 Cloud Run 修訂版本

對您新的服務進行匿名 POST 請求：

```bash
curl -X POST $SERVICE_URL
```

這將導致錯誤訊息說 `"Your client does not have permission to get the URL"`。這很好；您不希望服務可以被匿名使用者呼叫。

現在嘗試以授權使用者呼叫服務：

```bash
curl -X POST -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL
```

如果您收到回應 `"OK"`，您已成功部署 Cloud Run 服務。做得好！

## 任務 4. 當新文件上傳到 Cloud Storage 時觸發您的 Cloud Run 服務

現在 Cloud Run 服務已成功部署，Ruby 希望 Patrick 為要轉換的資料建立一個暫存區域。Cloud Storage bucket 將使用事件觸發器來通知應用程式新文件已上傳並需要處理。

1. 執行以下命令來為上傳的文件在 Cloud Storage 中建立一個 bucket：

```bash
gsutil mb gs://$GOOGLE_CLOUD_PROJECT-upload
```

2. 以及另一個用於處理的 PDF 的 bucket：

```bash
gsutil mb gs://$GOOGLE_CLOUD_PROJECT-processed
```

3. 現在返回您的 Cloud Console 分頁，開啟導覽選單並選取 **Cloud Storage**。驗證 bucket 已建立（平台使用的其他 bucket 也會在那裡。）

**測試完成任務**

點擊 **Check my progress** 來驗證您已執行上述任務。

建立兩個 Cloud Storage bucket

在 Cloud Shell 中執行以下命令，告訴 Cloud Storage 在新文件完成上傳到文件 bucket 時發送 Pub/Sub 通知：

```bash
gsutil notification create -t new-doc -f json -e OBJECT_FINALIZE gs://$GOOGLE_CLOUD_PROJECT-upload
```

通知將標記為主題 "new-doc"。

**測試完成任務**

點擊 **Check my progress** 來驗證您已執行上述任務。

建立 Pub/Sub 主題以處理來自儲存 bucket 的通知

然後建立一個新的服務帳戶，Pub/Sub 將用它來觸發 Cloud Run 服務：

```bash
gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"
```

給新的服務帳戶權限來呼叫 PDF 轉換器服務：

```bash
gcloud beta run services add-iam-policy-binding pdf-converter --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --platform managed --region Lab Region
```

尋找您的專案編號，執行此命令：

```bash
gcloud projects list
```

尋找名稱以 "qwiklabs-gcp-" 開頭的專案。您將在下一個命令中使用專案編號的值。

*專案編號圖表*

建立 `PROJECT_NUMBER` 環境變數，將 [project number] 替換為上一個命令的專案編號：

```bash
PROJECT_NUMBER=[project number]
```

然後啟用您的專案來建立 Cloud Pub/Sub 驗證權杖：

```bash
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator
```

**注意：**如果您在執行上述命令時收到 `service account does not exist` 錯誤。啟用 **Cloud Pub/Sub API**，如果它已經啟用，先停用然後重新啟用它。然後重新執行上述命令。

最後，建立一個 Pub/Sub 訂閱，以便 PDF 轉換器可以在訊息發佈到主題 "new-doc" 時執行。

```bash
gcloud beta pubsub subscriptions create pdf-conv-sub --topic new-doc --push-endpoint=$SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

**測試完成任務**

點擊 **Check my progress** 來驗證您已執行上述任務。

建立 Pub/Sub 訂閱

## 任務 5. 檢視當文件上傳到 Cloud Storage 時 Cloud Run 服務是否被觸發

為了驗證應用程式是否按預期運作，Ruby 要求 Patrick 將測試資料上傳到指定的儲存 bucket，然後檢查 Cloud Logging。

1. 將一些測試文件複製到您的上傳 bucket：

```bash
gsutil -m cp gs://spls/gsp644/* gs://$GOOGLE_CLOUD_PROJECT-upload
```

2. 一旦上傳完成，返回您的 Cloud Console 分頁，開啟導覽選單並點擊 **VIEW ALL PRODUCTS**。在可觀察性區段中選取 **Logging**。

3. 在 **All resources** 下拉式選單中，將您的結果過濾為 **Cloud Run Revision** 並點擊 **Apply**。然後點擊 **Run Query**。

4. 在 **Query results** 中，尋找以 `file:` 開頭的日誌項目並點擊它。它顯示 Pub/Sub 在新文件上傳時發送到您的 Cloud Run 服務的文件資料轉儲。

5. 您能在這個物件中找到您上傳的文件的名稱嗎？

*查詢結果圖表*

**注意：**如果您沒有看到以 "file" 開頭的日誌項目，請嘗試點擊頁面底部的 "load newer logs" 按鈕。

6. 現在返回程式碼編輯器分頁並在 Cloud Shell 中執行以下命令來清理您的 `upload` 目錄，刪除其中的文件：

```bash
gsutil -m rm gs://$GOOGLE_CLOUD_PROJECT-upload/*
```

## 任務 6. 容器

Patrick 需要將積壓的發票轉換為 PDF，以便所有客戶都可以開啟它們。他發送電子郵件給 Ruby 請求幫助...

Patrick 發送 Ruby 他寫來從文件產生 PDF 的程式碼片段：

```javascript
const {promisify} = require('util');
const exec        = promisify(require('child_process').exec);

const cmd = 'libreoffice --headless --convert-to pdf --outdir ' +
            `/tmp "/tmp/${fileName}"`;

const { stdout, stderr } = await exec(cmd);
if (stderr) {
  throw stderr;
}
```

Ruby 回覆 Patrick...

建構容器將需要整合多個元件：

*元件圖表：index.js、LibreOffice、Express、body-parser、child_process 和 @google-cloud/storage*

### 更新資訊清單

有了所有識別的文件，現在可以建立資訊清單。幫助 Ruby 設定和部署容器。

LibreOffice 套件之前沒有包含在容器中，這意味著現在需要新增它。Patrick 之前提供了他用來建構應用程式的命令，Ruby 將這些作為 `RUN` 命令新增到 Dockerfile 中。

- 開啟 `Dockerfile` 資訊清單並新增命令 `RUN apt-get update -y && apt-get install -y libreoffice && apt-get clean` 行，如下所示：

```dockerfile
FROM NODE_VERSION
RUN apt-get update -y \
    && apt-get install -y libreoffice \
    && apt-get clean
WORKDIR /usr/src/app
COPY package.json package*.json ./
RUN npm install --only=production
COPY . .
CMD [ "npm", "start" ]
```

### 部署 PDF 轉換服務的新版本

1. 開啟 `index.js` 檔案並在檔案頂部新增以下套件需求：

```javascript
const {promisify} = require('util');
const {Storage}   = require('@google-cloud/storage');
const exec        = promisify(require('child_process').exec);
const storage     = new Storage();
```

2. **替換** `app.post('/', async (req, res)` 為以下程式碼：

```javascript
app.post('/', async (req, res) => {
  try {
    const file = decodeBase64Json(req.body.message.data);
    await downloadFile(file.bucket, file.name);
    const pdfFileName = await convertFile(file.name);
    await uploadFile(process.env.PDF_BUCKET, pdfFileName);
    await deleteFile(file.bucket, file.name);
  }
  catch (ex) {
    console.log(`Error: ${ex}`);
  }
  res.set('Content-Type', 'text/plain');
  res.send('\n\nOK\n\n');
})
```

3. 現在在檔案底部新增以下處理 LibreOffice 文件的程式碼：

```javascript
// Helper function to check file existence (using fs.promises for async)
async function fileExists(filePath) {
  try {
    await fs.promises.access(filePath); // Throws an error if the file doesn't exist
    return true;
  } catch (err) {
    return false;
  }
}

async function downloadFile(bucketName, fileName) {
  // 1. Check if the file exists
  const fileExistsLocally = await fileExists(`/tmp/${fileName}`);

  // 2. Delete if present
  if (fileExistsLocally) {
    console.log(`File exists locally. Deleting: ${fileName}`);
    await fs.promises.unlink(`/tmp/${fileName}`); // Use fs.promises for async file operations
    console.log(`File deleted.`);
  } else {
    console.log(`File does not exist locally: ${fileName}`);
  }

  // 3. Download from the storage bucket
  const options = { destination: `/tmp/${fileName}` };
  await storage.bucket(bucketName).file(fileName).download(options);
  console.log(`File downloaded: ${fileName}`);
}

async function convertFile(fileName) {
  const cmd = 'libreoffice --headless --convert-to pdf --outdir /tmp ' +
              `"/tmp/${fileName}"`;
  console.log(cmd);
  const { stdout, stderr } = await exec(cmd);
  if (stderr) {
    console.log(`Conversion Failed: ${stderr}`);
    throw stderr;
  }
  console.log(`Conversion Success: ${stdout}`);
  pdfFileName = fileName.replace(/\.\w+$/, '.pdf');
  return pdfFileName;
}

async function deleteFile(bucketName, fileName) {
  await storage.bucket(bucketName).file(fileName).delete();
}

async function uploadFile(bucketName, fileName) {
  await storage.bucket(bucketName).upload(`/tmp/${fileName}`);
}
```

4. 確保您的 `index.js` 檔案看起來像以下內容：

**注意：**為了避免任何格式錯誤，建議您將所有程式碼替換為此範例程式碼。

```javascript
const {promisify} = require('util');
const {Storage}   = require('@google-cloud/storage');
const exec        = promisify(require('child_process').exec);
const storage     = new Storage();
const express     = require('express');
const bodyParser  = require('body-parser');
const app         = express();

app.use(bodyParser.json());

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Listening on port', port);
});

app.post('/', async (req, res) => {
  try {
    const file = decodeBase64Json(req.body.message.data);
    await downloadFile(file.bucket, file.name);
    const pdfFileName = await convertFile(file.name);
    await uploadFile(process.env.PDF_BUCKET, pdfFileName);
    await deleteFile(file.bucket, file.name);
  }
  catch (ex) {
    console.log(`Error: ${ex}`);
  }
  res.set('Content-Type', 'text/plain');
  res.send('\n\nOK\n\n');
})

function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}

// Helper function to check file existence (using fs.promises for async)
async function fileExists(filePath) {
  try {
    await fs.promises.access(filePath); // Throws an error if the file doesn't exist
    return true;
  } catch (err) {
    return false;
  }
}
async function downloadFile(bucketName, fileName) {
  // 1. Check if the file exists
  const fileExistsLocally = await fileExists(`/tmp/${fileName}`);

  // 2. Delete if present
  if (fileExistsLocally) {
    console.log(`File exists locally. Deleting: ${fileName}`);
    await fs.promises.unlink(`/tmp/${fileName}`); // Use fs.promises for async file operations
    console.log(`File deleted.`);
  } else {
    console.log(`File does not exist locally: ${fileName}`);
  }

  // 3. Download from the storage bucket
  const options = { destination: `/tmp/${fileName}` };
  await storage.bucket(bucketName).file(fileName).download(options);
  console.log(`File downloaded: ${fileName}`);
}

async function convertFile(fileName) {
  const cmd = 'libreoffice --headless --convert-to pdf --outdir /tmp ' +
              `"/tmp/${fileName}"`;
  console.log(cmd);
  const { stdout, stderr } = await exec(cmd);
  if (stderr) {
    console.log(`Conversion Failed: ${stderr}`);
    throw stderr;
  }
  console.log(`Conversion Success: ${stdout}`);
  pdfFileName = fileName.replace(/\.\w+$/, '.pdf');
  return pdfFileName;
}

async function deleteFile(bucketName, fileName) {
  await storage.bucket(bucketName).file(fileName).delete();
}

async function uploadFile(bucketName, fileName) {
  await storage.bucket(bucketName).upload(`/tmp/${fileName}`);
}
```

主要邏輯包含在這些函數中：

```
const file = decodeBase64Json(req.body.message.data);
await downloadFile(file.bucket, file.name);
const pdfFileName = await convertFile(file.name);
await uploadFile(process.env.PDF_BUCKET, pdfFileName);
await deleteFile(file.bucket, file.name);
```

每當有文件上傳時，此服務會被觸發。它執行這些任務，一行一個：

- 從 Pub/Sub 通知中提取文件詳細資訊。
- 從 Cloud Storage 下載文件到本機硬碟。這實際上不是物理磁碟，而是作為磁碟運作的虛擬記憶體區段。
- 將下載的文件轉換為 PDF。
- 將 PDF 文件上傳到 Cloud Storage。環境變數 `process.env.PDF_BUCKET` 包含 Cloud Storage bucket 的名稱，用來寫入 PDF。您將在下面部署服務時為此變數指派一個值。
- 從 Cloud Storage 刪除原始文件。

`index.js` 的其餘部分實作了由頂層程式碼呼叫的函數。

現在是部署服務，並設定 `PDF_BUCKET` 環境變數的時間。給 LibreOffice 2 GB RAM 來運作也很重要（請參閱帶有 `--memory` 選項的行）。

1. 執行以下命令來建構容器：

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter
```

**注意：**輸入 `Y` 如果您收到啟用 **Cloud Build API** 的快顯視窗

**測試完成任務**

點擊 **Check my progress** 來驗證您已執行上述任務。

建立另一個 REST API 建構

現在部署您的應用程式最新版本：

```bash
gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region Lab Region \
  --memory=2Gi \
  --no-allow-unauthenticated \
  --max-instances=1 \
  --set-env-vars PDF_BUCKET=$GOOGLE_CLOUD_PROJECT-processed
```

LibreOffice 成為容器的一部分，此建構將比之前的建構花費更長時間。這是起來伸展一下的好時機，等待幾分鐘。

點擊 **Check my progress** 來驗證目標。

建立新修訂版本

## 任務 7. 測試 PDF 轉換服務

1. 部署命令完成後，執行以下命令來確保服務已正確部署：

```bash
curl -X POST -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL
```

2. 如果您收到回應 `"OK"`，您已成功部署更新的 Cloud Run 服務。LibreOffice 可以將許多文件類型轉換為 PDF：DOCX、XLSX、JPG、PNG、GIF 等。

3. 建立一個腳本來執行上傳

```bash
cat <<'EOF' > copy_files.sh
#!/bin/bash

SOURCE_BUCKET="gs://spls/gsp644"
DESTINATION_BUCKET="gs://${GOOGLE_CLOUD_PROJECT}-upload"  # Replace with your actual bucket name
DELAY=5

# Get a list of files in the source bucket
files=$(gsutil ls "$SOURCE_BUCKET")

# Loop through the files
for file in $files; do
  # Construct the full path of the source file
  source_file_path="$file"

  # Copy the file to the destination bucket
  gsutil cp "$source_file_path" "$DESTINATION_BUCKET"

  # Check if the copy was successful
  if [ $? -eq 0 ]; then  # $? is the exit status of the previous command
    echo "Copied: $source_file_path to $DESTINATION_BUCKET"
  else
    echo "Failed to copy: $source_file_path"
  fi

  # Sleep for 5 seconds
  sleep $DELAY
done

echo "All files copied!"
EOF
```

4. 執行以下命令來上傳一些範例文件：

```bash
bash copy_files.sh
```

5. 返回 Cloud Console，開啟導覽選單並選取 **Cloud Storage**。開啟 `upload` bucket 並點擊 **Refresh** 按鈕幾次來查看文件如何一個一個被刪除，因為它們被轉換為 PDF。

6. 然後點擊左選單的 **Buckets**，並點擊名稱以 "-processed" 結尾的 bucket。它應該包含所有文件的 PDF 版本。隨意開啟 PDF 文件來確保它們已正確轉換：

**注意：**如果您沒有在 `-processed` bucket 中看到所有轉換的 PDF 文件，請重新執行命令。

## 恭喜！

Pet Theory 現在有一個系統來將其舊文件存檔轉換為 PDF。只需將舊文件上傳到 "upload" bucket，pdf-converter 服務就會轉換它們並將它們作為 PDF 寫入 "processed" bucket。

繼續您的無伺服器旅程在 [Serverless Cloud Run Development](https://www.cloudskillsboost.google/course_templates/741) 課程。您將閱讀一個虛構的商業案例，並協助角色進行其無伺服器遷移計劃。

## 故障排除

常見問題和解決方案：

- **建構失敗**：確保所有必要的 API 已啟用（Cloud Run API、Cloud Build API）
- **部署失敗**：檢查區域設定和服務帳戶權限
- **轉換失敗**：確保 LibreOffice 正確安裝且有足夠的記憶體
- **Pub/Sub 通知失敗**：驗證主題和訂閱已正確建立
- **檔案未處理**：檢查 Cloud Storage bucket 權限和 Pub/Sub 觸發器

## 清理

為了避免產生費用，請執行以下清理步驟：

1. 刪除 Cloud Run 服務：
```bash
gcloud run services delete pdf-converter
```

2. 刪除 Cloud Storage bucket：
```bash
gsutil rm -r gs://$GOOGLE_CLOUD_PROJECT-upload
gsutil rm -r gs://$GOOGLE_CLOUD_PROJECT-processed
```

3. 刪除 Pub/Sub 資源：
```bash
gcloud pubsub topics delete new-doc
gcloud pubsub subscriptions delete pdf-conv-sub
```

4. 刪除服務帳戶：
```bash
gcloud iam service-accounts delete pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

## 額外資源

- [Cloud Run 文件](https://cloud.google.com/run/)
- [Cloud Storage 文件](https://cloud.google.com/storage/)
- [Pub/Sub 文件](https://cloud.google.com/pubsub/)
- [Google Cloud Build 文件](https://cloud.google.com/cloud-build/)
- 相關 labs：
  - [Build a Serverless Web App with Firebase](https://google.qwiklabs.com/catalog_lab/2166)
  - [Importing Data to a Firestore Database](https://google.qwiklabs.com/catalog_lab/2163)

## 個人筆記

- 此 lab 展示了 Cloud Run 的強大功能，用於事件驅動的無伺服器處理
- LibreOffice 可以在容器中運作，用於文件轉換任務
- Pub/Sub 提供了可靠的事件驅動架構
- 環境變數對於設定很重要
- 適當的權限設定對於服務間通訊至關重要
