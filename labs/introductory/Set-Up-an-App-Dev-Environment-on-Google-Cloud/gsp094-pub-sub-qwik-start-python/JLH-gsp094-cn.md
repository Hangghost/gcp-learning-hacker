# GSP094 - Pub/Sub: Qwik Start - Python

## 實驗概述

Pub/Sub 服務允許應用程序以可靠、快速且非同步的方式交換消息。為了實現這一點，數據生產者將消息發布到 Cloud Pub/Sub 主題。然後訂閱者客戶端為該主題創建訂閱，並從訂閱中消費消息。Cloud Pub/Sub 會保留無法可靠傳遞的消息長達七天。

在此實驗中，您將學習如何使用 Python 客戶端庫開始發布消息與 Pub/Sub。

## 學習目標

完成此實驗後，您將能夠：
- 學習 Pub/Sub 的基本概念
- 使用 Python 創建、刪除和列出 Pub/Sub 主題和訂閱
- 將消息發布到主題
- 使用拉取訂閱者輸出個別主題消息

## 預估時間

45 分鐘

## 事前準備

- Google Cloud Platform 帳戶
- 基本的命令行知識
- Python 基礎知識

## 實驗步驟

### 任務 1：創建虛擬環境

Python 虛擬環境用於將軟件包安裝與系統隔離。

1. 安裝 `virtualenv` 環境：

```bash
sudo apt-get install -y virtualenv
```

2. 建置虛擬環境：

```bash
python3 -m venv venv
```

3. 啟動虛擬環境：

```bash
source venv/bin/activate
```

### 任務 2：安裝客戶端庫

1. 運行以下命令安裝客戶端庫：

```bash
pip install --upgrade google-cloud-pubsub
```

2. 通過克隆 GitHub 存儲庫獲取示例代碼：

```bash
git clone https://github.com/googleapis/python-pubsub.git
```

3. 導航到目錄：

```bash
cd python-pubsub/samples/snippets
```

### 任務 3：Pub/Sub 基礎概念

Pub/Sub 是一個非同步的全局消息服務。有三個在 Pub/Sub 中經常出現的術語：**主題**、**發布** 和 **訂閱**。

- **主題**：是一個共享字符串，允許應用程序通過共同線程相互連接。
- **發布者**：推送（或發布）消息到 Pub/Sub 主題。
- **訂閱者**：為主題創建**訂閱**，從中接收消息。

總之，發布者創建並發送消息到主題，訂閱者為主題創建訂閱以從中接收消息。

### Pub/Sub 在 Google Cloud 中的實現

Pub/Sub 預先安裝在 Cloud Shell 中，因此無需安裝或配置即可開始使用此服務。在此實驗中，您將使用 Python 創建主題、訂閱者，然後查看消息。您將使用 gcloud 命令將消息發布到主題。

### 任務 4：創建主題

要將數據發布到 Pub/Sub，您需要創建一個主題，然後配置一個發布者連接到該主題。

1. 在 Cloud Shell 中，您的項目 ID 應自動存儲在環境變數 `GOOGLE_CLOUD_PROJECT` 中：

```bash
echo $GOOGLE_CLOUD_PROJECT
```

輸出應與 CONNECTION DETAILS 中的項目 ID 相同。

2. 查看 publisher 腳本的內容：

```bash
cat publisher.py
```

**注意：** 或者，您可以使用安裝在 Cloud Shell 上的 shell 編輯器，例如 nano 或 vim，或使用 Cloud Shell 代碼編輯器查看 `python-pubsub/samples/snippets/publisher.py`。

3. 查看 publisher 腳本的幫助信息：

```bash
python publisher.py -h
```

4. 運行 publisher 腳本創建 Pub/Sub 主題：

```bash
python publisher.py $GOOGLE_CLOUD_PROJECT create MyTopic
```

**預期輸出：**
```
Topic created: name: "projects/qwiklabs-gcp-fe27729bc161fb22/topics/MyTopic"
```

**驗證任務完成**

點擊 **Check my progress** 驗證您的任務。如果您已成功創建 Cloud Pub/Sub 主題，您將看到評估分數。

創建主題。

5. 此命令返回給定項目中所有 Pub/Sub 主題的列表：

```bash
python publisher.py $GOOGLE_CLOUD_PROJECT list
```

**預期輸出：**
```
name: "projects/qwiklabs-gcp-fe27729bc161fb22/topics/MyTopic"
```

您還可以在 Cloud Console 中查看剛剛創建的主題。

6. 導航到 **Navigation menu** > **Pub/Sub** > **Topics**。

您應該看到 `MyTopic`。

### 任務 5：創建訂閱

1. 使用 `subscriber.py` 腳本為主題創建 Pub/Sub 訂閱：

```bash
python subscriber.py $GOOGLE_CLOUD_PROJECT create MyTopic MySub
```

**驗證任務完成**

點擊 **Check my progress** 驗證您的任務。如果您已成功創建 Cloud Pub/Sub 訂閱，您將看到評估分數。

創建訂閱。

2. 此命令返回給定項目中訂閱者的列表：

```bash
python subscriber.py $GOOGLE_CLOUD_PROJECT list-in-project
```

