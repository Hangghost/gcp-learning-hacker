# GSP918 - 創建和管理 Cloud SQL for PostgreSQL 實例

## Lab 概述
此實驗將指導您學習如何使用 Google Cloud Database Migration Service 將獨立 PostgreSQL 數據庫遷移到 Cloud SQL for PostgreSQL。您將設置源數據庫、創建遷移作業、測試連續遷移，並最終將 Cloud SQL 實例提升為獨立實例。

## 先決條件
- Google Cloud Platform 帳戶
- 基本 GCP 控制台操作知識
- PostgreSQL 數據庫基礎知識
- 基本的 Linux 命令行操作

## 學習目標
完成此實驗後，您將能夠：
- 為數據庫遷移準備獨立 PostgreSQL 實例
- 配置 pglogical 擴展和必要的權限
- 創建 Database Migration Service 連接配置文件
- 設置連續遷移作業從源數據庫到 Cloud SQL
- 測試數據遷移和連續同步
- 將 Cloud SQL 實例提升為獨立讀寫實例

## 所需 API 和服務
- Database Migration API
- Service Networking API
- Compute Engine API
- Cloud SQL API

## 估計完成時間
90-120 分鐘

## 實驗步驟

### 設置和要求

#### 驗證 Database Migration API 已啟用
1. 在 Google Cloud 控制台中，在頂部搜索欄輸入 **Database Migration API**。點擊 **Database Migration API** 的結果。

此頁面將顯示狀態信息或提供啟用 API 的選項。

1. 如果需要，**啟用** API。

#### 驗證 Service Networking API 已啟用
Service Networking API 對於配置 Cloud SQL 以支持 VPC Peering 和通過私有 IP 地址連接是必需的。

1. 在 Cloud 控制台中，在頂部搜索欄輸入 **Service Networking API**。點擊 **Service Networking API** 的結果。

此頁面將顯示狀態信息或提供啟用 API 的選項。

1. 如果需要，啟用 API。

### 任務 1. 為遷移準備源數據庫

在此任務中，您將為源數據庫添加支持功能，這些是 Database Migration Service 執行遷移所需的：
- 安裝和配置 pglogical 數據庫擴展
- 配置獨立 PostgreSQL 數據庫以允許從 Cloud Shell 和 Cloud SQL 訪問
- 為獨立服務器上的 `postgres`、`orders` 和 `gmemegen_db` 數據庫添加 `pglogical` 數據庫擴展
- 創建具有複製權限的 `migration_admin` 用戶，並為該用戶授予必要的權限

#### 升級數據庫以安裝 pglogical 擴展

在此步驟中，您將下載並添加到 `postgresql-vm` VM 實例上的 orders 和 postgres 數據庫的 `pglogical` 數據庫擴展。

1. 在 Google Cloud 控制台中，在 **Navigation menu** () 上，點擊 **Compute Engine** > **VM instances**。

2. 在 `postgresql-vm` 條目下，在 `Connect` 下點擊 **SSH**。
3. 如果提示，點擊 **Authorize**。
4. 在新瀏覽器窗口的終端中，安裝 `pglogical` 數據庫擴展：

```bash
sudo apt install postgresql-13-pglogical
```

**注意：** `pglogical` 是實現為 PostgreSQL 擴展的邏輯複製系統。完全集成，不需要觸發器或外部程序。這是使用發布/訂閱模型進行選擇性複製的高效數據複製方法。

1. 下載並應用 PostgreSQL 配置文件的附加內容（啟用 pglogical 擴展）並重新啟動 postgresql 服務：

```bash
sudo su - postgres -c "gsutil cp gs://spls/gsp918/pg_hba_append.conf ."
sudo su - postgres -c "gsutil cp gs://spls/gsp918/postgresql_append.conf ."
sudo su - postgres -c "cat pg_hba_append.conf >> /etc/postgresql/13/main/pg_hba.conf"
sudo su - postgres -c "cat postgresql_append.conf >> /etc/postgresql/13/main/postgresql.conf"

sudo systemctl restart postgresql@13-main
```

