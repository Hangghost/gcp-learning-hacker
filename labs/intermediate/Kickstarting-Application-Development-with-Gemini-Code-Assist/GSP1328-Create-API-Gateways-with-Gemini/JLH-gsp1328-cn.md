# GSP1328 - 使用 Gemini 創建 API Gateways

## 概述

Gemini 是一個由 AI 驅動的協作者，幫助開發團隊更快、更有效地建置、部署和運營應用程式。

在本實驗中，您將學習如何使用 Gemini for Developers 來協助撰寫新程式碼片段、提取微服務分解的程式碼，以及作為 Cymbal Superstore 專案的一部分建置 API Gateway。

本課程中的實驗涵蓋了從應用開發人員角度的典型軟體開發生命週期 (SDLC)。SDLC 的其他方面（需求、安全性、監控等）將在其他課程中涵蓋。

## 學習目標

本實驗重點在於以下方式利用 Gemini for Developers：

- 使用 Gemini Chat 引導您完成部署 API Gateway 服務所需的步驟。

## 您將學到什麼

Cymbal Superstore 是一個蓬勃發展的線上購物平台，致力於持續改進以保持市場競爭力。作為持續開發工作的一部分，設計了一個名為「New Products」的新功能，讓使用者能夠輕鬆發現商店庫存中的最新添加。

在本實驗中，我們將實作這個新功能 - 具體來說，新增一個名為「New Products」的服務端點。所有現有程式碼都將作為實驗設定的一部分提供，以及任何需要的基礎設施服務。程式碼將在名為「cymbal-superstore」的資料夾中。

## 任務 1：調查程式碼並部署 Cloud Function

### 設定環境變數

1. 在 Cloud Shell 中，執行以下命令來設定必要的環境變數。

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=Lab Region
export ZONE=Lab Zone
```

### 調查程式碼

隨著 Gemini 能夠解釋您不熟悉的程式碼片段的能力，它也可以為您建立註釋以添加到程式碼中，以增加未來維護週期的理解。

1. 點擊 Cloud Shell 視窗右上角的可見「**Open Editor**」選項來開啟編輯器。

2. 點擊「**Menu**」左側，並導航到「**File**」>「**Open Folder...**」。

3. 選取「**cymbal-superstore**」目錄，然後點擊「**OK**」。

4. 點擊「**Gemini**」旁的箭頭。

5. 點擊「**Select Gemini Code Assist Project**」，從列表中選取 `GCP Project ID` 專案。

6. 按住 **Ctrl+A** 或 **Cmd+A** 來選取整個程式碼區塊，然後按黃色或藍色燈泡來顯示 Gemini 協助選項，然後選取 `Gemini: Explain this`。這會開啟「**GEMINI: CHAT**」面板並解釋整個程式碼。

7. 如果提供了一般答案，則在聊天提示中輸入「`Explain in more detail`」。

### 部署 Cloud Function

讓我們現在部署 Cloud Function。

1. 使用 Cloud Shell 視窗工具列上的「**Open Terminal**」按鈕切換回 Cloud Shell 終端。在 Cloud Shell 終端中，執行以下命令來建立名為 `newproducts` 的 Cloud Function。

```bash
cd ~/cymbal-superstore/functions
gcloud functions deploy newproducts --runtime nodejs20 --trigger-http --allow-unauthenticated --region $REGION
```

**注意：** 如果 Cloud Function 建立因缺少權限而失敗，請重新執行上述命令。

2. 測試新 Function：從新瀏覽器分頁導航到 URL，並驗證 JSON 資料按預期返回。

## 任務 2：建立中介 API

為了分離並保護我們的後端服務免受公共網站影響，我們理想地使用 API 代理。我們可以在 Google Cloud 中使用 Apigee、Endpoints 來實現這一點。在我們的案例中，讓我們使用 API Gateway 服務。

1. 在 Cloud Shell 中，設定 API Gateway 使用的環境變數

```bash
export CONFIG_ID=newproducts-api-config
export API_ID=newproducts-api
export GATEWAY_ID=store
export OPENAPI_SPEC=newproducts.yaml
```

2. 讓我們建立一個名為 `newproducts.yaml` 的新檔案。

```bash
cd ~/cymbal-superstore/gateway
touch newproducts.yaml
```

3. 讓我們詢問 **Gemini** 一些協助來建立 OpenAPI 規範。使用 Cloud Shell 視窗工具列上的「**Open Editor**」選項切換回編輯器。

4. 開啟編輯器中的 `functions` 資料夾並選取 `index.js` 檔案。點擊 **plus** (**+**) 圖示啟動新聊天並輸入以下提示。

```
"Create an OpenAPI specification for this Cloud Function. The function returns a list of products from Firestore. The function URL is: [Cloud Function URL]"
```

5. 您可以使用生成的程式碼並貼到 `gateway` 資料夾下的 `newproducts.yaml` 檔案中，並視需要進行必要的編輯，或使用以下程式碼。

檔案應類似於以下內容：

```yaml
swagger: "2.0"
info:
  title: "newproducts"
  description: "A Cloud Function that returns a list of products from Firestore."
  version: "1.0.0"
