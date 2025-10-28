# GSP922 - 配置複製並為 Cloud SQL for PostgreSQL 啟用時間點恢復

## 實驗概述

時間點恢復 (Point-in-Time Recovery) 有助於將實例恢復到特定時間點。例如，如果錯誤導致資料遺失，您可以將資料庫恢復到錯誤發生之前的狀態。時間點恢復始終創建新實例；您無法對現有實例執行時間點恢復。新實例會繼承源實例的設定。

在此實驗中，您將為 Cloud SQL for PostgreSQL 實例配置和測試時間點恢復。

## 先決條件

- Google Cloud Platform 帳戶
- 基本 GCP 知識
- Cloud SQL 基本概念
- PostgreSQL 資料庫知識

## 學習目標

完成此實驗後，您將能夠：

- 在 Cloud SQL for PostgreSQL 實例上啟用時間點恢復
- 執行時間點恢復
- 確認恢復的資料庫反映了較早的時間點

## 預估時間

60 分鐘

## 任務總覽

### 任務 1：為 Cloud SQL for PostgreSQL 實例啟用備份

在此任務中，您將為 Cloud SQL for PostgreSQL 實例啟用排程備份。

#### 步驟 1：檢查實例詳細資訊

1. 在 Cloud Shell 中，顯示實例詳細資訊：

```bash
export CLOUD_SQL_INSTANCE=postgres-orders
gcloud sql instances describe $CLOUD_SQL_INSTANCE
```

#### 步驟 2：獲取當前 UTC 時間

2. 在 Cloud Shell 中，以 24 小時格式獲取當前 UTC 時間：

```bash
date +"%R"
```

#### 步驟 3：啟用排程備份

3. 在 Cloud Shell 中，輸入以下命令為實例啟用排程備份，將 `HH:MM` 替換為早於上一步顯示時間的時間。

```bash
gcloud sql instances patch $CLOUD_SQL_INSTANCE \
    --backup-start-time=HH:MM
```

**注意：** 為了此實驗的目的，您必須指定早於上一步顯示時間的備份開始時間。這是因為您不希望備份在您運行實驗時開始。
例如，如果 date 命令顯示當前時間為 `14:25`，您可以將 `HH:MM` 替換為 `13:25` 或甚至 `12:00`。您必須確保它是有效的 24 小時格式時間，否則會收到請求無效的錯誤。

#### 步驟 4：確認變更

4. 確認您的變更。注意 `format` 參數，它僅提取所需欄位。

```bash
gcloud sql instances describe $CLOUD_SQL_INSTANCE --format 'value(settings.backupConfiguration)'
```

您會看到類似以下的回應，顯示備份設定為 7 天，並在每天 14:00 運行：

```
backupRetentionSettings={'retainedBackups': 7, 'retentionUnit': 'COUNT'}; enabled=True;kind=sql#backupConfiguration; startTime=14:00; transactionLogRetentionDays=7
```

### 任務 2：啟用並運行時間點恢復

在此任務中，您將為 Cloud SQL for PostgreSQL 實例啟用和配置時間點恢復。時間點恢復始終創建新實例；您無法對現有實例執行時間點恢復。新實例會繼承源實例的設定。

#### 啟用時間點恢復

1. 在 Cloud Shell 中，啟用時間點恢復：

```bash
gcloud sql instances patch $CLOUD_SQL_INSTANCE \
    --enable-point-in-time-recovery \
    --retained-transaction-log-days=1
```

此命令完成需要約一分鐘到兩分鐘。

#### 修改 Cloud SQL for PostgreSQL 資料庫

2. 在 Cloud Console 的 **Navigation menu** () 上，點擊 **View All Products** > **Databases** > **Cloud SQL**，然後點擊名為 `postgres-orders` 的 Cloud SQL 實例。

3. 在 Cloud Console 的 `Connect to this instance` 部分，點擊 **Open Cloud Shell**。一個命令會自動填入 Cloud Shell。

4. 運行該命令並在提示時輸入密碼 `supersecret!`。Cloud Shell 中會啟動 **psql** 會話。

5. 在 **psql** 中，切換到 `orders` 資料庫：

```sql
\c orders
```

6. 當提示時，再次輸入密碼 `supersecret!`。

7. 在 **psql** 中，獲取 `distribution_centers` 表的行數：

```sql
SELECT COUNT(*) FROM distribution_centers;
```

**輸出：**

```
orders=> SELECT COUNT(*) FROM distribution_centers;
 count
-------
    10
(1 row)
```

8. 在 Cloud Shell 中，打開新標籤 (**+**)，以 RFC 3339 格式獲取當前 UTC 時間。這是您將用於創建時間點複本的時間戳。

```bash
date --rfc-3339=seconds
```

此時您應該等待幾分鐘，以確保您在下一步中所做的更改發生在此時間戳之後。

