# GSP920 - Securing a Cloud SQL for PostgreSQL Instance

## 實驗概述

客戶端管理的加密金鑰 (CMEK) 讓您能夠使用自己的密碼編譯金鑰來加密 Cloud SQL 中的靜態資料。在添加客戶端管理的加密金鑰後，每當進行 API 呼叫時，Cloud SQL 都會使用您的金鑰來存取資料。

此實驗將指導您逐步設定 Cloud SQL for PostgreSQL 實例的安全性。您將首先使用 CMEK 部署新的 Cloud SQL 實例。一旦建立 Cloud SQL for PostgreSQL 實例，您將設定 pgAudit 以選擇性記錄和追蹤針對該實例執行的 SQL 操作，最後設定並測試 Cloud SQL IAM 資料庫認證。

## 您將學會

- 為 Cloud SQL for PostgreSQL 設定 CMEK
- 在 Cloud SQL for PostgreSQL 實例上啟用和設定 pgAudit
- 設定 Cloud SQL for PostgreSQL IAM 資料庫認證

## 目標受眾

此實作實驗的內容最適合 PostgreSQL 資料庫管理員使用。此實驗旨在讓專業人士透過實際操作來體驗設定 Google Cloud 資源以支援 PostgreSQL 的過程。

## 估計時間

約 90 分鐘

## 實驗步驟

### 任務 1：使用 CMEK 建立 Cloud SQL for PostgreSQL 實例

在此任務中，您將使用 CMEK 啟用的方式建立 Cloud SQL for PostgreSQL 實例。請務必妥善保管金鑰，因為如果沒有這些金鑰，您將無法管理您的資料庫。

#### 建立 Cloud SQL 的每產品、每專案服務帳戶

您可以使用 `gcloud beta services identity create` 命令來建立 Cloud SQL CMEK 所需的服務帳戶。

1. 在 Cloud Shell 中，執行以下命令來建立服務帳戶：

```bash
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
gcloud beta services identity create \
    --service=sqladmin.googleapis.com \
    --project=$PROJECT_ID
```

如果出現授權提示，請按一下 **Authorize** 按鈕。

這將建立您將在稍後步驟中繫結到 CMEK 的服務帳戶。

#### 建立 Cloud Key Management Service 金鑰環和金鑰

在此區段中，您將建立 Cloud KMS 金鑰環和金鑰以與 CMEK 搭配使用。

1. 在 Cloud Shell 中，執行以下命令來建立 Cloud KMS 金鑰環：

```bash
export KMS_KEYRING_ID=cloud-sql-keyring
export ZONE=$(gcloud compute instances list --filter="NAME=bastion-vm" --format=json | jq -r .[].zone | awk -F "/zones/" '{print $NF}')
export REGION=${ZONE::-2}
gcloud kms keyrings create $KMS_KEYRING_ID \
    --location=$REGION
```

1. 在 Cloud Shell 中，執行以下命令來建立 Cloud KMS 金鑰：

```bash
export KMS_KEY_ID=cloud-sql-key
gcloud kms keys create $KMS_KEY_ID \
 --location=$REGION \
 --keyring=$KMS_KEYRING_ID \
 --purpose=encryption
```

1. 在 Cloud Shell 中，執行以下命令將金鑰繫結到服務帳戶：

```bash
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format 'value(projectNumber)')
gcloud kms keys add-iam-policy-binding $KMS_KEY_ID \
    --location=$REGION \
    --keyring=$KMS_KEYRING_ID \
    --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloud-sql.iam.gserviceaccount.com \
    --role=roles/cloudkms.cryptoKeyEncrypterDecrypter
```

服務帳戶名稱與 `gcloud beta services identity create` 命令傳回的名稱相同。

#### 使用 CMEK 建立 Cloud SQL 實例

在此區段中，您將使用 CMEK 啟用的方式建立 Cloud SQL for PostgreSQL 實例。請注意，無法對現有實例進行修補以啟用 CMEK，因此如果您計劃使用 CMEK 來加密資料，請記住這一點。

為了從外部開發或應用程式環境存取您的 Cloud SQL 實例，您可以將 Cloud SQL 實例設定為具有公共 IP 位址，並控制存取權限，方法是將那些環境的 IP 位址加入白名單。這會將對公共介面的存取權限限制為您指定的位址範圍。

您將實驗室中的 Compute Engine VM 實例視為開發環境，因此需要將該實例的外部 IP 位址加入白名單。您還將 Cloud Shell 的外部 IP 位址加入白名單，以便在實驗後續步驟中更容易完成任務。

