# GSP1329 - 使用 Gemini 進行程式碼生成

## 概述

Gemini 是一個由 AI 驅動的協作者，幫助開發團隊更快、更有效地建置、部署和運營應用程式。

在這裡，我們將展示如何使用 Gemini for Developers 來協助撰寫新的程式碼片段、提取微服務分解的程式碼，以及作為 Cymbal Superstore 專案的一部分建置 API Gateway。

本課程中的實驗涵蓋了從應用開發人員角度的典型軟體開發生命週期 (SDLC)。SDLC 的其他方面（需求、安全性、監控等）將在其他課程中涵蓋。

**實驗前提：** 您最近加入了一個開發了名為 Cymbal Superstore 的線上購物網站的團隊。它已經運營，您已被指派實作一些升級。具體來說，新增一個名為 new products 的端點服務。所有現有程式碼都將作為實驗設定的一部分提供，以及實驗所需的任何基礎設施服務。程式碼將在名為 cymbal-superstore 的資料夾中。

## 學習目標

在本實驗中，您將學習如何以下列方式利用 Gemini：

1. 使用自然語言描述建立有效的程式碼生成提示。

2. 使用內嵌註釋來生成和修改程式碼。

## 了解區域和區域

某些 Compute Engine 資源位於區域或區域中。區域是您可以運行資源的特定地理位置。每個區域有一個或多個區域。例如，us-central1 區域表示美國中部的一個區域，具有區域 us-central1-a、us-central1-b、us-central1-c 和 us-central1-f。

| **區域** | **區域** |
|----------|----------|
| 美國西部 | us-west1-a, us-west1-b |
| 美國中部 | us-central1-a, us-central1-b, us-central1-d, us-central1-f |
| 美國東部 | us-east1-b, us-east1-c, us-east1-d |
| 歐洲西部 | europe-west1-b, europe-west1-c, europe-west1-d |
| 東亞 | asia-east1-a, asia-east1-b, asia-east1-c |

位於區域中的資源稱為區域資源。虛擬機實例和持久磁碟位於區域中。要將持久磁碟連接至虛擬機實例，兩個資源必須在同一區域中。同樣，如果您想將靜態 IP 位址分配給實例，實例必須與靜態 IP 在同一區域中。

