# GCP 指令修正指南

## 概述

此文檔記錄了在生成 GCP Skill Badge (GSP) labs 自動化腳本時發現的常見 GCP 指令問題及其修正方法。這些修正基於實際執行時遇到的錯誤和 API 變更。

## 更新原則

此文檔應在以下情況下更新：
- 發現新的 GCP 指令語法錯誤
- GCP API 或 CLI 工具更新導致舊指令失效
- 發現更好的指令實踐或最佳做法
- 新的 lab 類型需要特定的指令修正

## Health Check 指令

### 問題：混合使用舊版和新版 health check 指令語法

- **Network Load Balancer**：使用 `gcloud compute http-health-checks create`
- **HTTP Load Balancer**：使用 `gcloud compute health-checks create http`

### Example

```bash
# Correct for Network LB
gcloud compute http-health-checks create basic-check
gcloud compute target-pools create www-pool --http-health-check=basic-check

# Correct for HTTP LB
gcloud compute health-checks create http http-basic-check --port=80
```

## Instance Template 參數

### 問題：Instance templates 缺少必要參數

- **解決方案**：根據實際 lab 需求包含適當的參數，如 `--region`、`--subnet`、`--network` 等

### Example

```bash
gcloud compute instance-templates create template-name \
  --region=$REGION \
  --network=default \
  --subnet=default \
  --tags=allow-health-check
```

## Startup Script 格式化

### 問題：metadata startup scripts 中的引號不一致

- **解決方案**：對整個 startup-script 值使用單引號

### Example

```bash
--metadata startup-script='#!/bin/bash
apt-get update
apt-get install apache2 -y
systemctl restart apache2'
```

## Firewall Rule 命名

### 問題：通用名稱可能與現有規則衝突

- **解決方案**：使用包含 lab 上下文的描述性名稱

### 範例

使用 `www-firewall-network-lb` 而非 `allow-http`

## 其他常見問題

### Region/Zone 參數

確保所有需要地理位置的資源都明確指定 `--region` 和 `--zone` 參數，避免使用預設值可能導致的問題。

### API 啟用順序

在建立資源前確保相關 API 已啟用：

```bash
# 範例：啟用 Compute Engine API
gcloud services enable compute.googleapis.com

# 範例：啟用 Pub/Sub API
gcloud services enable pubsub.googleapis.com
```

### 資源依賴順序

確保資源建立順序正確，避免引用尚未建立的資源：

```bash
# 正確順序：網路 -> 子網路 -> VM 實例
gcloud compute networks create my-network
gcloud compute networks subnets create my-subnet --network=my-network
gcloud compute instances create my-instance --subnet=my-subnet
```

## 測試建議

在將修正應用到生產腳本前：

1. 在測試專案中執行指令
2. 檢查資源是否正確建立
3. 驗證資源間的依賴關係
4. 測試清理功能是否正常運作

## 相關文件

- [generate-gsp-lab.md](../.cursor/commands/generate-gsp-lab.md) - 主要的 lab 生成指令
- [labs/templates/](../labs/templates/) - Lab 模板文件

## 維護者注意事項

- 定期檢查 GCP CLI 工具更新
- 關注 GCP 官方文檔的變更
- 在發現新問題時及時更新此文檔
- 保持範例的實用性和準確性