在 `pg_hba.conf` 中，這些命令添加了一條規則以允許來自所有主機的訪問：

```conf
#GSP918 - allow access to all hosts
host    all all 0.0.0.0/0   md5
```

在 `postgresql.conf` 中，這些命令為 pglogical 設置了最小配置，將其配置為偵聽所有地址：

```conf
#GSP918 - added configuration for pglogical database extension

wal_level = logical         # minimal, replica, or logical
max_worker_processes = 10   # one per database needed on provider node
                            # one per node needed on subscriber node
max_replication_slots = 10  # one per node needed on provider node
max_wal_senders = 10        # one per node needed on provider node
shared_preload_libraries = 'pglogical'
max_wal_size = 1GB
min_wal_size = 80MB

listen_addresses = '*'         # what IP address(es) to listen on, '*' is all
```

PostgreSQL 配置已更新並重新啟動。

1. 啟動 **psql** 工具：

```bash
sudo su - postgres
psql
```

1. 為 `postgres`、`orders` 和 `gmemegen_db` 數據庫添加 `pglogical` 數據庫擴展。

```sql
\c postgres;
CREATE EXTENSION pglogical;

\c orders;
CREATE EXTENSION pglogical;

\c gmemegen_db;
CREATE EXTENSION pglogical;
```

1. 列出服務器上的 PostgreSQL 數據庫：

```sql
\l
```

您可以看到，除了默認的 postgresql 數據庫之外，還提供了 `orders` 和 `gmemegen_db` 數據庫供此實驗使用。您不會在此實驗中使用 `gmemegen_db` 數據庫，但在遷移中將包含它以供以後的實驗使用。

#### 創建數據庫遷移用戶

在此步驟中，您將創建一個專門的用戶來管理數據庫遷移。

1. 在 **psql** 中，輸入以下命令以創建具有複製角色的用戶：

```sql
CREATE USER migration_admin PASSWORD 'DMS_1s_cool!';
ALTER DATABASE orders OWNER TO migration_admin;
ALTER ROLE migration_admin WITH REPLICATION;
```

#### 為遷移用戶分配權限

在此步驟中，您將為 `migration_admin` 用戶分配必要的權限，以使 Database Migration Service 能夠遷移您的數據庫。

1. 在 **psql** 中，為 `postgres` 數據庫的 `pglogical` 架構和表授予權限。

```sql
\c postgres;

GRANT USAGE ON SCHEMA pglogical TO migration_admin;
GRANT ALL ON SCHEMA pglogical TO migration_admin;

GRANT SELECT ON pglogical.tables TO migration_admin;
GRANT SELECT ON pglogical.depend TO migration_admin;
GRANT SELECT ON pglogical.local_node TO migration_admin;
GRANT SELECT ON pglogical.local_sync_status TO migration_admin;
GRANT SELECT ON pglogical.node TO migration_admin;
GRANT SELECT ON pglogical.node_interface TO migration_admin;
GRANT SELECT ON pglogical.queue TO migration_admin;
GRANT SELECT ON pglogical.replication_set TO migration_admin;
GRANT SELECT ON pglogical.replication_set_seq TO migration_admin;
GRANT SELECT ON pglogical.replication_set_table TO migration_admin;
GRANT SELECT ON pglogical.sequence_state TO migration_admin;
GRANT SELECT ON pglogical.subscription TO migration_admin;
```

1. 在 **psql** 中，為 `orders` 數據庫的 `pglogical` 架構和表授予權限。

```sql
\c orders;

GRANT USAGE ON SCHEMA pglogical TO migration_admin;
GRANT ALL ON SCHEMA pglogical TO migration_admin;

GRANT SELECT ON pglogical.tables TO migration_admin;
GRANT SELECT ON pglogical.depend TO migration_admin;
GRANT SELECT ON pglogical.local_node TO migration_admin;
GRANT SELECT ON pglogical.local_sync_status TO migration_admin;
GRANT SELECT ON pglogical.node TO migration_admin;
GRANT SELECT ON pglogical.node_interface TO migration_admin;
GRANT SELECT ON pglogical.queue TO migration_admin;
GRANT SELECT ON pglogical.replication_set TO migration_admin;
GRANT SELECT ON pglogical.replication_set_seq TO migration_admin;
GRANT SELECT ON pglogical.replication_set_table TO migration_admin;
GRANT SELECT ON pglogical.sequence_state TO migration_admin;
GRANT SELECT ON pglogical.subscription TO migration_admin;
```

