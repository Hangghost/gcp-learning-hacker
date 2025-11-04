# GSP919 - 將應用程式連接至 Cloud SQL for PostgreSQL 實例

## 實驗概述

Cloud SQL 是 Google Cloud 提供的全託管關聯式資料庫服務，支援 MySQL、PostgreSQL 和 Microsoft SQL Server，並提供備份、複寫和記錄等管理任務。本實驗將建立 Kubernetes 集群並部署一個簡單的應用程式，然後將該應用程式連接至提供的 Cloud SQL for PostgreSQL 實例，並確認應用程式能夠讀寫資料庫。

## 學習目標

完成本實驗後，您將能夠：
- 建立 Kubernetes 集群並部署輕量級應用程式
- 將應用程式連接至 Cloud SQL for PostgreSQL 資料庫實例
- 確認應用程式能夠讀寫資料庫

## 預估完成時間

60 分鐘

## 前置需求

- Google Cloud Platform 帳戶
- 基本 GCP 知識
- 熟悉 Kubernetes 和 Docker 概念
- 熟悉命令列工具

## 設定和需求

### 設定您的區域和區域

某些 Compute Engine 資源位於區域和區域中。區域是您執行資源的特定地理位置，每個區域都有一個或多個區域。

**注意**：請參考[區域和區域文件](https://cloud.google.com/compute/docs/regions-zones/)了解更多資訊並查看完整列表。

在 Cloud Shell 中執行以下 gcloud 指令來設定實驗的預設區域和區域：

```bash
gcloud config set compute/zone "ZONE"
export ZONE=$(gcloud config get compute/zone)

gcloud config set compute/region "REGION"
export REGION=$(gcloud config get compute/region)
```

## 實驗步驟

### 任務 1：初始化 API 並建立 Cloud IAM 服務帳戶

#### 啟用 API

您需要啟用本實驗所需的 API。由於稍後需要在 Artifact Registry 中建置和推送容器，您必須先啟用 Artifact Registry API。

1. 在 Cloud Shell 中執行以下指令啟用 Artifact Registry API：

```bash
gcloud services enable artifactregistry.googleapis.com
```

#### 建立 Cloud SQL 的服務帳戶

您需要為應用程式配置 IAM 服務帳戶憑證，以便連接 Cloud SQL 資料庫。服務帳戶必須綁定至允許其建立和存取 Cloud SQL 資料庫的角色。

1. 在 Cloud Shell 中建立服務帳戶並綁定至 Cloud SQL 管理員角色：

```bash
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export CLOUDSQL_SERVICE_ACCOUNT=cloudsql-service-account

gcloud iam service-accounts create $CLOUDSQL_SERVICE_ACCOUNT --project=$PROJECT_ID

gcloud projects add-iam-policy-binding $PROJECT_ID \
--member="serviceAccount:$CLOUDSQL_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
--role="roles/cloudsql.admin"
```

1. 在 Cloud Shell 中建立金鑰並匯出至本機檔案：

```bash
gcloud iam service-accounts keys create $CLOUDSQL_SERVICE_ACCOUNT.json \
    --iam-account=$CLOUDSQL_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
    --project=$PROJECT_ID
```

金鑰檔案將儲存至 Cloud Shell 的主資料夾中。

### 任務 2：部署輕量級 GKE 應用程式

在本任務中，您將建立 Kubernetes 集群並部署一個輕量級 Google Kubernetes Engine (GKE) 應用程式。您將配置應用程式以存取提供的 Cloud SQL 實例。

提供的應用程式是一個名為 gMemegen 的簡單 Flask-SQLAlchemy 網路應用程式。它透過提供一組照片和擷取標題及註腳文字來建立 meme，將其儲存在資料庫中並渲染至本機資料夾。它在單一 pod 中執行，包含兩個容器：一個用於應用程式，一個用於 Cloud SQL Auth Proxy 以 side-car 模式部署。

負載均衡器將透過 side-car 將請求從應用程式路由至資料庫。此負載均衡器將透過外部 Ingress IP 位址公開，您將使用該位址在瀏覽器中存取應用程式。

#### 建立 Kubernetes 集群

在此步驟中，您將建立一個最小的 Kubernetes 集群。集群部署需要幾分鐘。

1. 在 Cloud Shell 中建立最小的 Kubernetes 集群，如下所示：

```bash
ZONE=ZONE
gcloud container clusters create postgres-cluster \
--zone=$ZONE --num-nodes=2
```

#### 建立 Kubernetes 機密以存取資料庫

在此步驟中，您將建立一對 Kubernetes 機密，其中包含連接 Cloud SQL 實例和資料庫所需的憑證。

1. 在 Cloud Shell 中執行以下指令建立機密：

```bash
kubectl create secret generic cloudsql-instance-credentials \
--from-file=credentials.json=$CLOUDSQL_SERVICE_ACCOUNT.json

kubectl create secret generic cloudsql-db-credentials \
--from-literal=username=postgres \
--from-literal=password=supersecret! \
--from-literal=dbname=gmemegen_db
```

#### 下載並建置 GKE 應用程式容器

在將 gMemegen 應用程式部署至 GKE 集群之前，您需要建置容器並推送至儲存庫。

1. 在 Cloud Shell 中下載提供的應用程式程式碼並變更至應用程式目錄：

```bash
gsutil -m cp -r gs://spls/gsp919/gmemegen .
cd gmemegen
```

1. 建立環境變數用於區域、專案 ID 和 Artifact Registry 儲存庫：

```bash
export REGION="REGION"
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export REPO=gmemegen
```

1. 配置 Docker 以進行 Artifact Registry 驗證：

```bash
gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

- 系統提示確認時輸入 `Y`。

1. 建立 Artifact Registry 儲存庫：

```bash
gcloud artifacts repositories create $REPO \
    --repository-format=docker --location=$REGION
```

1. 建置本機 Docker 映像：

```bash
docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/gmemegen/gmemegen-app:v1 .
```

就本實驗而言，您可以忽略關於以 'root' 使用者身分執行 'pip' 的警告，儘管一般而言，尤其在本地機器上工作時，最佳實務是以虛擬環境使用。

1. 將映像推送至 Artifact Registry：

```bash
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/gmemegen/gmemegen-app:v1
```

#### 配置並部署 GKE 應用程式

您必須修改 gMemegen 應用程式的 Kubernetes 部署清單，以指向正確的容器，並配置 Cloud SQL Auth Proxy side-car 與 Cloud SQL PostgreSQL 實例的連接字串。

說明說明如何使用 Cloud Shell Editor 編輯檔案，但如果您偏好，也可以使用 Cloud Shell 中的 `vi` 或 `nano` 進行這些步驟。

1. 在 Cloud Shell 功能表列中，按一下 **Open Editor** 開啟 Cloud Shell Editor。
2. 在左側的 **Explorer** 面板中，展開 `gmemegen` 資料夾，然後選取 `gmemegen_deployment.yaml` 進行編輯。
3. 在**第 33 行**的 `image` 屬性中，將 `${REGION}` 替換為 `[REGION]`，並將 `${PROJECT_ID}` 替換為 `[PROJECT_ID]`。該行現在應為：

```yaml
image: "REGION"-docker.pkg.dev/"Project ID"/gmemegen/gmemegen-app:v1
```

1. 在**第 60 行**，將 `${REGION}` 替換為 `[REGION]`，並將 `${PROJECT_ID}` 替換為 `[PROJECT_ID]`。該行現在應為：
- `instances="Project ID":"REGION":postgres-gmemegen=tcp:5432`

若要確認連接名稱是否正確，請在 Google Cloud Console 中瀏覽至 **Databases** > **SQL**，選取 `postgres-gmemegen` 實例，並與 **Overview** 窗格中的 **Connection name** 比較。有效的連接名稱格式為 `PROJECT_ID:REGION:CLOUD_SQL_INSTANCE_ID`。

1. 從 Cloud Shell Editor 功能表選取 **File** > **Save** 儲存變更。
2. 在 Google Cloud Console 中按一下 **Open Terminal** 重新開啟 Cloud Shell。您可能需要拖曳功能表列中央的把手向下調整終端機視窗大小，以在 Cloud Console 視窗上方看到您的視窗。
3. 在 Cloud Shell 中執行以下指令部署應用程式：

```bash
kubectl create -f gmemegen_deployment.yaml
```

1. 在 Cloud Shell 中執行以下指令檢查部署是否成功：

```bash
kubectl get pods
```

可能需要一分鐘或更長時間讓 pod 啟動，因為它們需要從儲存庫提取映像。重複上述指令，直到您看到具有 2 個容器的 pod，狀態為 `Running`。

### 任務 3：將 GKE 應用程式連接至外部負載均衡器

在本任務中，您將建立負載均衡器以將請求從 GKE pod 中的容器路由至應用程式，並使用瀏覽器中的外部 IP 位址存取應用程式。

#### 建立負載均衡器以使您的 GKE 應用程式可從網頁存取

在此步驟中，您將建立 Kubernetes 負載均衡器服務，為應用程式提供公開 IP 位址。

1. 在 Cloud Shell 中執行以下指令為應用程式建立負載均衡器：

```bash
kubectl expose deployment gmemegen \
    --type "LoadBalancer" \
    --port 80 --target-port 8080
```

#### 測試應用程式以產生一些資料

在此步驟中，您將在網路瀏覽器中存取 gMemegen 應用程式。

應用程式有一個非常簡單的介面。它啟動至應用程式主頁面，顯示 6 個可用於製作 meme 的候選圖片。您可以按一下圖片來選取圖片。

**Create Meme** 頁面隨即顯示，您可以在其中輸入兩個文字項目，分別顯示在圖片上方和下方。按一下 **Submit** 會渲染 meme 並顯示它。介面不提供從完成 meme 頁面導覽。您將不得不使用瀏覽器的返回按鈕返回主頁面。

還有其他兩個頁面，**Recent** 和 **Random**，分別顯示最近生成的 meme 和隨機 meme。產生 meme 和導覽 UI 將產生資料庫活動，您可以在下面的記錄中查看。

等到負載均衡器公開外部 IP 位址，您可以如下取得：

1. 在 Cloud Shell 中從以下指令的輸出複製 `LoadBalancer Ingress` 的外部 IP 位址屬性：

```bash
kubectl describe service gmemegen
```

**輸出：**

```
Name:                     gmemegen
Namespace:                default
Labels:                   app=gmemegen
Annotations:              <none>
Selector:                 app=gmemegen
Type:                     LoadBalancer
IP Families:              <none>
IP:                       10.3.240.201
IPs:                      10.3.240.201
LoadBalancer Ingress:     34.67.122.203
Port:                     <unset>  80/TCP
TargetPort:               8080/TCP
NodePort:                 <unset>  31837/TCP
Endpoints:                10.0.0.7:8080
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  EnsuringLoadBalancer  85s   service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   36s   service-controller  Ensured load balancer
</unset></unset></none></none>
```

`LoadBalancer Ingress` 屬性可能需要一分鐘或更長時間才會包含在輸出中（請參閱上方），因此在執行下一步之前重複指令直到它出現。

1. 在瀏覽器中導覽至負載均衡器的 Ingress IP 位址。

您可以在 Cloud Shell 中使用以下指令為負載均衡器的外部 IP 位址建立可點擊連結：

```bash
export LOAD_BALANCER_IP=$(kubectl get svc gmemegen \
-o=jsonpath='{.status.loadBalancer.ingress[0].ip}' -n default)
echo gMemegen Load Balancer Ingress IP: http://$LOAD_BALANCER_IP
```

1. 在 Cloud Shell 中按一下連結，您將在新分頁中的瀏覽器中看到 gMemegen 應用程式執行。
2. 如下建立 meme：
    - 在 **Home** 頁面上，按一下其中一個顯示的圖片。
    - 在 **Top** 和 **Bottom** 文字方塊中輸入文字。
    - 按一下 **Submit** 按鈕。

您的新 meme 隨即顯示。

1. 若要建立更多 meme，請使用瀏覽器的返回按鈕導覽至主頁面。
2. 若要查看現有 meme，請在應用程式功能表中按一下 **Recent** 或 **Random**。（注意 **Random** 會在新瀏覽器分頁中開啟）
3. 在 Cloud Shell 中執行以下指令查看應用程式的活動：

```bash
POD_NAME=$(kubectl get pods --output=json | jq -r ".items[0].metadata.name")
kubectl logs $POD_NAME gmemegen | grep "INFO"
```

這會查詢 `gmemegen` 容器的記錄，並顯示 pod 上應用程式的活動，包括記錄至 stderr 的 SQL 陳述式，因為它們已執行。

### 任務 4：驗證應用程式對資料庫的完整讀寫能力

在本任務中，您將驗證應用程式能夠寫入資料庫並從中讀取。

#### 連接至資料庫並查詢應用程式表格

在此步驟中，您將在 Cloud Shell 中執行 PL/SQL 以連接 Cloud SQL 實例。

1. 在 Google Cloud Console 中，導覽至 **Databases** > **SQL** 並選取 `postgres-gmemegen` 實例。
2. 在 **Overview** 窗格中，向下捲動至 **Connect to this instance** 並按一下 **Open Cloud Shell** 按鈕。
3. 在 Cloud Shell 中執行自動填入的指令。
4. 系統提示時輸入密碼：`supersecret!`
5. 在 `postgres=>` 提示中輸入以下指令選取 gmemegen_db 資料庫：

```bash
\c gmemegen_db
```

1. 系統提示時輸入密碼：`supersecret!`
2. 在 `gmemegen_db=>` 提示中輸入：

```sql
select * from meme;
```

這將顯示應用程式中每個 meme 的資料列。

## 驗證

成功完成實驗的驗證步驟：

1. **任務 1**：確認服務帳戶已建立並具有正確的 IAM 角色
2. **任務 2**：確認 GKE 集群已建立且 pod 正在執行
3. **任務 3**：確認應用程式可透過外部 IP 存取且能夠產生 meme
4. **任務 4**：確認能夠從資料庫查詢 meme 記錄

## 故障排除

常見問題和解決方案：

- **Pod 無法啟動**：檢查容器映像是否正確推送至 Artifact Registry
- **無法連接資料庫**：驗證 Cloud SQL 實例正在執行且連接名稱正確
- **應用程式無法載入**：檢查負載均衡器是否已分配外部 IP
- **權限錯誤**：確認服務帳戶具有必要的 Cloud SQL 權限

## 清理

為避免產生費用，請執行以下清理步驟：

1. 刪除 GKE 集群：
```bash
gcloud container clusters delete postgres-cluster --zone=$ZONE
```

2. 刪除 Artifact Registry 儲存庫：
```bash
gcloud artifacts repositories delete $REPO --location=$REGION
```

3. 刪除服務帳戶：
```bash
gcloud iam service-accounts delete $CLOUDSQL_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
```

## 額外資源

- [Cloud SQL 文件](https://cloud.google.com/sql/docs)
- [GKE 文件](https://cloud.google.com/kubernetes-engine/docs)
- [Artifact Registry 文件](https://cloud.google.com/artifact-registry/docs)
- [Kubernetes 機密](https://kubernetes.io/docs/concepts/configuration/secret/)

## 相關實驗

- GSP918: Create and Manage Cloud SQL for PostgreSQL Instances
- GSP007: Set Up Network Load Balancers
- GSP155: Set Up Application Load Balancers

## 個人筆記

- 本實驗展示了如何將容器化應用程式連接至 Cloud SQL 資料庫
- Cloud SQL Auth Proxy 提供了安全的資料庫連接方式
- Kubernetes 機密用於管理敏感憑證
- 負載均衡器提供了外部存取能力
