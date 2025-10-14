# GSP089 - Cloud Monitoring: Qwik Start

## 簡介
Cloud Monitoring 提供對雲端應用程式效能、正常運行時間和整體健康的能見度。Cloud Monitoring 從 Google Cloud、Amazon Web Services、託管正常運行時間探針、應用程式檢測以及各種常見應用程式元件（包括 Cassandra、Nginx、Apache Web Server、Elasticsearch 等）收集指標、事件和中繼資料。Cloud Monitoring 會擷取這些資料，並通過儀表板、圖表和警報產生洞察。Cloud Monitoring 警報通過與 Slack、PagerDuty、HipChat、Campfire 等整合來幫助您協作。

在本實驗室中，您將安裝監控和日誌記錄代理程式來從您的實例收集資訊，這可能包括來自第三方應用程式的指標和日誌。

## 先決條件
- Google Cloud Platform 帳戶
- 基本 GCP 知識
- 熟悉 Linux 命令列

## 學習目標
在本實驗室中，您將學習如何：
- 使用 Cloud Monitoring 監控 Compute Engine 虛擬機器 (VM) 實例。
- 為您的 VM 安裝監控和日誌記錄代理程式

## 預估時間
45 分鐘

## 步驟

### 任務 1：設定您的區域和區域

某些 Compute Engine 資源存在於區域和區域中。區域是您可以運行資源的特定地理位置。每個區域都有一個或多個區域。