host: "Lab Default Region-PROJECT_ID.cloudfunctions.net"
schemes:
- "https"
paths:
  /newproducts:
    get:
      summary: "Get a list of products from Firestore."
      operationId: "newproducts"
      produces:
      - "application/json"
      responses:
        "200":
          description: "A list of products."
          schema:
            type: "array"
            items:
              type: "object"
              properties:
                id:
                  type: "string"
                name:
                  type: "string"
                price:
                  type: "number"
                quantity:
                  type: "integer"
                imgfile:
                  type: "string"
                timestamp:
                  type: "string"
                actualdateadded:
                  type: "string"
```

## 任務 3：建立 API Gateway 服務

1. 使用 Cloud Shell 視窗工具列上的「**Open Terminal**」按鈕切換回 Cloud Shell 終端，並執行以下命令啟用 API Gateway 服務。

```bash
gcloud services enable apigateway.googleapis.com
```

2. 詢問 Gemini 建立 API Gateway 的步驟。在聊天中輸入以下提示。

```
"Guide me through the steps to create an API Gateway in Google Cloud using the OpenAPI specification I just created."
```

**注意：** 您可能會得到多種回應。有時 Gemini 會提供概述，您需要要求更多詳細資訊。其他時候答案可能使用通用名稱，您需要相應調整。

3. 在 Cloud Shell 終端中，使用 OpenAPI 規範在 Google Cloud API Gateway 服務中建立 API。

```bash
cd ~/cymbal-superstore
gcloud api-gateway apis create $API_ID
```

4. 在 Google Cloud API Gateway 中建立新的 API 配置。

```bash
cd ~/cymbal-superstore/gateway
gcloud api-gateway api-configs create $CONFIG_ID \
    --api=$API_ID --openapi-spec=$OPENAPI_SPEC
```

如果此命令失敗並顯示以下錯誤。

```
ERROR: (gcloud.api-gateway.api-configs.create) API Config has a backend with no address. If using OpenAPI, each 'x-google-backend' extension requires the 'address' field to be set.
```

請參考 [文件](https://cloud.google.com/endpoints/docs/openapi/openapi-extensions#x-google-backend) 以獲得一些見解。

5. 要修復上述錯誤，請在 `newproducts.yaml` 檔案中添加以下程式碼。

```yaml
x-google-backend:
        address: https://Lab Default Region-Project Name.cloudfunctions.net/newproducts
```

6. `newproducts.yaml` 檔案最終應如下所示：

```yaml
swagger: "2.0"
info:
  title: "newproducts"
  description: "A Cloud Function that returns a list of products from Firestore."
  version: "1.0.0"
host: "Lab Default Region-PROJECT_ID.cloudfunctions.net"
schemes:
- "https"
paths:
  /newproducts:
    get:
      summary: "Get a list of products from Firestore."
      operationId: "newproducts"
      x-google-backend:
        address: https://Lab Default Region-PROJECT_ID.cloudfunctions.net/newproducts
      produces:
      - "application/json"
      responses:
        "200":
          description: "A list of products."
          schema:
            type: "array"
            items:
              type: "object"
              properties:
                id:
                  type: "string"
                name:
                  type: "string"
                price:
                  type: "number"
                quantity:
                  type: "integer"
                imgfile:
                  type: "string"
                timestamp:
                  type: "string"
                actualdateadded:
                  type: "string"