在 Compute Engine 頁面中了解更多關於區域和區域的資訊，並查看完整列表：[區域和區域文檔](https://cloud.google.com/compute/docs/regions-zones/)。

## 任務 1：設定 Cymbal Superstore

本實驗使用「Cymbal Superstore」雜貨網路應用。在本實驗的後續任務中，您將使用 Gemini 在此應用中開發和部署新功能。在此任務中，您建置此應用的前端和後端元件。

### 設定環境

在此和接下來的兩個子任務中在終端 shell 中執行命令。

1. 在 Cloud Shell 中，執行以下命令來設定必要的環境變數。

```bash
export PROJECT_ID=$(gcloud config get-value project)
export USER=$(gcloud config get-value account)
export REPO_NAME=store-repo
export REGION=Lab Region
export ZONE=Lab Zone
export APP_NAME=inventory
```

2. 要運行 Docker 憑證助手，請執行以下命令。當詢問是否要繼續時，輸入 **Y**。

```bash
gcloud auth configure-docker
```

3. 啟用 Cloud AI Companion API：

```bash
gcloud services enable cloudaicompanion.googleapis.com --project ${PROJECT_ID}
```

4. 要使用 Gemini，請將必要的 IAM 角色授予您的 Google Cloud Qwiklabs 使用者帳戶：

```bash
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member user:${USER} --role=roles/cloudaicompanion.user
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member user:${USER} --role=roles/serviceusage.serviceUsageViewer
```

添加這些角色讓使用者可以使用 Gemini 協助。

5. 要下載 `cymbal-superstore` 應用程式碼，請執行以下命令：

```bash
gsutil -m cp -r gs://duet-appdev/cymbal-superstore .
```

### 建置後端

網路應用後端實作了前端用來擷取和更新產品的庫存 API。

1. 要建置後端容器映像，在雲端終端中執行以下命令：

```bash
cd ~/cymbal-superstore/backend
docker build -t gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api:latest .
```

2. 要將建置的後端映像推送到 Cloud Repository，請執行以下命令：

```bash
docker push gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api:latest
```

3. 要將後端作為 Cloud Run 上的服務部署，請執行以下命令。按下按鈕 **Y** 以允許對庫存進行未經驗證的調用。

```bash
gcloud run deploy inventory --image=gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api --port=8000 --region=$REGION
```

**輸出：**

```
Deploying container to Cloud Run service [inventory] in project [PROJECT_ID] region [Lab Region]
OK Deploying... Done.
OK Creating Revision...
OK Routing traffic...
Done.
Service [inventory] revision [inventory-00002-n9z] has been deployed and is serving 100 percent of traffic.
Service URL: https://inventory-bacbqreknq-uk.a.run.app
```

記下創建的 Cloud Run 服務 URL（與上面不同）。

### 驗證端點正在工作

1. 通過瀏覽到 Cloud Run URL 來呼叫端點來檢查新端點。

2. 在瀏覽器分頁中，執行 Cloud Run 服務 URL（從上面）：

**範例：** `https://inventory-bacbqreknq-uk.a.run.app`

**輸出：**

`"🍎 Hello! This is the Cymbal Superstore Inventory API"`

將端點路徑 `/products` 添加到基礎 URL。

**範例：** `https://inventory-bacbqreknq-uk.a.run.app/products`

**範例輸出：**

```json
{"id":"01Jggpy8RcgXSZnsJ8gy","name":"Eggs","price":9,"quantity":227,"imgfile":"product-images/eggs.png","timestamp":{"_seconds":1704651168,"_nanoseconds":923000000},"actualdateadded":{"_seconds":1714468020,"_nanoseconds":203000000}},{"id":"0n0fnOTKQbR3W6eERmNY","name":"Peanut Butter and Jelly Cups","price":7,"quantity":8,"imgfile":"product-images/peanutbutterandjellycups.png","timestamp":{"_seconds":1713980240,"_nanoseconds":721000000},"actualdateadded":{"_seconds":1714468020,"_nanoseconds":213000000}}
```

這顯示了商店所有產品的 JSON 資料。

3. 將端點路徑 `/newproducts` 添加到基礎 URL - 這將顯示錯誤，因為 newproducts 端點尚未寫入。

**範例：** `https://inventory-bacbqreknq-uk.a.run.app/newproducts`

**輸出：**

`Cannot GET /newproducts`

### 建置前端網站並驗證網站工作

1. 執行以下命令導航到 `frontend` 資料夾：

```bash
cd ~/cymbal-superstore/frontend
```

2. 現在通過在終端視窗中運行這些命令來重建前端。

```bash
npm install
npm audit fix --force
export NODE_OPTIONS=--openssl-legacy-provider
npm install react-scripts@5.0.1 --save-dev
npm run build
```

3. 將其上傳到 Cloud Storage bucket。

```bash
gcloud storage cp -r build/* gs://$PROJECT_ID-cymbal-frontend --cache-control=no-cache,no-store,max-age=0
```

### 驗證網站正在工作

1. 使用網站的外部 IP 位址顯示 Cymbal Superstore 首頁。使用導航選單 ()，導航到 **View All Products > Networking > Network services > Load Balancing**。點擊 `cymbal-url-map` 並記下 Frontend 下的 IP。

2. 在新的瀏覽器分頁中輸入記下的 IP。點擊首頁上的 `New Arrivals!` 連結。

3. 驗證它是虛擬資料（由沒有照片和 Test Products 資料表示）。

## 任務 2：將 newProducts 端點添加到後端

1. 通過點擊 Cloud Shell 視窗右上角可見的 **Open Editor** 選項來開啟編輯器。

2. 點擊 **Menu** 在左側，並導航到 **File** > **Open Folder...**。

3. 選取 **cymbal-superstore** 目錄，然後點擊 **OK**。

4. 調查寫在 `backend` 資料夾下的 **index.ts** 檔案中的程式碼。

5. 在檔案的右上角，點擊 **Gemini** 旁邊的箭頭。

6. 點擊 **Select Gemini Code Assist Project**，以選取要用於 Gemini 的專案。從列表中選取 `GCP Project ID` 專案。

7. 在 `index.ts` 程式碼檔案中，滾動到第 102 行，您會看到 `/newproducts` 端點的佔位符註釋。

8. 用以下提示替換佔位符註釋：`// /newproducts endpoint` goes here：

```typescript
// Create a new route called /newproducts that uses a where filter
// to retrieve only products that were added within the last seven days.
```

9. 選取新添加的註釋，並點擊出現的黃色燈泡圖示。從列表中點擊以下選項：`Gemini: Generate code`。

10. Gemini 顯示一些建議的程式碼。查看建議的程式碼並通過點擊 **Accept** 或按 **Tab** 鍵來接受它。

### 重新部署後端

1. 從 Cloud Shell 終端執行以下命令來建置新容器。

```bash
cd ~/cymbal-superstore/backend
docker build -t gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api:latest .
```

2. 將新容器推送到 Artifact Registry。

```bash
docker push gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api:latest
```

3. 將容器部署到 Cloud Run

```bash
gcloud run deploy inventory --image=gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api --port=8000 --region=$REGION
```

如果詢問：Allow unauthenticated invocations to [inventory] (y/N)? 輸入 **Y**。

**輸出：**

```
Deploying container to Cloud Run service [inventory] in project [PROJECT_ID] region [Lab Region]
OK Deploying... Done.
OK Creating Revision...
OK Routing traffic...
Done.
Service [inventory] revision [inventory-00002-n9z] has been deployed and is serving 100 percent of traffic.
Service URL: https://inventory-bacbqreknq-uk.a.run.app
```

記下創建的 Cloud Run 服務 URL（與上面不同）。

### 驗證端點正在工作

1. 在瀏覽器分頁中，執行 Cloud Run 服務 URL（從上面）：

**範例：** `https://inventory-bacbqreknq-uk.a.run.app`

**輸出：**

`"🍎 Hello! This is the Cymbal Superstore Inventory API"`

2. 將端點路徑 `/products` 添加到基礎 URL。

**輸出：**

```json
{"id":"01Jggpy8RcgXSZnsJ8gy","name":"Eggs","price":5,"quantity":181,"imgfile":"product-images/eggs.png","timestamp":{"_seconds":1691767020,"_nanoseconds":20000000},"actualdateadded":{"_seconds":1714473490,"_nanoseconds":560000000}},{"id":"0n0fnOTKQbR3W6eERmNY","name":"Peanut Butter and Jelly Cups","price":5,"quantity":1,"imgfile":"product-images/peanutbutterandjellycups.png","timestamp":{"_seconds":1714000418,"_nanoseconds":14000000},"actualdateadded":{"_seconds":1714473490,"_nanoseconds":568000000}}
```

這顯示了商店所有產品的 JSON 資料。

3. 將端點路徑 `/newproducts` 添加到基礎 URL。

**輸出：**

```json
{"id":"0n0fnOTKQbR3W6eERmNY","name":"Peanut Butter and Jelly Cups","price":5,"quantity":1,"imgfile":"product-images/peanutbutterandjellycups.png","timestamp":{"_seconds":1714000418,"_nanoseconds":14000000},"actualdateadded":{"_seconds":1714473490,"_nanoseconds":568000000}},{"id":"HwtaJN6kXj9YEQtzHB7P","name":"Pineapple Kombucha","price":9,"quantity":39,"imgfile":"product-images/pineapplekombucha.png","timestamp":{"_seconds":1714002141,"_nanoseconds":22000000},"actualdateadded":{"_seconds":1714473490,"_nanoseconds":567000000}}
```

這現在有效，您應該會看到一個比產品列表小的 JSON 列表。

**注意：** 如果您在上面的可選步驟中添加了數量到產品名稱，您應該會在 JSON 資料中看到該格式。範例："name":"Pineapple Kombucha (91)"

如果在呼叫新的 /newproducts 路由時收到「System unavailable」訊息，或意外結果，請點擊下面的按鈕獲取提示。

### 測試程式碼

1. 展示程式碼與前端網站一起工作。

2. 導航到 `frontend` 資料夾：

```bash
cd ~/cymbal-superstore/frontend
```

3. 驗證其中一個檔案 `.env.production` 或 `env.production` 是否可用。要確保哪個檔案可用，請執行以下命令：

```bash
ls -all
```

4. 用 Cloud Run URL 更新可用的檔案 `.env.production` 或 `env.production`，以引用 URL。將註釋 `YOUR_ENDPOINT_URL_HERE` 替換為服務 URL。不要忘記排除 **/newproducts** 路徑。

```bash
REACT_APP_INVENTORY_API_URL = <Cloud Run URL w/o the /newproducts path>
```

**範例：**

```bash
REACT_APP_INVENTORY_API_URL = https://inventory-l2imehewsq-uc.a.run.app
```

### 重新建置前端

1. 執行以下命令導航到 `frontend` 資料夾：

```bash
cd ~/cymbal-superstore/frontend
```

2. 現在通過在終端視窗中運行這些命令來重建前端。

```bash
npm install
npm audit fix --force
export NODE_OPTIONS=--openssl-legacy-provider
npm install react-scripts@5.0.1 --save-dev
npm run build
```

3. 將其上傳到 Cloud Storage bucket。

```bash
gcloud storage cp -r build/* gs://$PROJECT_ID-cymbal-frontend --cache-control=no-cache,no-store,max-age=0
```

4. 使用網站的外部 IP 位址顯示 Cymbal Superstore 首頁。使用 **Navigation menu ()**，導航到 **View All Products > Networking > Network services > Load Balancing**。點擊 `cymbal-url-map` 並記下 **Frontend** 下的 IP。

5. 在新的瀏覽器分頁中輸入記下的 IP。點擊首頁上的 `New Arrivals!` 連結，您會看到 `Test Products` 不再顯示或快速替換。

**注意：** 顯示的 10 種產品確認後端已從資料庫正確擷取新產品。此外，如果您添加了數量到產品名稱，您應該會看到一些產品顯示數量為 0。

## 任務 3：使用 Cloud Functions 提取到新的微服務

### 部署 Cloud Function

現在讓我們看看是否可以部署這個新功能。

1. 在聊天回應中，Gemini 可能已經給了您部署命令。如果沒有，讓我們詢問：

**記住：** 與 Gemini 合作是一個對話。它可能需要一些來回會話來獲得足夠接近的結果來完成工作或至少開始。

2. 開啟 `functions/index.js` 檔案。通過按 **Ctrl + A** 或 **Cmd+A** 選取程式碼。點擊燈泡並點擊 `Gemini: Explain this`。這將開啟 **GEMINI: CHAT** 面板。按 **Enter** 以在聊天中接收程式碼的完整解釋。

3. 在 Gemini Chat 中，輸入以下提示。

```
What is the gcloud command to deploy this /newproducts route as a Cloud Run Function in the Lab Region region? Don't forget to allow unauthenticated http requests.
```

**深入探討：**

要查看 Gemini 相對於上下文如何工作，請在這其他 2 個場景下重新運行提示。

1. 關閉所有檔案視窗並通過點擊聊天上方的 **New Chat** 圖示 (+) 重置 Gemini 的 Chat - 提示結果將非常通用。

2. 開啟 package.json 檔案 - 提示結果將是特定的，但可能不會顯示 http 觸發器選項。這是因為 package.json 沒有引用 http。原始結果顯示了帶有 –trigger-http 的命令，因為 Gemini 看到端點是一個 http 功能。

4. 讓我們試試。在終端中，變更到 /functions 資料夾：

```bash
cd ~/cymbal-superstore/functions
```

然後運行 Gemini 給您的命令。

5. 如果部署不起作用，請點擊下面的按鈕獲取提示。

該功能已創建！

**注意：** 如果 Cloud Function 建立因缺少權限而失敗，請重新執行上述命令。

6. 功能的 URL 顯示在終端中，或者您可以通過在控制台中開啟 Cloud Functions 找到它。

**範例 URL：** `https://us-central1-qwiklabs-gcp-01-457d0634df06.cloudfunctions.net/newproducts`

### 讓我們測試新功能

1. 通過使用 **/newproducts** 路徑執行 Cloud Function 來顯示它有效，以驗證 JSON 資料按預期返回。

2. 從功能部署回應中複製 URL。

```
state: ACTIVE
updateTime: '2025-07-25T02:28:40.172396925Z'
url: https://Lab Region-PROJECT_ID.cloudfunctions.net/newproducts
```

3. 將 URL 貼到瀏覽器分頁並導航到它。

**輸出：**

```json
{"id":"vcMyZepctx3BrDL7yc5w","name":"Pineapple Kombucha (91)","price":1,"quantity":91,"imgfile":"product-images/pineapplekombucha.png","timestamp":{"_seconds":1707055701,"_nanoseconds":790000000},"actualdateadded":{"_seconds":1707500364,"_nanoseconds":191000000}},{"id":"ODThuqw2avA2mSvOUH6r","name":"White Chocolate Caramel Corn (9)","price":5,"quantity":9,"imgfile":"product-images/whitechocolatecaramelcorn.png","timestamp":{"_seconds":1707160496,"_nanoseconds":367000000},"actualdateadded":{"_seconds":1707500364,"_nanoseconds":192000000}}
```

您會看到這是您之前看到的相同幾個 JSON 記錄。現在是將其整合到前端 API 的時候了。

4. 編輯 `frontend/env.production` 或 `frontend/.env.production` 檔案，以使用剛創建的 Cloud Function 的 URL 更新 URL。用新的 Cloud Function URL 替換 Cloud Run URL。不要忘記排除 `/newproducts` 路徑。

**範例：**

5. 現在通過在終端視窗中運行這些命令來重建前端。

```bash
cd ~/cymbal-superstore/frontend
npm install
npm audit fix --force
export NODE_OPTIONS=--openssl-legacy-provider
npm install react-scripts@5.0.1 --save-dev
npm run build
```

6. 將其上傳到 Cloud Storage bucket。

```bash
gcloud storage cp -r build/* gs://$PROJECT_ID-cymbal-frontend --cache-control=no-cache,no-store,max-age=0
```

7. 現在讓我們通過按 **New Arrivals** 呼叫網站 IP 來試試。

## 恭喜！

您已成功使用 Gemini for Developers 實作了程式碼生成，並將新功能提取到微服務中。

## 相關資源

- [Gemini for Developers 文檔](https://cloud.google.com/gemini/docs)
- [Cloud Functions 文檔](https://cloud.google.com/functions/docs)
- [Cloud Run 文檔](https://cloud.google.com/run/docs)
- [Docker 文檔](https://docs.docker.com/)

## 故障排除

### 常見問題

1. **Gemini 無法生成程式碼**
   - 確保已正確設定 IAM 角色
   - 檢查 Cloud AI Companion API 已啟用
   - 驗證註釋格式正確

2. **Cloud Function 部署失敗**
   - 確保區域設定正確
   - 檢查程式碼語法
   - 驗證權限設定

3. **前端建置失敗**
   - 確保 Node.js 版本相容
   - 檢查 npm 依賴
   - 驗證環境變數

4. **API 端點無回應**
   - 檢查 Cloud Run/Cloud Function 狀態
   - 驗證 URL 正確
   - 檢查防火牆規則

## 下一步

完成此實驗後，您可以：

- 探索更多 Gemini 程式碼生成功能
- 學習微服務架構模式
- 實作更複雜的 API 端點
- 研究 Cloud Functions 最佳實務
