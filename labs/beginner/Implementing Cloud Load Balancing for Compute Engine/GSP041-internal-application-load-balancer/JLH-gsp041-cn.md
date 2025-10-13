# GSP041 - 使用內部應用程式負載平衡器

## 實驗概述
內部應用程式負載平衡器對於構建強大、安全且易於管理的內部應用程式至關重要，這些應用程式為您的業務運營提供動力。本實驗探討如何在私有雲網路內分配網路流量，而不將虛擬機器 (VM) 直接暴露給公共網際網路，從而保持服務的安全性和效率。

在本實驗中，您將構建一個簡化但非常常見的架構模式：
- "Web 層"（面向公眾的網站）需要請求另一個內部服務的幫助
- "內部服務層"（質數計算器）執行特定任務並分佈在多台機器上

## 先決條件
- Google Cloud Compute Engine 基礎知識：了解什麼是虛擬機器 (VM) 實例
- 網路基礎概念：了解什麼是 IP 位址
- Unix/Linux 命令列基礎：如何在終端機中輸入命令
- VPC（虛擬私有雲）知識：了解您的 Google Cloud 資源位於私有網路中

## 實驗目標
完成本實驗後，您將能夠：
- 了解構成內部負載平衡器的組件
- 創建後端機器群組（質數計算器）
- 設置內部負載平衡器以將內部流量導向後端機器
- 從另一個內部機器測試內部負載平衡器
- 設置面向公眾的 Web 伺服器，使用內部負載平衡器從內部「質數計算器」服務獲取結果

## 預估時間
60-90 分鐘

## 實驗步驟

### 步驟 1：創建虛擬環境
設置 Python 虛擬環境以保持專案軟體的整潔。

**指令：**
1. 安裝 `virtualenv` 環境：
   ```bash
   sudo apt-get install -y virtualenv
   ```

2. 構建虛擬環境：
   ```bash
   python3 -m venv venv
   ```

3. 啟動虛擬環境：
   ```bash
   source venv/bin/activate
   ```

**預期結果：**
虛擬環境已成功創建並啟動。

### 步驟 2：啟用 Cloud Shell IDE 中的 Gemini Code Assist
在 Cloud Shell IDE 中啟用 Gemini Code Assist 以獲得程式碼指導。

**指令：**
1. 啟用 Gemini for Google Cloud API：
   ```bash
   gcloud services enable cloudaicompanion.googleapis.com
   ```

2. 點擊 Cloud Shell 工具列上的 **Open Editor**

3. 在左側面板中，點擊 **Settings** 圖示，然後在 **Settings** 視圖中搜尋 **Gemini Code Assist**

4. 確保 **Geminicodeassist: Enable** 的複選框已選中

5. 點擊狀態列中的 **Cloud Code - No Project**

6. 按照指示授權外掛程式

**預期結果：**
Gemini Code Assist 已啟用並可在編輯器中使用。

### 步驟 3：創建後端託管實例群組
創建託管實例群組以自動創建和維護服務的相同副本。

**指令：**
1. 創建啟動腳本 `backend.sh`：
   ```bash
   touch ~/backend.sh
   ```

2. 在編輯器中添加以下腳本內容：
   ```bash
   sudo chmod -R 777 /usr/local/sbin/
   sudo cat << EOF > /usr/local/sbin/serveprimes.py
   import http.server

   def is_prime(a): return a!=1 and all(a % i for i in range(2,int(a**0.5)+1))

   class myHandler(http.server.BaseHTTPRequestHandler):
     def do_GET(s):
       s.send_response(200)
       s.send_header("Content-type", "text/plain")
       s.end_headers()
       s.wfile.write(bytes(str(is_prime(int(s.path[1:]))).encode('utf-8')))

   http.server.HTTPServer(("",80),myHandler).serve_forever()
   EOF
   nohup python3 /usr/local/sbin/serveprimes.py >/dev/null 2>&1 &
   ```

3. 創建實例模板：
   ```bash
   gcloud compute instance-templates create primecalc \
   --metadata-from-file startup-script=backend.sh \
   --no-address --tags backend --machine-type=e2-medium
   ```

4. 開啟防火牆規則：
   ```bash
   gcloud compute firewall-rules create http --network default --allow=tcp:80 \
   --source-ranges IP --target-tags backend
   ```

5. 創建實例群組：
   ```bash
   gcloud compute instance-groups managed create backend \
   --size 3 \
   --template primecalc \
   --zone ZONE
   ```

**預期結果：**
已創建包含 3 個後端 VM 的託管實例群組。

### 步驟 4：設置內部負載平衡器
設置內部負載平衡器並將其連接到您剛創建的實例群組。