```

7. 現在，再次嘗試建立 API 配置。

```bash
gcloud api-gateway api-configs create $CONFIG_ID \
    --api=$API_ID --openapi-spec=$OPENAPI_SPEC
```

8. 最終，基於配置檔案建立 Gateway。

```bash
gcloud api-gateway gateways create $GATEWAY_ID \
    --api=$API_ID --api-config=$CONFIG_ID \
    --location=$REGION --project=$PROJECT_ID
```

9. 驗證 Gateway 已建立並部署。

```bash
gcloud api-gateway gateways describe $GATEWAY_ID \
    --location=$REGION --project=$PROJECT_ID
```

記下輸出中的 `defaultHostname` 值，應類似於 `store-2srcbsle.uc.gateway.dev`。您將在實驗的後續階段需要此值。

10. 從瀏覽器開啟新分頁並輸入剛才記下的 `defaultHostname`，並附加 `/newproducts`。URL 應類似於：`https://store-2srcbsle.uc.gateway.dev/newproducts`

您應該會看到如下輸出中顯示的 10 條 JSON 記錄。

## 任務 4：更新前端網站

在本節中，讓我們更新前端以反映新的 `GATEWAY_ID` 主機名稱。

1. 在 Cloud Shell 終端中，導航到 `frontend` 資料夾：

```bash
cd ~/cymbal-superstore/frontend
```

2. 驗證其中一個檔案 `.env.production` 或 `env.production` 是否可用。要確保哪個檔案可用，請執行以下命令：

```bash
ls -all
```

3. 更新可用的檔案 `.env.production` 或 `env.production` 以使用 Gateway 的 `defaultHostname` 更新 URL。將註釋 `YOUR_ENDPOINT_URL_HERE` 替換為 Gateway 的 **defaultHostname**，記得排除 `/newproducts` 路徑。

4. 切換回 Cloud Shell 終端並重建前端。

```bash
cd ~/cymbal-superstore/frontend
npm install && npm run build
```

5. 將 `build` 目錄中的所有檔案和目錄上傳到 Google Cloud Storage bucket。

```bash
gcloud storage cp -r build/* gs://${PROJECT_ID}-cymbal-frontend --cache-control=no-cache,no-store,max-age=0
```

6. 使用網站的外部 IP 位址顯示 Cymbal Superstore 首頁。使用「**Navigation menu ()**」導航到「**View All Products > Networking > Network services > Load Balancing**」。點擊 `cymbal-url-map` 並記下 Frontend 下的 IP。

7. 在新的瀏覽器分頁中輸入記下的 IP。點擊首頁上的 `New Arrivals!` 連結。

您現在將被重新導向到新頁面，其中顯示 10 種產品。10 種產品的顯示確認後端已從資料庫正確獲取新產品。

## 恭喜！

您已成功建立 API Gateway 作為公共網站與後端服務之間的安全代理，並獲得 Gemini 的協助。

## 相關資源

- [API Gateway 文件](https://cloud.google.com/api-gateway/docs)
- [Cloud Functions 文件](https://cloud.google.com/functions/docs)
- [OpenAPI 規範](https://swagger.io/specification/)

## 故障排除

### 常見問題

1. **Cloud Function 部署失敗**
   - 確保您有足夠的權限
   - 檢查區域設定是否正確
   - 驗證程式碼語法

2. **API Gateway 建立失敗**
   - 檢查 OpenAPI 規範格式
   - 確保 Cloud Function URL 正確
   - 驗證 API Gateway 服務已啟用

3. **前端無法載入**
   - 檢查 Cloud Storage bucket 權限
   - 驗證建置過程完成
   - 確保環境變數正確設定

## 下一步

完成此實驗後，您可以：

- 探索更多 Gemini for Developers 的功能
- 學習其他 GCP API 管理服務
- 實作更複雜的微服務架構