1. 在 Cloud Shell 中，執行以下命令來尋找 `bastion-vm` VM 實例的外部 IP 位址：

```bash
export AUTHORIZED_IP=$(gcloud compute instances describe bastion-vm \
    --zone=$ZONE \
    --format 'value(networkInterfaces[0].accessConfigs.natIP)')
echo Authorized IP: $AUTHORIZED_IP
```

1. 在 Cloud Shell 中，執行以下命令來尋找 Cloud Shell 的外部 IP 位址：

```bash
export CLOUD_SHELL_IP=$(curl ifconfig.me)
echo Cloud Shell IP: $CLOUD_SHELL_IP
```

1. 在 Cloud Shell 中，執行以下命令來建立您的 Cloud SQL for PostgreSQL 實例：

```bash
export KEY_NAME=$(gcloud kms keys describe $KMS_KEY_ID \
    --keyring=$KMS_KEYRING_ID --location=$REGION \
    --format 'value(name)')

export CLOUDSQL_INSTANCE=postgres-orders
gcloud sql instances create $CLOUDSQL_INSTANCE \
    --project=$PROJECT_ID \
    --authorized-networks=${AUTHORIZED_IP}/32,$CLOUD_SHELL_IP/32 \
    --disk-encryption-key=$KEY_NAME \
    --database-version=POSTGRES_13 \
    --cpu=1 \
    --memory=3840MB \
    --region=$REGION \
    --root-password=supersecret!
```

1. 如果出現提示，請輸入 'y' 以確認並繼續。

### 任務 2：在 Cloud SQL for PostgreSQL 資料庫上啟用和設定 pgAudit

在此任務中，您將啟用資料庫擴充功能 pgAudit，這能讓您對所有類型的資料庫活動進行精細控制的記錄。

1. 在 Cloud Shell 中，執行以下命令將 pgAudit 資料庫旗標新增至您的 Cloud SQL 實例：

```bash
gcloud sql instances patch $CLOUDSQL_INSTANCE \
    --database-flags cloudsql.enable_pgaudit=on,pgaudit.log=all
```

1. 如果出現提示，請輸入 'y' 以確認並繼續。

**注意：** 請等到修補命令完成後再繼續。當您看到訊息「Patching Cloud SQL instance...done」時，您就可以繼續下一步。

1. 在 Cloud Console 中，按一下 **Navigation menu** ()，然後按一下 **SQL**。
2. 按一下名為 `postgres-orders` 的 Cloud SQL 實例。
3. 在 Cloud SQL **Overview** 面板中，按一下頂端功能表的 **Restart** 以在修補後重新啟動實例。

如果再次出現提示，請在快顯對話方塊中再次按一下 **Restart**。

**注意：** 重新啟動您的 Cloud SQL for PostgreSQL 實例可能需要幾分鐘的時間。當您看到實例已成功重新啟動的訊息 (`Restarted postgres-orders`) 時，您就可以繼續下一步。

1. 在 Cloud Console 中，在 **Connect to this instance** 區段中，按一下 **Open Cloud Shell**。

**注意：** 如果您收到錯誤訊息且無法連線，請等候幾分鐘，為重新啟動後的實例提供一些時間來重新變得可存取，然後重複步驟 6。

將會在 Cloud Shell 中自動填入連線至實例的命令。

1. 按原樣執行該命令，並在出現提示時輸入密碼 `supersecret!`。

這將會啟動 **psql** 工作階段。

1. 在 **psql** 中，執行以下命令來建立 `orders` 資料庫，並啟用 pgAudit 擴充功能來記錄所有讀取和寫入：

```sql
CREATE DATABASE orders;
\c orders;
```

1. 再次輸入密碼 `supersecret!`。
2. 在 **psql** 中，執行以下命令來建立和設定資料庫擴充功能：

```sql
CREATE EXTENSION pgaudit;
ALTER DATABASE orders SET pgaudit.log = 'read,write';
```

#### 啟用稽核記錄

在此區段中，您將在 Cloud Console 中啟用稽核記錄。

1. 在 Cloud Console 中，按一下 **Navigation menu** ()，然後按一下 **IAM & Admin** > **Audit Logs**。

**注意：** 如果您在頁面頂端看到訊息，指出「you don't have permission to view inherited audit logs configuration data for one or more parent resources」，您可以安全地忽略該訊息並繼續下一步。

