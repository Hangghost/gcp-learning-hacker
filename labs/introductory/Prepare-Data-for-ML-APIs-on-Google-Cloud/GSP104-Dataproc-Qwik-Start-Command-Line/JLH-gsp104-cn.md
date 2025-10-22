# GSP104 - Dataproc: Qwik Start - Command Line

## 實驗概述

Dataproc 是一個快速、易用、全受管理的雲端服務，用於在更簡單、更具成本效益的方式下運行 Apache Spark 和 Apache Hadoop 集群。操作通常需要數小時或數天的工作，可以在幾秒鐘或幾分鐘內完成。創建 Dataproc 集群快速，並可以隨時調整大小，因此您不必擔心數據管道會超出集群的容量。

此實驗將向您展示如何使用命令行創建 Dataproc 集群、在集群中運行簡單的 Apache Spark 作業，然後修改集群中的 worker 數量。

## 先決條件

- Google Cloud Platform 帳戶
- 基本的命令行知識
- 了解 Google Cloud Console 的基本操作

## 學習目標

完成此實驗後，您將能夠：

- 使用命令行創建 Dataproc 集群
- 運行簡單的 Apache Spark 作業
- 修改集群中的 worker 數量

## 預估時間

45 分鐘

## 實驗步驟

### 步驟 1：創建集群

在本任務中，您將學習如何使用命令行創建 Dataproc 集群。

**說明：**

1. 在 Cloud Shell 中，運行以下命令來設置區域：

```bash
gcloud config set dataproc/region REGION
```

**注意：** 將 `REGION` 替換為您的實際區域。

2. 停用 Dataproc API：

```bash
gcloud services disable dataproc.googleapis.com --force
```

3. 重新啟用 Dataproc API：

```bash
gcloud services enable dataproc.googleapis.com
```

4. Dataproc 會創建共享 staging 和 temp buckets，在同一區域的集群間共享。由於我們沒有指定 Dataproc 要使用的帳戶，它將使用 Compute Engine 默認服務帳戶，默認情況下沒有存儲 bucket 權限。讓我們添加這些權限。

   首先，運行以下命令來獲取 PROJECT_ID 和 PROJECT_NUMBER：

```bash
PROJECT_ID=$(gcloud config get-value project) && \
gcloud config set project $PROJECT_ID

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
```

5. 現在運行以下命令來為 Compute Engine 默認服務帳戶添加 Storage Admin 和 Dataproc Worker 角色：

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role=roles/storage.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --role=roles/dataproc.worker
```

6. 運行以下命令在您的子網路上啟用 Private Google Access：

```bash
gcloud compute networks subnets update default --region=REGION  --enable-private-ip-google-access
```

**注意：** 將 `REGION` 替換為您的實際區域。

7. 運行以下命令創建一個名為 `example-cluster` 的集群，使用 e2-standard-4 VM 和默認 Cloud Dataproc 設置：

```bash
gcloud dataproc clusters create example-cluster --worker-boot-disk-size 500 --worker-machine-type=e2-standard-4 --master-machine-type=e2-standard-4
```

8. 如果系統詢問您確認集群區域，請輸入 **Y**。

您的集群將構建幾分鐘。

```bash
Waiting for cluster creation operation...done.
Created [... example-cluster]
```

當您看到 "Created" 消息時，就可以繼續下一步了。

**預期結果：**
- 集群創建成功，並顯示創建確認消息

### 步驟 2：提交作業

在本任務中，您將學習如何提交示例 Spark 作業來計算 Pi 的近似值。

**說明：**

運行此命令來提交一個示例 Spark 作業，該作業計算 Pi 的粗略值：

```bash
gcloud dataproc jobs submit spark --cluster example-cluster \
  --class org.apache.spark.examples.SparkPi \
  --jars file:///usr/lib/spark/examples/jars/spark-examples.jar -- 1000
