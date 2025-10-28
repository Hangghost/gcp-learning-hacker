# GSP355 - 創建和管理 Cloud SQL for PostgreSQL 實例：挑戰實驗

## 概述

此挑戰實驗將測試您以下能力：
- 使用資料庫遷移服務將獨立 PostgreSQL 資料庫遷移至 Cloud SQL for PostgreSQL
- 將 Cloud SQL 資料庫提升為獨立實例以進行讀寫操作
- 使用 IAM 資料庫認證保護資料庫
- 在資料庫上執行時間點恢復

## 先決條件

開始此實驗前，請確保您有：
- 已啟用計費的 GCP 專案
- PostgreSQL 和 Cloud SQL 的基本知識
- 熟悉資料庫遷移服務

## 任務 1. 將獨立 PostgreSQL 資料庫遷移至 Cloud SQL for PostgreSQL 實例

### 步驟 1.1：啟用所需 API

1. 在 Google Cloud Console 中，前往 **APIs & Services > Library**
2. 啟用以下 API：
   - Database Migration API
   - Service Networking API

### 步驟 1.2：準備獨立 PostgreSQL 資料庫

1. **連接到 VM：**
   ```bash
   # SSH 連接到 postgres-vm
   gcloud compute ssh postgres-vm --zone=YOUR_ZONE
   ```

2. **安裝 pglogical 擴展：**
   ```bash
   sudo apt update
   sudo apt install postgresql-13-pglogical
   ```

3. **下載並應用配置檔案：**
   ```bash
   sudo su - postgres -c "gsutil cp gs://cloud-training/gsp918/pg_hba_append.conf ."
   sudo su - postgres -c "gsutil cp gs://cloud-training/gsp918/postgresql_append.conf ."
   sudo su - postgres -c "cat pg_hba_append.conf >> /etc/postgresql/13/main/pg_hba.conf"
   sudo su - postgres -c "cat postgresql_append.conf >> /etc/postgresql/13/main/postgresql.conf"
   sudo systemctl restart postgresql@13-main
   ```

4. **切換到 postgres 用戶並存取 psql：**
   ```bash
   sudo su - postgres
   psql
   ```

5. **創建 pglogical 擴展：**
   ```sql
   \c postgres;
   CREATE EXTENSION pglogical;

   \c orders;
   CREATE EXTENSION pglogical;
   ```

6. **創建遷移用戶（將 USERNAME 替換為實驗提供的用戶名）：**
   ```sql
   CREATE USER migration_admin PASSWORD 'DMS_1s_cool!';
   ALTER DATABASE orders OWNER TO migration_admin;
   ALTER ROLE migration_admin WITH REPLICATION;
   ```

7. **為 inventory_items 表添加主鍵：**
   ```sql
   \c orders;
   SELECT column_name FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'id';
   ALTER TABLE inventory_items ADD PRIMARY KEY (id);
   ```

8. **授予 migration_admin 用戶權限：**
   ```sql
   -- 授予 pglogical 架構權限
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

   -- 授予 public 架構權限
   GRANT USAGE ON SCHEMA public TO migration_admin;
   GRANT ALL ON SCHEMA public TO migration_admin;
   GRANT SELECT ON public.distribution_centers TO migration_admin;
   GRANT SELECT ON public.inventory_items TO migration_admin;
   GRANT SELECT ON public.order_items TO migration_admin;
   GRANT SELECT ON public.products TO migration_admin;
   GRANT SELECT ON public.users TO migration_admin;

   -- 更改表所有權
   ALTER TABLE public.distribution_centers OWNER TO migration_admin;
   ALTER TABLE public.inventory_items OWNER TO migration_admin;
   ALTER TABLE public.order_items OWNER TO migration_admin;
   ALTER TABLE public.products OWNER TO migration_admin;
   ALTER TABLE public.users OWNER TO migration_admin;
   ```

9. **在 postgres 資料庫中授予權限：**
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

### 步驟 1.3：創建資料庫遷移服務連接配置文件

1. 在 Google Cloud Console 中，前往 **Database Migration > Connection profiles**
2. 點擊 **CREATE PROFILE**
3. 配置配置文件：
   - **Source database engine**：PostgreSQL
   - **Connection profile name**：選擇一個名稱（例如：postgres-source-profile）
   - **Host**：postgres-vm 的內部 IP
   - **Port**：5432
   - **Username**：migration_admin
   - **Password**：DMS_1s_cool!
   - **Region**：YOUR_REGION（與您的實驗區域相同）

### 步驟 1.4：創建遷移作業

1. 前往 **Database Migration > Migration jobs**
2. 點擊 **CREATE MIGRATION JOB**
3. 配置遷移作業：
   - **Migration job name**：選擇一個名稱（例如：postgres-migration-job）
   - **Source connection profile**：選擇您創建的配置文件
   - **Destination**：
     - **Destination instance ID**：YOUR_MIGRATED_INSTANCE_ID
     - **Password**：supersecret!
     - **Database version**：Cloud SQL for PostgreSQL 13
     - **Region**：YOUR_REGION
     - **Connections**：同時啟用 Public IP 和 Private IP
     - **Private IP**：使用自動分配的 IP 範圍
     - **Edition**：Enterprise
     - **Machine type**：2 vCPU, 8GB RAM
   - **Connectivity method**：VPC peering（預設網路）
   - **Migration job type**：Continuous

