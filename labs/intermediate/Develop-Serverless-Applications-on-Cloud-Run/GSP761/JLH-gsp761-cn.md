# GSP761 - 使用 Go 和 Cloud Run 開發 REST API

## Lab 概述

對於 [Serverless Cloud Run Development](https://www.cloudskillsboost.google/course_templates/741) 課程中的 labs，您將閱讀一個虛構的商業案例，並協助角色進行其無伺服器遷移計劃。

12 年前，Lily 創立了 Pet Theory 獸醫診所鏈。隨著診所鏈的成長，Lily 花在與保險公司通話上的時間比治療寵物還多。如果保險公司能夠在線看到治療總額就好了！

在此系列的先前 labs 中，電腦顧問 Ruby 和 DevOps 工程師 Patrick 已將 Pet Theory 的客戶資料庫遷移到雲端中的無伺服器 Firestore 資料庫，然後開放存取讓客戶可以線上預約。由於 Pet Theory 的營運團隊只有一個人，他們需要一個不需要大量持續維護的無伺服器解決方案。

在此 lab 中，您將協助 Ruby 和 Patrick 讓保險公司能夠存取客戶資料，而不會暴露個人識別資訊 (PII)。您將使用 Cloud Run（這是無伺服器的）建置一個安全的 REST API 閘道器。這將讓保險公司能夠看到治療總成本，而不會看到客戶的 PII。

## 學習目標

在此 lab 中，您將：

- 使用 Go 開發 REST API
- 將測試客戶資料匯入 Firestore
- 將 REST API 連接到 Firestore 資料庫
- 將 REST API 部署到 Cloud Run

## 先決條件

這是一個中級 lab。假設熟悉 Cloud Console 和 Cloud Shell 環境。此 lab 是系列的一部分。參加之前的 labs 可能會有幫助，但不是必要的：

- 將資料匯入無伺服器資料庫
- 使用 Firebase 和 Firestore 建置無伺服器網路應用程式
- 建置建立 PDF 文件的無伺服器應用程式

協助 Ruby 管理建置 Pet Theory REST API 所需的活動。

## 任務 1. 啟用 Google APIs

在此 lab 中，已為您啟用 2 個 API：

| **名稱** | **API** |
|----------|---------|
| Cloud Build | cloudbuild.googleapis.com |
| Cloud Run Admin | run.googleapis.com |

## 任務 2. 開發 REST API

1. 啟用您的專案：

```bash
gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
```

2. 複製 pet-theory 儲存庫並存取原始碼：

```bash
git clone https://github.com/rosera/pet-theory.git && cd pet-theory/lab08
```

3. 使用您最喜歡的文字編輯器，或使用 Cloud Shell 功能區中的程式碼編輯器按鈕，來查看 `go.mod` 和 `go.sum` 檔案。

4. 建立檔案 `main.go` 並將以下內容新增至檔案：

```go
package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
)

func main() {
  port := os.Getenv("PORT")
  if port == "" {
      port = "8080"
  }
  http.HandleFunc("/v1/", func(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "{status: 'running'}")
  })
  log.Println("Pets REST API listening on port", port)
  if err := http.ListenAndServe(":"+port, nil); err != nil {
      log.Fatalf("Error launching Pets REST API server: %v", err)
  }
}
```

**注意：**在上面的程式碼中，您建立一個端點來測試服務是否按預期正常運行。透過將 "/v1/" 附加到服務 URL，您可以驗證應用程式是否按預期運作。Cloud Run 部署容器，因此您需要提供容器定義。名為 `Dockerfile` 的檔案告訴 Cloud Run 要使用哪個 Go 版本，要在應用程式中包含哪些檔案，以及如何啟動程式碼。

5. 現在建立名為 `Dockerfile` 的檔案，並將以下內容新增至其中：

```dockerfile
FROM gcr.io/distroless/base-debian12
WORKDIR /usr/src/app
COPY server .
CMD [ "/usr/src/app/server" ]
```

檔案 `server` 是從 `main.go` 建構的執行二進位檔案。

6. 執行以下命令來建構二進位檔案：

```bash
go build -o server
```

7. 執行建構命令後，請確保您在同一目錄中有必要的 Dockerfile 和 server：

```bash
ls -la
```

```
.
├── Dockerfile
├── go.mod
├── go.sum
├── main.go
└── server
```

對於大多數 Cloud Run Go 應用程式，可以使用類似上面的模板 Dockerfile，而無需修改它。

8. 執行以下命令來部署您的簡單 REST API：

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1
```

此命令使用您的程式碼建構容器，並將其放入您專案的 Artifact Registry 中。您可以點擊：**導覽選單** ()，點擊 **VIEW ALL PRODUCTS** > **CI/CD** > **Artifact Registry** 並點擊 **gcr.io** 儲存庫來查看容器。如果您沒有看到 `rest-api`，請點擊 **Refresh**。

*導覽選單圖標*

*Artifact Registry 圖表*

點擊 **Check my progress** 來驗證您已執行上述任務。

使用 Cloud Build 建構映像

9. 容器建構完成後，部署它：

```bash
gcloud run deploy rest-api \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1 \
  --platform managed \
  --region "Filled in at lab startup." \
  --allow-unauthenticated \
  --max-instances=2
```

10. 部署完成時，您會看到類似以下的訊息：

```
Service [rest-api] revision [rest-api-00001] has been deployed and is serving
traffic at https://rest-api-[hash].a.run.app
```

點擊 **Check my progress** 來驗證目標。

REST API 服務已部署

11. 點擊該訊息末尾的 Service URL，在新的瀏覽器分頁中開啟它。在 URL 末尾附加 `/v1/` 然後按 **Enter**。

您應該會看到此訊息：

```
{"status": "running"}
```

REST API 已啟動並運行。隨著原型服務可用，在下一區段中，API 將用於從 Firestore 資料庫擷取「客戶」資訊。

## 任務 3. 匯入測試客戶資料

Ruby 和 Patrick 之前已建立包含 10 個客戶的測試資料庫，其中包含一個客戶的貓的一些建議治療。

協助 Patrick 設定 Firestore 資料庫並匯入客戶測試資料。首先，在您的專案中啟用 Firestore。

1. 返回 Cloud Console 並點擊 **導覽選單** ()，點擊 **VIEW ALL PRODUCTS** > **Databases** > **Firestore**。

   *導覽選單圖標*

2. 點擊 **Create a Firestore Database** 按鈕。

3. 選取 **Standard Edition**。

4. 在 Configuration options 下，選取 **Firestore Native**。

5. 對於 Security rules，選擇 **Open**。

6. 對於 **Location type** 選取 **Region**。

7. 從可用清單中選取區域 `REGION` 並點擊 **Create Database**。

等待資料庫建立完成再繼續。

點擊 **Check my progress** 來驗證目標。

Firestore 資料庫已建立

8. 將匯入檔案遷移到已為您建立的 Cloud Storage bucket：

```bash
gsutil mb -c standard -l Region gs://$GOOGLE_CLOUD_PROJECT-customer
```

```bash
gsutil cp -r gs://spls/gsp645/2019-10-06T20:10:37_43617 gs://$GOOGLE_CLOUD_PROJECT-customer
```

9. 現在將此資料匯入 Firebase：

```bash
gcloud beta firestore import gs://$GOOGLE_CLOUD_PROJECT-customer/2019-10-06T20:10:37_43617/
```

重新載入 Cloud Console 瀏覽器以查看 Firestore 結果。

10. 在 Firestore 中，點擊 "Default" 下的 **customers**。您應該會看到匯入的寵物資料，請瀏覽一下。如果您沒有看到任何資料，請嘗試重新整理頁面。

太好了，Firestore 資料庫已成功建立並填入測試資料！

## 任務 4. 將 REST API 連接到 Firestore 資料庫

在此區段中，您將協助 Ruby 在 REST API 中建立另一個端點，看起來像這樣：

```
https://rest-api-[hash].a.run.app/v1/customer/22530
```

例如，該 URL 應該返回客戶 ID 22530 的所有建議、接受和拒絕治療的總金額，如果它們存在於 Firestore 資料庫中：

```json
{
  "status": "success",
  "data": {
    "proposed": 1602,
    "approved": 585,
    "rejected": 489
  }
}
```

**注意：**如果客戶不存在於資料庫中，應該返回狀態碼 404（未找到）和錯誤訊息。

此新功能需要一個套件來存取 Firestore 資料庫，另一個套件來處理跨來源資源共享 (CORS)。

1. 取得 $GOOGLE_CLOUD_PROJECT 環境變數的值

```bash
echo $GOOGLE_CLOUD_PROJECT
```

2. 在 pet-theory/lab08 目錄中開啟現有的 `main.go` 檔案。

**注意：**使用顯示的 $GOOGLE_CLOUD_PROJECT 值來更新 main.go 的內容。

3. 使用下面的程式碼替換檔案的內容，確保 `PROJECT_ID` 設定為：

```go
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"cloud.google.com/go/firestore"
	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"google.golang.org/api/iterator"
)

  var client *firestore.Client

  func main() {
    var err error
    ctx := context.Background()
    client, err = firestore.NewClient(ctx, "Filled in at lab startup.")
    if err != nil {
    log.Fatalf("Error initializing Cloud Firestore client: %v", err)
  }

  port := os.Getenv("PORT")
  if port == "" {
    port = "8080"
  }

  r := mux.NewRouter()
  r.HandleFunc("/v1/", rootHandler)
  r.HandleFunc("/v1/customer/{id}", customerHandler)

  log.Println("Pets REST API listening on port", port)
  cors := handlers.CORS(
    handlers.AllowedHeaders([]string{"X-Requested-With", "Authorization", "Origin"}),
    handlers.AllowedOrigins([]string{"https://storage.googleapis.com"}),
    handlers.AllowedMethods([]string{"GET", "HEAD", "POST", "OPTIONS", "PATCH", "CONNECT"}),
  )

	if err := http.ListenAndServe(":"+port, cors(r)); err != nil {
    log.Fatalf("Error launching Pets REST API server: %v", err)
	}
}
```

4. 在檔案底部新增處理器支援：

```go
func rootHandler(w http.ResponseWriter, r *http.Request) {
  fmt.Fprintf(w, "{status: 'running'}")
}

