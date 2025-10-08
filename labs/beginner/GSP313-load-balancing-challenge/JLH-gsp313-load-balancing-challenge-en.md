# GSP313 - Implement Load Balancing on Compute Engine: Challenge Lab

## Overview
This is the GSP313 Implement Load Balancing on Compute Engine: Challenge Lab overview. This lab tests your ability to implement load balancing on Google Cloud Platform.

## Tasks
In this lab, you need to complete the following tasks:
- Task 1: Create multiple web server instances
- Task 2: Configure the load balancing service
- Task 3: Create an HTTP load balancer

## Challenge Lab Summary

This section provides the commands needed to complete each task. Follow these steps and ensure you have set all necessary variables.

### Initial Variable Settings
```bash
# Set your region and zone
export REGION="us-central1"  # Please set according to your lab environment
export ZONE="us-central1-a"  # Please set according to your lab environment
export PROJECT_ID=$(gcloud config get-value project)
```

### Task Steps

#### Task 1: Create multiple web server instances
```bash
# Create three VM instances
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

# Create firewall rule to allow HTTP traffic
gcloud compute firewall-rules create allow-http \
  --network=default \
  --allow=tcp:80 \
  --target-tags=network-lb-tag
```

#### Task 2: Configure the load balancing service
```bash
# Create static external IP
gcloud compute addresses create network-lb-ip-1 \
  --region=$REGION

# Create target pool
gcloud compute target-pools create www-pool \
  --region=$REGION \
  --http-health-check

# Add instances to target pool
gcloud compute target-pools add-instances www-pool \
  --instances=web1,web2,web3 \
  --instances-zone=$ZONE \
  --region=$REGION

# Create forwarding rule
gcloud compute forwarding-rules create www-rule \
  --region=$REGION \
  --ports=80 \
  --address=network-lb-ip-1 \
  --target-pool=www-pool
```

#### Task 3: Create an HTTP load balancer
```bash
# Create instance template
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

# Create managed instance group
gcloud compute instance-groups managed create lb-backend-group \
  --template=lb-backend-template \
  --size=2 \
  --zone=$ZONE

# Create firewall rule to allow health checks
gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80

# Create health check
gcloud compute health-checks create http http-basic-check \
  --port 80

# Set named port for instance group
gcloud compute instance-groups managed set-named-ports lb-backend-group \
  --named-ports http:80 \
  --zone=$ZONE

# Create backend service
gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

# Add backend to backend service
gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=$ZONE \
  --global

# Create URL map
gcloud compute url-maps create web-map-http \
  --default-service web-backend-service

# Create target HTTP proxy
gcloud compute target-http-proxies create http-lb-proxy \
  --url-map web-map-http

# Create external IP address
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global

# Create forwarding rule
gcloud compute forwarding-rules create http-content-rule \
  --address=lb-ipv4-1\
  --global \
  --target-http-proxy=http-lb-proxy \
  --ports=80
```

## Cleanup
```bash
# Clean up HTTP load balancer resources
gcloud compute forwarding-rules delete http-content-rule --global --quiet
gcloud compute addresses delete lb-ipv4-1 --global --quiet
gcloud compute target-http-proxies delete http-lb-proxy --quiet
gcloud compute url-maps delete web-map-http --quiet
gcloud compute backend-services delete web-backend-service --global --quiet
gcloud compute instance-groups managed delete lb-backend-group --zone=$ZONE --quiet
gcloud compute instance-templates delete lb-backend-template --quiet
gcloud compute health-checks delete http-basic-check --quiet
gcloud compute firewall-rules delete fw-allow-health-check --quiet

# Clean up network load balancer resources
gcloud compute forwarding-rules delete www-rule --region=$REGION --quiet
gcloud compute target-pools delete www-pool --region=$REGION --quiet
gcloud compute addresses delete network-lb-ip-1 --region=$REGION --quiet

# Clean up instances
gcloud compute instances delete web1 web2 web3 --zone=$ZONE --quiet

# Clean up firewall rules
gcloud compute firewall-rules delete allow-http --quiet
```
