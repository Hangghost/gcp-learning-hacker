# GSP762 - 使用 Go 和 Cloud Run 創建 PDF

## Lab 概述

在此 lab 中，您將建置一個 PDF 轉換器網路應用程式，使用 Cloud Run（一個無伺服器服務），自動將儲存在 Google Drive 中的文件轉換為 PDF，並儲存在分離的 Google Drive 資料夾中。

## 案例場景

您協助 Pet Theory 獸醫診所自動將其發票轉換為 PDF，以方便客戶使用。

*架構圖表*

此 lab 需要使用 Google APIs。已為您啟用以下 APIs：

| **名稱** | **API** |
|----------|---------|
| Cloud Build | cloudbuild.googleapis.com |
| Cloud Storage | storage-component.googleapis.com |
| Cloud Run Admin | run.googleapis.com |

## 學習目標

在此 lab 中，您將學習如何：

- 獲取 lab 的源代碼
- 將 Go 應用程序轉換為容器
- 使用 Google Cloud Build 建構容器
- 創建一個在雲端將文件轉換為 PDF 文件的 Cloud Run 服務
- 創建服務帳戶並添加權限
- 啟動 Cloud Storage 通知觸發器
- 使用 Cloud Storage 進行事件處理

## 任務 1. 獲取源代碼

在此任務中，您從下載此 lab 所需的代碼開始。

1. 運行以下命令在 Cloud Shell 中啟用您的 lab 帳戶：

```bash
gcloud auth list --filter=status:ACTIVE --format="value(account)"
```

2. 運行以下命令來複製 Pet Theory 儲存庫：

```bash
git clone https://github.com/Deleplace/pet-theory.git
```

3. 運行以下命令來變更到正確的目錄：

```bash
cd pet-theory/lab03
```

## 啟用 Gemini Code Assist in Cloud Shell IDE

您可以在 Cloud Shell IDE 等整合式開發環境 (IDE) 中使用 Gemini Code Assist 來接收程式碼指導或解決程式碼問題。在可以使用 Gemini Code Assist 之前，您需要啟用它。

1. 在 Cloud Shell 中，使用以下命令啟用 **Gemini for Google Cloud** API：

```bash
gcloud services enable cloudaicompanion.googleapis.com
```

2. 點擊 **Open Editor** 在 Cloud Shell 工具列中。

**注意：** 要開啟 Cloud Shell Editor，請點擊 Cloud Shell 工具列中的 **Open Editor**。您可以透過點擊 **Open Editor** 或 **Open Terminal** 在 Cloud Shell 和程式碼編輯器之間切換。

3. 在左窗格中，點擊 **Settings** 圖標，然後在 **Settings** 視圖中搜尋 **Gemini Code Assist**。

4. 找到並確保選取 **Geminicodeassist: Enable** 的核取方塊，然後關閉 **Settings**。

5. 點擊狀態列底部的 **Cloud Code - No Project**。

6. 按照指示授權外掛程式。如果未自動選取專案，請點擊 **Select a Google Cloud Project**，然後選擇 `Project ID`。

7. 驗證您的 Google Cloud 專案 (`Project ID`) 顯示在狀態列的 Cloud Code 狀態訊息中。

## 任務 2. 創建發票微服務

在此任務中，您創建一個 Go 應用程序來處理請求。如架構圖表所述，您打算將 Cloud Storage 作為解決方案的一部分整合。

1. 在 Cloud Shell Editor 的 File Explorer 中，導覽至 **pet-theory** > **lab03** > **server.go**。

2. 開啟 `server.go` 檔案。此動作會啟用 Gemini Code Assist，如編輯器右上角的 **Gemini Code Assist: Smart Actions** 圖標所示。

   *Gemini Code Assist: Smart Actions 圖表*

3. 開啟 `server.go` 源代碼並編輯以匹配以下內容：