您只會看到一個訂閱，因為您只創建了一個訂閱。

**預期輸出：**
```
projects/qwiklabs-gcp-7877af129f04d8b3/subscriptions/MySub
```

3. 查看您剛創建的訂閱。在左側窗格中，點擊 **Subscriptions**。您應該看到訂閱名稱和其他詳細信息。

4. 查看 `subscriber` 腳本的幫助信息：

```bash
python subscriber.py -h
```

### 任務 6：發布消息

現在您已經設置了 `MyTopic`（主題）和對 `MyTopic` 的訂閱（`MySub`），使用 `gcloud` 命令將消息發布到 `MyTopic`。

1. 將消息 "Hello" 發布到 `MyTopic`：

```bash
gcloud pubsub topics publish MyTopic --message "Hello"
```

2. 將更多消息發布到 `MyTopic`——運行以下命令（將 <YOUR NAME> 替換為您的姓名，將 <FOOD> 替換為您喜歡吃的食物）：

```bash
gcloud pubsub topics publish MyTopic --message "Publisher's name is <YOUR NAME>"
gcloud pubsub topics publish MyTopic --message "Publisher likes to eat <FOOD>"
gcloud pubsub topics publish MyTopic --message "Publisher thinks Pub/Sub is awesome"
```

### 任務 7：查看消息

現在您已經將消息發布到 MyTopic，使用 MySub 拉取並查看消息。

1. 使用 MySub 從 MyTopic 拉取消息：

```bash
python subscriber.py $GOOGLE_CLOUD_PROJECT receive MySub
```

**預期輸出：**
```
Listening for messages on projects/qwiklabs-gcp-7877af129f04d8b3/subscriptions/MySub
Received message: Message {
  data: 'Publisher thinks Pub/Sub is awesome'
  attributes: {}
}
Received message: Message {
  data: 'Hello'
  attributes: {}
}
Received message: Message {
  data: "Publisher's name is Harry"
  attributes: {}
}
Received message: Message {
  data: 'Publisher likes to eat cheese'
  attributes: {}
}
```

2. 按 **Ctrl**+**c** 停止監聽。

### 任務 8：測試您的理解

以下是多選題，用於強化您對此實驗概念的理解。請盡可能回答。

Google Cloud Pub/Sub 服務允許應用程序以可靠、快速且非同步的方式交換消息。

- [x] True
- [ ] False

_____ 是允許應用程序通過共同線程相互連接的共享字符串。

- [ ] subscription
- [x] topic
- [ ] message

## 驗證

要驗證實驗是否成功完成：

1. 確認您已成功創建主題 `MyTopic`
2. 確認您已成功創建訂閱 `MySub`
3. 確認您能夠發布消息到主題
4. 確認您能夠從訂閱接收消息

## 故障排除

### 常見問題

- **虛擬環境激活失敗**：確保使用 `python3 -m venv venv` 而不是 `virtualenv venv`
- **pip 安裝失敗**：確保虛擬環境已激活（提示符應顯示 `(venv)`）
- **主題創建失敗**：檢查項目 ID 是否正確設置
- **消息發布失敗**：確保主題名稱拼寫正確
- **無法接收消息**：確保訂閱正確連接到主題

### 錯誤消息和解決方案

- **"Topic already exists"**：使用不同的主題名稱或先刪除現有主題
- **"Subscription already exists"**：使用不同的訂閱名稱或先刪除現有訂閱
- **"Permission denied"**：確保您有足夠的 IAM 權限

## 清理

為避免產生不必要的費用，請按照以下步驟清理資源：

1. 刪除訂閱：
```bash
python subscriber.py $GOOGLE_CLOUD_PROJECT delete MyTopic MySub
```

2. 刪除主題：
```bash
python publisher.py $GOOGLE_CLOUD_PROJECT delete MyTopic
```

3. 退出虛擬環境：
```bash
deactivate
```

4. 刪除虛擬環境（可選）：
```bash
rm -rf venv
```

## 額外資源

- [Pub/Sub 官方文檔](https://cloud.google.com/pubsub/docs)
- [Pub/Sub Python 客戶端庫](https://googleapis.dev/python/pubsub/latest/index.html)
- [Pub/Sub Lite：另一個消息服務選項](https://cloud.google.com/pubsub/docs/choosing-pubsub-or-lite)


## 下一步

恭喜！您已使用 Python 創建了 Pub/Sub 主題、發布到主題、創建了訂閱，然後使用訂閱從主題拉取數據。

補充 Pub/Sub 的 [Pub/Sub Lite](https://cloud.google.com/pubsub/docs/choosing-pubsub-or-lite) 是一個區域服務，用於具有可預測流量模式的訊息系統。如果您每秒發布 1 MiB-1 GiB 的消息，Pub/Sub Lite 是高容量事件攝取的低成本選項。

## 個人筆記

- Pub/Sub 是 Google Cloud 的完全託管消息服務
- 支持全球分佈和自動擴展
- 消息保留期限最長為 7 天
- 支持推送和拉取兩種訂閱模式
- Python 客戶端庫提供了完整的功能支持
