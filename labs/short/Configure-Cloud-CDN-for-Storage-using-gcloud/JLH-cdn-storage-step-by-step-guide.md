# Configure Cloud CDN for Storage using gcloud - 逐步操作指南

## 實驗室概述

本 Challenge Lab 要求您為一個快速成長的線上新聞平台配置 Cloud CDN，以改善全球使用者存取靜態內容（圖片、影片、文章）的速度。您需要為預先建立的 Cloud Storage bucket 設定 Cloud CDN 快取配置，減少遠端地區使用者的頁面載入時間。

### 學習目標
- 了解如何使用 gcloud 為 Cloud Storage 配置 Cloud CDN
- 掌握建立後端 bucket 和 URL map 的流程
- 學習設定全球負載均衡器以啟用 CDN 功能

## 先決條件

- 基本了解 Google Cloud Platform 和 gcloud SDK
- 熟悉 Cloud Storage 基本概念
- 了解 CDN（內容分發網路）的基本原理
- 了解 HTTP/HTTPS 負載均衡的基本概念

## 預估時間

**15-20 分鐘**

## 任務 1：為 Cloud Storage 創建 Cloud CDN 配置

### 步驟詳情

#### 1. 設定環境變數

首先，自動查詢並設定專案 ID、區域和現有 bucket：

```bash
export PROJECT_ID=$(gcloud config get-value project) && export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])") && echo "Using project: $PROJECT_ID and region: $REGION"
```

**說明**：
- 自動取得當前專案 ID
- 自動取得預設區域

接著，自動查詢實驗室預先建立的 Cloud Storage bucket：

```bash
# 取得專案中的第一個 Bucket
export BUCKET_NAME=$( (gsutil ls -p ${PROJECT_ID} || gsutil ls) | head -1 | sed 's|gs://||;s|/||' ) && echo "Using Bucket: ${BUCKET_NAME}"
```

**說明**：
- 自動取得當前專案 ID
- 自動取得預設區域
- 取得專案中的第一個 bucket
- 如果專案中沒有 bucket，則使用預設命名格式
- 顯示最終使用的 bucket 名稱供確認

最後，直接定義我們即將建立的各項資源名稱：

```bash
# 設定資源名稱
export BACKEND_BUCKET_NAME=news-backend-bucket
export IP_NAME=news-cdn-ip
export URL_MAP_NAME=news-url-map
export HTTP_PROXY_NAME=news-http-proxy
export FORWARDING_RULE_NAME=news-forwarding-rule
```

**說明**：這些是我們即將手動建立的資源名稱。在空的環境中，使用統一的命名規範（如 `news-` 前綴）可以讓管理更清晰。

驗證所有變數已正確設定：

```bash
echo "專案 ID: ${PROJECT_ID}"
echo "區域: ${REGION}"
echo "源站 Bucket: ${BUCKET_NAME}"
echo "後端 Bucket: ${BACKEND_BUCKET_NAME}"
echo "靜態 IP 名稱: ${IP_NAME}"
```

#### 2. 確認 Cloud Storage bucket 是否存在

檢查預先建立的 bucket：

```bash
gsutil ls gs://${BUCKET_NAME}
```

**說明**：此指令列出 bucket 的內容。如果 bucket 不存在，您可能需要建立它：

```bash
gsutil mb -l ${REGION} gs://${BUCKET_NAME}
```

#### 3. 設定 bucket 為公開可讀（如需要）

為了讓 CDN 能夠快取和提供內容，bucket 需要設定為公開可讀：

```bash
gsutil iam ch allUsers:objectViewer gs://${BUCKET_NAME}
```

**說明**：此指令授予所有使用者對 bucket 中物件的檢視權限。`allUsers` 代表任何人都可以讀取，`objectViewer` 是允許列出和讀取物件的角色。

#### 4. （可選）上傳一些測試內容

如果 bucket 是空的，上傳一些測試檔案：

```bash
echo "<h1>Test Content</h1>" > test.html
gsutil cp test.html gs://${BUCKET_NAME}/
```

#### 5. 建立後端 bucket

後端 bucket 是 Cloud CDN 和 Cloud Storage 之間的連接：

```bash
gcloud compute backend-buckets create ${BACKEND_BUCKET_NAME} --gcs-bucket-name=${BUCKET_NAME} --enable-cdn
```