```go
package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
  "os/exec"
  "regexp"
  "strings"
)

func main() {
  http.HandleFunc("/", process)

  port := os.Getenv("PORT")
  if port == "" {
      port = "8080"
      log.Printf("Defaulting to port %s", port)
  }

  log.Printf("Listening on port %s", port)
  err := http.ListenAndServe(fmt.Sprintf(":%s", port), nil)
  log.Fatal(err)
}

func process(w http.ResponseWriter, r *http.Request) {
  log.Println("Serving request")

  if r.Method == "GET" {
      fmt.Fprintln(w, "Ready to process POST requests from Cloud Storage trigger")
      return
  }

  //
  // Read request body containing Cloud Storage object metadata
  //
  gcsInputFile, err1 := readBody(r)
  if err1 != nil {
      log.Printf("Error reading POST data: %v", err1)
      w.WriteHeader(http.StatusBadRequest)
      fmt.Fprintf(w, "Problem with POST data: %v \n", err1)
      return
  }

  //
  // Working directory (concurrency-safe)
  localDir, err := os.MkdirTemp("", "")
  if err != nil {
      log.Printf("Error creating local temp dir: %v", err)
      w.WriteHeader(http.StatusInternalServerError)
      fmt.Fprintf(w, "Could not create a temp directory on server. \n")
      return
  }
  defer os.RemoveAll(localDir)

  //
  // Download input file from Cloud Storage
  //
  localInputFile, err2 := download(gcsInputFile, localDir)
  if err2 != nil {
      log.Printf("Error downloading Cloud Storage file [%s] from bucket [%s]: %v",
          gcsInputFile.Name, gcsInputFile.Bucket, err2)
      w.WriteHeader(http.StatusInternalServerError)
      fmt.Fprintf(w, "Error downloading Cloud Storage file [%s] from bucket [%s]",
          gcsInputFile.Name, gcsInputFile.Bucket)
      return
  }

  //
  // Use LibreOffice to convert local input file to local PDF file.
  //
  localPDFFilePath, err3 := convertToPDF(localInputFile.Name(), localDir)
  if err3 != nil {
      log.Printf("Error converting to PDF: %v", err3)
      w.WriteHeader(http.StatusInternalServerError)
      fmt.Fprintf(w, "Error converting to PDF.")
      return
  }

  //
  // Upload the freshly generated PDF to Cloud Storage
  //
  targetBucket := os.Getenv("PDF_BUCKET")
  err4 := upload(localPDFFilePath, targetBucket)
  if err4 != nil {
      log.Printf("Error uploading PDF file to bucket [%s]: %v", targetBucket, err4)
      w.WriteHeader(http.StatusInternalServerError)
      fmt.Fprintf(w, "Error downloading Cloud Storage file [%s] from bucket [%s]",
          gcsInputFile.Name, gcsInputFile.Bucket)
      return
  }

  //
  // Delete the original input file from Cloud Storage.
  //
  err5 := deleteGCSFile(gcsInputFile.Bucket, gcsInputFile.Name)
  if err5 != nil {
      log.Printf("Error deleting file [%s] from bucket [%s]: %v", gcsInputFile.Name,
          gcsInputFile.Bucket, err5)
      // This is not a blocking error.
      // The PDF was successfully generated and uploaded.
  }

  log.Println("Successfully produced PDF")
  fmt.Fprintln(w, "Successfully produced PDF")
}

func convertToPDF(localFilePath string, localDir string) (resultFilePath string, err error) {
  log.Printf("Converting [%s] to PDF", localFilePath)
  cmd := exec.Command("libreoffice", "--headless", "--convert-to", "pdf",
      "--outdir", localDir,
      localFilePath)
  cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
  log.Println(cmd)
  err = cmd.Run()
  if err != nil {
      return "", err
  }

  pdfFilePath := regexp.MustCompile(`\.\w+$`).ReplaceAllString(localFilePath, ".pdf")
  if !strings.HasSuffix(pdfFilePath, ".pdf") {
      pdfFilePath += ".pdf"
  }
  log.Printf("Converted %s to %s", localFilePath, pdfFilePath)
  return pdfFilePath, nil
}
```

4. 點擊 **Gemini Code Assist: Smart Actions** 圖標並選取 **Explain this**。

   *Gemini Code Assist: Smart Actions 圖表*