1. 在 **psql** 中，為 `orders` 數據庫的 `public` 架構和表授予權限。

```sql
GRANT USAGE ON SCHEMA public TO migration_admin;
GRANT ALL ON SCHEMA public TO migration_admin;

GRANT SELECT ON public.distribution_centers TO migration_admin;
GRANT SELECT ON public.inventory_items TO migration_admin;
GRANT SELECT ON public.order_items TO migration_admin;
GRANT SELECT ON public.products TO migration_admin;
GRANT SELECT ON public.users TO migration_admin;
```

1. 在 **psql** 中，為 `gmemegen_db` 數據庫的 `pglogical` 架構和表授予權限。

```sql
\c gmemegen_db;

GRANT USAGE ON SCHEMA pglogical TO migration_admin;
GRANT ALL ON SCHEMA pglogical TO migration_admin;

GRANT SELECT ON pglogical.tables TO migration_admin;
GRANT SELECT ON pglogical.depend TO migration_admin;
GRANT SELECT ON pglogical.local_node TO migration_admin;
GRANT SELECT ON pglogical.local_sync_status TO migration_admin;
GRANT SELECT ON pglogical.node TO migration_admin;
GRANT SELECT ON pglogical.node_interface TO migration_admin;
GRANT SELECT ON pglogical.queue TO migration_admin;
GRANT SELECT ON pglogical.replication_set TO migration_admin;
GRANT SELECT ON pglogical.replication_set_seq TO migration_admin;
GRANT SELECT ON pglogical.replication_set_table TO migration_admin;
GRANT SELECT ON pglogical.sequence_state TO migration_admin;
GRANT SELECT ON pglogical.subscription TO migration_admin;
```

1. 在 **psql** 中，為 `gmemegen_db` 數據庫的 `public` 架構和表授予權限。

```sql
GRANT USAGE ON SCHEMA public TO migration_admin;
GRANT ALL ON SCHEMA public TO migration_admin;

GRANT SELECT ON public.meme TO migration_admin;
```

源數據庫現在已為遷移做好準備。您授予 `migration_admin` 用戶的權限是 Database Migration Service 遷移 `postgres`、`orders` 和 `gmemegen_db` 數據庫所需的所有權限。

為了讓您能夠稍後在測試遷移時編輯源數據，請將 `orders` 數據庫中表的擁有者更改為 `migration_admin`。

1. 在 **psql** 中，運行以下命令：

```sql
\c orders;
\dt

ALTER TABLE public.distribution_centers OWNER TO migration_admin;
ALTER TABLE public.inventory_items OWNER TO migration_admin;
ALTER TABLE public.order_items OWNER TO migration_admin;
ALTER TABLE public.products OWNER TO migration_admin;
ALTER TABLE public.users OWNER TO migration_admin;
\dt
```

1. 退出 **psql** 和 postgres 用戶會話

```sql
\q
exit
```

### 任務 2. 創建 Database Migration Service 連接配置文件以連接獨立 PostgreSQL 數據庫

在此任務中，您將為 PostgreSQL 源實例創建連接配置文件。

#### 獲取 PostgreSQL 源實例的連接信息

在此步驟中，您將識別源數據庫實例的內部 IP 地址，您將遷移該實例到 Cloud SQL。

1. 在 Google Cloud Console 中，在 **Navigation menu** () 上，點擊 **Compute Engine** > **VM instances**。

2. 找到名為 **postgresql-vm** 的實例。
3. 複製 **Internal IP** 的值（例如，10.128.0.2）。