**說明**：
- `backend-buckets create`：建立一個後端 bucket 資源
- `--gcs-bucket-name`：指定要關聯的 Cloud Storage bucket 名稱
- `--enable-cdn`：啟用 Cloud CDN 快取功能

#### 6. （可選）配置 CDN 快取設定

您可以進一步自訂 CDN 的快取行為：

```bash
gcloud compute backend-buckets update ${BACKEND_BUCKET_NAME} --enable-cdn --cache-mode=CACHE_ALL_STATIC
```

**說明**：
- `--cache-mode=CACHE_ALL_STATIC`：快取所有靜態內容
- 其他可用模式：`USE_ORIGIN_HEADERS`（使用來源標頭）、`FORCE_CACHE_ALL`（強制快取所有內容）

#### 7. 保留全球靜態外部 IP 地址

為負載均衡器保留一個靜態 IP：

```bash
gcloud compute addresses create ${IP_NAME} --ip-version=IPV4 --global
```

**說明**：靜態 IP 讓您的 CDN 端點有一個固定的 IP 地址，便於 DNS 配置。

#### 8. 取得並記錄靜態 IP

```bash
gcloud compute addresses describe ${IP_NAME} --format="get(address)" --global
```

**說明**：記下這個 IP 地址，稍後可用於 DNS 設定。

#### 9. 建立 URL map

URL map 定義如何將請求路由到後端服務：

```bash
gcloud compute url-maps create ${URL_MAP_NAME} --default-backend-bucket=${BACKEND_BUCKET_NAME}
```

**說明**：
- `url-maps create`：建立一個 URL map
- `--default-backend-bucket`：指定預設的後端 bucket，所有請求將被路由到這裡

#### 10. 建立目標 HTTP proxy

建立一個 HTTP proxy 來處理進入的 HTTP 請求：

```bash
gcloud compute target-http-proxies create ${HTTP_PROXY_NAME} --url-map=${URL_MAP_NAME}
```

**說明**：Target HTTP proxy 接收來自轉發規則的請求，並根據 URL map 將其路由到適當的後端。

#### 11. 建立全球轉發規則

最後，建立轉發規則來完成負載均衡器設定：

```bash
gcloud compute forwarding-rules create ${FORWARDING_RULE_NAME} --load-balancing-scheme=EXTERNAL --network-tier=PREMIUM --address=${IP_NAME} --global --target-http-proxy=${HTTP_PROXY_NAME} --ports=80
```

**說明**：
- `--load-balancing-scheme=EXTERNAL`：外部負載均衡器
- `--network-tier=PREMIUM`：使用高級網路層級以獲得最佳全球效能
- `--address`：使用先前保留的靜態 IP
- `--global`：全球轉發規則
- `--target-http-proxy`：關聯到我們建立的 HTTP proxy
- `--ports=80`：監聽 HTTP 流量（Port 80）

### 驗證步驟

1. **偵測 Bucket 中的實際內容**：
   實驗室通常會預放一些圖片或影片檔案，我們需要找出它們：
   ```bash
   gsutil ls gs://${BUCKET_NAME}/images/
   ```

2. **測試 CDN 端點（需等待約 5-10 分鐘讓配置生效）**：
   挑選一個現有的檔案（例如 `images/kitten.png`）進行測試。
   **注意**：看到 `Via: 1.1 google` 標頭才代表 CDN 真正生效。

   ```bash
   STATIC_IP=$(gcloud compute addresses describe ${IP_NAME} --format="get(address)" --global) && export ASSET_PATH="images/kitten.png" && echo "Using static IP: ${STATIC_IP} and asset path: ${ASSET_PATH}"
   # 連續測試以觸發快取並確認生效
   for i in {1..10}; do echo "--- Request $i: http://${STATIC_IP}/${ASSET_PATH} ---"; curl -I http://${STATIC_IP}/${ASSET_PATH}; echo ""; sleep 5; done

   for i in {1..5}; do for file in images/kitten.png images/logo.png images/nature.png videos/Health-report.mp4; do curl -L -s -o /dev/null http://${STATIC_IP}/$file; done; echo "Round $i 完成..."; sleep 2; done
   ```

## 執行指南

### 常見問題與解決方案

**問題 1：Bucket 不存在**
- **解決方案**：確認您的專案中是否有預先建立的 bucket。如果沒有，使用 `gsutil mb` 指令建立。