```

此命令指定：

- 您要在 `example-cluster` 集群上運行 spark 作業
- 包含作業的 Pi 計算應用程序的主要方法的類
- 包含作業代碼的 jar 文件的位置
- 您要傳遞給作業的參數（此處為任務數量，即 `1000`）

**注意：** 傳遞給作業的參數必須跟隨雙破折號 (--)。有關更多信息，請參閱 [gcloud 文檔](https://cloud.google.com/sdk/gcloud/reference/dataproc/jobs/submit/spark)。

作業的運行和最終輸出將顯示在終端窗口中：

```bash
Waiting for job output...
...
Pi is roughly 3.14118528
...
state: FINISHED
```

**預期結果：**
- 作業成功運行並顯示 Pi 的近似值
- 最終狀態顯示為 FINISHED

### 步驟 3：更新集群

在本任務中，您將學習如何修改集群中的 worker 數量。

**說明：**

1. 要將集群中的 worker 數量更改為四個，請運行以下命令：

```bash
gcloud dataproc clusters update example-cluster --num-workers 4
```

您的集群的更新詳細信息將顯示在命令的輸出中：

```bash
Waiting on operation [projects/.../operations/...].
Waiting for cluster update operation...done.
```

2. 您可以使用相同的命令來減少 worker 節點數量：

```bash
gcloud dataproc clusters update example-cluster --num-workers 2
```

現在您可以從 Google Cloud 的 `gcloud` 命令行創建 Dataproc 集群並調整 worker 數量。

**預期結果：**
- 集群 worker 數量成功更新
- 顯示集群更新操作完成的消息

### 步驟 4：測試您的理解

以下是多選題，用於強化您對此實驗概念的理解。請盡可能正確回答。

**問題：** 可以使用多種虛擬機類型、磁盤大小和節點數量快速創建和擴展集群。

- True
- False

**正確答案：** True

## 驗證

要驗證實驗是否成功完成：

1. **任務 1 驗證：** 檢查集群是否成功創建
   - 運行：`gcloud dataproc clusters list`
   - 應該看到 `example-cluster` 在列表中

2. **任務 2 驗證：** 檢查作業是否成功運行
   - 在作業輸出中查找 "Pi is roughly" 消息
   - 確保最終狀態為 "FINISHED"

3. **任務 3 驗證：** 檢查集群是否成功更新
   - 運行：`gcloud dataproc clusters describe example-cluster`
   - 檢查 worker 數量是否正確

## 故障排除

常見問題和解決方案：

- **權限錯誤：** 如果遇到權限相關錯誤，請確保 Compute Engine 默認服務帳戶具有正確的 IAM 角色（Storage Admin 和 Dataproc Worker）

- **集群創建失敗：** 如果集群創建失敗，請檢查：
  - 區域設置是否正確
  - API 是否已啟用
  - 配額是否充足

- **作業提交失敗：** 如果作業提交失敗，請檢查：
  - 集群名稱是否正確
  - 集群狀態是否為運行中
  - jar 文件路徑是否正確

- **API 未啟用：** 如果收到 API 未啟用的錯誤，請重新運行啟用命令：
  ```bash
  gcloud services enable dataproc.googleapis.com
  ```

## 清理

為了避免產生不必要的費用，請在完成實驗後清理資源：

1. 刪除集群：
   ```bash
   gcloud dataproc clusters delete example-cluster --region=REGION
   ```

2. 刪除臨時存儲桶（如果存在）：
   ```bash
   gsutil rm -r gs://dataproc-staging-REGION-PROJECT_ID/
   gsutil rm -r gs://dataproc-temp-REGION-PROJECT_ID/
   ```

**注意：** 將 `REGION` 和 `PROJECT_ID` 替換為您的實際值。

## 額外資源

- [Dataproc 文檔](https://cloud.google.com/dataproc/docs)
- [Apache Spark 文檔](http://spark.apache.org/)
- [Apache Hadoop 文檔](http://hadoop.apache.org/)
- [gcloud dataproc 命令參考](https://cloud.google.com/sdk/gcloud/reference/dataproc)
- [Dataproc 定價](https://cloud.google.com/dataproc/pricing)

## 相關實驗

- GSP103: Dataproc: Qwik Start - Console
- GSP105: Dataprep: Qwik Start
- GSP192: Dataflow: Qwik Start - Templates

## 筆記

- Dataproc 是 Google Cloud 上運行 Apache Spark 和 Hadoop 的受管理服務
- 集群可以快速創建和擴展以適應工作負載需求
- 命令行工具提供了對 Dataproc 資源的完全控制
- 記得在生產環境中正確配置 IAM 權限和安全設置