1. 在 **Filter** 方塊下的 **Data access audit logs configuration** 中輸入 `Cloud SQL`，然後在下拉式清單中選取項目。
2. 勾選 **Cloud SQL** 左側的核取方塊，然後在右側的 **Info Panel** 中啟用以下核取方塊：
   - **Admin read**
   - **Data read**
   - **Data write**
3. 按一下 **Info Panel** 中的 **Save**。

#### 填入 Cloud SQL for PostgreSQL 資料庫

在此區段中，您將為您填入 `orders` 資料庫。

1. 按一下 Cloud Shell 標題列上的 **+** 圖示，以在新索引標籤中開啟 Cloud Shell。
2. 在新索引標籤中，執行以下命令來下載資料和資料庫填入指令碼：

```bash
export SOURCE_BUCKET=gs://spls/gsp920
gsutil -m cp ${SOURCE_BUCKET}/create_orders_db.sql .
gsutil -m cp ${SOURCE_BUCKET}/DDL/distribution_centers_data.csv .
gsutil -m cp ${SOURCE_BUCKET}/DDL/inventory_items_data.csv .
gsutil -m cp ${SOURCE_BUCKET}/DDL/order_items_data.csv .
gsutil -m cp ${SOURCE_BUCKET}/DDL/products_data.csv .
gsutil -m cp ${SOURCE_BUCKET}/DDL/users_data.csv .
```

1. 在新索引標籤中繼續執行，並執行以下命令來建立和填入資料庫：

```bash
export CLOUDSQL_INSTANCE=postgres-orders
export POSTGRESQL_IP=$(gcloud sql instances describe $CLOUDSQL_INSTANCE --format="value(ipAddresses[0].ipAddress)")
export PGPASSWORD=supersecret!
psql "sslmode=disable user=postgres hostaddr=${POSTGRESQL_IP}" \
    -c "\i create_orders_db.sql"
```

1. 結束新索引標籤中的終端機工作階段：

```bash
exit
```

1. 返回原始 Cloud Shell 索引標籤中的 **psql** 工作階段，並執行以下命令來進一步記錄特定關聯 (例如 `order_items` 資料表) 的所有 `SELECT` 操作：

```sql
CREATE ROLE auditor WITH NOLOGIN;
ALTER DATABASE orders SET pgaudit.role = 'auditor';
GRANT SELECT ON order_items TO auditor;
```

1. 執行以下第一個 `SELECT` 查詢：

```sql
SELECT
    users.id  AS users_id,
    users.first_name  AS users_first_name,
    users.last_name  AS users_last_name,
    COUNT(DISTINCT order_items.order_id ) AS order_items_order_count,
    COALESCE(SUM(order_items.sale_price ), 0) AS order_items_total_revenue
FROM order_items
LEFT JOIN users ON order_items.user_id = users.id
GROUP BY 1, 2, 3
ORDER BY 4 DESC
LIMIT 500;
```

1. 結果將會有 500 行長，因此請輸入 `q` 以關閉結果並返回 `orders=>` 提示。
2. 對程式碼區塊中的其他兩個查詢索引標籤重複步驟 5-6。
3. 執行以下命令來結束 **psql**：

```sql
\q
```

#### 查看 pgAudit 日誌

在此步驟中，您將查看 pgAudit 日誌中資料庫更新和查詢的記錄。

1. 在 Cloud Console 中，按一下 **Navigation menu** ()，然後在 **Observability** 下按一下 **Logging** 以開啟 **Logs Explorer** 頁面。
2. 在 **Logs Explorer** 的 **Query** 索引標籤中貼上以下內容，然後按一下 **Run query**：

```
resource.type="cloudsql_database"
logName="projects/(GCP Project)/logs/cloudaudit.googleapis.com%2Fdata_access"
protoPayload.request.@type="type.googleapis.com/google.cloud.sql.audit.v1.PgAuditEntry"
```

1. 在顯示的長條圖中，您可以看到與您稍早執行的 DDL 插入和 `SELECT` 查詢相關聯的稽核活動。

1. 按一下長條圖上最後一個長條 (對應於您執行的 `SELECT` 查詢)。

在長條圖下方的 **Query results** 面板中，會列出日誌項目。

1. 展開日誌項目，並在 `protoPayload.request` 下，您將看到 `SELECT` 查詢。

### 任務 3：設定 Cloud SQL IAM 資料庫認證