**問題 2：權限不足錯誤**
- **解決方案**：確保您的帳號有足夠的權限執行這些操作。可能需要 `roles/compute.admin` 和 `roles/storage.admin` 角色。

**問題 3：CDN 快取沒有生效**
- **解決方案**：
  - CDN 配置需要時間傳播（通常 5-10 分鐘）
  - 確認 `--enable-cdn` 標記已設定
  - 檢查 Cache-Control 標頭是否正確設定

**問題 4：無法存取靜態 IP**
- **解決方案**：
  - 確認轉發規則已成功建立
  - 檢查防火牆規則是否允許 HTTP 流量
  - 等待 DNS 和負載均衡器配置完全傳播

**問題 5：HTTPS 支援**
- **解決方案**：如需 HTTPS，您需要：
  - 建立 SSL 憑證：`gcloud compute ssl-certificates create`
  - 使用 `target-https-proxies` 而非 `target-http-proxies`
  - 在轉發規則中使用 Port 443

### 提示與技巧

1. **快取策略**：
   - 為靜態內容設定適當的 `Cache-Control` 標頭
   - 考慮使用不同的快取模式以符合您的需求

2. **效能監控**：
   - 使用 Cloud Monitoring 追蹤 CDN 命中率
   - 監控後端 bucket 的請求延遲

3. **成本優化**：
   - CDN 快取可大幅減少 Cloud Storage 的輸出流量成本
   - 合理設定快取 TTL 以平衡新鮮度和成本

4. **安全性考量**：
   - 如果內容不應公開，使用 Signed URLs 或 Signed Cookies
   - 考慮使用 Cloud Armor 提供 DDoS 防護

### 清理步驟

完成實驗後，清理資源以避免不必要的費用：

```bash
# 刪除轉發規則
gcloud compute forwarding-rules delete ${FORWARDING_RULE_NAME} --global --quiet

# 刪除目標 HTTP proxy
gcloud compute target-http-proxies delete ${HTTP_PROXY_NAME} --quiet

# 刪除 URL map
gcloud compute url-maps delete ${URL_MAP_NAME} --quiet

# 刪除後端 bucket
gcloud compute backend-buckets delete ${BACKEND_BUCKET_NAME} --quiet

# 釋放靜態 IP
gcloud compute addresses delete ${IP_NAME} --global --quiet

# （可選）刪除 Cloud Storage bucket 的內容和 bucket
gsutil rm -r gs://${BUCKET_NAME}
```

## 額外資源

- [Cloud CDN 官方文檔](https://cloud.google.com/cdn/docs)
- [使用 Cloud CDN 提供來自 Cloud Storage 的內容](https://cloud.google.com/cdn/docs/setting-up-cdn-with-bucket)
- [Cloud CDN 快取概述](https://cloud.google.com/cdn/docs/caching)
- [gcloud compute backend-buckets 指令參考](https://cloud.google.com/sdk/gcloud/reference/compute/backend-buckets)
- [HTTP(S) 負載均衡概述](https://cloud.google.com/load-balancing/docs/https)

## 技術筆記

### Cloud CDN 架構

Cloud CDN 使用 Google 的全球邊緣節點網路來快取和提供內容。架構包含：
- **來源伺服器**：Cloud Storage bucket
- **後端 bucket**：GCP 資源，連接 CDN 和 Storage
- **負載均衡器**：包含 URL map、target proxy 和轉發規則
- **邊緣節點**：分布在全球的快取伺服器

### 快取行為

Cloud CDN 的快取行為受多個因素影響：
- **Cache-Control 標頭**：來源設定的快取指令
- **Cache mode**：後端 bucket 的快取模式設定
- **請求類型**：某些請求類型（如 POST）不會被快取

### 效能考量

- **首次請求**：第一個請求會從來源獲取內容（cache miss）
- **後續請求**：相同內容的後續請求將從最近的邊緣節點提供（cache hit）
- **快取失效**：可使用 `gcloud compute url-maps invalidate-cdn-cache` 手動清除快取

### 監控指標

重要的監控指標包括：
- **Cache hit ratio**：快取命中率
- **Request count**：請求數量
- **Bandwidth**：頻寬使用量
- **Error rate**：錯誤率

---

**完成時間戳記**：此指南最後更新於 2026-02-15

**注意**：實際的 bucket 名稱、區域和其他參數可能因您的實驗環境而異。請根據實驗室提供的具體資訊調整指令中的變數。
