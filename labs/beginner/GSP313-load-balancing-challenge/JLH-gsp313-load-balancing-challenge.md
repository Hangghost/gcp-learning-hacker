# GSP313 - Implement Load Balancing on Compute Engine: Challenge Lab - 挑戰實驗室

## 簡介 (Overview)
這是 GSP313 Implement Load Balancing on Compute Engine: Challenge Lab 挑戰實驗室的簡要概述。此實驗室旨在測試您在 Google Cloud 平台上實作負載平衡的能力。

## 任務列表 (Tasks)
在此實驗室中，您需要完成以下任務：
- 任務 1：創建多個 web 服務器實例
- 任務 2：配置負載平衡服務
- 任務 3：創建 HTTP 負載平衡器

## 挑戰實驗室摘要 (Challenge Lab Summary)

本節提供完成每個任務所需的指令。請按照以下步驟執行，確保您已設定所有必要的變數。

### 初始變數設定 (Initial Variable Settings)
```bash
# 設定您的區域和區域
export REGION=""  # 請根據您的 lab 環境設定
export ZONE=""  # 請根據您的 lab 環境設定
export PROJECT_ID=$(gcloud config get-value project)
```

### 任務步驟 (Task Steps)

#### 任務 1：創建多個 web 服務器實例 (Create multiple web server instances)
```bash
# 創建三個 VM 實例
gcloud compute instances create web1 \
  --zone=$ZONE \
  --machine-type=e2-small \
  --network=default \
  --tags=network-lb-tag \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --metadata startup-script="#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo '<h3>Web Server: web1</h3>' | tee /var/www/html/index.html"

gcloud compute instances create web2 \
  --zone=$ZONE \
  --machine-type=e2-small \
  --network=default \
  --tags=network-lb-tag \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --metadata startup-script="#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo '<h3>Web Server: web2</h3>' | tee /var/www/html/index.html"

gcloud compute instances create web3 \
  --zone=$ZONE \
  --machine-type=e2-small \
  --network=default \
  --tags=network-lb-tag \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --metadata startup-script="#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo '<h3>Web Server: web3</h3>' | tee /var/www/html/index.html"

# 創建防火牆規則允許 HTTP 流量
gcloud compute firewall-rules create allow-http \
  --network=default \
  --allow=tcp:80 \
  --target-tags=network-lb-tag
```

#### 任務 2：配置負載平衡服務 (Configure the load balancing service)
```bash
# 創建靜態外部 IP
gcloud compute addresses create network-lb-ip-1 \
  --region=$REGION

# 創建 target pool
gcloud compute target-pools create www-pool \
  --region=$REGION \
  --http-health-check

# 添加實例到 target pool
gcloud compute target-pools add-instances www-pool \
  --instances=web1,web2,web3 \
  --instances-zone=$ZONE \
  --region=$REGION

# 創建轉發規則
gcloud compute forwarding-rules create www-rule \
  --region=$REGION \
  --ports=80 \
  --address=network-lb-ip-1 \
  --target-pool=www-pool
```

#### 任務 3：創建 HTTP 負載平衡器 (Create an HTTP load balancer)
```bash
# 創建實例模板
gcloud compute instance-templates create lb-backend-template \
  --machine-type=e2-medium \
  --network=default \
  --tags=allow-health-check \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --metadata startup-script="#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo '<h3>Web Server: lb-backend-group</h3>' | tee /var/www/html/index.html"

# 創建受控實例組
gcloud compute instance-groups managed create lb-backend-group \
  --template=lb-backend-template \
  --size=2 \
  --zone=$ZONE

# 創建防火牆規則允許健康檢查
gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80

# 創建健康檢查
gcloud compute health-checks create http http-basic-check \
  --port 80

# 設置實例組的命名端口
gcloud compute instance-groups managed set-named-ports lb-backend-group \
  --named-ports http:80 \
  --zone=$ZONE

# 創建後端服務
gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

# 添加後端到後端服務
gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=$ZONE \
  --global

# 創建 URL map
gcloud compute url-maps create web-map-http \
  --default-service web-backend-service

# 創建目標 HTTP 代理
gcloud compute target-http-proxies create http-lb-proxy \
  --url-map web-map-http

# 創建外部 IP 地址
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global

# 創建轉發規則
gcloud compute forwarding-rules create http-content-rule \
  --address=lb-ipv4-1\
  --global \
  --target-http-proxy=http-lb-proxy \
  --ports=80
```

## 清理 (Cleanup)
```bash
# 清理 HTTP 負載平衡器資源
gcloud compute forwarding-rules delete http-content-rule --global --quiet
gcloud compute addresses delete lb-ipv4-1 --global --quiet
gcloud compute target-http-proxies delete http-lb-proxy --quiet
gcloud compute url-maps delete web-map-http --quiet
gcloud compute backend-services delete web-backend-service --global --quiet
gcloud compute instance-groups managed delete lb-backend-group --zone=$ZONE --quiet
gcloud compute instance-templates delete lb-backend-template --quiet
gcloud compute health-checks delete http-basic-check --quiet
gcloud compute firewall-rules delete fw-allow-health-check --quiet

# 清理網路負載平衡器資源
gcloud compute forwarding-rules delete www-rule --region=$REGION --quiet
gcloud compute target-pools delete www-pool --region=$REGION --quiet
gcloud compute addresses delete network-lb-ip-1 --region=$REGION --quiet

# 清理實例
gcloud compute instances delete web1 web2 web3 --zone=$ZONE --quiet

# 清理防火牆規則
gcloud compute firewall-rules delete allow-http --quiet
```
