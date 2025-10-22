# GSP103 - Dataproc: Qwik Start - Console

## Lab 概述

Dataproc 是一個快速、易用且完全受管理的雲端服務，用於在更簡單、更具成本效益的方式下運行 Apache Spark 和 Apache Hadoop 集群。過去需要數小時或數天的操作，現在只需幾秒鐘或幾分鐘即可完成。Dataproc 可以快速創建集群並隨時調整大小，因此您無需擔心數據管道會超出集群容量。

此實驗將向您展示如何使用 Google Cloud 主控台創建 Dataproc 集群、在集群中運行簡單的 Apache Spark 作業，然後修改集群中的 worker 節點數量。

## 先決條件

- Google Cloud Platform 帳戶
- 基本 GCP 知識
- 熟悉 Google Cloud Console

## 學習目標

完成此實驗後，您將能夠：

- 在 Google Cloud 主控台中創建 Dataproc 集群
- 運行簡單的 Apache Spark 作業
- 修改集群中的 worker 節點數量

## 預估時間

45 分鐘

## 設定和需求

### 確認 Cloud Dataproc API 已啟用

要創建 Dataproc 集群，必須啟用 Cloud Dataproc API。要確認 API 已啟用：

1. 點擊 **Navigation menu** > **APIs & Services** > **Library**：
2. 在 **Search for APIs & Services** 對話框中輸入 **Cloud Dataproc**
3. 從搜尋結果中點擊 **Cloud Dataproc API**
4. 如果 API 尚未啟用，點擊 **Enable** 按鈕

### 設定 Service Account 權限

要為服務帳戶分配存儲權限（創建集群所需）：

1. 前往 **Navigation menu > IAM & Admin > IAM**
2. 點擊 `compute@developer.gserviceaccount.com` 服務帳戶旁的鉛筆圖標
3. 點擊 **+ ADD ANOTHER ROLE** 按鈕，選擇角色 **Storage Admin**

選取 **Storage Admin** 角色後，點擊 **Save**

## Lab 步驟

### 任務 1：創建集群

1. 在 Cloud Platform Console 中，選擇 **Navigation menu** > **View all products** > **Dataproc** > **Clusters**，然後點擊 **Create cluster**
2. 點擊 **Create** 選擇 **Cluster on Compute Engine**
3. 為集群設定以下欄位，並為所有其他欄位保留預設值：

**注意：**在 Configure nodes 部分，確保**主節點和 Worker 節點**都設定正確的 Machine Series 和 Machine Type。如果沒有顯示 E2 系列，請確認您已將 Primary Disk type 選項設為 "Standard Persistent Disk"。

| 欄位 | 值 |
|------|-----|
| Name | example-cluster |
| Region | [您的區域] |
| Zone | [您的區域] |
| Primary disk type (Manager Node) | Standard Persistent Disk |
| Machine Series (Manager Node) | E2 |
| Machine Type (Manager Node) | e2-standard-2 |
| Primary disk size (Manager Nodes) | 30 GB |
| Number of Worker Nodes | 2 |
| Primary disk type (Worker Node) | Standard Persistent Disk |
| Machine Series (Worker Nodes) | E2 |
| Machine Type (Worker Nodes) | e2-standard-2 |
| Primary disk size (Worker Nodes) | 30 GB |
| Internal IP only | 取消選取 "Configure all instances to have only internal IP addresses" |

**注意：**Zone 是一個特殊的多區域命名空間，能夠將實例部署到全球所有的 Google Compute zones。您也可以指定不同的區域，例如 `us-central1` 或 `europe-west1`，來隔離資源（包括 VM 實例和 Cloud Storage）並定位元數據存儲位置，由 Cloud Dataproc 在用戶指定的區域內使用。

4. 點擊 **Create** 創建集群

您的新集群將出現在 Clusters 列表中。創建可能需要幾分鐘，集群 Status 會顯示為 **Provisioning**，直到集群準備就緒，然後變為 **Running**。

**驗證任務完成**

點擊 **Check my progress** 驗證您已完成任務。

創建 Dataproc 集群

### 任務 2：提交作業

要運行示例 Spark 作業：

1. 點擊左側窗格中的 **Jobs** 切換到 Dataproc 的作業視圖，然後點擊 **Submit job**
2. 設定以下欄位以更新作業，保留所有其他欄位的預設值：

| 欄位 | 值 |
|------|-----|
| Region | [您的區域] |
| Cluster | example-cluster |
| Job type | Spark |
| Main class or jar | org.apache.spark.examples.SparkPi |
| Jar files | file:///usr/lib/spark/examples/jars/spark-examples.jar |
| Arguments | 1000（設定任務數量） |

3. 點擊 **Submit**