func customerHandler(w http.ResponseWriter, r *http.Request) {
  id := mux.Vars(r)["id"]
  ctx := context.Background()
  customer, err := getCustomer(ctx, id)
  if err != nil {
    w.WriteHeader(http.StatusInternalServerError)
    fmt.Fprintf(w, `{"status": "fail", "data": '%s'}`, err)
    return
  }
  if customer == nil {
    w.WriteHeader(http.StatusNotFound)
    msg := fmt.Sprintf("`Customer \"%s\" not found`", id)
    fmt.Fprintf(w, fmt.Sprintf(`{"status": "fail", "data": {"title": %s}}`, msg))
    return
  }
  amount, err := getAmounts(ctx, customer)
  if err != nil {
    w.WriteHeader(http.StatusInternalServerError)
    fmt.Fprintf(w, `{"status": "fail", "data": "Unable to fetch amounts: %s"}`, err)
    return
  }
  data, err := json.Marshal(amount)
  if err != nil {
    w.WriteHeader(http.StatusInternalServerError)
    fmt.Fprintf(w, `{"status": "fail", "data": "Unable to fetch amounts: %s"}`, err)
    return
  }
  fmt.Fprintf(w, fmt.Sprintf(`{"status": "success", "data": %s}`, data))
}
```

5. 在檔案底部新增 Customer 支援：

```go
type Customer struct {
  Email string `firestore:"email"`
  ID    string `firestore:"id"`
  Name  string `firestore:"name"`
  Phone string `firestore:"phone"`
}