5. Gemini Code Assist 開啟一個聊天窗格，並預填提示 **Explain this**。在 Code Assist 聊天的內嵌文字方塊中，將預填提示替換為以下內容，然後點擊 **Send**：

```
You are an expert Go developer at Cymbal AI. A new team member is unfamiliar with this server implementation. Explain this "server.go" file in detail, breaking down its key components used in the code.

For the suggested improvements, don't update this file.
```

`server.go` 檔案中的程式碼說明會出現在 **Gemini Code Assist** 聊天中。

6. 在 Cloud Shell 終端中，運行以下命令來建構應用程序：

```bash
go build -o server
```

此應用程序由以下源文件呼叫的函數建構：

- server.go
- notification.go
- gcs.go

成功建構應用程序後，您可以創建 PDF 轉換服務。

## 任務 3. 創建 PDF 轉換服務

PDF 服務使用 Cloud Run 和 Cloud Storage 來啟動每次文件上傳到指定儲存時的處理。

要實現此任務，您決定使用共同的事件通知模式與 Cloud Pub/Sub 結合。這樣做可以啟用應用程序專注於僅處理資訊。傳輸和傳遞資訊由其他服務執行，讓您保持應用程序簡單。

建構發票模組需要整合兩個組件：

*容器包含兩個組件：server 和 LibreOffice*

新增 LibreOffice 套件意味著它可以在您的應用程序中使用。

1. 在 **Open editor** 中，打開現有的 `Dockerfile` 資訊清單並更新檔案如下：

```dockerfile
FROM amd64/debian
RUN apt-get update -y \
  && apt-get install -y libreoffice \
  && apt-get clean
WORKDIR /usr/src/app
COPY server .
CMD [ "./server" ]
```

2. **儲存** 更新的 `Dockerfile`。

3. 點擊 **Gemini Code Assist: Smart Actions** 圖標並選取 **Explain this**。

   *Gemini Code Assist: Smart Actions 圖表*

4. Gemini Code Assist 開啟一個聊天窗格，並預填提示 **Explain this**。在 Code Assist 聊天的內嵌文字方塊中，將預填提示替換為以下內容，然後點擊 **Send**：

```
You are a Senior DevOps Engineer at Cymbal AI. A new team member has asked you to explain the Dockerfile. Provide a comprehensive explanation of the contents and structure of this Dockerfile, including key instructions and best practices.

For the suggested improvements, don't update this Dockerfile.
```

`Dockerfile` 檔案中的程式碼說明會出現在 **Gemini Code Assist** 聊天中。

5. 使用 Cloud Build 啟動 `pdf-converter` 映像的重新建構：

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter
```

點擊 **Check my progress** 來驗證您已執行上述任務。

使用 Cloud Build 建構映像

6. 部署更新的 PDF 轉換器服務。

   **注意：** 給 LibreOffice 2GB RAM 來運作是個好主意，請參閱帶有 `--memory` 選項的行。

7. 運行以下命令來建構容器並部署它：

```bash
gcloud run deploy pdf-converter \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/pdf-converter \
  --platform managed \
  --region "REGION" \
  --memory=2Gi \
  --no-allow-unauthenticated \
  --set-env-vars PDF_BUCKET=$GOOGLE_CLOUD_PROJECT-processed \
  --max-instances=3
