# GSP007 - Set Up Network Load Balancers

## Lab Overview
In this hands-on lab you learn how to set up a passthrough network load balancer (NLB) running on Compute Engine virtual machines (VMs). A Layer 4 (L4) NLB handles traffic based on network-level information like IP addresses and port numbers, and does not inspect the content of the traffic.

There are several ways you can [load balance on Google Cloud](https://cloud.google.com/load-balancing/docs/load-balancing-overview#a_closer_look_at_cloud_load_balancers). This lab takes you through the setup of the following load balancers:

- [Network Load Balancer](https://cloud.google.com/compute/docs/load-balancing/network/)

You are encouraged to type the commands yourself, which can help you learn the core concepts. Many labs include a code block that contains the required commands. You can easily copy and paste the commands from the code block into the appropriate places during the lab.

## Prerequisites
- Google Cloud Platform account
- Basic familiarity with Google Cloud Console
- Understanding of basic Compute Engine virtual machine concepts
- Familiarity with Linux command line operations

## Objectives
By the end of this lab, you will be able to:
- Configure the default region and zone for your resources
- Create multiple web server instances
- Configure a load balancing service
- Configure a forwarding rule to distribute traffic

## Estimated Time
45-60 minutes

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

5. Run the following to list your instances. You'll see their IP addresses in the `EXTERNAL_IP` column:
   ```bash
   gcloud compute instances list
   ```

6. Verify that each instance is running with `curl`, replacing **[IP_ADDRESS]** with the external IP address for each of your VMs:
   ```bash
   curl http://[IP_ADDRESS]
   ```

**Expected Result:**
Three web server instances have been successfully created and firewall rules allow HTTP traffic.

### Step 3: Configure the load balancing service
When you configure the load balancing service, your virtual machine instances receives packets that are destined for the static external IP address you configure. Instances made with a Compute Engine image are automatically configured to handle this IP address.

**Note:** Learn more about how to set up Network Load Balancing from the [Backend service-based external passthrough Network Load Balancer overview](https://cloud.google.com/compute/docs/load-balancing/network/) guide.

**Instructions:**
1. Create a static external IP address for your load balancer:
   ```bash
   gcloud compute addresses create network-lb-ip-1 \
     --region Region
   ```

2. Add a legacy HTTP health check resource:
   ```bash
   gcloud compute http-health-checks create basic-check
   ```

**Expected Result:**
Static external IP address and HTTP health check have been created.

### Step 4: Create the target pool and forwarding rule
A target pool is a group of backend instances that receive incoming traffic from external passthrough NLBs. All backend instances of a target pool must reside in the same Google Cloud region.

**Instructions:**
1. Run the following to create the target pool and use the health check, which is required for the service to function:
   ```bash
   gcloud compute target-pools create www-pool \
     --region Region --http-health-check basic-check
   ```

2. Add the instances you created earlier to the pool:
   ```bash
   gcloud compute target-pools add-instances www-pool \
       --instances www1,www2,www3
   ```

Next you'll make the [forwarding rule](https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts). A forwarding rule specifies how to route network traffic to the backend services of a load balancer.

3. Add a forwarding rule:
   ```bash
   gcloud compute forwarding-rules create www-rule \
       --region  Region \
       --ports 80 \
       --address network-lb-ip-1 \
       --target-pool www-pool
   ```

**Expected Result:**
Target pool and forwarding rule have been successfully created.

### Step 5: Send traffic to your instances
Now that the load balancing service is configured, you can start sending traffic to the forwarding rule and watch the traffic be dispersed to different instances.

**Instructions:**
1. Enter the following command to view the external IP address of the www-rule forwarding rule used by the load balancer:
   ```bash
   gcloud compute forwarding-rules describe www-rule --region Region
   ```

2. Access the external IP address:
   ```bash
   IPADDRESS=$(gcloud compute forwarding-rules describe www-rule --region Region --format="json" | jq -r .IPAddress)
   ```

3. Show the external IP address:
   ```bash
   echo $IPADDRESS
   ```

4. Use the `curl` command to access the external IP address, replacing `IP_ADDRESS` with an external IP address from the previous command:
   ```bash
   while true; do curl -m1 $IPADDRESS; done
   ```

   The response from the `curl` command alternates randomly among the three instances. If your response is initially unsuccessful, wait approximately 30 seconds for the configuration to be fully loaded and for your instances to be marked healthy before trying again.

5. Use **Ctrl** + **C** to stop running the command.

**Expected Result:**
Traffic is successfully distributed across the three web server instances.

## Verification
To verify that the lab was completed successfully:
1. Confirm all three VM instances are running
2. Confirm firewall rules allow HTTP traffic
3. Confirm load balancer IP address is accessible
4. Confirm traffic is correctly distributed between instances

## Troubleshooting
Common issues and their solutions:
- **Instances not accessible**: Check that firewall rules are correctly applied to instance tags
- **Load balancer not routing traffic**: Ensure health checks are passing and instances are marked healthy
- **curl command fails**: Wait 30 seconds for configuration to fully load
- **IP address not assigned**: Check that region configuration is correct

## Cleanup
To avoid charges, clean up resources by following these steps:
1. Delete the forwarding rule:
   ```bash
   gcloud compute forwarding-rules delete www-rule --region Region --quiet
   ```

2. Delete the target pool:
   ```bash
   gcloud compute target-pools delete www-pool --region Region --quiet
   ```

3. Delete the instances:
   ```bash
   gcloud compute instances delete www1 www2 www3 --zone Zone --quiet
   ```

4. Delete the firewall rule:
   ```bash
   gcloud compute firewall-rules delete www-firewall-network-lb --quiet
   ```

5. Delete the static IP address:
   ```bash
   gcloud compute addresses delete network-lb-ip-1 --region Region --quiet
   ```

6. Delete the health check:
   ```bash
   gcloud compute http-health-checks delete basic-check --quiet
   ```

## Additional Resources
- [Network Load Balancing Documentation](https://cloud.google.com/compute/docs/load-balancing/network/)
- [Load Balancing Overview](https://cloud.google.com/load-balancing/docs/load-balancing-overview)
- [Compute Engine Regions and Zones](https://cloud.google.com/compute/docs/zones)
- [Forwarding Rule Concepts](https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts)

## Notes
This lab demonstrates how to set up a basic network load balancer. Key learning points include:
- Network load balancers operate at Layer 4
- Target pools are used to manage backend instances
- Health checks ensure only healthy instances receive traffic
- Forwarding rules route traffic to the load balancer
