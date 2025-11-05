# GSP328 - Develop Serverless Applications on Cloud Run: Challenge Lab 逐步操作指南

## 概述

這是 **GSP328 - Develop Serverless Applications on Cloud Run: Challenge Lab** 的完整逐步操作指南。此實驗室是一個挑戰實驗室，需要您將 Pet Theory 的單體計費應用程式遷移到無伺服器架構。

**注意：** 這是一個 Challenge Lab，您不會得到逐步指示。您需要使用在此課程中學到的技能來完成任務。

## 架構概述

Pet Theory 希望將其單體計費應用程式遷移到無伺服器架構。本實驗室包含以下元件：

- **Staging 架構**：公開計費服務和前端服務
- **Production 架構**：私有計費服務和前端服務，具有安全的服務間通訊
- **服務帳戶**：用於安全的服務間通訊
- **Cloud Run**：無伺服器容器平台
- **Cloud Build**：容器建構服務

## 環境設定

### 1. 設定專案和區域

```bash
# 設定預設專案
export PROJECT_ID=$(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
gcloud config set project $PROJECT_ID

# 設定 Cloud Run 區域
export REGION=
gcloud config set run/region $REGION

# 設定 Cloud Run 平台
gcloud config set run/platform managed
```

### 2. 複製程式碼儲存庫

```bash
# 複製 Pet Theory 儲存庫
git clone https://github.com/rosera/pet-theory.git
cd pet-theory/lab07
```

## 任務 1: 啟用公開服務

### 目標
部署一個公開的計費 REST API 服務。

### 詳細步驟

1. **建構容器映像**
   ```bash
   # 建構 billing-staging-api:0.1 映像
   gcloud builds submit --tag gcr.io/$PROJECT_ID/billing-staging-api:0.1 ./unit-api-billing
   ```

2. **部署 Cloud Run 服務**
   ```bash
   # 部署公開計費服務
   gcloud run deploy public-billing-service \
     --image gcr.io/$PROJECT_ID/billing-staging-api:0.1 \
     --platform managed \
     --region $REGION \
     --allow-unauthenticated
   ```

3. **測試服務**
   ```bash
   # 取得服務 URL
   export PUBLIC_BILLING_URL=$(gcloud run services describe public-billing-service \
     --platform managed \
     --region $REGION \
     --format "value(status.url)")

   # 測試服務回應
   curl -X GET $PUBLIC_BILLING_URL
   ```

## 任務 2: 部署前端服務

### 目標
部署一個無認證的前端服務來顯示計費資訊。

### 詳細步驟

1. **建構容器映像**
   ```bash
   # 建構 frontend-staging:0.1 映像
   gcloud builds submit --tag gcr.io/$PROJECT_ID/frontend-staging:0.1 ./staging-frontend-billing
   ```

2. **部署 Cloud Run 服務**
   ```bash
   # 部署前端服務
   gcloud run deploy frontend-staging-service \
     --image gcr.io/$PROJECT_ID/frontend-staging:0.1 \
     --platform managed \
     --region $REGION \
     --allow-unauthenticated
   ```

3. **測試服務**
   ```bash
   # 取得服務 URL
   export FRONTEND_STAGING_URL=$(gcloud run services describe frontend-staging-service \
     --platform managed \
     --region $REGION \
     --format "value(status.url)")

   # 測試服務回應
   curl -X GET $FRONTEND_STAGING_URL
   ```

## 任務 3: 部署私有服務

### 目標
部署一個需要認證的私有計費服務。

### 詳細步驟

1. **刪除現有的公開服務**
   ```bash
   # 刪除公開計費服務
   gcloud run services delete public-billing-service --region $REGION --quiet
   ```

2. **建構新版本的容器映像**
   ```bash
   # 建構 billing-staging-api:0.2 映像
   gcloud builds submit --tag gcr.io/$PROJECT_ID/billing-staging-api:0.2 ./staging-api-billing
   ```

3. **部署需要認證的服務**
   ```bash
   # 部署私有計費服務
   gcloud run deploy private-billing-service \
     --image gcr.io/$PROJECT_ID/billing-staging-api:0.2 \
     --platform managed \
     --region $REGION \
     --no-allow-unauthenticated
   ```

4. **設定環境變數**
   ```bash
   # 取得私有計費服務 URL
   export BILLING_URL=$(gcloud run services describe private-billing-service \
     --platform managed \
     --region $REGION \
     --format "value(status.url)")
   ```

5. **測試認證訪問**
   ```bash
   # 使用身份權杖測試訪問
   curl -X GET -H "Authorization: Bearer $(gcloud auth print-identity-token)" $BILLING_URL
   ```

## 任務 4: 建立計費服務帳戶

### 目標
為生產環境的計費服務建立服務帳戶。

### 詳細步驟

```bash
# 建立計費服務帳戶
gcloud iam service-accounts create billing-service \
  --display-name "Billing Service Cloud Run" \
  --description "Service account for billing service"
```

## 任務 5: 部署生產計費服務

### 目標
使用服務帳戶部署生產版本的計費服務。

### 詳細步驟

1. **建構生產版本映像**
   ```bash
   # 建構 billing-prod-api:0.1 映像
   gcloud builds submit --tag gcr.io/$PROJECT_ID/billing-prod-api:0.1 ./prod-api-billing
   ```