#### 創建 PostgreSQL 源實例的新連接配置文件

連接配置文件存儲源數據庫實例（例如，獨立 PostgreSQL）的相關信息，並由 Database Migration Service 用於將數據從源遷移到您的 Cloud SQL 數據庫實例。創建連接配置文件後，可以跨遷移作業重用。

在此步驟中，您將為 PostgreSQL 源實例創建新的連接配置文件。

1. 在 Google Cloud Console 中，在 **Navigation menu** () 上，點擊 **VIEW ALL PRODUCTS** 在 **Databases** 部分點擊 **Database Migration** > **Connection profiles**。

2. 點擊 **+ Create Profile**。
3. 對於 **Profile Role**，選擇 **Source**。
4. 對於 **Database engine**，選擇 **PostgreSQL**。
5. 對於 **Connection profile name**，輸入 **postgres-vm**。
6. 對於 **Region** 選擇 **(region)**。
7. 在 **Define connection configurations** 下點擊 **Define**
8. 對於 **Hostname or IP address**，輸入您在上一步驟中複製的 PostgreSQL 源實例的內部 IP（例如，10.128.0.2）
9. 對於 **Port**，輸入 **5432**。
10. 對於 **Username**，輸入 **migration_admin**。
11. 對於 **Password**，輸入 **DMS_1s_cool!**。
12. 對於所有其他值保留默認值。
13. 點擊 **Save**。
14. 點擊 **Create**。

名為 **postgres-vm** 的新連接配置文件將出現在 Connections profile 列表中。

### 任務 3. 創建和啟動連續遷移作業

創建新遷移作業時，您首先使用之前創建的連接配置文件定義源數據庫實例。然後您創建新的 Cloud SQL 數據庫實例並配置源實例和目標實例之間的連接。

在此任務中，您將使用遷移作業界面創建新的 Cloud SQL for PostgreSQL 數據庫實例，並將其設置為從 PostgreSQL 源實例進行連續遷移的目的地。

#### 創建新的連續遷移作業

在此步驟中，您將創建新的連續遷移作業。

1. 在 Google Cloud Console 中，在 **Navigation menu** () 上，點擊 **VIEW ALL PRODUCTS** 在 **Databases** 部分點擊 **Database Migration** > **Migration jobs**。

2. 點擊 **+ Create Migration Job**。
3. 對於 **Migration job name**，輸入 **vm-to-cloudsql**。
4. 對於 **Source database engine**，選擇 **PostgreSQL**。
5. 對於 **Destination database engine**，選擇 **Cloud SQL for PostgreSQL**。
6. 對於 **Destination region**，選擇 **(region)**。
7. 對於 **Migration job type**，選擇 **Continuous**。

保留其他設置的默認值。

1. 點擊 **Save & Continue**。

#### 定義源實例

在此步驟中，您將定義遷移的源實例。

1. 對於 **Source connection profile**，選擇 **postgres-vm**。

保留其他設置的默認值。

1. 點擊 **Save & Continue**。

#### 創建目標實例

在此步驟中，您將創建遷移的目標實例。

1. 對於 **Destination Instance ID**，輸入 **postgresql-cloudsql**。
2. 對於 **Password**，輸入 **supersecret!**。
3. 對於 **Database version**，選擇 **Cloud SQL for PostgreSQL 13**。
4. 對於 **Choose a Cloud SQL edition**，選擇 **Enterprise** edition。
5. 在 **Choose region and zone** 部分，選擇 **Single zone** 並選擇 **(zone)** 作為 **primary zone**。
6. 對於 **Instance connectivity**，選擇 **Private IP** 和 **Public IP**。
7. 選擇 **Use an automatically allocated IP range**。

保留其他設置的默認值。

1. 點擊 **Allocate & Connect**。

當步驟完成時，一條更新的消息會通知您實例將使用現有的托管服務連接。

您需要在此任務結束時測試遷移配置之前，在 VM 實例上編輯 pg_hba.conf 文件以允許訪問自動生成的 IP 範圍。

