# GSP650 - 建置具有 Cloud Run 和 Pub/Sub 的彈性、非同步系統

## Lab 概述

對於 [Serverless Cloud Run Development](https://www.cloudskillsboost.google/course_templates/741) 課程中的 labs，您將閱讀一個虛構的商業案例，並協助角色進行其無伺服器遷移計劃。

12 年前，Lily 創立了 Pet Theory 獸醫診所鏈。多年來，診所的數量有所增長，自動化的需求也隨之增加。Pet Theory 處理來自實驗室的醫學測試結果的方式太慢且容易出錯，Lily 希望改善這個情況。

目前，Pet Theory 的 IT 管理員 Patrick 手動處理測試結果。每當收到測試結果時，他會撰寫並發送電子郵件給接受測試的寵物主人，然後在手機上敲出簡訊並以文字形式發送結果。

Patrick 正在與軟體顧問 Ruby 合作設計一個更具可擴展性的系統。他們想要建置一個不需要大量持續維護的解決方案。Patrick 和 Ruby 決定使用無伺服器技術。

## 學習目標

在此 lab 中，您將學習如何：

- 建立 Pub/Sub 主題和訂閱
- 建立一個接收 HTTP 請求並將訊息發布到 Cloud Pub/Sub 的 Cloud Run 服務
- 建立一個從 Cloud Pub/Sub 接收訊息的 Cloud Run 服務
- 建立一個觸發 Cloud Run 服務的 Pub/Sub 訂閱
- 測試系統的彈性

## 先決條件

此 lab 假設熟悉 Cloud Console 和 shell 環境。此 lab 是系列的一部分，參加之前的 labs 可能會有幫助，但不是必要的：

- [將資料匯入 Firestore 資料庫](https://google.qwiklabs.com/catalog_lab/2163)
- [使用 Firebase 建構無伺服器網路應用程式](https://google.qwiklabs.com/catalog_lab/2166)
- [建置使用 Cloud Run 建立 PDF 文件的無伺服器應用程式](https://google.qwiklabs.com/catalog_lab/2161)

## 案例場景

Pet Theory 使用外部公司進行醫學測試。一旦實驗室公司完成醫學測試，他們會將結果發送到 Pet Theory。

實驗室公司使用 HTTP(s) POST 到 Pet Theory 的醫學實驗室結果網路端點。下面的圖表概述了一般的架構。

*Pet Theory 系統架構圖表*

在查看了遵循的一般流程後，Ruby 相信可以設計一個系統，讓 Pet Theory 能夠：

1. 接收 HTTP POST 請求並確認收到實驗室結果。
2. 將測試結果以電子郵件發送給客戶。
3. 將測試結果以文字訊息 (SMS) 和電子郵件發送給客戶。

Ruby 的設計隔離了上述每個活動，並要求：

- 一個服務來執行實驗結果請求和回應
- 一個服務來向客戶發送測試結果電子郵件
- 一個服務來向客戶發送文字訊息 (SMS)
- Pub/Sub 用於服務間通訊
- 應用程式架構使用無伺服器基礎設施

透過使用單一用途函數，Ruby 正在開發更容易編寫且包含較少錯誤的程式碼。

*架構圖表*

## 任務 1. 架構

Pet Theory 使用外部公司進行醫學測試。一旦實驗室公司完成醫學測試，他們會將結果發送到 Pet Theory。

實驗室公司使用 HTTP(s) POST 到 Pet Theory 的醫學實驗室結果網路端點。下面的圖表概述了一般的架構。

*Pet Theory 系統架構圖表*

在查看了遵循的一般流程後，Ruby 相信可以設計一個系統，讓 Pet Theory 能夠：

1. 接收 HTTP POST 請求並確認收到實驗室結果。
2. 將測試結果以電子郵件發送給客戶。
3. 將測試結果以文字訊息 (SMS) 和電子郵件發送給客戶。

Ruby 的設計隔離了上述每個活動，並要求：

- 一個服務來執行實驗結果請求和回應
- 一個服務來向客戶發送測試結果電子郵件
- 一個服務來向客戶發送文字訊息 (SMS)
- Pub/Sub 用於服務間通訊
- 應用程式架構使用無伺服器基礎設施

透過使用單一用途函數，Ruby 正在開發更容易編寫且包含較少錯誤的程式碼。

*架構圖表*

## 任務 2. 建置 Lab Report Service

協助 Ruby 設定新的 Lab Report Service。

*Lab Report Service 在架構圖表中突出顯示*

此服務將用於原型設計，因此它只會做兩件事：

1. 接收包含報告資料的實驗室報告 HTTPS POST。
2. 在 Pub/Sub 上發布訊息。

### 新增 Lab Report Service 的程式碼

1. 在 Cloud Shell 中，複製此 lab 所需的儲存庫：

```bash
git clone https://github.com/rosera/pet-theory.git
```

2. 移動到 `lab-service` 目錄：

```bash
cd pet-theory/lab05/lab-service
```

3. 安裝將需要接收傳入 HTTPS 請求和發布到 Pub/Sub 的套件：

```bash
npm install express
npm install body-parser
npm install @google-cloud/pubsub
```

這些命令會更新 `package.json` 檔案，以指示此服務所需的依賴項。

您現在將編輯 `package.json` 檔案，讓 Cloud Run 知道如何啟動您的程式碼。

1. 開啟 `package.json` 檔案。
2. 在 `package.json` 檔案的 "scripts" 區段中，在第 7 行新增程式碼行 `"start": "node index.js",`，如下所示，然後儲存檔案：

```json
"scripts": {
  "start": "node index.js",
  "test": "echo \"Error: no test specified\" && exit 1"
},
```

**注意：**請務必完全按照提供的程式碼新增，包括結尾的逗號：

`"start": "node index.js",`

否則，您在部署時會遇到錯誤。

1. 建立名為 `index.js` 的新檔案，並將此程式碼新增至其中：

```javascript
const {PubSub} = require('@google-cloud/pubsub');
const pubsub = new PubSub();
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());
const port = process.env.PORT || 8080;

app.listen(port, () => {
  console.log('Listening on port', port);
});

app.post('/', async (req, res) => {
  try {
    const labReport = req.body;
    await publishPubSubMessage(labReport);
    res.status(204).send();
  }
  catch (ex) {
    console.log(ex);
    res.status(500).send(ex);
  }
})

async function publishPubSubMessage(labReport) {
  const buffer = Buffer.from(JSON.stringify(labReport));
  await pubsub.topic('new-lab-report').publish(buffer);
}
```

這兩行做主要工作：`const labReport = req.body;`

`await publishPubSubMessage(labReport);`

具體來說，這些行：

- 從 POST 請求中提取實驗室報告。
- 發布包含新發布的實驗室報告的 PubSub 訊息。

1. 現在建立名為 `Dockerfile` 的檔案，並將下面的程式碼新增至其中：

```dockerfile
FROM node:18
WORKDIR /usr/src/app
COPY package.json package*.json ./
RUN npm install --only=production
COPY . .
CMD [ "npm", "start" ]
```

此檔案定義如何將 Cloud Run 服務打包到容器中。

### 部署 lab-report-service

1. 建立名為 `deploy.sh` 的檔案，並將這些命令貼到其中：

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/lab-report-service
gcloud run deploy lab-report-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/lab-report-service \
  --platform managed \
  --region "REGION" \
  --allow-unauthenticated \
  --max-instances=1
```

1. 在 Cloud Shell 中，執行以下命令讓此檔案可執行：

```bash
chmod u+x deploy.sh
```

1. 現在是部署 Lab Report Service 的時間！執行部署腳本：

```bash
./deploy.sh
```

由於定時問題，您第一次執行此命令時可能會收到錯誤。如果您收到，請重新執行 `deploy.sh`。

部署成功完成時，您會看到類似以下的訊息：

```
Service [lab-report-service] revision [lab-report-service-00001] has been deployed and is serving traffic at https://lab-report-service-[hash].a.run.app
```

太好了，Lab Report Service 已部署並將透過 HTTP 消費醫學實驗室結果。您現在可以測試新服務是否正常運作。

點擊 **Check my progress** 來驗證目標。

部署 Lab Report Service：建構

點擊 **Check my progress** 來驗證目標。

部署 Lab Report Service：建立修訂版本

### 測試 Lab Report Service

為了驗證 Lab Report Service，模擬實驗室公司發出的三個 HTTPS POST，每個包含一個報告。為了測試目的，創建的實驗室報告只會包含一個 ID。

1. 首先，將報告的 URL 放到環境變數中，以方便使用。

```bash
export LAB_REPORT_SERVICE_URL=$(gcloud run services describe lab-report-service --platform managed --region "REGION" --format="value(status.address.url)")
```

1. 確認 LAB_REPORT_SERVICE_URL 已擷取：

```bash
echo $LAB_REPORT_SERVICE_URL
```

1. 建立名為 `post-reports.sh` 的新檔案，並將下面的程式碼新增至其中：

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"id\": 12}" \
  $LAB_REPORT_SERVICE_URL &
curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"id\": 34}" \
  $LAB_REPORT_SERVICE_URL &
curl -X POST \
  -H "Content-Type: application/json" \
  -d "{\"id\": 56}" \
  $LAB_REPORT_SERVICE_URL &
```

上面的腳本會使用 `curl` 命令將三個不同的 ID 發布到 Lab Service URL。每個命令將在背景中個別執行。

1. 讓 `post-reports.sh` 腳本可執行：

```bash
chmod u+x post-reports.sh
```

1. 現在使用上面概述的腳本測試 Lab Report Service 端點，發布三個實驗室報告給它：

```bash
./post-reports.sh
```

此腳本發布了三個實驗室報告到您的 Lab Report Service。檢查日誌以查看結果！

1. 在 Cloud console 中，點擊 **Navigation menu () > Cloud Run**。

   *Navigation menu 圖標*

2. 您現在應該會在 **Services** 清單中看到新部署的 **lab-report-service**。點擊它。

3. 下一個頁面顯示您的 lab-report-service 詳細資訊。點擊 **Logs** 標籤。

在 Logs 頁面上是您剛剛使用腳本發布的三個測試報告的結果。希望返回的 HTTP 程式碼是 204，表示 OK - 不內容，如下所示。如果您沒有看到任何項目，請向上和向下滾動帶有右側滾動條的頁面。這會重新載入日誌。

下一個任務是編寫 SMS 和 Email 服務。這些服務將在 Lab Report Service 在 "new-lab-report" 主題上發布 Pub/Sub 訊息時被觸發。

## 任務 3. Email Service

協助 Ruby 設定新的 Email Service。

*Email Service 在架構圖表中突出顯示*

### 新增 Email Service 的程式碼

1. 移動到 Email Service 目錄：

```bash
cd ~/pet-theory/lab05/email-service
```

2. 安裝套件，讓程式碼能夠處理傳入的 HTTPS 請求：

```bash
npm install express
npm install body-parser
```

上面的命令會更新 `package.json` 檔案，這描述了應用程式及其依賴項。Cloud Run 需要知道如何運行程式碼，所以新增 `start` 指示，讓它知道該做什麼。

1. 開啟 `package.json` 檔案。
2. 在 "scripts" 區段中，新增 `"start": "node index.js",` 行，如下所示並儲存檔案：

```json
...
"scripts": {
    "start": "node index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
},
...
```

**注意：**請務必完全按照提供的程式碼新增，包括結尾的逗號：

`"start": "node index.js",`

否則，您在部署時會遇到錯誤。

1. 建立名為 `index.js` 的新檔案，並將以下內容新增至其中：

```javascript
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Listening on port', port);
});

app.post('/', async (req, res) => {
  const labReport = decodeBase64Json(req.body.message.data);
  try {
    console.log(`Email Service: Report ${labReport.id} trying...`);
    sendEmail();
    console.log(`Email Service: Report ${labReport.id} success :-)`);
    res.status(204).send();
  }
  catch (ex) {
    console.log(`Email Service: Report ${labReport.id} failure: ${ex}`);
    res.status(500).send();
  }
})

function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}

function sendEmail() {
  console.log('Sending email');
}
```

當 Pub/Sub 將訊息發布到服務時，此程式碼會運行。這是它所做的事情：

- 它解碼 Pub/Sub 訊息並嘗試呼叫 `sendEmail()` 函數。
- 如果成功且沒有拋出例外，它會返回狀態碼 204，讓 Pub/Sub 知道訊息已被處理。
- 如果有例外，服務會返回狀態碼 500，讓 Pub/Sub 知道訊息未被處理，並應稍後重新發布到服務。

一旦服務間的通訊正常運作，Ruby 將新增程式碼到 `sendEmail()` 函數來實際發送電子郵件。

1. 現在建立名為 `Dockerfile` 的檔案，並將下面的程式碼新增至其中：

```dockerfile
FROM node:18
WORKDIR /usr/src/app
COPY package.json package*.json ./
RUN npm install --only=production
COPY . .
CMD [ "npm", "start" ]
```

此檔案定義如何將 Cloud Run 服務打包到容器中。

### 部署 Email Service

1. 建立名為 `deploy.sh` 的新檔案，並新增以下內容：

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/email-service

gcloud run deploy email-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/email-service \
  --platform managed \
  --region "REGION" \
  --no-allow-unauthenticated \
  --max-instances=1
```

1. 讓 `deploy.sh` 可執行：

```bash
chmod u+x deploy.sh
```

1. 部署 Email Service：

```bash
./deploy.sh
```

部署完成時，您會看到類似以下的訊息：

```
Service [email-service] revision [email-service-00001] has been deployed and is serving traffic at https://email-service-[hash].a.run.app
```

服務已成功部署。您現在需要確保 Email Service 在有 Pub/Sub 訊息可用時被觸發。

點擊 **Check my progress** 來驗證目標。

部署 Email Service：建構

點擊 **Check my progress** 來驗證目標。

部署 Email Service：建立修訂版本

### 設定 Pub/Sub 來觸發 Email Service

每當新的 Pub/Sub 訊息使用 "new-lab-report" 主題發布時，它應該觸發 Email Service。為了實現此任務，設定服務帳戶來自動處理與此服務相關聯的請求。

*架構圖表突出顯示從 Cloud Pub/Sub 到 Email Service 的流程*

1. 建立一個新的服務帳戶，將用來觸發回應 Pub/Sub 訊息的服務：

```bash
gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"
```

點擊 **Check my progress** 來驗證目標。

建立服務帳戶

1. 給新的服務帳戶權限來呼叫 Email Service：

```bash
gcloud run services add-iam-policy-binding email-service --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --region "REGION" --platform managed
```

接下來，告訴 Pub/Sub 在發布 "new-lab-report" 訊息時呼叫 SMS Service。

1. 將專案編號放到環境變數中以方便存取：

```bash
PROJECT_NUMBER=$(gcloud projects list --filter="qwiklabs-gcp" --format='value(PROJECT_NUMBER)')
```

接下來，啟用專案來建立 Pub/Sub 驗證權杖。

1. 執行下面的程式碼：

```bash
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com --role=roles/iam.serviceAccountTokenCreator
```

1. 將 Email Service 的 URL 放到另一個環境變數中：

```bash
EMAIL_SERVICE_URL=$(gcloud run services describe email-service --platform managed --region "REGION" --format="value(status.address.url)")
```

1. 確認 EMAIL_SERVICE_URL 已擷取：

```bash
echo $EMAIL_SERVICE_URL
```

1. 為 Email Service 建立 Pub/Sub 訂閱。

```bash
gcloud pubsub subscriptions create email-service-sub --topic new-lab-report --push-endpoint=$EMAIL_SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

太好了！服務現在設定為在 Cloud Pub/Sub 主題佇列中有訊息可用時回應。下一步是驗證程式碼是否符合要求。

點擊 **Check my progress** 來驗證目標。

建立 Pub/Sub 訂閱

### 一起測試 Lab Report Service 和 Email Service

1. 使用稍早建立的腳本，再次發布實驗室報告：

```bash
~/pet-theory/lab05/lab-service/post-reports.sh
```

1. 然後開啟日誌 (**Navigation menu** > **Cloud Run**)。您會看到您的帳戶中有兩個 Cloud Run 服務，**email-service** 和 **lab-report-service**。

2. 點擊 **email-service**，然後點擊 **Logs**。

   您會看到此服務被 Pub/Sub 觸發的結果。如果您沒有看到預期的訊息，您可能需要使用右側的滾動條向上和向下滾動以重新載入日誌。

太好了！Email service 現在能夠在從 Cloud Pub/Sub 主題佇列處理訊息時寫入日誌！最後一個任務是編寫 SMS Service。

## 任務 4. SMS Service

協助 Ruby 設定新的 SMS Service。

*SMS Service 在架構圖表中突出顯示*

### 新增 SMS Service 的程式碼

1. 建立 SMS Service 的目錄：

```bash
cd ~/pet-theory/lab05/sms-service
```

2. 安裝接收傳入 HTTPS 請求所需的套件：

```bash
npm install express
npm install body-parser
```

1. 開啟 `package.json` 檔案。
2. 在 "scripts" 區段中，新增 `"start": "node index.js",` 行，如下所示並儲存檔案：

```json
...
"scripts": {
    "start": "node index.js",
    "test": "echo \"Error: no test specified\" && exit 1"
},
...
```

**注意：**請務必完全按照提供的程式碼新增，包括結尾的逗號：

`"start": "node index.js",`

否則，您在部署時會遇到錯誤。

1. 建立名為 `index.js` 的新檔案，並將以下內容新增至其中：

```javascript
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Listening on port', port);
});

app.post('/', async (req, res) => {
  const labReport = decodeBase64Json(req.body.message.data);
  try {
    console.log(`SMS Service: Report ${labReport.id} trying...`);
    sendSms();

    console.log(`SMS Service: Report ${labReport.id} success :-)`);
    res.status(204).send();
  }
  catch (ex) {
    console.log(`SMS Service: Report ${labReport.id} failure: ${ex}`);
    res.status(500).send();
  }
})

function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}

function sendSms() {
  console.log('Sending SMS');
}
```

1. 現在建立名為 `Dockerfile` 的檔案，並將下面的程式碼新增至其中：

```dockerfile
FROM node:18
WORKDIR /usr/src/app
COPY package.json package*.json ./
RUN npm install --only=production
COPY . .
CMD [ "npm", "start" ]
```

此檔案定義如何將 Cloud Run 服務打包到容器中。現在程式碼已建立，下一步是部署服務。

### 部署 SMS Service

1. 建立名為 `deploy.sh` 的檔案，並將此程式碼新增至其中：

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/sms-service

gcloud run deploy sms-service \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/sms-service \
  --platform managed \
  --region "REGION" \
  --no-allow-unauthenticated \
  --max-instances=1
```

1. 讓 `deploy.sh` 可執行：

```bash
chmod u+x deploy.sh
```

1. 部署 SMS Service：

```bash
./deploy.sh
```

部署完成時，會顯示類似以下的訊息：

```
Service [sms-service] revision [sms-service-00001] has been deployed and is serving traffic at https://sms-service-[hash].a.run.app
```

SMS Service 已成功部署，但它沒有連結到 Cloud Pub/Sub 服務。修正接下來部分。

點擊 **Check my progress** 來驗證目標。

部署 SMS Service

### 設定 Cloud Pub/Sub 來觸發 SMS Service

與 Email Service 一樣，需要設定 Cloud Pub/Sub 和 SMS 服務之間的連結，讓訊息可以被消費。

*架構圖表突出顯示從 Cloud Pub/Sub 到 SMS Service 的流程*

1. 設定權限，讓 Pub/Sub 可以觸發 SMS Service：

```bash
gcloud run services add-iam-policy-binding sms-service --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com --role=roles/run.invoker --region "REGION" --platform managed
```

接下來，告訴 Pub/Sub 在發布 "new-lab-report" 訊息時呼叫 SMS Service。

1. 首先，將 SMS Service 的位址 URL 放到環境變數中：

```bash
SMS_SERVICE_URL=$(gcloud run services describe sms-service --platform managed --region "REGION" --format="value(status.address.url)")
```

1. 確認 SMS_SERVICE_URL 已擷取：複製

```bash
echo $SMS_SERVICE_URL
```

2. 然後建立 Pub/Sub 訂閱：

```bash
gcloud pubsub subscriptions create sms-service-sub --topic new-lab-report --push-endpoint=$SMS_SERVICE_URL --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

1. 再次執行測試腳本，將三個實驗室報告發布到 Lab Report Service：

```bash
~/pet-theory/lab05/lab-service/post-reports.sh
```

1. 然後開啟日誌 (**Navigation menu** > **Cloud Run**)。您會看到您的帳戶中有三個 Cloud Run 服務，email-service、lab-report-service 和 sms-service。

2. 點擊 **sms-service**，然後點擊 **Logs**。您會看到此服務被 Pub/Sub 觸發的結果。

原型系統已建立並成功測試。然而，Patrick 擔心彈性作為初始驗證過程的一部分還沒有測試。

## 任務 5. 測試系統的彈性

Patrick 之前遇到過這種情況，這是常見的情況。

協助 Ruby 調查確保系統能夠處理此案例。她想要測試當服務失敗時會發生什麼，方法是部署 Email Service 的壞版本。

1. 返回 `email-service` 目錄：

```bash
cd ~/pet-theory/lab05/email-service
```

新增一些無效文字到 Email Service 應用程式來造成錯誤。

1. 編輯 `index.js` 並在 `sendEmail()` 函數中新增 `throw` 行，如下所示。這會拋出例外，好像電子郵件伺服器關閉一樣：

```javascript
...
function sendEmail() {
  throw 'Email server is down';
  console.log('Sending email');
}
...
```

新增此程式碼會讓服務在被呼叫時崩潰。

1. 部署此壞版本的 Email Service：

```bash
./deploy.sh
```

1. Email Service 部署成功完成後，再次發布實驗室報告資料，然後密切關注 **email-service** 日誌狀態：

```bash
~/pet-theory/lab05/lab-service/post-reports.sh
```

1. 開啟 Email Service 日誌來查看壞 Email Service 的日誌狀態：**Navigation menu** > **Cloud Run**。

2. 當您在帳戶中看到三個 Cloud Run 服務時，點擊 **email-service**。

Email Service 正在被呼叫，但它會不斷崩潰。如果您稍微向後滾動日誌，您會找到根本原因："Email server is down"。您也可以看到服務返回狀態碼 500，並且 Pub/Sub 持續重試呼叫服務。

如果您查看 SMS 服務的日誌，您會看到它成功運作。

現在修復 Email Service 中的錯誤來恢復應用程式！

1. 開啟 `index.js` 檔案並移除您先前輸入的 throw 行，然後儲存檔案。

您現在的 `index.js` `sendEmail` 函數應該看起來類似這樣：

```javascript
function sendEmail() {
  console.log('Sending email');
}
```

1. 部署修復版本的 Email Service：

```bash
./deploy.sh
```

1. 部署完成後，點擊右上角的 **refresh** 圖標。

您會看到報告 12、34 和 56 的電子郵件最終被發送，Email Service 返回狀態碼 204，並且 Pub/Sub 停止呼叫服務。沒有資料遺失；Pub/Sub 持續重試直到最終成功。這是強大系統的基礎！

## 重要收穫

1. 如果服務透過 Pub/Sub 非同步彼此通訊而不是直接互相呼叫，系統可以更具彈性。

2. Lab Report Service 觸發器獨立於其他服務，感謝 Pub/Sub 的使用。例如，如果客戶還想要透過另一個訊息服務接收實驗結果，可以新增而不需更新 Lab Report Service。

3. Cloud Pub/Sub 處理重試，服務不需要。服務只需要返回狀態碼：成功或失敗。

4. 如果服務關閉，系統能夠自動 "癒合" 本身，當服務重新上線時感謝 Pub/Sub 重試。

## 恭喜！

Ruby 在您的幫助下，已成功建置原型系統。服務能夠自動向每個客戶發送電子郵件和 SMS 訊息。在個別服務暫時關閉的事件中，系統將實作重試機制，讓沒有資料遺失。Ruby 得到應得的讚揚...

*Ruby 得到讚揚的圖表*

## 後續步驟 / 深入學習

- Medium 文章：[Cloud Run 作為內部非同步工作者](https://medium.com/google-cloud/cloud-run-as-an-internal-async-worker)

