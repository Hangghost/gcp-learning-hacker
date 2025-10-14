# GSP007 - 設置網路負載平衡器

## 實驗概述
在本實作實驗中，您將學習如何設置運行在 Compute Engine 虛擬機器 (VM) 上的直通網路負載平衡器 (NLB)。第 4 層 (L4) NLB 基於網路級別資訊（如 IP 位址和連接埠號碼）處理流量，而不會檢查流量的內容。

Google Cloud 上有多種[負載平衡方式](https://cloud.google.com/load-balancing/docs/load-balancing-overview#a_closer_look_at_cloud_load_balancers)。本實驗將引導您設置以下負載平衡器：

- [網路負載平衡器](https://cloud.google.com/compute/docs/load-balancing/network/)

建議您親自輸入命令，這有助於學習核心概念。許多實驗都包含一個包含所需命令的程式碼區塊。您可以輕鬆地將程式碼區塊中的命令複製並貼上到實驗中的適當位置。

## 先決條件
- Google Cloud Platform 帳戶
- 基本熟悉 Google Cloud Console
- 了解 Compute Engine 虛擬機器的基本概念
- 熟悉 Linux 命令列操作

## 實驗目標
完成本實驗後，您將能夠：
- 為您的資源配置預設區域和區域
- 創建多個 Web 伺服器實例
- 配置負載平衡服務
- 配置轉發規則以分配流量

## 預估時間
45-60 分鐘

## 實驗步驟

### 步驟 1：為所有資源設置預設區域和區域
在本任務中，您將設置 Google Cloud 資源的預設區域和區域。

**指令：**
1. 設置預設區域：
   ```bash
   gcloud config set compute/region Region
   ```

2. 在 Cloud Shell 中設置預設區域：
   ```bash
   gcloud config set compute/zone Zone
   ```

   了解更多關於在 Compute Engine 中選擇區域和區域的資訊，請參閱[區域和區域](https://cloud.google.com/compute/docs/zones)文檔。

**預期結果：**
預設區域和區域已成功設置。

### 步驟 2：創建多個 Web 伺服器實例
對於此負載平衡場景，您將創建三個 Compute Engine VM 實例並在它們上安裝 Apache，然後添加一個允許 HTTP 流量到達實例的防火牆規則。

提供的程式碼將區域設置為 `Zone`。設置 `tags` 欄位可讓您一次引用所有這些實例，例如使用防火牆規則。這些命令還在每個實例上安裝 Apache，並為每個實例提供唯一的首頁。

**指令：**
1. 使用以下程式碼在您的預設區域中創建虛擬機器 `www1`：
   ```bash
   gcloud compute instances create www1 \
     --zone=Zone \
     --tags=network-lb-tag \
     --machine-type=e2-small \
     --image-family=debian-11 \
     --image-project=debian-cloud \
     --metadata=startup-script='#!/bin/bash
       apt-get update
       apt-get install apache2 -y
       service apache2 restart
       echo "
   <h3>Web Server: www1</h3>" | tee /var/www/html/index.html'
   ```

2. 使用以下程式碼在您的預設區域中創建虛擬機器 `www2`：
   ```bash
   gcloud compute instances create www2 \
     --zone=Zone \
     --tags=network-lb-tag \
     --machine-type=e2-small \
     --image-family=debian-11 \
     --image-project=debian-cloud \
     --metadata=startup-script='#!/bin/bash
       apt-get update
       apt-get install apache2 -y
       service apache2 restart
       echo "
   <h3>Web Server: www2</h3>" | tee /var/www/html/index.html'
   ```

3. 創建虛擬機器 `www3`：
   ```bash
   gcloud compute instances create www3 \
     --zone=Zone  \
     --tags=network-lb-tag \
     --machine-type=e2-small \
     --image-family=debian-11 \
     --image-project=debian-cloud \
     --metadata=startup-script='#!/bin/bash
       apt-get update
       apt-get install apache2 -y
       service apache2 restart
       echo "
   <h3>Web Server: www3</h3>" | tee /var/www/html/index.html'
   ```

4. 創建防火牆規則以允許外部流量到達 VM 實例：
   ```bash
   gcloud compute firewall-rules create www-firewall-network-lb \
       --target-tags network-lb-tag --allow tcp:80
   ```

現在您需要獲取實例的外部 IP 位址並驗證它們正在運行。

5. 運行以下命令列出您的實例。您將在 `EXTERNAL_IP` 欄中看到它們的 IP 位址：
   ```bash
   gcloud compute instances list
   ```

6. 使用 `curl` 驗證每個實例正在運行，將 **[IP_ADDRESS]** 替換為每個 VM 的外部 IP 位址：
   ```bash
   curl http://[IP_ADDRESS]
   ```

**預期結果：**
已成功創建三個 Web 伺服器實例，並且防火牆規則允許 HTTP 流量。

### 步驟 3：配置負載平衡服務
配置負載平衡服務時，您的虛擬機器實例將接收發送到您配置的靜態外部 IP 位址的封包。使用 Compute Engine 映像製作的實例會自動配置為處理此 IP 位址。

**注意：** 從[後端服務型外部直通網路負載平衡器概述](https://cloud.google.com/compute/docs/load-balancing/network/)指南中了解更多關於設置網路負載平衡的資訊。

**指令：**
1. 為您的負載平衡器創建靜態外部 IP 位址：
   ```bash
   gcloud compute addresses create network-lb-ip-1 \
     --region Region
   ```

2. 添加舊版 HTTP 健康檢查資源：
   ```bash
   gcloud compute http-health-checks create basic-check
   ```

**預期結果：**
已創建靜態外部 IP 位址和 HTTP 健康檢查。

### 步驟 4：創建目標池和轉發規則
目標池是接收來自外部直通 NLB 傳入流量的後端實例組。目標池的所有後端實例必須位於同一 Google Cloud 區域中。

**指令：**
1. 運行以下命令創建目標池並使用健康檢查，這對於服務正常運行是必需的：
   ```bash
   gcloud compute target-pools create www-pool \
     --region Region --http-health-check basic-check
   ```

2. 將您之前創建的實例添加到池中：
   ```bash
   gcloud compute target-pools add-instances www-pool \
       --instances www1,www2,www3
   ```

接下來您將製作[轉發規則](https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts)。轉發規則指定如何將網路流量路由到負載平衡器的後端服務。

3. 添加轉發規則：
   ```bash
   gcloud compute forwarding-rules create www-rule \
       --region  Region \
       --ports 80 \
       --address network-lb-ip-1 \
       --target-pool www-pool
   ```

**預期結果：**
已成功創建目標池和轉發規則。

### 步驟 5：向您的實例發送流量
現在負載平衡服務已配置，您可以開始向轉發規則發送流量，並觀察流量如何分散到不同的實例。

**指令：**
1. 輸入以下命令以查看負載平衡器使用的 www-rule 轉發規則的外部 IP 位址：
   ```bash
   gcloud compute forwarding-rules describe www-rule --region Region
   ```

2. 訪問外部 IP 位址：
   ```bash
   IPADDRESS=$(gcloud compute forwarding-rules describe www-rule --region Region --format="json" | jq -r .IPAddress)
   ```

3. 顯示外部 IP 位址：
   ```bash
   echo $IPADDRESS
   ```

4. 使用 `curl` 命令訪問外部 IP 位址，將 `IP_ADDRESS` 替換為上一命令中的外部 IP 位址：
   ```bash
   while true; do curl -m1 $IPADDRESS; done
   ```

   `curl` 命令的回應會在三個實例之間隨機交替。如果您的回應最初不成功，請等待約 30 秒讓配置完全載入並讓您的實例被標記為健康，然後再試一次。

5. 使用 **Ctrl** + **C** 停止運行命令。

**預期結果：**
流量成功分散到三個 Web 伺服器實例。

## 驗證
要驗證實驗已成功完成：
1. 確認所有三個 VM 實例正在運行
2. 確認防火牆規則允許 HTTP 流量
3. 確認負載平衡器 IP 位址可訪問
4. 確認流量在實例之間正確分散

## 故障排除
常見問題及其解決方案：
- **實例無法訪問**：檢查防火牆規則是否正確應用到實例標籤
- **負載平衡器無法路由流量**：確保健康檢查通過且實例被標記為健康
- **curl 命令失敗**：等待 30 秒讓配置完全載入
- **IP 位址未分配**：檢查區域配置是否正確

## 清理
為避免費用，請按照以下步驟清理資源：
1. 刪除轉發規則：
   ```bash
   gcloud compute forwarding-rules delete www-rule --region Region --quiet
   ```

2. 刪除目標池：
   ```bash
   gcloud compute target-pools delete www-pool --region Region --quiet
   ```

3. 刪除實例：
   ```bash
   gcloud compute instances delete www1 www2 www3 --zone Zone --quiet
   ```

4. 刪除防火牆規則：
   ```bash
   gcloud compute firewall-rules delete www-firewall-network-lb --quiet
   ```

5. 刪除靜態 IP 位址：
   ```bash
   gcloud compute addresses delete network-lb-ip-1 --region Region --quiet
   ```

6. 刪除健康檢查：
   ```bash
   gcloud compute http-health-checks delete basic-check --quiet
   ```

## 其他資源
- [網路負載平衡文檔](https://cloud.google.com/compute/docs/load-balancing/network/)
- [負載平衡概述](https://cloud.google.com/load-balancing/docs/load-balancing-overview)
- [Compute Engine 區域和區域](https://cloud.google.com/compute/docs/zones)
- [轉發規則概念](https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts)

## 筆記
此實驗演示了如何設置基本的網路負載平衡器。關鍵學習點包括：
- 網路負載平衡器在第 4 層運行
- 目標池用於管理後端實例
- 健康檢查確保只有健康的實例接收流量
- 轉發規則將流量路由到負載平衡器