2. **部署生產計費服務**
   ```bash
   # 使用服務帳戶部署
   gcloud run deploy billing-production-service \
     --image gcr.io/$PROJECT_ID/billing-prod-api:0.1 \
     --platform managed \
     --region $REGION \
     --no-allow-unauthenticated \
     --service-account billing-service@$PROJECT_ID.iam.gserviceaccount.com
   ```

3. **設定環境變數**
   ```bash
   # 取得生產計費服務 URL
   export PROD_BILLING_URL=$(gcloud run services describe billing-production-service \
     --platform managed \
     --region $REGION \
     --format "value(status.url)")
   ```

4. **測試服務**
   ```bash
   # 使用身份權杖測試訪問
   curl -X GET -H "Authorization: Bearer $(gcloud auth print-identity-token)" $PROD_BILLING_URL
   ```

## 任務 6: 前端服務帳戶

### 目標
建立一個具有 Cloud Run 調用者權限的前端服務帳戶。

### 詳細步驟

```bash
# 建立前端服務帳戶
gcloud iam service-accounts create frontend-prod-service \
  --display-name "Billing Service Cloud Run Invoker" \
  --description "Service account for frontend service with invoker permissions"

# 給予 Cloud Run 調用者角色
gcloud run services add-iam-policy-binding billing-production-service \
  --member="serviceAccount:frontend-prod-service@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.invoker" \
  --region $REGION
```

## 任務 7: 重新部署前端服務

### 目標
使用新的服務帳戶重新部署前端服務，使其能夠調用私有計費服務。

### 詳細步驟

1. **建構生產前端映像**
   ```bash
   # 建構 frontend-prod:0.1 映像
   gcloud builds submit --tag gcr.io/$PROJECT_ID/frontend-prod:0.1 ./prod-frontend-billing
   ```

2. **重新部署前端服務**
   ```bash
   # 使用服務帳戶重新部署
   gcloud run deploy frontend-production-service \
     --image gcr.io/$PROJECT_ID/frontend-prod:0.1 \
     --platform managed \
     --region $REGION \
     --allow-unauthenticated \
     --service-account frontend-prod-service@$PROJECT_ID.iam.gserviceaccount.com
   ```

3. **測試完整系統**
   ```bash
   # 取得前端服務 URL
   export FRONTEND_PROD_URL=$(gcloud run services describe frontend-production-service \
     --platform managed \
     --region $REGION \
     --format "value(status.url)")

   # 測試前端服務（應該能夠調用後端計費服務）
   curl -X GET $FRONTEND_PROD_URL
   ```

## 驗證檢查點

### 每個任務的驗證

1. **任務 1**: 公開計費服務可以被匿名訪問
2. **任務 2**: 前端服務可以被匿名訪問
3. **任務 3**: 私有計費服務需要認證
4. **任務 4**: 計費服務帳戶已建立
5. **任務 5**: 生產計費服務使用服務帳戶並需要認證
6. **任務 6**: 前端服務帳戶具有調用者權限
7. **任務 7**: 前端服務使用服務帳戶並可以調用計費服務

### 常見問題排除

- **建構失敗**: 確保 Cloud Build API 已啟用
- **部署失敗**: 檢查區域設定和服務帳戶權限
- **認證失敗**: 驗證身份權杖和服務帳戶設定
- **權限錯誤**: 檢查 IAM 政策和角色指派

## 清理資源

```bash
# 刪除所有服務
gcloud run services delete frontend-production-service --region $REGION --quiet
gcloud run services delete billing-production-service --region $REGION --quiet
gcloud run services delete private-billing-service --region $REGION --quiet
gcloud run services delete frontend-staging-service --region $REGION --quiet

# 刪除服務帳戶
gcloud iam service-accounts delete frontend-prod-service@$PROJECT_ID.iam.gserviceaccount.com --quiet
gcloud iam service-accounts delete billing-service@$PROJECT_ID.iam.gserviceaccount.com --quiet

# 刪除容器映像（可選）
gcloud container images delete gcr.io/$PROJECT_ID/billing-staging-api:0.1 --quiet
gcloud container images delete gcr.io/$PROJECT_ID/billing-staging-api:0.2 --quiet
gcloud container images delete gcr.io/$PROJECT_ID/billing-prod-api:0.1 --quiet
gcloud container images delete gcr.io/$PROJECT_ID/frontend-staging:0.1 --quiet
gcloud container images delete gcr.io/$PROJECT_ID/frontend-prod:0.1 --quiet
```

## 學習重點

- **無伺服器架構**: Cloud Run 提供完全管理的容器平台
- **服務帳戶**: 用於安全的服務間通訊
- **認證與授權**: IAM 和服務帳戶用於控制訪問
- **CI/CD**: Cloud Build 用於自動化容器建構
- **微服務**: 將單體應用程式分解為獨立的服務

## 相關資源

- [Cloud Run 文件](https://cloud.google.com/run/docs)
- [服務帳戶概觀](https://cloud.google.com/iam/docs/service-accounts)
- [Cloud Build 文件](https://cloud.google.com/cloud-build/docs)
- 相關 Labs:
  - GSP644: Develop Serverless Applications on Cloud Run
  - GSP650: Build a Resilient, Asynchronous System with Cloud Run and Pub/Sub
  - GSP761: Developing a REST API with Go and Cloud Run
  - GSP762: Creating PDFs with Go and Cloud Run

---

*此指南基於 Google Cloud Skills Boost GSP328 Challenge Lab 內容編寫。請根據實際環境調整參數。*
