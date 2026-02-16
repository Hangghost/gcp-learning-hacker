# Configure Cloud CDN for Storage using gcloud - Step-by-Step Guide

## Lab Overview

This Challenge Lab requires you to configure Cloud CDN for a rapidly growing online news platform to improve global user access speeds for static content (images, videos, articles). You need to set up a Cloud CDN cache configuration for a pre-created Cloud Storage bucket to reduce page load times for users in remote regions.

### Learning Objectives
- Understand how to configure Cloud CDN for Cloud Storage using gcloud
- Master the process of creating backend buckets and URL maps
- Learn to set up a global load balancer to enable CDN functionality

## Prerequisites

- Basic understanding of Google Cloud Platform and gcloud SDK
- Familiarity with Cloud Storage basic concepts
- Understanding of CDN (Content Delivery Network) fundamentals
- Understanding of HTTP/HTTPS load balancing basics

## Estimated Time

**15-20 minutes**

## Task 1: Create Cloud CDN Configuration for Cloud Storage

### Step Details

#### 1. Set Environment Variables

First, automatically query and set project ID, region, and existing bucket:

```bash
export PROJECT_ID=$(gcloud config get-value project) && export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])") && echo "Using project: $PROJECT_ID and region: $REGION"
```

**Explanation**:
- Automatically get current project ID
- Automatically get default region from project metadata

Next, automatically query the pre-created Cloud Storage bucket from the lab:

```bash
# Get the first bucket in the project
export BUCKET_NAME=$( (gsutil ls -p ${PROJECT_ID} || gsutil ls) | head -1 | sed 's|gs://||;s|/||' ) && echo "Using Bucket: ${BUCKET_NAME}"
```

**Explanation**:
- Automatically get current project ID
- Automatically get default region from project metadata
- Get the first bucket in the project
- If no bucket exists in project, use default naming format
- Display the final bucket name for confirmation

Finally, define the resource names we are about to create:

```bash
# Define resource names
export BACKEND_BUCKET_NAME=news-backend-bucket
export IP_NAME=news-cdn-ip
export URL_MAP_NAME=news-url-map
export HTTP_PROXY_NAME=news-http-proxy
export FORWARDING_RULE_NAME=news-forwarding-rule
```

**Explanation**: These are the resource names we will create manually. In an empty environment, using a consistent naming convention (like the `news-` prefix) makes management clearer.

Verify all variables are set correctly:

```bash
echo "Project ID: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo "Origin Bucket: ${BUCKET_NAME}"
echo "Backend Bucket: ${BACKEND_BUCKET_NAME}"
echo "Static IP Name: ${IP_NAME}"
```

#### 2. Verify Cloud Storage Bucket Exists

Check the pre-created bucket:

```bash
gsutil ls gs://${BUCKET_NAME}
```

**Explanation**: This command lists the contents of the bucket. If the bucket doesn't exist, you may need to create it:

```bash
gsutil mb -l ${REGION} gs://${BUCKET_NAME}
```

#### 3. Set Bucket to Publicly Readable (if needed)

For CDN to cache and serve content, the bucket needs to be publicly readable:

```bash
gsutil iam ch allUsers:objectViewer gs://${BUCKET_NAME}
```

**Explanation**: This command grants all users view permission for objects in the bucket. `allUsers` means anyone can read, and `objectViewer` is the role that allows listing and reading objects.

#### 4. (Optional) Upload Some Test Content

If the bucket is empty, upload some test files:

```bash
echo "<h1>Test Content</h1>" > test.html
gsutil cp test.html gs://${BUCKET_NAME}/
```

#### 5. Create Backend Bucket

The backend bucket is the connection between Cloud CDN and Cloud Storage:

```bash
gcloud compute backend-buckets create ${BACKEND_BUCKET_NAME} --gcs-bucket-name=${BUCKET_NAME} --enable-cdn
```

**Explanation**:
- `backend-buckets create`: Creates a backend bucket resource
- `--gcs-bucket-name`: Specifies the Cloud Storage bucket name to associate with
- `--enable-cdn`: Enables Cloud CDN caching functionality

