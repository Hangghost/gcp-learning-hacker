# GSP095 - Pub/Sub: Qwik Start - Command Line

## 實驗概述

Pub/Sub 是用於在應用程式和服務之間交換事件資料的訊息服務。通過解耦發送者和接收者，它允許在獨立編寫的應用程式之間進行安全且高度可用的通訊。Pub/Sub 提供低延遲/耐用訊息，並且通常被開發人員用於實作非同步工作流程、分發事件通知以及從各種流程或設備串流資料。

## 學習目標

在本實驗中，您將學習：

- 創建、刪除和列出 Pub/Sub 主題和訂閱
- 向主題發佈訊息
- 使用拉取訂閱者

## 先決條件

這是一個**入門級**實驗。本實驗假設您對 Pub/Sub 沒有或很少有經驗，並將教您此 Google Cloud 服務的基本設定和使用方法。

## 估計時間

約 30 分鐘

## 實驗步驟

### 任務 1：Pub/Sub 主題

Pub/Sub 預先安裝在 Cloud Shell 中，因此無需安裝或配置即可開始使用此服務。

1. 運行以下命令創建名為 `myTopic` 的主題：

```bash
gcloud pubsub topics create myTopic
```

**測試已完成任務**

點擊**檢查我的進度**來驗證您的執行任務。如果您成功完成了任務，將獲得評估分數。

創建 Pub/Sub 主題。

2. 為了保險起見，再創建兩個主題；一個叫 `Test1`，另一個叫 `Test2`：

```bash
gcloud pubsub topics create Test1
gcloud pubsub topics create Test2
```

3. 要查看剛剛創建的三個主題，請運行以下命令：

```bash
gcloud pubsub topics list
```

您的輸出應該類似於以下內容：

```
---
messageStoragePolicy:
  allowedPersistenceRegions:
  - us-central1
name: projects/qwiklabs-gcp-01-af5b4aaa2d32/topics/myTopic
---
messageStoragePolicy:
  allowedPersistenceRegions:
  - us-central1
name: projects/qwiklabs-gcp-01-af5b4aaa2d32/topics/Test1
---
messageStoragePolicy:
  allowedPersistenceRegions:
  - us-central1
name: projects/qwiklabs-gcp-01-af5b4aaa2d32/topics/Test2
```

4. 現在清理一下。通過運行以下命令刪除 `Test1` 和 `Test2`：

```bash
gcloud pubsub topics delete Test1
gcloud pubsub topics delete Test2
```

5. 再次運行 `gcloud pubsub topics list` 命令來驗證主題已被刪除：

```bash
gcloud pubsub topics list
```

您應該獲得以下輸出：

```
---
name: projects/qwiklabs-gcp-3450558d2b043890/topics/myTopic
```

### 任務 2：Pub/Sub 訂閱

現在您已經熟悉創建、查看和刪除主題，是時候處理訂閱了。

1. 運行以下命令為主題 `myTopic` 創建名為 `mySubscription` 的訂閱：

```bash
gcloud pubsub subscriptions create --topic myTopic mySubscription
```

**測試已完成任務**

點擊**檢查我的進度**來驗證您的執行任務。如果您成功完成了任務，將獲得評估分數。

創建 Pub/Sub 訂閱。

2. 為 `myTopic` 添加另外兩個訂閱。運行以下命令來創建 `Test1` 和 `Test2` 訂閱：

```bash
gcloud pubsub subscriptions create --topic myTopic Test1
gcloud pubsub subscriptions create --topic myTopic Test2
```

3. 運行以下命令列出 myTopic 的訂閱：

```bash
gcloud pubsub topics list-subscriptions myTopic
```

您的輸出應該類似於以下內容：

```
-- projects/qwiklabs-gcp-3450558d2b043890/subscriptions/Test2
--- projects/qwiklabs-gcp-3450558d2b043890/subscriptions/Test1
--- projects/qwiklabs-gcp-3450558d2b043890/subscriptions/mySubscription
```

**測試您的理解**

以下是多項選擇題，用於強化您對本實驗概念的理解。請盡您所能回答。

要接收發佈到主題的訊息，您必須為該主題創建訂閱。對/錯

4. 現在刪除 `Test1` 和 `Test2` 訂閱。運行以下命令：

```bash
gcloud pubsub subscriptions delete Test1
gcloud pubsub subscriptions delete Test2
```

5. 檢查 `Test1` 和 `Test2` 訂閱是否已被刪除。再運行一次 `list-subscriptions` 命令：

```bash
gcloud pubsub topics list-subscriptions myTopic
```

您應該獲得以下輸出：

```
-- projects/qwiklabs-gcp-3450558d2b043890/subscriptions/mySubscription
```

### 任務 3：Pub/Sub 發佈和拉取單一訊息

接下來您將學習如何向 Pub/Sub 主題發佈訊息。

1. 運行以下命令向您之前創建的主題 (`myTopic`) 發佈訊息 `"Hello"`：