當您看到實例將使用現有的托管服務連接的更新消息時，繼續下一步驟。

輸入創建目標實例所需的附加信息。

1. 對於 **Machine shapes**，檢查 **1 vCPU, 3.75 GB**
2. 對於 **Storage type**，選擇 **SSD**
3. 對於 **Storage capacity**，選擇 **10 GB**
4. 點擊 **Create & Continue**。

如果提示，點擊 **Create Destination & Continue**。一條消息將說明您的目標數據庫實例正在創建。繼續等待。

#### 定義連接方法

在此步驟中，您將定義遷移的連接方法。

當您看到目標實例已創建的更新消息時，繼續下一步驟。

1. 對於 **Connectivity method**，選擇 **VPC peering**。
2. 對於 **VPC**，選擇 **default**。

VPC peering 由 Database Migration Service 使用提供的 VPC 網絡信息進行配置（此示例中的默認網絡）。

當您看到目標實例已創建的更新消息時，繼續下一步驟。

1. 點擊 **Configure & Continue**。

#### 配置遷移數據庫

在此步驟中，您將定義遷移的源實例。

1. 對於 **Databases to migrate**，選擇 **All databases**。
2. 點擊 **Save & Continue**。

#### 允許從自動分配 IP 範圍訪問 postgresql-vm 實例

在此步驟中，您將編輯 `pg_hba.conf` PostgreSQL 配置文件，以允許 Database Migration Service 訪問獨立 PostgreSQL 數據庫。

1. 獲取分配的 IP 地址範圍。在 Google Cloud Console 中，在 **Navigation menu** () 上，右鍵點擊 **VPC network** > **VPC network peering** 並在新標籤頁中打開。

2. 點擊 `servicenetworking-googleapis-com` 條目，然後點擊底部的 **Effective Routes View**。
3. 從 **Network** 下拉列表中選擇 **default**，從 **Region** 中選擇 **(region)**。點擊 **View**。
4. 在 **Destination IP range** 列中，複製 `IP range`（例如，10.107.176.0/24），在 **peering-route-xxxxx...** 路由旁邊。
5. 在 VM 實例的終端會話中，按如下方式編輯 `pg_hba.conf` 文件：

```bash
sudo nano /etc/postgresql/13/main/pg_hba.conf
```

1. 在文件的最後一行：

```conf
#GSP918 - allow access to all hosts
host    all all 0.0.0.0/0   md5
```

將 "all IP addresses" 範圍（0.0.0.0/0）替換為您在上一步複製的範圍。

```conf
#GSP918 - allow access to all hosts
host    all all 10.107.176.0/24   md5
```

**注意：** 此步驟對於使遷移工作不是必需的，但在遷移過程中使源數據庫更安全是很好的實踐，並在遷移後限制訪問。

1. 保存並退出 nano 編輯器，按 Ctrl-O、Enter、Ctrl-X
2. 重新啟動 PostgreSQL 服務以使更改生效。在 VM 實例終端會話中：

```bash
sudo systemctl start postgresql@13-main
```

#### 測試並啟動連續遷移作業

在此步驟中，您將測試並啟動遷移作業。

1. 在您之前打開的 **Database Migration Service** 標籤中，查看遷移作業的詳細信息。
2. 點擊 **Test Job**。
3. 成功測試後，點擊 **Create & Start Job**。

如果提示，點擊 **Create & Start**。

#### 查看連續遷移作業的狀態

在此步驟中，您將確認連續遷移作業正在運行。

1. 在 Google Cloud Console 中，在 **Navigation menu** () 上，點擊 **Database Migration** > **Migration jobs**。

2. 點擊遷移作業 **vm-to-cloudsql** 以查看詳細信息頁面。
3. 查看遷移作業狀態。
   - 如果您尚未啟動作業，狀態將顯示為 **Not started**。您可以選擇啟動或刪除作業。
   - 作業啟動後，狀態將顯示為 **Starting**，然後轉變為 **Running Full dump in progress** 以指示初始數據庫轉儲正在進行中。
   - 初始數據庫轉儲完成後，狀態將轉變為 **Running CDC in progress** 以指示連續遷移處於活動狀態。