**注意：Spark 作業如何計算 Pi：**Spark 作業使用蒙特卡洛方法估計 Pi 值。它在坐標平面上生成 x,y 點來模擬一個圓圈，並圍繞單位正方形。輸入參數（1000）決定要生成的 x,y 對數量；生成的對越多，估計的準確性就越高。這個估計利用 Cloud Dataproc worker 節點來並行化計算。有關詳細信息，請參閱[使用蒙特卡洛方法估計 Pi](https://academo.org/demos/estimating-pi-monte-carlo/) 以及 GitHub 上的 [JavaSparkPi.java](https://github.com/Apache/spark/blob/master/examples/src/main/java/org/apache/spark/examples/JavaSparkPi.java)。

您的作業將出現在 **Jobs** 列表中，顯示項目的作業及其集群、類型和當前狀態。作業狀態顯示為 **Running**，然後在完成後顯示 **Succeeded**。

**驗證任務完成**

點擊 **Check my progress** 驗證您已完成任務。

提交作業

### 任務 3：查看作業輸出

要查看已完成作業的輸出：

1. 點擊 **Jobs** 列表中的作業 ID
2. 選擇 **LINE WRAP** 為 `ON`，或向右滾動到底部查看計算出的 Pi 值。**LINE WRAP** `ON` 時，您的輸出應類似如下：

[輸出](https://cdn.qwiklabs.com/DnVGNZW%2F3WiDYaqOqt3ET3nW%2Bp4NZbZYgvi2OL0QjXo%3D)

您的作業已成功計算出 Pi 的粗略值！

### 任務 4：更新集群以修改 worker 數量

要更改集群中的 worker 實例數量：

1. 點擊左側導航窗格中的 **Clusters** 返回 Dataproc Clusters 視圖
2. 點擊 **Clusters** 列表中的 **example-cluster**。預設情況下，頁面顯示集群的 CPU 使用率概覽
3. 點擊 **Configuration** 顯示集群的當前設定
4. 點擊 **Edit**。現在可以編輯 worker 節點數量
5. 在 **Worker nodes** 欄位中輸入 **4**
6. 點擊 **Save**

您的集群現已更新。檢查集群中的 VM 實例數量。

**驗證任務完成**

點擊 **Check my progress** 驗證您已完成任務。

更新集群

要使用更新的集群重新運行作業，您可以點擊左側窗格中的 **Jobs**，然後點擊 **SUBMIT JOB**。

設定與**提交作業**部分相同的欄位：

| 欄位 | 值 |
|------|-----|
| Region | [您的區域] |
| Cluster | example-cluster |
| Job type | Spark |
| Main class or jar | org.apache.spark.examples.SparkPi |
| Jar files | file:///usr/lib/spark/examples/jars/spark-examples.jar |
| Arguments | 1000（設定任務數量） |

點擊 **Submit**

### 任務 5：測試您的理解

以下是多選題，用於強化您對此實驗概念的理解。請根據您的最佳能力回答。

此實驗中提交的 Dataproc 作業類型是什麼？SparkSparkSqlHadoopPigPySpark

Dataproc 有助於用戶處理、轉換和理解大量數據。TrueFalse

## 驗證

成功完成此實驗的標誌包括：

- 成功創建名為 `example-cluster` 的 Dataproc 集群
- 成功提交並運行 Spark Pi 計算作業
- 能夠查看作業輸出並看到 Pi 的估計值
- 成功將集群的 worker 節點數量從 2 更改為 4

## 故障排除

常見問題和解決方案：

- **集群創建失敗**：確保 Cloud Dataproc API 已啟用，並且服務帳戶具有正確的權限
- **作業提交失敗**：檢查集群狀態是否為 Running，並確保區域設定正確
- **無法查看作業輸出**：等待作業完成（狀態為 Succeeded），然後重新整理頁面
- **權限錯誤**：確保您的 GCP 帳戶具有必要的 IAM 權限來創建和使用 Dataproc 資源

## 清理

為避免產生額外費用，請在完成實驗後清理資源：

1. 返回 Dataproc Clusters 頁面
2. 選擇 `example-cluster`
3. 點擊 **Delete** 按鈕
4. 確認刪除

或者，您可以通過 Cloud Shell 運行以下命令：

```bash
gcloud dataproc clusters delete example-cluster --region=[YOUR_REGION]
```

## 額外資源

- [Cloud Dataproc 文檔](https://cloud.google.com/dataproc/docs)
- [Apache Spark 官方文檔](http://spark.apache.org/)
- [Apache Hadoop 官方文檔](http://hadoop.apache.org/)
- [Cloud Dataproc 快速入門](https://cloud.google.com/dataproc/docs/quickstarts)
- [蒙特卡洛方法估計 Pi](https://academo.org/demos/estimating-pi-monte-carlo/)

## 相關 Labs

- GSP104: Dataproc: Qwik Start - Command Line
- GSP105: Dataprep: Qwik Start
- GSP192: Dataflow: Qwik Start - Templates

## 筆記

- Dataproc 是一個完全受管理的服務，可以顯著簡化大數據處理工作負載
- 集群可以根據需要動態調整大小，這對於處理變化的工作負載非常有用
- Spark Pi 示例演示了如何使用 Dataproc 進行並行計算
- 記住清理資源以避免意外費用