```bash
gcloud pubsub topics publish myTopic --message "Hello"
```

2. 向 `myTopic` 發佈更多訊息。運行以下命令（將 `<YOUR NAME>` 替換為您的姓名，將 `<FOOD>` 替換為您喜歡吃的食物）：

```bash
gcloud pubsub topics publish myTopic --message "Publisher's name is <YOUR NAME>"
gcloud pubsub topics publish myTopic --message "Publisher likes to eat <FOOD>"
gcloud pubsub topics publish myTopic --message "Publisher thinks Pub/Sub is awesome"
```

接下來，使用 `pull` 命令從您的主題獲取訊息。pull 命令是基於訂閱的，這應該有效，因為您之前為主題 `myTopic` 設定了訂閱 `mySubscription`。

3. 使用以下命令從 Pub/Sub 主題拉取您剛剛發佈的訊息：

```bash
gcloud pubsub subscriptions pull mySubscription --auto-ack
```

您的輸出應該類似於以下內容：

```
Data: Publisher likes to eat <FOOD>
Message ID: 123456789012345
Attributes:
```

這裡發生了什麼？您向主題發佈了 4 條訊息，但只輸出了 1 條。

現在是提及 `pull` 命令的一些功能的重要時機，這些功能經常讓開發人員感到困惑：

- **使用不帶任何標誌的 pull 命令只會輸出一個訊息，即使您訂閱的主題中有更多訊息保留在其中。**
- **一旦從特定的訂閱-based pull 命令輸出了單個訊息，您就無法再次使用 pull 命令訪問該訊息。**

4. 要查看第二個要點在說什麼，再運行最後一個命令三次。您將看到它會輸出您發佈的其他訊息之前。
5. 現在，第 4 次運行命令。您將獲得以下輸出（因為沒有剩餘的訊息可以返回）：

```bash
Listed 0 items.
```

在最後一節中，您將學習如何使用 `flag` 從主題拉取多個訊息。

### 任務 4：從訂閱拉取所有訊息

由於您在上一個示例中從主題拉取了所有訊息，請用更多訊息填充 `myTopic`。

1. 運行以下命令：

```bash
gcloud pubsub topics publish myTopic --message "Publisher is starting to get the hang of Pub/Sub"
gcloud pubsub topics publish myTopic --message "Publisher wonders if all messages will be pulled"
gcloud pubsub topics publish myTopic --message "Publisher will have to test to find out"
```

2. 向您的命令添加 `flag`，以便您可以在一個請求中輸出所有三個訊息。

您可能沒有注意到，但您實際上一直在使用標誌：`pull` 命令的 `--auto-ack` 部分是一個標誌，它將您的訊息格式化為您在拉取的訊息中看到的整齊框。

`limit` 是另一個標誌，用於設定要拉取的訊息數量的上限。

3. 等一分鐘讓主題創建完成。使用 `limit` 標誌運行 pull 命令：

```bash
gcloud pubsub subscriptions pull mySubscription --limit=3
```

您的輸出應該匹配以下內容：

```
Data: Publisher is starting to get the hang of Pub/Sub
Message ID: 123456789012345
Attributes:
---
Data: Publisher wonders if all messages will be pulled
Message ID: 123456789012346
Attributes:
---
Data: Publisher will have to test to find out
Message ID: 123456789012347
Attributes:
```

現在您知道如何向 Pub/Sub 命令添加標誌來輸出更大的訊息池。您正走在成為 Pub/Sub 大師的路上。

## 驗證

要驗證實驗是否成功完成：

1. 確保所有主題和訂閱都已正確創建和刪除
2. 確認訊息發佈和拉取功能正常工作
3. 驗證 `--limit` 標誌正確拉取多個訊息

## 故障排除

常見問題和解決方案：

- **權限錯誤**：確保您有足夠的 Pub/Sub 權限
- **主題不存在**：在創建訂閱之前先創建主題
- **訊息拉取失敗**：檢查訂閱是否正確綁定到主題
- **命令語法錯誤**：仔細檢查 gcloud 命令的參數和標誌

## 清理

為了避免產生費用，請清理資源：

1. 刪除所有測試主題：

```bash
gcloud pubsub topics delete myTopic
```

2. 驗證清理：

```bash
gcloud pubsub topics list
gcloud pubsub subscriptions list
```

## 額外資源

- [Pub/Sub 官方文檔](https://cloud.google.com/pubsub/docs)
- [Pub/Sub 架構](https://cloud.google.com/pubsub/docs/overview)
- [Pub/Sub 快速入門](https://cloud.google.com/pubsub/docs/quickstart)
- 相關實驗：GSP096 - Pub/Sub: Qwik Start - Console

## 筆記

Pub/Sub 是 Google Cloud 的強大訊息服務，適合用於解耦應用程式組件和處理事件驅動架構。掌握基本的主題、訂閱和訊息處理是進一步學習的基礎。
