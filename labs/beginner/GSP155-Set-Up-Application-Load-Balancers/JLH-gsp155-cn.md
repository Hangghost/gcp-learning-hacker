# GSP155 - 設置應用程式負載平衡器

## 實驗概述
在本實作實驗中，您將學習如何設置運行在 Compute Engine 虛擬機器 (VM) 上的第 7 層 (L7) 應用程式負載平衡器。L7 負載平衡器能夠理解 HTTP(S) 協議，允許它們根據參數（如 URL、標頭、Cookie 和請求內容）做出路由決策。這允許改進應用程式效能和回應能力。

Google Cloud 上有多種[負載平衡方式](https://cloud.google.com/load-balancing/docs/load-balancing-overview#a_closer_look_at_cloud_load_balancers)。本實驗將引導您設置以下負載平衡器：

- [應用程式負載平衡器](https://cloud.google.com/compute/docs/load-balancing/http/)

建議您親自輸入命令，這有助於學習核心概念。許多實驗都包含一個包含所需命令的程式碼區塊。您可以輕鬆地將程式碼區塊中的命令複製並貼上到實驗中的適當位置。

## 先決條件
- Google Cloud Platform 帳戶
- 基本熟悉 Google Cloud Console
- 了解 Compute Engine 虛擬機器的基本概念
- 熟悉 Linux 命令列操作
- 了解負載平衡的基本概念

## 實驗目標
完成本實驗後，您將能夠：
- 為您的資源配置預設區域和區域
- 創建應用程式負載平衡器
- 測試發送到您的實例的流量

## 預估時間
60-75 分鐘

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

提供的程式碼設置區域為 `Zone`。設置 `tags` 欄位允許您一次引用這些實例，例如使用防火牆規則。這些命令還在每個實例上安裝 Apache，並為每個實例提供唯一的首頁。

**指令：**
1. 使用以下程式碼創建虛擬機 `www1`：
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

2. 使用以下程式碼創建虛擬機 `www2`：
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

3. 創建虛擬機 `www3`：
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

4. 創建允許外部流量到達 VM 實例的防火牆規則：
   ```bash
   gcloud compute firewall-rules create www-firewall-network-lb \
       --target-tags network-lb-tag --allow tcp:80
   ```

現在您需要獲取實例的外部 IP 位址並驗證它們正在運行。

1. 運行以下命令列出您的實例。您將在 `EXTERNAL_IP` 欄中看到它們的 IP 位址：
   ```bash
   gcloud compute instances list
   ```

2. 使用 `curl` 驗證每個實例是否正在運行，將 `[IP_ADDRESS]` 替換為每個 VM 的外部 IP 位址：
   ```bash
   curl http://[IP_ADDRESS]
   ```

**預期結果：**
三個 Web 伺服器實例已創建並正在運行，每個實例顯示其唯一的標識符。

### 步驟 3：創建應用程式負載平衡器
應用程式負載平衡在 Google Front End (GFE) 上實現。GFE 在全球分佈並與 Google 的全球網路和控制平面一起運作。您可以配置 URL 規則將某些 URL 路由到一個實例集，將其他 URL 路由到其他實例。

請求總是被路由到最接近用戶的實例組，如果該組有足夠的容量並適合請求。如果最接近的組沒有足夠的容量，請求將被發送到有容量的最接近組。

要使用 Compute Engine 後端設置負載平衡器，您的 VM 需要在實例組中。託管實例組為外部應用程式負載平衡器的後端伺服器提供 VM。對於此實驗，後端服務其自己的主機名。

**指令：**
1. 首先創建負載平衡器模板：
   ```bash
   gcloud compute instance-templates create lb-backend-template \
      --region=Region \
      --network=default \
      --subnet=default \
      --tags=allow-health-check \
      --machine-type=e2-medium \
      --image-family=debian-11 \
      --image-project=debian-cloud \
      --metadata=startup-script='#!/bin/bash
        apt-get update
        apt-get install apache2 -y
        a2ensite default-ssl
        a2enmod ssl
        vm_hostname="$(curl -H "Metadata-Flavor:Google" \
        http://169.254.169.254/computeMetadata/v1/instance/name)"
        echo "Page served from: $vm_hostname" | \
        tee /var/www/html/index.html
        systemctl restart apache2'
   ```

   [託管實例組](https://cloud.google.com/compute/docs/instance-groups) (MIG) 讓您可以在多個相同 VM 上運作應用。您可以利用自動 MIG 服務來使工作負載可擴展且高度可用，包括：自動擴展、自動修復、區域（多區域）部署，以及自動更新。

2. 基於模板創建託管實例組：
   ```bash
   gcloud compute instance-groups managed create lb-backend-group \
      --template=lb-backend-template --size=2 --zone=Zone
   ```

3. 創建 `fw-allow-health-check` 防火牆規則：
   ```bash
   gcloud compute firewall-rules create fw-allow-health-check \
     --network=default \
     --action=allow \
     --direction=ingress \
     --source-ranges=130.211.0.0/22,35.191.0.0/16 \
     --target-tags=allow-health-check \
     --rules=tcp:80
   ```

   **注意：**入口規則允許來自 Google Cloud 健康檢查系統的流量（`130.211.0.0/22` 和 `35.191.0.0/16`）。此實驗使用目標標籤 `allow-health-check` 來標識 VM。

4. 現在實例已啟動並運行，設置一個您的客戶用來訪問負載平衡器的全域靜態外部 IP 位址：
   ```bash
   gcloud compute addresses create lb-ipv4-1 \
     --ip-version=IPV4 \
     --global
   ```

   注意到已保留的 IPv4 位址：

   ```bash
   gcloud compute addresses describe lb-ipv4-1 \
     --format="get(address)" \
     --global
   ```

   **注意：**保存此 IP 位址，因為您稍後在本實驗中需要引用它。

5. 為負載平衡器創建健康檢查（確保只有健康的後端被發送流量）：
   ```bash
   gcloud compute health-checks create http http-basic-check \
     --port 80
   ```

6. 創建後端服務：
   ```bash
   gcloud compute backend-services create web-backend-service \
     --protocol=HTTP \
     --port-name=http \
     --health-checks=http-basic-check \
     --global
   ```

7. 將您的實例組添加為後端服務的後端：
   ```bash
   gcloud compute backend-services add-backend web-backend-service \
     --instance-group=lb-backend-group \
     --instance-group-zone=Zone \
     --global
   ```

8. 創建 [URL 映射](https://cloud.google.com/load-balancing/docs/url-map-concepts) 將傳入請求路由到預設後端服務：
   ```bash
   gcloud compute url-maps create web-map-http \
       --default-service web-backend-service
   ```

   **注意：**URL 映射是 Google Cloud 配置資源，用於將請求路由到後端服務或後端儲存桶。例如，使用外部應用程式負載平衡器，您可以對 URL 映射使用單一 URL 映射，以根據 URL 映射中配置的規則將請求路由到不同的目的地：

   - 針對 https://example.com/video 的請求轉到一個後端服務。
   - 針對 https://example.com/audio 的請求轉到不同的後端服務。
   - 針對 https://example.com/images 的請求轉到 Cloud Storage 後端儲存桶。
   - 針對任何其他主機和路徑組合的請求轉到預設後端服務。

9. 創建 [目標 HTTP 代理](https://cloud.google.com/load-balancing/docs/target-proxies) 將請求路由到您的 URL 映射：
   ```bash
   gcloud compute target-http-proxies create http-lb-proxy \
       --url-map web-map-http
   ```

10. 創建 [全域轉發規則](https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts) 將傳入請求路由到代理：
    ```bash
    gcloud compute forwarding-rules create http-content-rule \
       --address=lb-ipv4-1\
       --global \
       --target-http-proxy=http-lb-proxy \
       --ports=80
    ```

**注意：**[轉發規則](https://cloud.google.com/load-balancing/docs/using-forwarding-rules)以及其相應的 IP 位址代表 Google Cloud 負載平衡器的前端配置。從[轉發規則概述](https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts)指南中了解轉發規則的一般理解。

**預期結果：**
應用程式負載平衡器已創建，包括所有必要的元件（後端服務、URL 映射、代理和轉發規則）。

### 步驟 4：測試發送到您的實例的流量
現在您可以測試負載平衡器是否正常工作。

**指令：**
1. 在 Google Cloud 主控台上方的**搜尋**欄位中輸入**負載平衡**，然後從搜尋結果中選擇**負載平衡**。
2. 點擊您剛剛創建的負載平衡器 `web-map-http`。
3. 在**後端**部分，點擊後端的名稱並確認 VM 為**健康**。如果它們不健康，請稍等片刻並重新載入頁面。
4. VM 健康後，使用 Web 瀏覽器測試負載平衡器，前往 `http://IP_ADDRESS/`，將 `IP_ADDRESS` 替換為您之前複製的負載平衡器 IP 位址。

**注意：**這可能需要 3 到 5 分鐘。如果您無法連接，請稍等一分鐘，然後重新載入瀏覽器。

您的瀏覽器應渲染一個顯示服務頁面的實例名稱的頁面，以及其區域（例如，`Page served from: lb-backend-group-xxxx`）。

**預期結果：**
負載平衡器正常運行，請求被路由到健康的後端實例，並顯示來自不同實例的回應。

## 驗證
要驗證實驗已成功完成：
1. 負載平衡器在 Google Cloud Console 中顯示為健康
2. 訪問負載平衡器的 IP 位址會返回來自後端實例的 Web 頁面
3. 多次重新整理頁面會顯示來自不同實例的回應（證明負載平衡正在工作）

## 疑難排解
常見問題和解決方案：
- **負載平衡器未顯示為健康**：等待幾分鐘讓健康檢查完成，或檢查防火牆規則是否正確配置
- **無法訪問負載平衡器 IP**：確保轉發規則已正確創建，並且全域 IP 位址已正確分配
- **VM 實例未啟動**：檢查啟動腳本是否有語法錯誤，或確保 VM 有足夠的資源配額

## 清理
要清理資源並避免費用：
1. 刪除轉發規則：
   ```bash
   gcloud compute forwarding-rules delete http-content-rule --global --quiet
   ```

2. 刪除目標 HTTP 代理：
   ```bash
   gcloud compute target-http-proxies delete http-lb-proxy --quiet
   ```

3. 刪除 URL 映射：
   ```bash
   gcloud compute url-maps delete web-map-http --quiet
   ```

4. 刪除後端服務：
   ```bash
   gcloud compute backend-services delete web-backend-service --global --quiet
   ```

5. 刪除實例組：
   ```bash
   gcloud compute instance-groups managed delete lb-backend-group --zone=Zone --quiet
   ```

6. 刪除實例模板：
   ```bash
   gcloud compute instance-templates delete lb-backend-template --quiet
   ```

7. 刪除健康檢查：
   ```bash
   gcloud compute health-checks delete http-basic-check --quiet
   ```

8. 刪除全域 IP 位址：
   ```bash
   gcloud compute addresses delete lb-ipv4-1 --global --quiet
   ```

9. 刪除防火牆規則：
   ```bash
   gcloud compute firewall-rules delete www-firewall-network-lb --quiet
   gcloud compute firewall-rules delete fw-allow-health-check --quiet
   ```

10. 刪除 VM 實例：
    ```bash
    gcloud compute instances delete www1 www2 www3 --zone=Zone --quiet
    ```

## 其他資源
- [使用託管實例組後端設置經典應用程式負載平衡器](https://cloud.google.com/load-balancing/docs/https/ext-https-lb-simple)
- [外部應用程式負載平衡器概述](https://cloud.google.com/load-balancing/docs/https)
- [創建健康檢查](https://cloud.google.com/load-balancing/docs/health-checks)

## 筆記
此實驗演示了如何設置應用程式負載平衡器，這是 Google Cloud 中最常見的負載平衡類型之一。應用程式負載平衡器提供 L7 功能，允許基於 HTTP 請求的內容進行智慧路由決策。

與網路負載平衡器不同，應用程式負載平衡器可以檢查 HTTP 標頭、URL 路徑和 cookie，使其適用於更複雜的應用程式架構。這種負載平衡器類型對於現代 Web 應用程式特別有用，因為它們可以實現基於內容的路由、SSL 終止和會話親和性等功能。
