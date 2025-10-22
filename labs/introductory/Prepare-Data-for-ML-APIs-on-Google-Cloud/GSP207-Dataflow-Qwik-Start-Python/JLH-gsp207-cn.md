# GSP207 - Dataflow: Qwik Start - Python

## 實驗室標題
學習使用 Apache Beam SDK for Python 設置 Dataflow 開發環境並運行示例 pipeline。

## 先決條件
- 基本的 GCP 知識
- 熟悉命令行操作
- 已啟用 Dataflow API
- Python 基礎知識

## 目標
完成此實驗室後，您將能夠：
- 創建 Cloud Storage bucket 來存儲 Dataflow pipeline 結果
- 安裝 Apache Beam SDK for Python
- 在本地運行 Dataflow pipeline 示例
- 在 Dataflow 上遠程運行 pipeline
- 驗證 pipeline 執行結果

## 預計時間
45 分鐘

## 實驗室步驟

### 步驟 1: 設置區域

在 Cloud Shell 中運行以下命令來設置此實驗室的項目區域：

```bash
gcloud config set compute/region "REGION"
```

### 步驟 2: 確保 Dataflow API 已成功啟用

要確保訪問必要的 API，請重新啟動對 Dataflow API 的連接。

1. 在 Cloud Console 中，在頂部搜索欄輸入 "Dataflow API"。點擊結果中的 **Dataflow API**。
2. 點擊 **管理**。
3. 點擊 **停用 API**。

如果提示確認，點擊 **停用**。

4. 點擊 **啟用**。

API 重新啟用後，頁面將顯示停用選項。

### 步驟 3: 創建 Cloud Storage bucket

當您使用 Dataflow 運行 pipeline 時，您的結果將存儲在 Cloud Storage bucket 中。在此任務中，您將創建一個 Cloud Storage bucket 來存儲稍後任務中運行的 pipeline 結果。

1. 在 **導航選單** () 上，點擊 **Cloud Storage** > **Buckets**。

2. 點擊 **創建 bucket**。
3. 在 **創建 bucket** 對話框中，指定以下屬性：
   - **名稱**：為確保唯一的 bucket 名稱，請使用以下名稱：`____`bucket。注意，此名稱不包含敏感信息在 bucket 名稱中，因為 bucket 命名空間是全局的並且公開可見。
   - **位置類型**：多區域
   - **位置**：`us`
   - 一個將存儲 bucket 數據的位置。
4. 點擊 **創建**。
5. 如果提示公開訪問將被阻止，點擊 **確認**。

**測試已完成任務**

點擊 **檢查我的進度** 來驗證您的已執行任務。如果您已成功完成任務，您將獲得評估分數。

創建 Cloud Storage bucket。

### 步驟 4: 安裝 Apache Beam SDK for Python

1. 要確保您使用受支持的 Python 版本，首先運行 `Python3.9` Docker 鏡像：

```bash
docker run -it -e DEVSHELL_PROJECT_ID=$DEVSHELL_PROJECT_ID python:3.9 /bin/bash
```

此命令拉取包含最新穩定版本 Python 3.9 的 Docker 容器，然後為您打開一個命令 shell 以在容器內運行以下命令。

2. 容器運行後，從虛擬環境安裝最新版本的 Apache Beam SDK for Python：

```bash
pip install 'apache-beam[gcp]'==2.42.0
```

您將看到與依賴相關的警告。它們對於此實驗室來說是安全的，可以忽略。

3. 在本地運行 `wordcount.py` 示例：

```bash
python -m apache_beam.examples.wordcount --output OUTPUT_FILE
```

您可能會看到類似以下的消息：

```
INFO:root:Missing pipeline option (runner). Executing pipeline using the default runner: DirectRunner.
INFO:oauth2client.client:Attempting refresh to obtain initial access_token
```

此消息可以忽略。

4. 現在您可以列出雲端環境中的文件，以獲取 `OUTPUT_FILE` 的名稱：

```bash
ls
```

5. 復制 `OUTPUT_FILE` 的名稱並使用 `cat` 查看其內容：

```bash
cat <file name>
```

您的結果顯示文件中的每個單詞及其出現次數。

### 步驟 5: 遠程運行示例 Dataflow pipeline

1. 將 BUCKET 環境變量設置為您之前創建的 bucket：

```bash
BUCKET=gs://<bucket name provided earlier>
```

2. 現在您將遠程運行 `wordcount.py` 示例：

```bash
python -m apache_beam.examples.wordcount --project $DEVSHELL_PROJECT_ID \
  --runner DataflowRunner \
  --staging_location $BUCKET/staging \
  --temp_location $BUCKET/temp \
  --output $BUCKET/results/output \
  --region "filled in at lab start"
```

在您的輸出中，等待看到消息：

```
JOB_MESSAGE_DETAILED: Workers have started successfully.
```

然後繼續實驗室。

### 步驟 6: 檢查您的 Dataflow 作業是否成功

1. 打開導航選單並點擊列表中的 **Dataflow**。

您應該會看到您的 **wordcount** 作業，最初狀態為 **Running**。

2. 點擊名稱來觀察進程。當所有框都打勾時，您可以繼續在 Cloud Shell 中觀看日志。

進程完成時，狀態將為 **Succeeded**。

**測試已完成任務**

點擊 **檢查我的進度** 來驗證您的已執行任務。如果您已成功完成任務，您將獲得評估分數。

遠程運行示例 Pipeline。

3. 點擊 **導航選單** > Cloud Console 中的 **Cloud Storage**。
4. 點擊您的 bucket 名稱。在您的 bucket 中，您應該會看到 **results** 和 **staging** 目錄。
5. 點擊 **results** 文件夾，您應該會看到您的作業創建的輸出文件：
6. 點擊文件來查看其包含的單詞計數。

### 步驟 7: 測試您的理解

以下是強化您對此實驗室概念理解的多選題。請盡您所能回答。

Dataflow temp_location 必須是有效的 Cloud Storage URL。

- [x] True
- [ ] False

## 驗證
要驗證實驗室已成功完成：

1. 檢查 Dataflow 作業狀態為 **Succeeded**
2. 確認 Cloud Storage bucket 中存在 results 和 staging 目錄
3. 驗證輸出文件包含預期的單詞計數結果

## 故障排除
常見問題和解決方案：

- **Docker 容器問題**：確保您有權限運行 Docker 命令
- **pip 安裝失敗**：檢查網絡連接和 Python 版本兼容性
- **Dataflow 作業失敗**：檢查項目配額、權限和區域設置
- **Cloud Storage 訪問問題**：驗證 bucket 名稱和權限

## 清理
要清理資源並避免費用：

1. 刪除 Cloud Storage bucket：
```bash
gsutil rm -r gs://<your-bucket-name>
```

2. 如果創建了任何其他資源，請確保將其刪除

## 額外資源
- [Apache Beam 文檔](https://beam.apache.org/)
- [Google Cloud Dataflow 文檔](https://cloud.google.com/dataflow/docs)
- [Python Apache Beam SDK 文檔](https://beam.apache.org/documentation/sdks/python/)
- [Cloud Storage 文檔](https://cloud.google.com/storage/docs)

## 筆記
- Apache Beam 是一個開源的數據管道編程模型
- Dataflow 是 Google Cloud 上托管的 Apache Beam 運行器
- 始終使用 staging_location 和 temp_location 來存儲臨時文件
- 遠程運行時使用 DataflowRunner 而不是 DirectRunner
