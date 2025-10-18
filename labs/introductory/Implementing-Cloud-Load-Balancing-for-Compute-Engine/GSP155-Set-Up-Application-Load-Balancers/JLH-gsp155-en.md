# GSP155 - Set Up Application Load Balancers

## Lab Overview
In this hands-on lab you learn how to set up a Layer 7 (L7) application load balancer on Compute Engine virtual machines (VMs). L7 load balancers can understand HTTP(S) protocols, allowing them to make routing decisions based on parameters like URL, headers, cookies, and the content of the request. This allows for improved application performance and responsiveness.

There are several ways you can [load balance on Google Cloud](https://cloud.google.com/load-balancing/docs/load-balancing-overview#a_closer_look_at_cloud_load_balancers). This lab takes you through the setup of the following load balancers:

- [Application Load Balancer](https://cloud.google.com/compute/docs/load-balancing/http/)

You are encouraged to type the commands yourself, which can help you learn the core concepts. Many labs include a code block that contains the required commands. You can easily copy and paste the commands from the code block into the appropriate places during the lab.

## Prerequisites
- Google Cloud Platform account
- Basic familiarity with Google Cloud Console
- Understanding of basic Compute Engine virtual machine concepts
- Familiarity with Linux command line operations
- Understanding of load balancing concepts

## Objectives
By the end of this lab, you will be able to:
- Configure the default region and zone for your resources
- Create an Application Load Balancer
- Test traffic sent to your instances

## Estimated Time
60-75 minutes

## Lab Steps

### Step 1: Set the default region and zone for all resources
In this task, you set the default region and zone for your Google Cloud resources.

**Instructions:**
1. Set the default region:
   ```bash
   gcloud config set compute/region Region
   ```

2. In Cloud Shell, set the default zone:
   ```bash
   gcloud config set compute/zone Zone
   ```

   Learn more about choosing zones and regions in Compute Engine's [Regions and zones](https://cloud.google.com/compute/docs/zones) documentation.

**Expected Result:**
Default region and zone have been successfully configured.

### Step 2: Create multiple web server instances
For this load balancing scenario, you create three Compute Engine VM instances and install Apache on them, then add a firewall rule that allows HTTP traffic to reach the instances.

The code provided sets the zone to `Zone`. Setting the `tags` field lets you reference these instances all at once, such as with a firewall rule. These commands also install Apache on each instance and give each instance a unique home page.

**Instructions:**
1. Create a virtual machine, `www1`, in your default zone using the following code:
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

2. Create a virtual machine, `www2`, in your default zone using the following code:
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

3. Create a virtual machine, `www3`, in your default zone:
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

4. Create a firewall rule to allow external traffic to the VM instances:
   ```bash
   gcloud compute firewall-rules create www-firewall-network-lb \
       --target-tags network-lb-tag --allow tcp:80
   ```

Now you need to get the external IP addresses of your instances and verify that they are running.

1. Run the following to list your instances. You'll see their IP addresses in the `EXTERNAL_IP` column:
   ```bash
   gcloud compute instances list
   ```

2. Verify that each instance is running with `curl`, replacing `[IP_ADDRESS]` with the external IP address for each of your VMs:
   ```bash
   curl http://[IP_ADDRESS]
   ```

**Expected Result:**
Three web server instances have been created and are running, each displaying its unique identifier.

### Step 3: Create an Application Load Balancer
Application Load Balancing is implemented on Google Front End (GFE). GFEs are distributed globally and operate together using Google's global network and control plane. You can configure URL rules to route some URLs to one set of instances and route other URLs to other instances.

Requests are always routed to the instance group that is closest to the user, if that group has enough capacity and is appropriate for the request. If the closest group does not have enough capacity, the request is sent to the closest group that does have capacity.

To set up a load balancer with a Compute Engine backend, your VMs need to be in an instance group. The managed instance group provides VMs running the backend servers of an external application load balancer. For this lab, backends serve their own hostnames.

**Instructions:**
1. First, create the load balancer template:
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

   [Managed instance groups](https://cloud.google.com/compute/docs/instance-groups) (MIGs) let you operate apps on multiple identical VMs. You can make your workloads scalable and highly available by taking advantage of automated MIG services, including: autoscaling, autohealing, regional (multiple zone) deployment, and automatic updating.

2. Create a managed instance group based on the template:
   ```bash
   gcloud compute instance-groups managed create lb-backend-group \
      --template=lb-backend-template --size=2 --zone=Zone
   ```

3. Create the `fw-allow-health-check` firewall rule:
   ```bash
   gcloud compute firewall-rules create fw-allow-health-check \
     --network=default \
     --action=allow \
     --direction=ingress \
     --source-ranges=130.211.0.0/22,35.191.0.0/16 \
     --target-tags=allow-health-check \
     --rules=tcp:80
   ```

   **Note:** The ingress rule allows traffic from the Google Cloud health checking systems (`130.211.0.0/22` and `35.191.0.0/16`). This lab uses the target tag `allow-health-check` to identify the VMs.

4. Now that the instances are up and running, set up a global static external IP address that your customers use to reach your load balancer:
   ```bash
   gcloud compute addresses create lb-ipv4-1 \
     --ip-version=IPV4 \
     --global
   ```

   Notice the IPv4 address that was reserved:
   ```bash
   gcloud compute addresses describe lb-ipv4-1 \
     --format="get(address)" \
     --global
   ```

   **Note:** Save this IP address, as you need to refer to it later in this lab.

5. Create a health check for the load balancer (to ensure that only healthy backends are sent traffic):
   ```bash
   gcloud compute health-checks create http http-basic-check \
     --port 80
   ```

6. Create a backend service:
   ```bash
   gcloud compute backend-services create web-backend-service \
     --protocol=HTTP \
     --port-name=http \
     --health-checks=http-basic-check \
     --global
   ```

7. Add your instance group as the backend to the backend service:
   ```bash
   gcloud compute backend-services add-backend web-backend-service \
     --instance-group=lb-backend-group \
     --instance-group-zone=Zone \
     --global
   ```

8. Create a [URL map](https://cloud.google.com/load-balancing/docs/url-map-concepts) to route the incoming requests to the default backend service:
   ```bash
   gcloud compute url-maps create web-map-http \
       --default-service web-backend-service
   ```

   **Note:** URL map is a Google Cloud configuration resource used to route requests to backend services or backend buckets. For example, with an external Application Load Balancer, you can use a single URL map to route requests to different destinations based on the rules configured in the URL map:

   - Requests for https://example.com/video go to one backend service.
   - Requests for https://example.com/audio go to a different backend service.
   - Requests for https://example.com/images go to a Cloud Storage backend bucket.
   - Requests for any other host and path combination go to a default backend service.

9. Create a [target HTTP proxy](https://cloud.google.com/load-balancing/docs/target-proxies) to route requests to your URL map:
   ```bash
   gcloud compute target-http-proxies create http-lb-proxy \
       --url-map web-map-http
   ```

10. Create a [global forwarding rule](https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts) to route incoming requests to the proxy:
    ```bash
    gcloud compute forwarding-rules create http-content-rule \
       --address=lb-ipv4-1\
       --global \
       --target-http-proxy=http-lb-proxy \
       --ports=80
    ```

**Note:** A [forwarding rule](https://cloud.google.com/load-balancing/docs/using-forwarding-rules) and its corresponding IP address represent the frontend configuration of a Google Cloud load balancer. Learn more about the general understanding of forwarding rules from the [Forwarding rules overview](https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts) guide.

**Expected Result:**
Application Load Balancer has been created with all necessary components (backend service, URL map, proxy, and forwarding rule).

### Step 4: Test traffic sent to your instances
Now you can test that the load balancer is working correctly.

**Instructions:**
1. On the Google Cloud console in the **Search** field type **Load balancing**, then choose **Load balancing** from the search results.
2. Click on the load balancer that you just created, `web-map-http`.
3. In the **Backend** section, click on the name of the backend and confirm that the VMs are **Healthy**. If they are not healthy, wait a few moments and try reloading the page.
4. When the VMs are healthy, test the load balancer using a web browser, going to `http://IP_ADDRESS/`, replacing `IP_ADDRESS` with the load balancer's IP address that you copied previously.

**Note:** This may take three to five minutes. If you do not connect, wait a minute, and then reload the browser.

Your browser should render a page with content showing the name of the instance that served the page, along with its zone (for example, `Page served from: lb-backend-group-xxxx`).

**Expected Result:**
Load balancer is functioning properly, requests are being routed to healthy backend instances, and responses are displayed from different instances.

## Verification
To verify that the lab was completed successfully:
1. Load balancer shows as healthy in Google Cloud Console
2. Accessing the load balancer's IP address returns web pages from backend instances
3. Refreshing the page multiple times shows responses from different instances (proving load balancing is working)

## Troubleshooting
Common issues and their solutions:
- **Load balancer not showing as healthy**: Wait a few minutes for health checks to complete, or check that firewall rules are configured correctly
- **Cannot access load balancer IP**: Ensure forwarding rule was created correctly and global IP address was properly assigned
- **VM instances not starting**: Check for syntax errors in startup scripts, or ensure VM has sufficient resource quotas

## Cleanup
Instructions for cleaning up resources to avoid charges:
1. Delete the forwarding rule:
   ```bash
   gcloud compute forwarding-rules delete http-content-rule --global --quiet
   ```

2. Delete the target HTTP proxy:
   ```bash
   gcloud compute target-http-proxies delete http-lb-proxy --quiet
   ```

3. Delete the URL map:
   ```bash
   gcloud compute url-maps delete web-map-http --quiet
   ```

4. Delete the backend service:
   ```bash
   gcloud compute backend-services delete web-backend-service --global --quiet
   ```

5. Delete the instance group:
   ```bash
   gcloud compute instance-groups managed delete lb-backend-group --zone=Zone --quiet
   ```

6. Delete the instance template:
   ```bash
   gcloud compute instance-templates delete lb-backend-template --quiet
   ```

7. Delete the health check:
   ```bash
   gcloud compute health-checks delete http-basic-check --quiet
   ```

8. Delete the global IP address:
   ```bash
   gcloud compute addresses delete lb-ipv4-1 --global --quiet
   ```

9. Delete the firewall rules:
   ```bash
   gcloud compute firewall-rules delete www-firewall-network-lb --quiet
   gcloud compute firewall-rules delete fw-allow-health-check --quiet
   ```

10. Delete the VM instances:
    ```bash
    gcloud compute instances delete www1 www2 www3 --zone=Zone --quiet
    ```

## Additional Resources
- [Set up a classic Application Load Balancer with a managed instance group backend](https://cloud.google.com/load-balancing/docs/https/ext-https-lb-simple)
- [External Application Load Balancer overview](https://cloud.google.com/load-balancing/docs/https)
- [Creating health checks](https://cloud.google.com/load-balancing/docs/health-checks)

## Notes
This lab demonstrates how to set up an Application Load Balancer, which is one of the most commonly used load balancer types in Google Cloud. Application Load Balancers provide L7 capabilities, allowing intelligent routing decisions based on HTTP request content.

Unlike Network Load Balancers, Application Load Balancers can inspect HTTP headers, URL paths, and cookies, making them suitable for more complex application architectures. This type of load balancer is particularly useful for modern web applications as they can implement content-based routing, SSL termination, and session affinity features.