4. **測試連接**，然後 **Create & Start** 遷移作業

5. **等待遷移完成** - 這可能需要幾分鐘時間

## 任務 2. 將 Cloud SQL 提升為獨立實例以進行讀寫資料操作

1. 在 Google Cloud Console 中，前往 **SQL**
2. 選擇您的遷移後的 Cloud SQL 實例
3. 點擊 **Promote** 將遷移複本提升為獨立實例
4. 等待提升完成 - 遷移作業狀態將更新為「Completed」

## 任務 3. 實作 Cloud SQL for PostgreSQL IAM 資料庫認證

### 步驟 3.1：將 VM 的公用 IP 添加到授權網路

1. 在 Cloud SQL 實例中，前往 **Connections > Networking**
2. 在 **Public IP** 下，點擊 **ADD A NETWORK**
3. 添加 postgres-vm 虛擬機器的外部 IP

### 步驟 3.2：創建 Cloud IAM 用戶

1. 在 Cloud SQL 實例中，前往 **Users**
2. 點擊 **ADD USER ACCOUNT**
3. 選擇 **Cloud IAM**
4. 輸入 Qwiklabs 用戶帳戶名稱作為主體

### 步驟 3.3：授予權限並測試存取

1. 在 Cloud SQL 實例中，前往 **Overview > Connect to this instance**
2. 點擊 **Open Cloud Shell**
3. 連接到資料庫：
   ```sql
   -- 輸入密碼：supersecret!
   \c orders;
   -- 再次輸入密碼：supersecret!
   ```

4. 授予 SELECT 權限（將 TABLE_NAME 和 QWIKLABS_USER 替換為實際值）：
   ```sql
   GRANT SELECT ON TABLE_NAME TO "QWIKLABS_USER_ACCOUNT_NAME";
   ```

5. 測試存取：
   ```sql
   SELECT COUNT(*) FROM TABLE_NAME;
   ```

## 任務 4. 配置並測試時間點恢復

### 步驟 4.1：啟用時間點恢復

1. 在 Cloud SQL 實例中，前往 **Overview**
2. 點擊 **EDIT > Data Protection**
3. 啟用 **Point-in-time recovery**
4. 設定 **Number of retained transaction log days** 為所需值

### 步驟 4.2：記錄恢復時間戳

1. 執行此命令獲取當前時間戳：
   ```bash
   date -u --rfc-3339=ns | sed -r 's/ /T/; s/\.([0-9]{3}).*/\.\1Z/'
   ```
2. **保存此時間戳** 以供後續使用

### 步驟 4.3：對資料庫進行更改

1. 通過 Cloud Shell 連接到資料庫：
   ```sql
   -- 密碼：supersecret!
   \c orders;
   -- 密碼：supersecret!
   ```

2. 向 distribution_centers 表添加行：
   ```sql
   INSERT INTO distribution_centers VALUES (-80.1918, 25.7617, 'Miami FL', 11);
   ```

3. 退出 psql：
   ```sql
   \q
   ```

### 步驟 4.4：創建時間點恢復複本

1. 在 Cloud Shell 中執行：
   ```bash
   gcloud auth login --quiet
   gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID
   export INSTANCE_ID=YOUR_MIGRATED_INSTANCE_ID
   gcloud sql instances clone $INSTANCE_ID postgres-orders-pitr --point-in-time 'YOUR_SAVED_TIMESTAMP'
   ```

2. 等待複本創建完成 - 這將創建一個名為 `postgres-orders-pitr` 的新實例

## 驗證

- **任務 1**：遷移作業成功完成
- **任務 2**：Cloud SQL 實例提升為獨立實例
- **任務 3**：IAM 用戶可以成功查詢表
- **任務 4**：時間點恢復複本成功創建

## 故障排除

- **遷移失敗**：檢查 pglogical 是否正確配置以及所有權限是否已授予
- **連接問題**：驗證 IP 位址和網路配置
- **IAM 認證失敗**：確保用戶帳戶格式正確
- **時間點恢復失敗**：檢查時間戳格式並確保已啟用備份

## 清理

完成實驗後，您可以：
1. 刪除複本實例 (postgres-orders-pitr)
2. 刪除遷移作業
3. 刪除 Cloud SQL 實例（如果不需要）
4. 刪除 VM 實例（如果不需要）

## 其他資源

- [資料庫遷移服務文檔](https://cloud.google.com/database-migration/docs)
- [Cloud SQL IAM 資料庫認證](https://cloud.google.com/sql/docs/postgres/authentication)
- [時間點恢復](https://cloud.google.com/sql/docs/postgres/backup-recovery/pitr)