```

點擊 **Check my progress** 來驗證您已執行此任務。

部署 PDF 轉換器服務

Cloud Run 服務現在已成功部署。但是，您部署了一個需要正確權限來存取它的應用程序。

## 任務 4. 創建服務帳戶

[服務帳戶](https://cloud.google.com/iam/docs/understanding-service-accounts) 是一種特殊類型的帳戶，具有對 Google APIs 的存取權。

此 lab 使用服務帳戶在處理 Cloud Storage 事件時存取 Cloud Run。Cloud Storage 支援豐富的通知集，可用於觸發事件。

在此任務中，您更新程式碼以在文件上傳時通知應用程序。

1. 點擊 **導覽選單** () > **Cloud Storage**，並驗證已創建兩個 bucket。您應該會看到：

   - `PROJECT_ID`processed
   - `PROJECT_ID`upload

2. 創建一個 Pub/Sub 通知來指示新文件已上傳到文件 bucket ("uploaded")。通知以主題 "new-doc" 標記。

```bash
gsutil notification create -t new-doc -f json -e OBJECT_FINALIZE gs://$GOOGLE_CLOUD_PROJECT-upload
```

**預期輸出：**

```
Created Cloud Pub/Sub topic projects/"PROJECT_ID"/topics/new-doc
Created notification config projects/_/buckets/"PROJECT_ID"-upload/notificationConfigs/1
```

3. 創建一個新的服務帳戶來觸發 Cloud Run 服務：

```bash
gcloud iam service-accounts create pubsub-cloud-run-invoker --display-name "PubSub Cloud Run Invoker"
```

**預期輸出：**

```
Created service account [pubsub-cloud-run-invoker].
```

4. 給服務帳戶權限來呼叫 PDF 轉換器服務：

```bash
gcloud run services add-iam-policy-binding pdf-converter \
  --member=serviceAccount:pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com \
  --role=roles/run.invoker \
  --region "REGION" \
  --platform managed
```

**預期輸出：**

```
Updated IAM policy for service [pdf-converter].
bindings:
- members:
  - serviceAccount:pubsub-cloud-run-invoker@"PROJECT_ID".iam.gserviceaccount.com
    role: roles/run.invoker
    etag: BwYYfbXS240=
    version: 1
```

5. 運行此命令來找到您的專案編號：

```bash
PROJECT_NUMBER=$(gcloud projects list \
 --format="value(PROJECT_NUMBER)" \
 --filter="$GOOGLE_CLOUD_PROJECT")
```

6. 啟用您的專案來建立 Cloud Pub/Sub 驗證權杖：

```bash
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member=serviceAccount:"PROJECT_ID"@"PROJECT_ID".iam.gserviceaccount.com \
  --role=roles/iam.serviceAccountTokenCreator
```

點擊 **Check my progress** 來驗證您已執行此任務。

創建服務帳戶

創建服務帳戶後，它可以用來呼叫 Cloud Run Service。

## 任務 5. 測試 Cloud Run 服務

在進一步進行之前，您需要測試已部署的服務。由於服務需要驗證，測試它有助於確保它實際上是私有的。

1. 將您服務的 URL 儲存在環境變數 **$SERVICE_URL** 中：

```bash
SERVICE_URL=$(gcloud run services describe pdf-converter \
  --platform managed \
  --region "REGION" \
  --format "value(status.url)")
```

2. 顯示 SERVICE URL：

```bash
echo $SERVICE_URL
```

3. 對您的新服務進行匿名 GET 請求：

```bash
curl -X GET $SERVICE_URL
```

**預期輸出：**

```html
<html><head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<title>403 Forbidden</title>
</head>
<body text=#000000 bgcolor=#ffffff>
<h1>Error: Forbidden</h1>
<h2>Your client does not have permission to get URL <code>/</code> from this server.</h2>
<h2></h2>
```

**注意：** 匿名 GET 請求導致錯誤訊息："Your client does not have permission to get URL"。這很好；您不希望服務可以被匿名使用者呼叫。

4. 現在嘗試以授權使用者身分呼叫服務：

```bash
curl -X GET -H "Authorization: Bearer $(gcloud auth print-identity-token)" $SERVICE_URL
```

**預期輸出：**

```
Ready to process POST requests from Cloud Storage trigger
```

太好了，您已成功部署經過驗證的 Cloud Run 服務。

## 任務 6. 配置 Cloud Storage 觸發器

要啟動新內容上傳到 Cloud Storage 時的通知，請為您的現有 Pub/Sub Topic 新增訂閱。

**注意：** Cloud Storage 通知會在上傳新內容時自動將訊息推送到您的 Topic 佇列。使用通知允許您創建強大的應用程序，這些應用程序對事件做出回應，而無需編寫額外程式碼。

- 創建一個 Pub/Sub 訂閱，以便每當訊息發布到主題 `new-doc` 時，PDF 轉換器就會運行：

```bash
gcloud pubsub subscriptions create pdf-conv-sub \
  --topic new-doc \
  --push-endpoint=$SERVICE_URL \
  --push-auth-service-account=pubsub-cloud-run-invoker@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com
