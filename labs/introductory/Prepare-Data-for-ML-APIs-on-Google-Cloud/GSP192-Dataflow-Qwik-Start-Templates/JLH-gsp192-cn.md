# GSP192 - Dataflow: Qwik Start - Templates

## 實驗概述

在本實驗中，您將學習如何使用 Google 提供的 Dataflow 模板創建串流管道。更具體來說，您將使用 Pub/Sub to BigQuery 模板，該模板從 Pub/Sub 主題讀取以 JSON 格式寫入的訊息，並將其推送至 BigQuery 表。您可以在 [Get started with Google-provided templates Guide](https://cloud.google.com/dataflow/docs/templates/provided-templates) 中找到此模板的文件。

您可以選擇使用 Cloud Shell 命令行或 Cloud Console 來創建 BigQuery 資料集和表。**請選擇一種方法使用**，然後繼續使用該方法完成整個實驗。如果您想體驗這兩種方法，可以第二次運行此實驗。

## 您將完成的工作

- 創建 BigQuery 資料集和表
- 創建 Cloud Storage bucket
- 使用 Pub/Sub to BigQuery Dataflow 模板創建串流管道

## 預備知識

- 基本的 GCP 知識
- 熟悉 BigQuery、Cloud Storage 和 Dataflow 的基本概念
- 了解 Pub/Sub 訊息傳遞

## 目標

完成此實驗後，您將能夠：
- 使用 GCP Console 或命令行創建 BigQuery 資源
- 部署 Dataflow 模板來處理串流資料
- 查詢從 Pub/Sub 流到 BigQuery 的資料

## 估計時間

45 分鐘

## 實驗步驟

### 步驟 1：確保 Dataflow API 成功重新啟用

要確保存取必要的 API，請重新啟動與 Dataflow API 的連接。

**指令：**
1. 在 Cloud Shell 中，運行以下命令來重置 Dataflow API，方法是停用並重新啟用專案的 Dataflow API。

```bash
gcloud services disable dataflow.googleapis.com --project $GOOGLE_CLOUD_PROJECT --force
gcloud services enable dataflow.googleapis.com --project $GOOGLE_CLOUD_PROJECT
```

**預期結果：**
- Dataflow API 已被停用並重新啟用

### 步驟 2：使用 Cloud Shell 創建 BigQuery 資料集、BigQuery 表和 Cloud Storage bucket

讓我們先創建一個 BigQuery 資料集和表。

**注意：** 此任務使用 `bq` 命令行工具。**如果您想使用 Cloud Console 完成這些步驟，請跳至步驟 3**。

**指令：**
1. 運行以下命令來創建名為 `taxirides` 的資料集：

```bash
bq mk taxirides
```

**預期結果：**
```
Dataset '<your-project-id:taxirides>' successfully created
```

2. 創建資料集後，使用以下命令實例化 BigQuery 表：

```bash
bq mk \
--time_partitioning_field timestamp \
--schema ride_id:string,point_idx:integer,latitude:float,longitude:float,\
timestamp:timestamp,meter_reading:float,meter_increment:float,ride_status:string,\
passenger_count:integer -t taxirides.realtime
```

**預期結果：**
```
Table 'your-project-id:taxirides.realtime' successfully created
```

**創建 Cloud Storage bucket：**

1. 使用專案 ID 作為 bucket 名稱以確保全域唯一名稱：

```bash
export BUCKET_NAME=$GOOGLE_CLOUD_PROJECT
gsutil mb gs://$BUCKET_NAME/
```

**預期結果：**
- Cloud Storage bucket 成功創建

### 步驟 3：使用 Google Cloud Console 創建 BigQuery 資料集、BigQuery 表和 Cloud Storage bucket

**注意：** 如果您完成了步驟 2，請不要完成步驟 3，因為它們包含相同的任務！

**指令：**
1. 從左側選單，在 Big Data 部分點擊 **BigQuery**。
2. 然後點擊 **Done**。
3. 點擊 **Explorer** 部分下專案名稱旁的三个點，然後點擊 **Create dataset**。
4. 輸入 `taxirides` 作為資料集 ID：
5. 選擇 **us (multiple regions in United States)** 作為資料位置。
6. 保留所有其他預設設定，然後點擊 **CREATE DATASET**。

**預期結果：**
- `taxirides` 資料集出現在左側控制台的專案名稱下

1. 現在點擊 `taxirides` 資料集旁的三个點並選擇 **Open**。
2. 然後在右側控制台選擇 **CREATE TABLE**。
3. 在 **Destination** > **Table Name** 輸入中，輸入 `realtime`。
4. 在 Schema 下，切換 **Edit as text** 滑塊並輸入以下內容：

```
ride_id:string,point_idx:integer,latitude:float,longitude:float,timestamp:timestamp,
meter_reading:float,meter_increment:float,ride_status:string,passenger_count:integer
```

5. 現在點擊 **Create table**。

**創建 Cloud Storage bucket：**

1. 返回 Cloud Console 並導航至 **Cloud Storage** > **Buckets** > **Create bucket**。
2. 使用專案 ID 作為 bucket 名稱以確保全域唯一名稱
3. 保留所有其他預設設定，然後點擊 **Create**。

**預期結果：**
- Cloud Storage bucket 成功創建

### 步驟 4：運行管道

部署 Dataflow 模板：

```bash
gcloud dataflow jobs run iotflow \
    --gcs-location gs://dataflow-templates-us-central1/latest/PubSub_to_BigQuery \
    --region us-central1 \
    --worker-machine-type e2-medium \
    --staging-location gs://$BUCKET_NAME/temp \
    --parameters inputTopic=projects/pubsub-public-data/topics/taxirides-realtime,outputTableSpec=$GOOGLE_CLOUD_PROJECT:taxirides.realtime
```

**預期結果：**
- 在 **Navigation menu** 中點擊 **View All Products** > **Analytics** > **Dataflow** > **Jobs**。您將看到您的 dataflow 作業。

**注意：** 您可能需要等待一分鐘讓活動追蹤完成。

### 步驟 5：提交查詢

您可以使用標準 SQL 提交查詢。

**指令：**
1. 在 BigQuery **Editor** 中，添加以下內容來查詢專案中的資料：

```sql
SELECT * FROM `$GOOGLE_CLOUD_PROJECT.taxirides.realtime` LIMIT 1000
```

2. 現在點擊 **RUN**。

如果遇到任何問題或錯誤，請重新運行查詢（管道啟動需要一分鐘。）

**預期結果：**
- 當查詢成功運行時，您將在 **Query Results** 面板中看到輸出

## 驗證

成功完成實驗的證明：
- BigQuery 表中填充了來自 Pub/Sub 主題的計程車乘車資料
- 能夠成功運行查詢並檢索資料
- Dataflow 作業在控制台中運行且沒有錯誤

## 故障排除

常見問題和解決方案：
- **Dataflow 作業失敗**：檢查您的專案權限和 API 啟用狀態
- **BigQuery 表未填充資料**：等待幾分鐘讓管道完全啟動
- **查詢返回空結果**：確保 Pub/Sub 主題正在發送資料
- **權限錯誤**：確保您的帳戶有必要的 IAM 角色

## 清理

為避免產生費用，請清理以下資源：
1. 停止 Dataflow 作業：
   - 在 Dataflow 控制台中選擇作業
   - 點擊 **Stop** 並確認

2. 刪除 BigQuery 資料集：
```bash
bq rm -r -f taxirides
```

3. 刪除 Cloud Storage bucket：
```bash
gsutil rm -r gs://$BUCKET_NAME
```

## 額外資源

- [Dataflow 文件](https://cloud.google.com/dataflow/docs)
- [BigQuery 文件](https://cloud.google.com/bigquery/docs)
- [Pub/Sub 文件](https://cloud.google.com/pubsub/docs)
- [Dataflow 模板指南](https://cloud.google.com/dataflow/docs/templates/provided-templates)
- [BigQuery 命令行參考](https://cloud.google.com/bigquery/docs/reference/bq-cli-reference)

## 測試您的理解

以下是強化您對此實驗概念理解的多選題：

**Google Cloud Dataflow 是否支援批次處理？**
- 正確答案：是

**在此實驗中使用了哪個 Dataflow 模板來運行管道？**
- 正確答案：Pub/Sub to BigQuery

## 筆記

- 此實驗展示了如何使用 Google 提供的模板快速設定串流資料管道
- Pub/Sub to BigQuery 模板是處理即時資料的強大工具
- 記住清理資源以避免意外費用
- Dataflow 模板大大簡化了常見資料處理模式的實現
