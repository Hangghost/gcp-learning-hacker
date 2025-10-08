# GSP041 - Use an Internal Application Load Balancer

## Lab Overview
The internal Application Load Balancer is essential for building robust, secure, and easily manageable internal applications that power your business operations. This lab explores how to distribute network traffic within your private cloud network without exposing your virtual machines (VMs) directly to the public internet, which keeps your services secure and efficient.

In this lab, you will build a simplified but very common architectural pattern:
- "Web Tier" (public-facing website) that needs to request help from another internal service
- "Internal Service Tier" (prime number calculator) that performs specific tasks and is distributed across multiple machines

## Prerequisites
- Basic familiarity with Google Cloud Compute Engine: Understanding what a Virtual Machine (VM) instance is
- Basic concepts of networking: What an IP address is
- Basic Unix/Linux command line: How to type commands in a terminal
- Some knowledge about VPCs (Virtual Private Clouds): Understanding that your Google Cloud resources live in a private network

## Objectives
By the end of this lab, you will be able to:
- Learn about the components that make up an Internal Load Balancer
- Create a group of backend machines (prime number calculator)
- Set up internal load balancer to direct internal traffic to the backend machines
- Test the internal load balancer from another internal machine
- Set up a public-facing web server that uses the internal load balancer to get results from the internal "prime number calculator" service

## Estimated Time
60-90 minutes

## Lab Steps

### Step 1: Create a Virtual Environment
Set up a Python virtual environment to keep your project's software tidy.

**Instructions:**
1. Install the `virtualenv` environment:
   ```bash
   sudo apt-get install -y virtualenv
   ```

2. Build the virtual environment:
   ```bash
   python3 -m venv venv
   ```

3. Activate the virtual environment:
   ```bash
   source venv/bin/activate
   ```

**Expected Result:**
Virtual environment has been successfully created and activated.

### Step 2: Enable Gemini Code Assist in Cloud Shell IDE
Enable Gemini Code Assist in Cloud Shell IDE to receive code guidance.

**Instructions:**
1. Enable Gemini for Google Cloud API:
   ```bash
   gcloud services enable cloudaicompanion.googleapis.com
   ```

2. Click **Open Editor** on the Cloud Shell toolbar

3. In the left pane, click the **Settings** icon, then in the **Settings** view, search for **Gemini Code Assist**

4. Ensure the checkbox for **Geminicodeassist: Enable** is selected

5. Click **Cloud Code - No Project** in the status bar

6. Authorize the plugin as instructed

**Expected Result:**
Gemini Code Assist is enabled and available for use in the editor.

### Step 3: Create a Backend Managed Instance Group
Create a managed instance group to automatically create and maintain identical copies of your service.

**Instructions:**
1. Create startup script `backend.sh`:
   ```bash
   touch ~/backend.sh
   ```

2. Add the following script content in the editor:
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

3. Create instance template:
   ```bash
   gcloud compute instance-templates create primecalc \
   --metadata-from-file startup-script=backend.sh \
   --no-address --tags backend --machine-type=e2-medium
   ```

4. Open firewall rule:
   ```bash
   gcloud compute firewall-rules create http --network default --allow=tcp:80 \
   --source-ranges IP --target-tags backend
   ```

5. Create instance group:
   ```bash
   gcloud compute instance-groups managed create backend \
   --size 3 \
   --template primecalc \
   --zone ZONE
   ```

**Expected Result:**
A managed instance group with 3 backend VMs has been created.

### Step 4: Set Up the Internal Load Balancer
Set up the internal load balancer and connect it to the instance group you just created.

**Instructions:**
1. Create health check:
   ```bash
   gcloud compute health-checks create http ilb-health --request-path /2
   ```

2. Create backend service:
   ```bash
   gcloud compute backend-services create prime-service \
   --load-balancing-scheme internal --region=REGION \
   --protocol tcp --health-checks ilb-health
   ```