func getCustomer(ctx context.Context, id string) (*Customer, error) {
  query := client.Collection("customers").Where("id", "==", id)
  iter := query.Documents(ctx)

  var c Customer
  for {
    doc, err := iter.Next()
    if err == iterator.Done {
	break
    }
    if err != nil {
	return nil, err
    }
    err = doc.DataTo(&c)
    if err != nil {
	return nil, err
    }
  }
  return &c, nil
}

func getAmounts(ctx context.Context, c *Customer) (map[string]int64, error) {
  if c == nil {
    return map[string]int64{}, fmt.Errorf("Customer should be non-nil: %v", c)
  }
  result := map[string]int64{
    "proposed": 0,
    "approved": 0,
    "rejected": 0,
  }
  query := client.Collection(fmt.Sprintf("customers/%s/treatments", c.Email))
  if query == nil {
    return map[string]int64{}, fmt.Errorf("Query is nil: %v", c)
  }
  iter := query.Documents(ctx)
  for {
    doc, err := iter.Next()
    if err == iterator.Done {
	break
    }
    if err != nil {
	return nil, err
    }
    treatment := doc.Data()
    result[treatment["status"].(string)] += treatment["cost"].(int64)
  }
  return result, nil
}
```

6. **儲存** 檔案。

## 任務 5. 小測驗

哪個函數回應具有模式 `/v1/customer/` 的 URL？`customerHandler`

哪個陳述式向客戶返回成功？`fmt.Fprintf(w, fmt.Sprintf(`{"status": "success", "data": %s}`

哪個函數從 Firestore 資料庫讀取？`getCustomer and getAmounts`

## 任務 6. 部署新修訂版本

1. 重新建構原始碼：

```bash
go build -o server
```

2. 為 REST API 建構新映像：

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2
```

點擊 **Check my progress** 來驗證目標。

建構映像修訂版本 0.2

3. 部署更新的映像：

```bash
gcloud run deploy rest-api \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2 \
  --platform managed \
  --region "Filled in at lab startup." \
  --allow-unauthenticated \
  --max-instances=2
```

4. 部署完成時，您會看到與之前類似的訊息。部署新版本時，您的 REST API URL 沒有變更：

```
Service [rest-api] revision [rest-api-00002] has been deployed and is serving
traffic at https://rest-api-[hash].a.run.app
```

5. 返回已指向該 URL 的瀏覽器分頁（末尾有 `/v1/`）。重新整理它並確保您得到與之前相同的訊息，表示 API 狀態仍在運行。

```
{"status": "running"}
```

6. 在瀏覽器的位址列中將 `/customer/22530` 附加到應用程式 URL。您應該會得到此 JSON 回應，列出客戶的建議、接受和拒絕治療的總和：

```json
{
  "status": "success",
  "data": {
    "proposed": 1602,
    "approved": 585,
    "rejected": 489
  }
}
```

7. 以下是一些您可以放在 URL 中而不是 22530 的其他客戶 ID：

- 34216
- 70156（所有金額應該為零）
- 12345（客戶/寵物不存在，應該返回錯誤，例如 **Query is nil**）

您已建置一個可擴展、低維護、無伺服器的 REST API，可以從資料庫讀取。

## 恭喜！

恭喜！在此 lab 中，您協助 Ruby 和 Patrick 成功為 Pet Theory 建置原型 REST API。您建立了一個連接到 Firestore 資料庫的 REST API，並將其部署到 Cloud Run。您還測試了 API 以確保它按預期運作。