#### 6. (Optional) Configure CDN Cache Settings

You can further customize CDN caching behavior:

```bash
gcloud compute backend-buckets update ${BACKEND_BUCKET_NAME} --enable-cdn --cache-mode=CACHE_ALL_STATIC
```

**Explanation**:
- `--cache-mode=CACHE_ALL_STATIC`: Caches all static content
- Other available modes: `USE_ORIGIN_HEADERS` (use origin headers), `FORCE_CACHE_ALL` (force cache all content)

#### 7. Reserve Global Static External IP Address

Reserve a static IP for the load balancer:

```bash
gcloud compute addresses create ${IP_NAME} --ip-version=IPV4 --global
```

**Explanation**: A static IP gives your CDN endpoint a fixed IP address, making DNS configuration easier.

#### 8. Retrieve and Record Static IP

```bash
gcloud compute addresses describe ${IP_NAME} --format="get(address)" --global
```

**Explanation**: Note this IP address for later use in DNS configuration.

#### 9. Create URL Map

The URL map defines how to route requests to backend services:

```bash
gcloud compute url-maps create ${URL_MAP_NAME} --default-backend-bucket=${BACKEND_BUCKET_NAME}
```

**Explanation**:
- `url-maps create`: Creates a URL map
- `--default-backend-bucket`: Specifies the default backend bucket where all requests will be routed

#### 10. Create Target HTTP Proxy

Create an HTTP proxy to handle incoming HTTP requests:

```bash
gcloud compute target-http-proxies create ${HTTP_PROXY_NAME} --url-map=${URL_MAP_NAME}
```

**Explanation**: The target HTTP proxy receives requests from the forwarding rule and routes them to the appropriate backend based on the URL map.

#### 11. Create Global Forwarding Rule

Finally, create the forwarding rule to complete the load balancer setup:

```bash
gcloud compute forwarding-rules create ${FORWARDING_RULE_NAME} --load-balancing-scheme=EXTERNAL --network-tier=PREMIUM --address=${IP_NAME} --global --target-http-proxy=${HTTP_PROXY_NAME} --ports=80
```

**Explanation**:
- `--load-balancing-scheme=EXTERNAL`: External load balancer
- `--network-tier=PREMIUM`: Uses premium network tier for best global performance
- `--address`: Uses the previously reserved static IP
- `--global`: Global forwarding rule
- `--target-http-proxy`: Associates with our created HTTP proxy
- `--ports=80`: Listens for HTTP traffic (Port 80)

### Verification Steps

1. **Detect Actual Content in Bucket**:
   Labs usually pre-load some images or video files, we need to find them:
   ```bash
   gsutil ls gs://${BUCKET_NAME}/images/
   ```

2. **Test CDN Endpoint (Wait about 5-10 minutes for configuration to take effect)**:
   Select an existing file (e.g., `images/kitten.png`) for testing.
   **Note**: Seeing the `Via: 1.1 google` header means the CDN is truly active.

   ```bash
   STATIC_IP=$(gcloud compute addresses describe ${IP_NAME} --format="get(address)" --global) && export ASSET_PATH="images/kitten.png" && echo "Using static IP: ${STATIC_IP} and asset path: ${ASSET_PATH}"
   # Continuous testing to trigger cache and confirm effectiveness
   for i in {1..10}; do echo "--- Request $i: http://${STATIC_IP}/${ASSET_PATH} ---"; curl -I http://${STATIC_IP}/${ASSET_PATH}; echo ""; sleep 5; done

   for i in {1..5}; do for file in images/kitten.png images/logo.png images/nature.png videos/Health-report.mp4; do curl -L -s -o /dev/null http://${STATIC_IP}/$file; done; echo "Round $i complete..."; sleep 2; done
   ```

## Execution Guide

### Common Issues and Solutions

**Issue 1: Bucket doesn't exist**
- **Solution**: Confirm whether there's a pre-created bucket in your project. If not, use the `gsutil mb` command to create one.

**Issue 2: Insufficient permissions error**
- **Solution**: Ensure your account has sufficient permissions to perform these operations. You may need `roles/compute.admin` and `roles/storage.admin` roles.