**注意：** 為了此實驗的目的，您必須指定在啟用時間點恢復之後但在源實例被修改之前的時間戳。如果不是，成功的備份將被要求作為起始點。如果不是，源實例的更改將被複製到複本，恢復不會顯現。

9. 在 **psql** 中，為 `orders.distribution_centers` 表添加一行並獲取新的 COUNT：

```sql
INSERT INTO distribution_centers VALUES(-80.1918,25.7617,'Miami FL',11);
SELECT COUNT(*) FROM distribution_centers;
```

**輸出：**

```
orders=> SELECT COUNT(*) FROM distribution_centers;
 count
-------
    11
(1 row)
```

10. 退出 **psql**：

```sql
\q
```

#### 執行時間點恢復

11. 在 Cloud Shell 中，要創建時間點複本，請運行：

```bash
export NEW_INSTANCE_NAME=postgres-orders-pitr
gcloud sql instances clone $CLOUD_SQL_INSTANCE $NEW_INSTANCE_NAME \
    --point-in-time 'TIMESTAMP'
```

您必須將 TIMESTAMP 占位符替換為您之前使用 `date` 命令顯示的確切時間戳。

此 TIMESTAMP 必須是 UTC 時區，RFC 3339 格式，例如 '2021-11-01 15:00:00'。TIMESTAMP 表示您想要恢復資料庫狀態的時間。它應該用單引號括起來。可選的 RFC3339 變體也受支持：'2021-11-01T15:00:00.000Z'。

創建複本並準備好使用可能需要 10 分鐘或更長時間。在此期間，請繼續執行下一個任務。

### 任務 3：確認資料庫已恢復到正確的時間點

在此任務中，您將確認原始資料庫在時間點恢復時間戳之後添加到原始資料庫的資料行不在複製的資料庫中。

1. 在 Cloud Console 的 **Overview** 頁面，點擊 **All Instances** 麵包屑，然後點擊名為 `postgres-orders-pitr` 的 Cloud SQL 實例。

現在您必須等待複本上線。

2. 在 Cloud Console 的 `Connect to this instance` 部分，點擊 **Open Cloud Shell**。一個命令會自動填入 Cloud Shell。

3. 運行該命令並在提示時輸入密碼 `supersecret!`。Cloud Shell 中會啟動 **psql** 會話。

4. 在 **psql** 中，切換到 `orders` 資料庫：

```sql
\c orders
```

5. 當提示時，再次輸入密碼 `supersecret!`。

6. 在 **psql** 中，獲取 `distribution_centers` 表的行數：

```sql
SELECT COUNT(*) FROM distribution_centers;
```

**輸出：**

```
orders=> SELECT COUNT(*) FROM distribution_centers;
 count
-------
    10
(1 row)
```

您會看到新 Cloud SQL for PostgreSQL 實例的 `distribution_centers` 表在複製時具有源實例的 10 行。如果您的查詢返回 11 行，請檢查您是否連接到複本實例而不是原始實例。

## 驗證

成功完成實驗的驗證：

1. **任務 1**：備份配置正確啟用，並顯示在實例描述中
2. **任務 2**：時間點恢復已啟用，並成功創建了新實例
3. **任務 3**：複製的資料庫僅包含 10 行（不包括時間戳之後添加的行）

## 故障排除

常見問題和解決方案：

- **備份開始時間錯誤**：確保使用有效的 24 小時格式時間，並早於當前時間
- **時間戳格式錯誤**：使用 RFC 3339 格式，包含時區資訊
- **複本創建失敗**：等待足夠時間讓實例初始化，可能需要 10-15 分鐘
- **資料庫連接問題**：確保使用正確的密碼和實例名稱
- **權限問題**：確保您的 GCP 帳戶具有必要的 Cloud SQL 權限

## 清理

為避免產生額外費用，請清理在此實驗中創建的資源：

1. 刪除 PITR 實例：

```bash
gcloud sql instances delete $NEW_INSTANCE_NAME --quiet
```

2. 可選：如果您想要完全清理，也可以刪除原始實例（但通常不需要，因為它是實驗環境的一部分）：

```bash
gcloud sql instances delete $CLOUD_SQL_INSTANCE --quiet
```

## 其他資源

- [Cloud SQL for PostgreSQL 文件](https://cloud.google.com/sql/docs/postgres/)
- [時間點恢復概述](https://cloud.google.com/sql/docs/postgres/backup-recovery/point-in-time-recovery)
- [Cloud SQL 備份和恢復](https://cloud.google.com/sql/docs/postgres/backup-recovery/backups)
- [相關實驗](https://www.cloudskillsboost.google/course_templates/652)

## 備註

- 時間點恢復對於災難恢復至關重要
- 始終在新實例上測試恢復，而不是覆蓋生產實例
- 監控交易日誌保留天數以控制儲存成本
- 考慮定期測試恢復過程以確保可靠性