當作業狀態更改為 **Running CDC in progress** 時，繼續執行下一任務。

### 任務 4. 確認 Cloud SQL for PostgreSQL 中的數據

#### 檢查 Cloud SQL 中的 PostgreSQL 數據庫

1. 在 Google Cloud Console 中，在 **Navigation menu** () 上，點擊 **SQL**。

2. 展開實例 ID 為 **postgresql-cloudsql-master**。
3. 點擊實例 **postgresql-cloudsql**（PostgreSQL 讀取複本）。
4. 在 **Replica Instance** 菜單中，點擊 **Databases**。

注意 `postgres`、`orders` 和 `gmemegen_db` 數據庫已遷移到 Cloud SQL。

#### 連接到 PostgreSQL 實例

1. 在 **Replica Instance** 菜單中，點擊 **Overview**。
2. 向下滾動到 **Connect to this instance** 部分，點擊 **Open Cloud Shell**。

連接到 PostgreSQL 的命令將預填充到 Cloud Shell 中：

```bash
gcloud sql connect postgresql-cloudsql --user=postgres --quiet
```

1. 運行預填充的命令。

如果提示，點擊 **Authorize** 進行 API。

1. 當提示輸入密碼時，輸入您之前設置的密碼：

```bash
supersecret!
```

您現在已激活 Cloud SQL 實例的目的地實例的 PostgreSQL 交互式控制台。

#### 查看 Cloud SQL for PostgreSQL 實例中的數據

1. 在 PostgreSQL 交互式控制台中，要選擇數據庫，請運行以下命令：

```sql
\c orders;
```

1. 當提示輸入密碼時，輸入：

```bash
supersecret!
```

1. 查詢 `distribution_centers` 表：

```sql
select * from distribution_centers;
```

1. 退出 PostgreSQL 交互式控制台，輸入：

```sql
\q
```

#### 更新獨立源數據以測試連續遷移

1. 在 Cloud Shell 中，輸入以下命令以連接到源 PostgreSQL 實例：

```bash
export VM_NAME=postgresql-vm
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export POSTGRESQL_IP=$(gcloud compute instances describe ${VM_NAME} \
  --zone=(zone) --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
echo $POSTGRESQL_IP
psql -h $POSTGRESQL_IP -p 5432 -d orders -U migration_admin
```

**注意：** 這是訪問 VM 實例上的獨立數據庫的替代方法。

1. 當提示輸入密碼時，輸入：

```bash
DMS_1s_cool!
```

1. 在 **psql** 中，輸入以下命令：

```sql
\c orders;

insert into distribution_centers values(-80.1918,25.7617,'Miami FL',11);
```

1. 關閉交互式 **psql** 會話：

```sql
\q
```

#### 連接到 Cloud SQL PostgreSQL 數據庫以檢查更新的數據是否已遷移

1. 在 Cloud Shell 中，輸入以下命令以連接到目標 Cloud SQL PostgreSQL 實例：

```bash
gcloud sql connect postgresql-cloudsql --user=postgres --quiet
```

1. 當提示輸入密碼時，輸入 Cloud SQL 實例的密碼：

```bash
supersecret!
```

您現在已激活 Cloud SQL 實例的目的地實例的 PostgreSQL 交互式控制台。

#### 查看 Cloud SQL for PostgreSQL 數據庫中的數據

1. 在 Cloud Shell 中，在 PostgreSQL 交互式控制台中選擇活動數據庫：

```sql
\c orders;
```

1. 當提示輸入密碼時，輸入：

```bash
supersecret!
```

1. 查詢 `distribution_centers` 表：

```sql
select * from distribution_centers;
```

注意源獨立 `orders` 數據庫上添加的新行現在存在於遷移的數據庫上。

1. 退出 PostgreSQL 交互式控制台：

```sql
\q
```

### 任務 5. 將 Cloud SQL 提升為獨立實例以進行讀寫數據