**Issue 3: CDN caching not working**
- **Solution**:
  - CDN configuration needs time to propagate (usually 5-10 minutes)
  - Confirm the `--enable-cdn` flag is set
  - Check if Cache-Control headers are properly configured

**Issue 4: Cannot access static IP**
- **Solution**:
  - Confirm forwarding rule was successfully created
  - Check if firewall rules allow HTTP traffic
  - Wait for DNS and load balancer configuration to fully propagate

**Issue 5: HTTPS support**
- **Solution**: For HTTPS, you need to:
  - Create SSL certificate: `gcloud compute ssl-certificates create`
  - Use `target-https-proxies` instead of `target-http-proxies`
  - Use Port 443 in forwarding rule

### Tips and Tricks

1. **Caching Strategy**:
   - Set appropriate `Cache-Control` headers for static content
   - Consider using different cache modes to fit your needs

2. **Performance Monitoring**:
   - Use Cloud Monitoring to track CDN hit ratio
   - Monitor backend bucket request latency

3. **Cost Optimization**:
   - CDN caching can significantly reduce Cloud Storage egress costs
   - Set reasonable cache TTL to balance freshness and cost

4. **Security Considerations**:
   - If content shouldn't be public, use Signed URLs or Signed Cookies
   - Consider using Cloud Armor for DDoS protection

### Cleanup Steps

After completing the lab, clean up resources to avoid unnecessary charges:

```bash
# Delete forwarding rule
gcloud compute forwarding-rules delete ${FORWARDING_RULE_NAME} --global --quiet

# Delete target HTTP proxy
gcloud compute target-http-proxies delete ${HTTP_PROXY_NAME} --quiet

# Delete URL map
gcloud compute url-maps delete ${URL_MAP_NAME} --quiet

# Delete backend bucket
gcloud compute backend-buckets delete ${BACKEND_BUCKET_NAME} --quiet

# Release static IP
gcloud compute addresses delete ${IP_NAME} --global --quiet

# (Optional) Delete Cloud Storage bucket contents and bucket
gsutil rm -r gs://${BUCKET_NAME}
```

## Additional Resources

- [Cloud CDN Official Documentation](https://cloud.google.com/cdn/docs)
- [Serving Content from Cloud Storage with Cloud CDN](https://cloud.google.com/cdn/docs/setting-up-cdn-with-bucket)
- [Cloud CDN Caching Overview](https://cloud.google.com/cdn/docs/caching)
- [gcloud compute backend-buckets Command Reference](https://cloud.google.com/sdk/gcloud/reference/compute/backend-buckets)
- [HTTP(S) Load Balancing Overview](https://cloud.google.com/load-balancing/docs/https)

## Technical Notes

### Cloud CDN Architecture

Cloud CDN uses Google's global network of edge nodes to cache and serve content. The architecture includes:
- **Origin Server**: Cloud Storage bucket
- **Backend Bucket**: GCP resource connecting CDN and Storage
- **Load Balancer**: Includes URL map, target proxy, and forwarding rule
- **Edge Nodes**: Cache servers distributed globally

### Caching Behavior

Cloud CDN caching behavior is influenced by multiple factors:
- **Cache-Control Headers**: Caching directives set by the origin
- **Cache Mode**: Cache mode setting of the backend bucket
- **Request Type**: Some request types (like POST) won't be cached

### Performance Considerations

- **First Request**: The first request fetches content from origin (cache miss)
- **Subsequent Requests**: Subsequent requests for the same content are served from the nearest edge node (cache hit)
- **Cache Invalidation**: Use `gcloud compute url-maps invalidate-cdn-cache` to manually clear cache

### Monitoring Metrics

Important monitoring metrics include:
- **Cache hit ratio**: Percentage of requests served from cache
- **Request count**: Number of requests
- **Bandwidth**: Bandwidth usage
- **Error rate**: Rate of errors

---

**Completion Timestamp**: This guide was last updated on 2026-02-15

**Note**: Actual bucket names, regions, and other parameters may vary depending on your lab environment. Please adjust the variables in the commands according to the specific information provided by the lab.