```

**預期輸出：**

```
Created subscription [projects/"PROJECT_ID"/subscriptions/pdf-conv-sub].
```

點擊 **Check my progress** 來驗證您已執行此任務。

確認 Pub/Sub 訂閱

現在每當上傳文件時，Pub/Sub 訂閱會與您的服務帳戶互動。然後服務帳戶會啟動您的 PDF Converter Cloud Run 服務。

## 任務 7. 測試 Cloud Storage 通知

要測試 Cloud Run 服務，請使用可用的範例文件。

1. 將測試文件複製到您的上傳 bucket：

```bash
gsutil -m cp -r gs://spls/gsp762/* gs://$GOOGLE_CLOUD_PROJECT-upload
```

**預期輸出：**

```
Copying gs://spls/gsp762/cat-and-mouse.jpg [Content-Type=image/jpeg]...
Copying gs://spls/gsp762/file-sample_100kB.doc [Content-Type=application/msword]...
Copying gs://spls/gsp762/file-sample_500kB.docx [Content-Type=application/vnd.openxmlformats-officedocument.wordprocessingml.document]...
Copying gs://spls/gsp762/file_example_XLS_10.xls [Content-Type=application/vnd.ms-excel]...
Copying gs://spls/gsp762/file-sample_1MB.docx [Content-Type=application/vnd.openxmlformats-officedocument.wordprocessingml.document]...
Copying gs://spls/gsp762/file_example_XLSX_50.xlsx [Content-Type=application/vnd.openxmlformats-officedocument.spreadsheetml.sheet]...
Copying gs://spls/gsp762/file_example_XLS_100.xls [Content-Type=application/vnd.ms-excel]...
Copying gs://spls/gsp762/file_example_XLS_50.xls [Content-Type=application/vnd.ms-excel]...
Copying gs://spls/gsp762//Copy of cat-and-mouse.jpg [Content-Type=image/jpeg]...
```

2. 在 Cloud Console 中，點擊 **Cloud Storage > Buckets** 然後點擊以 "**`PROJECT_ID`upload**" 結尾的 bucket 名稱。

3. 點擊 **Refresh** 按鈕幾次，看看文件如何一個一個被刪除，因為它們被轉換為 PDF。

4. 然後點擊 **Buckets**，然後點擊以 "**`PROJECT_ID`processed**" 結尾的 bucket 名稱。它應該包含所有文件的 PDF 版本。

   **注意：** 處理文件可能需要幾分鐘。使用 Bucket 刷新選項來檢查處理完成狀態。

5. 隨意開啟 PDF 文件以確保它們已正確轉換。

6. 上傳完成後，點擊 **導覽選單 > Cloud Run**，並點擊 **pdf-converter** 服務。

7. 選取 **LOGS** 標籤並新增篩選器 "Converting" 以查看轉換的文件。

8. 導覽至 **導覽選單 > Cloud Storage** 並開啟以 "**`PROJECT_ID`upload**" 結尾的 bucket 名稱，以確認所有上傳的文件都已處理。

太好了，您已成功建置一個新服務，將上傳到 Cloud Storage 的文件轉換為 PDF。

## 恭喜！

在此 lab 中，您探索了如何將 Go 應用程序轉換為容器，使用 Google Cloud Build 建構容器，並啟動 Cloud Run 服務。

您還獲得了透過服務帳戶啟用權限以及利用 Cloud Storage 事件處理的技能，所有這些都是 PDF 轉換器服務運作不可或缺的一部分，該服務將文件轉換為 PDF 並將它們儲存在 "processed" bucket 中。

## Google Cloud 訓練和認證

...幫助您充分利用 Google Cloud 技術。[我們的課程](https://cloud.google.com/training) 包含技術技能和最佳實務，幫助您快速上手並繼續您的學習之旅。我們提供從基礎到進階的訓練，並有隨需、即時和虛擬選項來滿足您忙碌的行程。[認證](https://cloud.google.com/certification/) 幫助您驗證並證明您在 Google Cloud 技術方面的技能和專業知識。