**指令：**
1. 創建健康檢查：
   ```bash
   gcloud compute health-checks create http ilb-health --request-path /2
   ```

2. 創建後端服務：
   ```bash
   gcloud compute backend-services create prime-service \
   --load-balancing-scheme internal --region=REGION \
   --protocol tcp --health-checks ilb-health
   ```

3. 將實例群組添加到後端服務：
   ```bash
   gcloud compute backend-services add-backend prime-service \
   --instance-group backend --instance-group-zone=ZONE \
   --region=REGION
   ```

4. 創建轉發規則：
   ```bash
   gcloud compute forwarding-rules create prime-lb \
   --load-balancing-scheme internal \
   --ports 80 --network default \
   --region=REGION --address IP \
   --backend-service prime-service
   ```

**預期結果：**
內部負載平衡器已設置完成，可以通過內部 IP 位址查詢質數計算服務。

### 步驟 5：測試負載平衡器
創建測試實例以驗證內部應用程式負載平衡器是否正確將流量導向後端服務。

**指令：**
1. 創建測試實例：
   ```bash
   gcloud compute instances create testinstance \
   --machine-type=e2-standard-2 --zone ZONE
   ```

2. SSH 連接到測試實例：
   ```bash
   gcloud compute ssh testinstance --zone ZONE
   ```

3. 查詢負載平衡器：
   ```bash
   curl IP/2
   curl IP/4
   curl IP/5
   ```

4. 退出並刪除測試實例：
   ```bash
   exit
   gcloud compute instances delete testinstance --zone=ZONE
   ```

**預期結果：**
應該看到 2 和 5 被正確識別為質數，而 4 不是。

### 步驟 6：創建面向公眾的 Web 伺服器
創建面向公眾的 Web 伺服器，使用內部「質數計算器」服務顯示質數矩陣。

**指令：**
1. 創建前端啟動腳本 `frontend.sh`：
   ```bash
   touch ~/frontend.sh
   ```

2. 在編輯器中添加前端腳本內容（包含 getprimes.py 的完整程式碼）

3. 創建前端實例：
   ```bash
   gcloud compute instances create frontend --zone=ZONE \
   --metadata-from-file startup-script=frontend.sh \
   --tags frontend --machine-type=e2-standard-2
   ```

4. 為前端開啟防火牆：
   ```bash
   gcloud compute firewall-rules create http2 --network default --allow=tcp:80 \
   --source-ranges 0.0.0.0/0 --target-tags frontend
   ```

**預期結果：**
可以通過瀏覽器訪問前端的外部 IP，看到質數矩陣顯示。

## 驗證
1. 檢查 Compute Engine > VM instances 中是否有 3 個後端 VM 和 1 個前端 VM
2. 通過瀏覽器訪問前端外部 IP，確認質數矩陣正常顯示
3. 測試不同路徑（如 /10000）確認服務響應

## 故障排除
常見問題及其解決方案：
- **健康檢查失敗**：確認後端 VM 正在運行且 port 80 可訪問
- **防火牆規則問題**：檢查防火牆規則是否正確創建且目標標籤匹配
- **負載平衡器無響應**：確認轉發規則和後端服務配置正確
- **前端無法訪問**：檢查前端 VM 的外部 IP 和防火牆規則

## 清理
為避免產生費用，請清理資源：
1. 刪除前端實例：
   ```bash
   gcloud compute instances delete frontend --zone=ZONE
   ```

2. 刪除後端實例群組：
   ```bash
   gcloud compute instance-groups managed delete backend --zone=ZONE
   ```

3. 刪除實例模板：
   ```bash
   gcloud compute instance-templates delete primecalc
   ```

4. 刪除負載平衡器組件：
   ```bash
   gcloud compute forwarding-rules delete prime-lb --region=REGION
   gcloud compute backend-services delete prime-service --region=REGION
   gcloud compute health-checks delete ilb-health
   ```

5. 刪除防火牆規則：
   ```bash
   gcloud compute firewall-rules delete http
   gcloud compute firewall-rules delete http2
   ```

## 額外資源
- [內部應用程式負載平衡器文件](https://cloud.google.com/load-balancing/docs/l7-internal)
- [子網路文件](https://cloud.google.com/compute/docs/subnetworks)
- [Google Cloud 訓練和認證](https://cloud.google.com/training)

## 筆記
本實驗展示了如何使用 Google Cloud 的內部應用程式負載平衡器構建可靠的內部服務，並演示了公共應用程式如何安全地利用它。重點在於理解內部負載平衡的架構模式和實作細節。