3. Add instance group to backend service:
   ```bash
   gcloud compute backend-services add-backend prime-service \
   --instance-group backend --instance-group-zone=ZONE \
   --region=REGION
   ```

4. Create forwarding rule:
   ```bash
   gcloud compute forwarding-rules create prime-lb \
   --load-balancing-scheme internal \
   --ports 80 --network default \
   --region=REGION --address IP \
   --backend-service prime-service
   ```

**Expected Result:**
Internal load balancer is set up and ready to query the prime number calculation service through its internal IP address.

### Step 5: Test the Load Balancer
Create a test instance to verify that the internal Application Load Balancer correctly directs traffic to the backend services.

**Instructions:**
1. Create test instance:
   ```bash
   gcloud compute instances create testinstance \
   --machine-type=e2-standard-2 --zone ZONE
   ```

2. SSH into test instance:
   ```bash
   gcloud compute ssh testinstance --zone ZONE
   ```

3. Query the load balancer:
   ```bash
   curl IP/2
   curl IP/4
   curl IP/5
   ```

4. Exit and delete test instance:
   ```bash
   exit
   gcloud compute instances delete testinstance --zone=ZONE
   ```

**Expected Result:**
You should see that 2 and 5 are correctly identified as prime numbers, but 4 is not.

### Step 6: Create a Public-Facing Web Server
Create a public-facing web server that uses the internal "prime number calculator" service to display a prime number matrix.

**Instructions:**
1. Create frontend startup script `frontend.sh`:
   ```bash
   touch ~/frontend.sh
   ```

2. Add frontend script content in the editor (including complete code for getprimes.py)

3. Create frontend instance:
   ```bash
   gcloud compute instances create frontend --zone=ZONE \
   --metadata-from-file startup-script=frontend.sh \
   --tags frontend --machine-type=e2-standard-2
   ```

4. Open firewall for frontend:
   ```bash
   gcloud compute firewall-rules create http2 --network default --allow=tcp:80 \
   --source-ranges 0.0.0.0/0 --target-tags frontend
   ```

**Expected Result:**
You can access the frontend's external IP through a browser and see the prime number matrix display.

## Verification
1. Check Compute Engine > VM instances for 3 backend VMs and 1 frontend VM
2. Access frontend external IP through browser to confirm prime number matrix displays correctly
3. Test different paths (such as /10000) to confirm service response

## Troubleshooting
Common issues and their solutions:
- **Health check failure**: Confirm backend VMs are running and port 80 is accessible
- **Firewall rule issues**: Check if firewall rules are created correctly and target tags match
- **Load balancer not responding**: Confirm forwarding rules and backend service configuration are correct
- **Frontend not accessible**: Check frontend VM's external IP and firewall rules

## Cleanup
To avoid charges, please clean up resources:
1. Delete frontend instance:
   ```bash
   gcloud compute instances delete frontend --zone=ZONE
   ```

2. Delete backend instance group:
   ```bash
   gcloud compute instance-groups managed delete backend --zone=ZONE
   ```

3. Delete instance template:
   ```bash
   gcloud compute instance-templates delete primecalc
   ```

4. Delete load balancer components:
   ```bash
   gcloud compute forwarding-rules delete prime-lb --region=REGION
   gcloud compute backend-services delete prime-service --region=REGION
   gcloud compute health-checks delete ilb-health
   ```

5. Delete firewall rules:
   ```bash
   gcloud compute firewall-rules delete http
   gcloud compute firewall-rules delete http2
   ```

## Additional Resources
- [Internal Application Load Balancer Documentation](https://cloud.google.com/load-balancing/docs/l7-internal)
- [Subnetworks Documentation](https://cloud.google.com/compute/docs/subnetworks)
- [Google Cloud Training and Certification](https://cloud.google.com/training)

## Notes
This lab demonstrates how to build reliable internal services using Google Cloud's internal Application Load Balancer and shows how public applications can securely leverage it. The focus is on understanding the architectural patterns and implementation details of internal load balancing.