在此任務中，您將設定 Cloud SQL IAM 資料庫認證。迄今為止，您執行過的所有資料庫存取和更新任務都使用了內建的 PostgreSQL 使用者帳戶。您也可以使用 Cloud IAM 帳戶來建立 Cloud SQL for PostgreSQL 使用者。資料庫使用者可以使用 Cloud IAM 而非內建資料庫帳戶進行認證，並且可以在資料庫層級為這些使用者授予精細的權限。

在此任務中，您將實驗室使用者帳戶設定為 Cloud SQL IAM 使用者，使用 **postgres** 管理員帳戶授予該使用者存取 `orders.order_items` 資料庫資料表的權限，然後使用 **psql** 命令列公用程式從命令列測試對 `orders.order_items` 資料庫資料表的存取權限。

在此任務中使用的認證程序詳載於 [Cloud SQL for PostgreSQL 的 IAM 認證文件](https://cloud.google.com/sql/docs/postgres/iam-logins#logging-in-as-a-user)。

#### 在設定 Cloud SQL IAM 認證之前，使用 Cloud IAM 使用者測試資料庫存取權限

在設定 Cloud SQL IAM 認證之前，您將嘗試使用 Cloud IAM 使用者存取資料庫，以建立 Cloud IAM 使用者無法初始存取資料的事實。您將在下一步中處理此問題。

- 在 Cloud Shell 中，使用實驗室學生帳戶作為使用者名稱來測試對 `orders` 資料庫的存取權限：

```bash
export USERNAME=$(gcloud config list --format="value(core.account)")
export CLOUDSQL_INSTANCE=postgres-orders
export POSTGRESQL_IP=$(gcloud sql instances describe $CLOUDSQL_INSTANCE --format="value(ipAddresses[0].ipAddress)")
export PGPASSWORD=$(gcloud auth print-access-token)
psql --host=$POSTGRESQL_IP $USERNAME --dbname=orders
```

此連線嘗試將失敗，您會看到類似以下的認證失敗訊息，因為 Cloud SQL IAM 使用者尚未建立：

```
psql --host=$POSTGRESQL_IP $USERNAME --dbname=orders
psql: error: connection to server at "35.226.251.234", port 5432 failed: FATAL:  password authentication failed for user "student-01-22fa974575e4@qwiklabs.net"
connection to server at "35.226.251.234", port 5432 failed: FATAL:  password authentication failed for user "student-01-22fa974575e4@qwiklabs.net"
```

Cloud SQL IAM 認證使用 OAuth 2.0 存取權杖作為 Cloud IAM 使用者密碼，這些權杖是短期的且僅有效一小時，因此您需要在每次需要認證時重新產生權杖。存取權杖應始終使用 **PGPASSWORD** 環境變數傳遞至 **psql** 命令，因為 **psql** 密碼緩衝區太小而無法容納 OAuth 2.0 權杖字串。

#### 建立 Cloud SQL IAM 使用者

在此區段中，您將建立 Cloud SQL IAM 使用者，並確認 Cloud SQL IAM 使用者認證已啟用。

1. 在 Cloud Console 中，按一下 **Navigation menu** ()，然後按一下 **SQL**。
2. 按一下名為 `postgres-orders` 的 Cloud SQL 實例。

在右側的 **Configuration** 面板中，注意 **Database flags and parameters** 清單僅包含 **pgAudit.log** 和 **cloudsql.enable_pgaudit**。

1. 在 **SQL menu** (左側面板) 中的 **Primary instance** 下，按一下 **Users** 以開啟 **Users** 面板。
2. 按一下 **Add user account**。
3. 選取 **Cloud IAM**。
4. 在 **Principal** 方塊中輸入實驗室學生名稱：`[USERNAME]`
5. 按一下 **Add**。

等待新使用者成功新增。

在實例的主要概覽頁面上，在右側的 **Configuration** 面板中，注意 **cloudsql.iam_authentication** 已新增至 **Database flags and parameters** 清單。

#### 授予 Cloud IAM 使用者存取 Cloud SQL 資料庫資料表的權限

您現在將使用內建的 `postgres` 管理員帳戶連線至 `postgres-orders` 實例，並授予 Cloud IAM 使用者存取 `orders.order_items` 資料表的權限。

1. 在實例的主要概覽頁面上，在 **Connect to this instance** 區段中，按一下 **Open Cloud Shell**。

將會在 Cloud Shell 中自動填入連線至實例的命令。

1. 按原樣執行該命令，並在出現提示時輸入密碼 `supersecret!`。
2. 輸入以下 SQL 命令來切換至 `orders` 資料庫：

```sql
\c orders
```

再次輸入密碼 `supersecret!` 時出現提示。

1. 輸入以下 SQL 命令來授予實驗室使用者在 `order_items` 資料表上的所有權限。Cloud IAM 使用者名稱已為您插入此查詢中。

```sql
GRANT ALL PRIVILEGES ON TABLE order_items TO "[IAM Username]";
\q
```

#### 在設定 Cloud SQL IAM 認證之後，使用 Cloud IAM 使用者測試資料庫存取權限

設定 Cloud SQL IAM 認證之後，您將重複嘗試使用 Cloud IAM 使用者存取資料庫，以建立 Cloud IAM 使用者現在可以存取資料的事實。

您現在可以再次測試使用 Cloud IAM 使用者而非內建 `postgres` 使用者來存取資料庫：

1. 在 Cloud Shell 中，執行以下命令來使用 Cloud IAM 資料庫使用者連線至資料庫：

```bash
export PGPASSWORD=$(gcloud auth print-access-token)
psql --host=$POSTGRESQL_IP $USERNAME --dbname=orders
```

此連線將成功，您現在將使用 Cloud IAM 使用者認證連線至實例。

1. 執行以下查詢來測試您的存取權限：

```sql
SELECT COUNT(*) FROM order_items;
```

這現在將傳回成功的結果：

```
orders=> SELECT COUNT(*) FROM order_items;
 count
--------
 198553
(1 row)
```

1. 執行以下查詢來確認您無法存取其他資料表：

```sql
SELECT COUNT(*) FROM users;
```

此查詢不會傳回成功的結果：

```
orders=> SELECT COUNT(*) FROM users;
ERROR:  permission denied for table users
```

## 驗證

成功完成此實驗後，您應該能夠：

1. 使用 CMEK 建立安全的 Cloud SQL for PostgreSQL 實例
2. 設定 pgAudit 以記錄資料庫活動
3. 在 Cloud Logging 中查看稽核日誌
4. 使用 Cloud IAM 帳戶設定資料庫使用者認證
5. 授予和測試資料庫層級權限

## 故障排除

### 常見問題

- **CMEK 設定失敗**：確保服務帳戶已正確建立並具有適當的 KMS 權限
- **pgAudit 未記錄**：確認資料庫旗標已正確設定且實例已重新啟動
- **IAM 認證失敗**：確保 Cloud IAM 使用者已建立且權杖未過期 (有效期 1 小時)
- **權限遭拒**：檢查是否已正確授予資料庫層級權限

### 檢查實例狀態

```bash
gcloud sql instances describe $CLOUDSQL_INSTANCE --format="value(state)"
```

### 重新啟動實例 (如果需要)

```bash
gcloud sql instances restart $CLOUDSQL_INSTANCE
```

## 清理

為了避免產生額外費用，請在完成實驗後刪除建立的資源：

1. 刪除 Cloud SQL 實例：

```bash
gcloud sql instances delete $CLOUDSQL_INSTANCE
```

2. 刪除 KMS 金鑰和金鑰環：

```bash
gcloud kms keys versions destroy 1 --key=$KMS_KEY_ID --keyring=$KMS_KEYRING_ID --location=$REGION
gcloud kms keys delete $KMS_KEY_ID --keyring=$KMS_KEYRING_ID --location=$REGION
gcloud kms keyrings delete $KMS_KEYRING_ID --location=$REGION
```

3. 移除 IAM 政策繫結 (如果需要)。

## 額外資源

- [Cloud SQL for PostgreSQL 文件](https://cloud.google.com/sql/docs/postgres)
- [客戶端管理的加密金鑰 (CMEK)](https://cloud.google.com/sql/docs/postgres/cmek)
- [pgAudit 擴充功能](https://cloud.google.com/sql/docs/postgres/pg-audit)
- [Cloud SQL IAM 資料庫認證](https://cloud.google.com/sql/docs/postgres/iam-logins)
- [Cloud KMS 文件](https://cloud.google.com/kms/docs)
- [Cloud Audit Logs](https://cloud.google.com/logging/docs/audit)

## 相關實驗

- GSP918: Create and Manage Cloud SQL for PostgreSQL Instances
- GSP919: Connect an App to a Cloud SQL for PostgreSQL Instance

## 筆記

- CMEK 提供額外的安全層級，但需要仔細管理金鑰
- pgAudit 可以記錄所有資料庫活動，對於稽核很重要
- IAM 認證允許使用現有的 Google 帳戶進行資料庫存取
- 記得定期輪換 KMS 金鑰以維持安全性
- 監控 Cloud Audit Logs 以追蹤資料庫活動