1. 在 Google Cloud Console 中，在 **Navigation menu** () 上，點擊 **VIEW ALL PRODUCTS** 在 **Databases** 部分點擊 **Database Migration** > **Migration jobs**。

2. 點擊遷移作業名稱 **vm-to-cloudsql** 以查看詳細信息頁面。
3. 點擊 **Promote**。

如果提示，點擊 **Promote**。

提升完成後，作業的狀態將更新為 **Completed**。

1. 在 Google Cloud Console 中，在 **Navigation menu** () 上，點擊 **VIEW ALL PRODUCTS** 在 **Databases** > **SQL**。

注意 **postgresql-cloudsql** 現在是一個獨立的實例，用於讀寫數據。

## 驗證步驟

### 檢查遷移作業狀態
- 確保遷移作業狀態為 **Completed**
- 驗證 Cloud SQL 實例顯示為 **Primary instance**

### 驗證數據完整性
- 確認所有三個數據庫（postgres、orders、gmemegen_db）都存在
- 檢查數據是否正確遷移，包括新插入的記錄
- 驗證表結構和權限正確設置

### 測試連接
- 確保可以通過 Cloud Shell 連接到 Cloud SQL 實例
- 驗證讀寫操作正常工作

## 故障排除

### 常見問題和解決方案

**遷移作業卡在 "Starting" 狀態：**
- 檢查源數據庫連接配置
- 確保防火牆規則允許從 Cloud SQL 到源數據庫的訪問
- 驗證 migration_admin 用戶權限正確設置

**數據不同步：**
- 檢查 pglogical 擴展是否正確安裝
- 驗證 WAL 配置正確
- 確保源數據庫允許複製連接

**連接失敗：**
- 檢查 VPC 對等設置
- 驗證 IP 範圍配置正確
- 確保 Service Networking API 已啟用

**API 啟用問題：**
- 等待幾分鐘讓 API 完全啟用
- 檢查項目權限
- 確保計費帳戶正確設置

## 清理步驟

要避免產生不必要的費用，請按以下步驟清理資源：

1. **停止遷移作業**（如果仍在運行）：
   - 在 Database Migration Service 中停止 vm-to-cloudsql 作業

2. **刪除遷移作業**：
   - 在 Database Migration Service 中刪除 vm-to-cloudsql 作業

3. **刪除連接配置文件**：
   - 刪除 postgres-vm 連接配置文件

4. **刪除 Cloud SQL 實例**：
   - 在 Cloud SQL 中刪除 postgresql-cloudsql 實例

5. **刪除 VM 實例**：
   - 在 Compute Engine 中刪除 postgresql-vm 實例

6. **清理存儲桶**（如果已創建）：
   - 刪除任何臨時存儲桶

## 額外資源

### 官方文檔
- [Database Migration Service 文檔](https://cloud.google.com/database-migration/docs)
- [Cloud SQL for PostgreSQL 文檔](https://cloud.google.com/sql/docs/postgres)
- [pglogical 擴展文檔](https://github.com/2ndQuadrant/pglogical)

### 相關實驗
- GSP103: Dataproc: Qwik Start - Console
- GSP104: Dataproc: Qwik Start - Command Line
- GSP192: Dataflow: Qwik Start - Templates

### 進一步閱讀
- [PostgreSQL 邏輯複製](https://www.postgresql.org/docs/current/logical-replication.html)
- [Google Cloud VPC 對等](https://cloud.google.com/vpc/docs/vpc-peering)
- [Cloud SQL 私有 IP 連接](https://cloud.google.com/sql/docs/postgres/private-ip)

## 個人筆記

此實驗演示了將獨立 PostgreSQL 數據庫遷移到 Cloud SQL 的完整過程。關鍵學習點：

- pglogical 擴展對於邏輯複製至關重要
- 連續遷移允許最小停機時間
- VPC 對等提供安全的私有連接
- 權限配置對於成功遷移很重要

記住檢查所有 API 都已啟用，並仔細配置防火牆規則以確保安全遷移。