**注意**：在[區域和區域文件](https://cloud.google.com/compute/docs/regions-zones/)中了解更多關於區域和區域的資訊，並查看完整列表。

在 Cloud Shell 中運行以下 gcloud 命令來為您的實驗室設定預設區域和區域：

```bash
gcloud config set compute/zone "ZONE"
export ZONE=$(gcloud config get compute/zone)

gcloud config set compute/region "REGION"
export REGION=$(gcloud config get compute/region)
```

### 任務 2：創建 Compute Engine 實例

1. 在 **Cloud Console** 中，按一下 **導航選單** (☰)，然後按一下 **Compute Engine** > **VM 實例**，再按一下 **創建實例**。

2. 在 **機器配置** 中

   輸入以下欄位的值：

   | **欄位** | **值** |
   | --- | --- |
   | **名稱** | `lamp-1-vm` |
   | **區域** | `<REGION>` |
   | **區域** | `<ZONE>` |
   | **系列** | `E2` |
   | **機器** | `e2-medium` |

3. 按一下 **作業系統和儲存**：

   選擇開機磁碟：
   - **開機磁碟**：Debian GNU/Linux 12 (bookworm)

4. 按一下 **網路**：

   選擇防火牆：
   - **防火牆**：允許 HTTP 流量

5. 設定所有區段後，向下捲動並按一下 **創建** 以啟動您的新虛擬機器實例。

   等待幾分鐘，您會看到綠色勾選表示實例已啟動。

### 任務 3：為您的實例新增 Apache2 HTTP Server

1. 在 Console 中，按一下 `lamp-1-vm` 旁的 **SSH** 以開啟到您的實例的終端機。

2. 在 SSH 視窗中運行以下命令來設定 Apache2 HTTP Server：

```bash
sudo apt-get update
sudo apt-get install apache2 php7.0
```

3. 當詢問是否要繼續時，輸入 **Y**。

**注意**：如果無法安裝 php7.0，請使用 php5。

```bash
sudo service apache2 restart
```

4. 返回 Cloud Console，在 VM 實例頁面中。按一下 `lamp-1-vm` 實例的 **外部 IP** 以查看此實例的 Apache2 預設頁面。

**注意**：如果找不到 **外部 IP** 欄位，請按一下右上角的 **欄位顯示選項** 圖示，選取 **外部 IP** 核取方塊，然後按一下 **確定**。

### 任務 4：創建監控指標範圍

設定與您的 Google Cloud 專案綁定的監控指標範圍。以下步驟創建一個具有監控免費試用版的新帳戶。

- 在 Cloud Console 中，按一下 **導航選單** () > 查看所有產品 > 可觀測性 > **監控**。

當監控 **概述** 頁面開啟時，您的指標範圍專案已準備就緒。

### 任務 5：安裝監控和日誌記錄代理程式

代理程式收集資料，然後將資訊發送到 Cloud Console 中的 Cloud Monitoring。

*Cloud Monitoring 代理程式* 是一個收集型精靈，它從虛擬機器實例收集系統和應用程式指標，並將它們發送到監控。預設情況下，監控代理程式收集磁碟、CPU、網路和處理程序指標。配置監控代理程式允許第三方應用程式獲取代理程式指標的完整列表。在 Google Cloud Operations 網站上，請參閱 [Cloud Monitoring 文件](https://cloud.google.com/monitoring/docs#) 了解更多資訊。

在本節中，您安裝 *Cloud Logging 代理程式* 以將日誌從您的 VM 實例串流到 Cloud Logging。稍後在本實驗室中，您將看到當您停止和啟動 VM 時會產生哪些日誌。

**注意**：最佳實務是在所有 VM 實例上運行 Cloud Logging 代理程式。

1. 在您的 VM 實例的 SSH 終端機中運行監控代理程式安裝腳本命令來安裝 Cloud Monitoring 代理程式：

```bash
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
```

2. 如果詢問是否要繼續，請按 **Y**。

3. 在您的 VM 實例的 SSH 終端機中運行日誌記錄代理程式安裝腳本命令來安裝 Cloud Logging 代理程式：

```bash
sudo systemctl status google-cloud-ops-agent"*"
```

按 **q** 退出狀態。

```bash
sudo apt-get update
```

### 任務 6：創建正常運行時間檢查

正常運行時間檢查驗證資源始終可存取。為了練習，創建一個正常運行時間檢查來驗證您的 VM 是否正常運行。

1. 在 Cloud Console 中，在左側選單中，按一下 **正常運行時間檢查**，然後按一下 **創建正常運行時間檢查**。

2. 對於 **協定**，選取 **HTTP**。

3. 對於 **資源類型**，選取 **實例**。

4. 對於 **實例**，選取 **lamp-1-vm**。

5. 對於 **檢查頻率**，選取 **1 分鐘**。

6. 按一下 **繼續**。

7. 在回應驗證中，接受預設值，然後按一下 **繼續**。

8. 在警報和通知中，接受預設值，然後按一下 **繼續**。

9. 對於標題，輸入 **Lamp Uptime Check**。

10. 按一下 **測試** 以驗證您的正常運行時間檢查是否可以連接到資源。

    當您看到綠色勾選時，一切都可以連接到。

11. 按一下 **創建**。

    您配置的正常運行時間檢查需要一些時間才能變為活動狀態。繼續進行實驗室，您稍後會檢查結果。在等待時，為不同資源創建警報政策。

### 任務 7：創建警報政策

使用 Cloud Monitoring 創建一個或多個警報政策。

1. 在左側選單中，按一下 **警報**，然後按一下 **+創建政策**。

2. 按一下 **選取指標** 下拉式選單。取消選取 **活動**。

3. 在按資源和指標名稱篩選中輸入 **Network traffic**，然後按一下 **VM instance > Interface**。選取 `Network traffic` (agent.googleapis.com/interface/traffic)，然後按一下 **套用**。將所有其他欄位保留為預設值。

4. 按一下 **下一步**。

5. 將 **閾值位置** 設定為 `Above threshold`，**閾值值** 設定為 `500`，並將 **進階選項 > 重新測試視窗** 設定為 `1 min`。按一下 **下一步**。

6. 按一下 **通知頻道** 旁的向下箭頭，然後按一下 **管理通知頻道**。

通知頻道頁面將在新分頁中開啟。

7. 向下捲動頁面，然後為 **Email** 按一下 **新增**。

8. 在 **創建電子郵件頻道** 對話方塊中，在 **電子郵件地址** 欄位中輸入您的個人電子郵件地址，並輸入 **顯示名稱**。

9. 按一下 **儲存**。

10. 返回先前的 **創建警報政策** 分頁。

11. 再次按一下 **通知頻道**，然後按一下 **重新整理圖示** 以獲取您在上一步中提到的顯示名稱。

12. 如有必要，再次按一下 **通知頻道**，選取您的 **顯示名稱**，然後按一下 **確定**。

13. 在文件中新增訊息，這將包含在電子郵件警報中。

14. 將 **警報名稱** 提及為 `Inbound Traffic Alert`。

15. 按一下 **下一步**。

16. 檢閱警報，然後按一下 **創建政策**。

您已創建警報！在等待系統觸發警報時，創建儀表板和圖表，然後查看 Cloud Logging。

### 任務 8：創建儀表板和圖表

您可以在自己的圖表和儀表板中顯示 Cloud Monitoring 收集的指標。在本節中，您為實驗室指標創建圖表和自訂儀表板。

1. 在左側選單中選取 **儀表板**，然後選取 **+創建自訂儀表板**。

2. 將儀表板命名為 `Cloud Monitoring LAMP Qwik Start Dashboard`。

#### 新增第一個圖表

1. 按一下 **+ 新增小工具**

2. 在 **新增小工具** 中選取 **Visualization** 下的 **Line** 選項。

3. 將小工具標題命名為 **CPU Load**。

4. 按一下 **選取指標** 下拉式選單。取消選取 **活動**。

5. 在按資源和指標名稱篩選中輸入 **CPU load (1m)**，然後按一下 **VM instance > Cpu**。選取 `CPU load (1m)`，然後按一下 **套用**。將所有其他欄位保留為預設值。重新整理分頁以查看圖表。

#### 新增第二個圖表

1. 按一下 **+ 新增小工具**，並在 **新增小工具** 中選取 **Visualization** 下的 **Line** 選項。

2. 將此小工具標題命名為 **Received Packets**。

3. 按一下 **選取指標** 下拉式選單。取消選取 **活動**。

4. 在按資源和指標名稱篩選中輸入 **Received packets**，然後按一下 **VM instance > Instance**。選取 `Received packets`，然後按一下 **套用**。重新整理分頁以查看圖表。

5. 將其他欄位保留為預設值。您會看到圖表資料。

### 任務 9：查看您的日誌

Cloud Monitoring 和 Cloud Logging 緊密整合。查看您實驗室的日誌。

1. 選取 **導航選單** > **記錄** > **記錄瀏覽器**。

2. 選取您要查看的日誌，在這種情況下，您選取在本實驗室開始時創建的 lamp-1-vm 實例的日誌：
   - 按一下 **所有資源**。
   - 在資源下拉式選單中選取 **VM Instance** > **lamp-1-vm**。
   - 按一下 **套用**。

在結果區段中，您可以看到 VM 實例的日誌。

#### 查看啟動和停止 VM 實例時會發生什麼

為了最好地查看 Cloud Monitoring 和 Cloud Logging 如何反映 VM 實例變更，請在一個瀏覽器視窗中對您的實例進行變更，然後查看 Cloud Monitoring，然後 Cloud Logging 視窗中會發生什麼。

1. 在新瀏覽器視窗中開啟 Compute Engine 視窗。選取 **導航選單** > **Compute Engine**，右鍵按一下 **VM instances** > **在新視窗中開啟連結**。

2. 將記錄檢視器瀏覽器視窗移到 Compute Engine 視窗旁邊。這使得查看 VM 變更如何反映在日誌中更容易。

3. 在 Compute Engine 視窗中，選取 `lamp-1-vm` 實例，按一下畫面右側的三個垂直點，然後按一下 **停止**，然後確認停止實例。

   實例停止需要幾分鐘。

4. 在記錄檢視分頁中監視 VM 何時停止。

5. 在 VM 實例詳細資料視窗中，按一下畫面右側的三個垂直點，然後按一下 **啟動/繼續**，然後確認。實例重新啟動需要幾分鐘。監視啟動的日誌訊息。

### 任務 10：檢查正常運行時間檢查結果和觸發的警報

1. 在 Cloud Logging 視窗中，選取 **導航選單** > **監控** > **正常運行時間檢查**。此視圖提供所有活動正常運行時間檢查的列表，以及每個檢查在不同位置的狀態。

   您會看到 Lamp Uptime Check 已列出。由於您剛剛重新啟動實例，區域處於失敗狀態。區域變為活動狀態可能需要長達 5 分鐘。必要時重新載入瀏覽器視窗，直到區域變為活動狀態。

2. 按一下正常運行時間檢查的名稱，`Lamp Uptime Check`。

   由於您剛剛重新啟動實例，區域變為活動狀態可能需要一些分鐘。必要時重新載入瀏覽器視窗。

#### 檢查是否已觸發警報

1. 在左側選單中，按一下 **警報**。

2. 您會在警報視窗中看到列出的事件和事件。

3. 檢查您的電子郵件帳戶。您應該會看到 Cloud Monitoring 警報。

**注意**：從您的警報政策中移除電子郵件通知。實驗室的資源在您完成後可能會保持活動一段時間，這可能會導致發送更多電子郵件通知。

## 驗證

要驗證實驗室已成功完成：

1. VM 實例 `lamp-1-vm` 正在運行並可通過其外部 IP 存取
2. 監控代理程式已安裝並運行
3. 日誌記錄代理程式已安裝並運行
4. 正常運行時間檢查已創建並處於活動狀態
5. 警報政策已創建
6. 自訂儀表板已創建並顯示指標
7. 日誌在 Cloud Logging 中可用

## 故障排除

常見問題和解決方案：

- **無法安裝 PHP7.0**：使用 `sudo apt-get install php5` 替代
- **代理程式安裝失敗**：確保您有足夠的權限並重新運行安裝命令
- **正常運行時間檢查失敗**：等待幾分鐘讓檢查變為活動狀態
- **圖表不顯示資料**：重新整理瀏覽器並確保代理程式正在運行

## 清理

要清理資源並避免費用：

1. 在 Cloud Console 中，前往 **Compute Engine** > **VM 實例**
2. 選取 `lamp-1-vm` 實例
3. 按一下 **刪除**
4. 在 **監控** 中刪除儀表板、警報政策和正常運行時間檢查

## 額外資源

- [Cloud Monitoring 文件](https://cloud.google.com/monitoring/docs)
- [Cloud Logging 文件](https://cloud.google.com/logging/docs)
- [Compute Engine 文件](https://cloud.google.com/compute/docs)
- 相關實驗室：GSP064 (Cloud IAM)

## 筆記

- 監控代理程式收集系統指標、日誌記錄代理程式收集應用程式日誌
- 正常運行時間檢查有助於監控服務可用性
- 警報政策可以根據指標自動通知
- 自訂儀表板有助於視覺化監控資料
