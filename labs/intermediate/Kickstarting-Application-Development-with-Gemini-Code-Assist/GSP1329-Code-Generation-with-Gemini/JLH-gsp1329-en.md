# GSP1329 - Code Generation with Gemini

## Overview

Gemini is an AI-powered collaborator helping development teams build, deploy, and operate applications faster and more efficiently.

Here we will show how Gemini for Developers can be used to assist in writing new code segments, extracting code for microservice decomposition, and building an API Gateway as part of the Cymbal Superstore project.

The labs in this course covers a typical software development life cycle (SDLC) from the application developers point of view. Other aspects of the SDLC (requirements, security, monitoring, etc.) will be covered in other courses.

**Lab Premise:** You have recently joined a team that has developed an online shopping website called Cymbal Superstore. It is operational and you have been tasked with implementing some upgrades. Specifically adding a new endpoint service called new products. All of the existing code will be provided as part of the lab setup as well as any infrastructure services needed for the lab. The code will be in a folder called cymbal-superstore.

## Objectives

In this lab, you learn how to utilize Gemini in the following ways:

1. Create effective code generation prompts using natural language descriptions.

2. Use in-line comments to generate and modify code.

## Understanding Regions and Zones

Certain Compute Engine resources live in regions or zones. A region is a specific geographical location where you can run your resources. Each region has one or more zones. For example, the us-central1 region denotes a region in the Central United States that has zones `us-central1-a`, `us-central1-b`, `us-central1-c`, and `us-central1-f`.

| **Regions** | **Zones** |
|-------------|-----------|
| Western US | us-west1-a, us-west1-b |
| Central US | us-central1-a, us-central1-b, us-central1-d, us-central1-f |
| Eastern US | us-east1-b, us-east1-c, us-east1-d |
| Western Europe | europe-west1-b, europe-west1-c, europe-west1-d |
| Eastern Asia | asia-east1-a, asia-east1-b, asia-east1-c |

Resources that live in a zone are referred to as zonal resources. Virtual machine Instances and persistent disks live in a zone. To attach a persistent disk to a virtual machine instance, both resources must be in the same zone. Similarly, if you want to assign a static IP address to an instance, the instance must be in the same region as the static IP.

Learn more about regions and zones and see a complete list in the Compute Engine page, [Regions and zones documentation](https://cloud.google.com/compute/docs/regions-zones)).

## Task 1. Setup the Cymbal Superstore

This lab uses the "Cymbal Superstore" grocery web app. In subsequent tasks of this lab, you use Gemini to develop and deploy a new feature in this app. In this task, you build the frontend and backend components of this app.

### Configure the environment

Execute the commands in this and the next two subtasks in the terminal shell.

1. In Cloud Shell, run the following command to set the necessary environment variables.

```bash
export PROJECT_ID=$(gcloud config get-value project)
export USER=$(gcloud config get-value account)
export REPO_NAME=store-repo
export REGION=Lab Region
export ZONE=Lab Zone
export APP_NAME=inventory
```

2. To run the Docker credential helper, run the following command. When asked if you want to continue, type **Y**.

```bash
gcloud auth configure-docker
```

3. Enable the Cloud AI Companion API:

```bash
gcloud services enable cloudaicompanion.googleapis.com --project ${PROJECT_ID}
```

4. To use Gemini, grant the necessary IAM roles to your Google Cloud Qwiklabs user account:

```bash
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member user:${USER} --role=roles/cloudaicompanion.user
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member user:${USER} --role=roles/serviceusage.serviceUsageViewer
```

Adding these roles lets the user use Gemini assistance.

5. To download the `cymbal-superstore` application code, run the following command:

```bash
gsutil -m cp -r gs://duet-appdev/cymbal-superstore .
```

### Build the backend

The web app backend implements an inventory API that is used by the frontend to fetch and update products.

1. To build the backend container image, in the cloud terminal, run the following commands:

```bash
cd ~/cymbal-superstore/backend
docker build -t gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api:latest .
```

2. To push the built backend image to the Cloud Repository, run the following command:

```bash
docker push gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api:latest
```

3. To deploy the backend as a service on Cloud Run, run the following command. Allow unauthenticated invocations to inventory by pressing the button **Y**.

```bash
gcloud run deploy inventory --image=gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api --port=8000 --region=$REGION
```

**Output:**

```
Deploying container to Cloud Run service [inventory] in project [PROJECT_ID] region [Lab Region]
OK Deploying... Done.
OK Creating Revision...
OK Routing traffic...
Done.
Service [inventory] revision [inventory-00002-n9z] has been deployed and is serving 100 percent of traffic.
Service URL: https://inventory-bacbqreknq-uk.a.run.app
```

Make note of the Cloud Run Service URL that was created (different from above).

### Verify endpoint is working

1. Check the new endpoint by browsing to the Cloud Run URL to call the endpoint.

2. In a browser tab, execute Cloud Run Service URL (from above):

**Example:** `https://inventory-bacbqreknq-uk.a.run.app`

**Output:**

`"🍎 Hello! This is the Cymbal Superstore Inventory API"`

To the base URL add the endpoint path `/products`.

**Example:** `https://inventory-bacbqreknq-uk.a.run.app/products`

**Example Output:**

```json
{"id":"01Jggpy8RcgXSZnsJ8gy","name":"Eggs","price":9,"quantity":227,"imgfile":"product-images/eggs.png","timestamp":{"_seconds":1704651168,"_nanoseconds":923000000},"actualdateadded":{"_seconds":1714468020,"_nanoseconds":203000000}},{"id":"0n0fnOTKQbR3W6eERmNY","name":"Peanut Butter and Jelly Cups","price":7,"quantity":8,"imgfile":"product-images/peanutbutterandjellycups.png","timestamp":{"_seconds":1713980240,"_nanoseconds":721000000},"actualdateadded":{"_seconds":1714468020,"_nanoseconds":213000000}}
```

This shows the JSON Data of all the store's products.

3. To the base URL add the endpoint path `/newproducts` - This will display an error since the newproducts endpoint has not been written.

**Example:** `https://inventory-bacbqreknq-uk.a.run.app/newproducts`

**Output:**

`Cannot GET /newproducts`

### Build frontend website and verify site works

1. Run the below command to navigate to the `frontend` folder:

```bash
cd ~/cymbal-superstore/frontend
```

2. Now rebuild the front end by running these commands in a terminal window.

```bash
npm install
npm audit fix --force
export NODE_OPTIONS=--openssl-legacy-provider
npm install react-scripts@5.0.1 --save-dev
npm run build
```

3. Upload it the Cloud Storage bucket.

```bash
gcloud storage cp -r build/* gs://$PROJECT_ID-cymbal-frontend --cache-control=no-cache,no-store,max-age=0
```

### Verify website is working

1. Use the website's External IP address to display the Cymbal Superstore home page. Using the Navigation menu (), navigate to **View All Products > Networking > Network services > Load Balancing**. Click on `cymbal-url-map` and note down the IP under Frontend.

2. Open a new browser tab and enter the IP noted down earlier. Click on `New Arrivals!` link on the homepage.

3. Verify it is dummy data (indicated by no photos and Test Products data).

## Task 2. Add newProducts endpoint to backend

1. Open the editor by clicking the **Open Editor** option visible at the top right of the Cloud Shell window.

2. Click on **Menu** on the left, and navigate to **File** > **Open Folder...**.

3. Select the **cymbal-superstore** directory, and click **OK**.

4. Investigate the code written in **index.ts** file under the `backend` folder.

5. At the top right of the file, click the arrow next to **Gemini**.

6. Click on **Select Gemini Code Assist Project**, to select the project to use for Gemini. From the list, select `GCP Project ID` project.

7. In the `index.ts` code file, scroll to line 102 where you see the placeholder comment for the `/newproducts` endpoint.

8. Replace the placeholder comment: `// /newproducts endpoint` goes here with the following prompt:

```typescript
// Create a new route called /newproducts that uses a where filter
// to retrieve only products that were added within the last seven days.
```

9. Select the newly added comment, and click on the yellow light bulb icon that appears. From the list, click on the following option: `Gemini: Generate code`.

10. Gemini displays some suggested code. Look at the suggested code and accept it by clicking **Accept** or pressing **Tab** key.

### Redeploy the backend

1. From the Cloud Shell terminal run the following commands to build the new container.

```bash
cd ~/cymbal-superstore/backend
docker build -t gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api:latest .
```

2. Push the new container into the Artifact Registry.

```bash
docker push gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api:latest
```

3. Deploy the container to Cloud Run

```bash
gcloud run deploy inventory --image=gcr.io/$PROJECT_ID/cymbal-superstore-inventory-api --port=8000 --region=$REGION
```

If asked: Allow unauthenticated invocations to [inventory] (y/N)? Enter **Y**.

**Output:**

```
Deploying container to Cloud Run service [inventory] in project [PROJECT_ID] region [Lab Region]
OK Deploying... Done.
OK Creating Revision...
OK Routing traffic...
Done.
Service [inventory] revision [inventory-00002-n9z] has been deployed and is serving 100 percent of traffic.
Service URL: https://inventory-bacbqreknq-uk.a.run.app
```

Make note of the Cloud Run Service URL that was created (different from above).

### Verify endpoint is working

1. In a browser tab, execute the Cloud Run Service URL (from above):

**Example:** `https://inventory-bacbqreknq-uk.a.run.app`

**Output:**

`"🍎 Hello! This is the Cymbal Superstore Inventory API"`

2. To the base URL add the endpoint path `/products`.

**Output:**

```json
{"id":"01Jggpy8RcgXSZnsJ8gy","name":"Eggs","price":5,"quantity":181,"imgfile":"product-images/eggs.png","timestamp":{"_seconds":1691767020,"_nanoseconds":20000000},"actualdateadded":{"_seconds":1714473490,"_nanoseconds":560000000}},{"id":"0n0fnOTKQbR3W6eERmNY","name":"Peanut Butter and Jelly Cups","price":5,"quantity":1,"imgfile":"product-images/peanutbutterandjellycups.png","timestamp":{"_seconds":1714000418,"_nanoseconds":14000000},"actualdateadded":{"_seconds":1714473490,"_nanoseconds":568000000}}
```

This shows the JSON Data of all the store's products.

3. To the base URL add the endpoint path `/newproducts`.

**Output:**

```json
{"id":"0n0fnOTKQbR3W6eERmNY","name":"Peanut Butter and Jelly Cups","price":5,"quantity":1,"imgfile":"product-images/peanutbutterandjellycups.png","timestamp":{"_seconds":1714000418,"_nanoseconds":14000000},"actualdateadded":{"_seconds":1714473490,"_nanoseconds":568000000}},{"id":"HwtaJN6kXj9YEQtzHB7P","name":"Pineapple Kombucha","price":9,"quantity":39,"imgfile":"product-images/pineapplekombucha.png","timestamp":{"_seconds":1714002141,"_nanoseconds":22000000},"actualdateadded":{"_seconds":1714473490,"_nanoseconds":567000000}}
```

This now works and you should see a JSON list that is smaller than the products list.

**Note:** If you added the quantity to the product name, in the optional step above, you should see that formatted in the JSON data. Example: "name":"Pineapple Kombucha (91)"

If you get a "System unavailable" message, or unexpected results, when you call the new /newproducts route, click the button below for a hint.

### Test code

1. Demonstrate the code works with the frontend Web Site.

2. Navigate to `frontend` folder:

```bash
cd ~/cymbal-superstore/frontend
```

3. Verify that one of the files, `.env.production` or `env.production` is available. To ensure which file is available run the below command:

```bash
ls -all
```

4. Update the available file `.env.production` or `env.production` with the URL to reference the Cloud Run URL. Replace the comment `YOUR_ENDPOINT_URL_HERE` with the Service URL. Do not forget to exclude the **/newproducts** path.

```bash
REACT_APP_INVENTORY_API_URL = <Cloud Run URL w/o the /newproducts path>
```

**Example:**

```bash
REACT_APP_INVENTORY_API_URL = https://inventory-l2imehewsq-uc.a.run.app
```

### Rebuild the frontend

1. Run the below command to navigate to the `frontend` folder:

```bash
cd ~/cymbal-superstore/frontend
```

2. Now rebuild the front end by running these commands in a terminal window.

```bash
npm install
npm audit fix --force
export NODE_OPTIONS=--openssl-legacy-provider
npm install react-scripts@5.0.1 --save-dev
npm run build
```

3. Upload it to the Cloud Storage bucket.

```bash
gcloud storage cp -r build/* gs://$PROJECT_ID-cymbal-frontend --cache-control=no-cache,no-store,max-age=0
```

4. Use the website's External IP address to display the Cymbal Superstore home page. Using **Navigation menu ()**, navigate to **View All Products > Networking > Network services > Load Balancing**. Click on `cymbal-url-map` and note down the IP under **Frontend**.

5. Open a new browser tab and enter the IP noted down earlier. Click on `New Arrivals!` link on the homepage and see the `Test Products` are no longer displayed or quickly replaced.

**Note:** The 10 products shown confirm the backend has properly fetched the new products from the database. Also, if you added the quantity to the product name, you should see some of the products show a quantity of 0.

## Task 3. Extract to new microservice using Cloud Functions

### Deploy a Cloud Function

Now lets see if we can deploy this new function.

1. In the Chat response, Gemini may have given you the deploy command. If not lets ask:

**Remember:** working with Gemini is a conversation. It may take some back and forth sessions to get a result that is close enough to get the job done or at least get started.

2. Open the `functions/index.js` file. Select the code by Pressing **Ctrl + A** or **Cmd+A**. Click on the light bulb and click on `Gemini: Explain this`. This will open the **GEMINI: CHAT** panel. Press **Enter** to receive a full explanation of the code in the chat.

3. In the Gemini Chat, enter the following prompt.

```
What is the gcloud command to deploy this /newproducts route as a Cloud Run Function in the Lab Region region? Don't forget to allow unauthenticated http requests.
```

**Deep Dive:**

To see how Gemini works relative to context, rerun the prompt under these other 2 scenarios.

1. Close all file windows and reset Gemini's Chat by clicking on the **New Chat** icon (+) above the chat - the prompt result will be very generic.

2. Open the package.json file - the prompt result will be specific, but might not show the http trigger option. This is because the package.json doesn't refer to http. The original result showed a command with the –trigger-http because Gemini saw that the endpoint was an http function.

4. Let's try it. In the terminal, change to the /functions folder:

```bash
cd ~/cymbal-superstore/functions
```

Then run the command Gemini gave you.

5. If the deployment doesn't work, click the button below for a hint.

The function was created!

**Note:** If the cloud function creation fails due to missing permissions, re-run the above command.

6. The function's URL is displayed in the terminal or you can find it by opening Cloud Functions in the Console.

**Example url:** `https://us-central1-qwiklabs-gcp-01-457d0634df06.cloudfunctions.net/newproducts`

### Let's test the new function

1. Show that it works by executing the cloud function with the **/newproducts** path to verify the JSON data is returned as expected.

2. From the function deploy response, copy the URL.

```
state: ACTIVE
updateTime: '2025-07-25T02:28:40.172396925Z'
url: https://Lab Region-PROJECT_ID.cloudfunctions.net/newproducts
```

3. Paste the URL into a browser tab and navigate to it.

**Output:**

```json
{"id":"vcMyZepctx3BrDL7yc5w","name":"Pineapple Kombucha (91)","price":1,"quantity":91,"imgfile":"product-images/pineapplekombucha.png","timestamp":{"_seconds":1707055701,"_nanoseconds":790000000},"actualdateadded":{"_seconds":1707500364,"_nanoseconds":191000000}},{"id":"ODThuqw2avA2mSvOUH6r","name":"White Chocolate Caramel Corn (9)","price":5,"quantity":9,"imgfile":"product-images/whitechocolatecaramelcorn.png","timestamp":{"_seconds":1707160496,"_nanoseconds":367000000},"actualdateadded":{"_seconds":1707500364,"_nanoseconds":192000000}}
```

You will see this is the same few JSON records that you saw earlier. Time to integrate it into the front end API

4. Edit the `frontend/env.production` or `frontend/.env.production` file to update the URL with the URL of the Cloud Function just created. Replace the Cloud Run URL with the new Cloud Function URL. Do not forget to exclude the `/newproducts` path.

**Example:**

5. Now rebuild the front end by running these commands in a terminal window.

```bash
cd ~/cymbal-superstore/frontend
npm install
npm audit fix --force
export NODE_OPTIONS=--openssl-legacy-provider
npm install react-scripts@5.0.1 --save-dev
npm run build
```

6. Upload it to the Cloud Storage bucket.

```bash
gcloud storage cp -r build/* gs://$PROJECT_ID-cymbal-frontend --cache-control=no-cache,no-store,max-age=0
```

7. Now let's try it Calling the Website IP by pressing the **New Arrivals**.

## Congratulations!

You have successfully implemented code generation with Gemini for Developers and extracted the new feature into a microservice.

## Related Resources

- [Gemini for Developers Documentation](https://cloud.google.com/gemini/docs)
- [Cloud Functions Documentation](https://cloud.google.com/functions/docs)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Docker Documentation](https://docs.docker.com/)

## Troubleshooting

### Common Issues

1. **Gemini Unable to Generate Code**
   - Ensure IAM roles are set correctly
   - Check Cloud AI Companion API is enabled
   - Verify comment format is correct

2. **Cloud Function Deployment Failure**
   - Ensure region settings are correct
   - Check code syntax
   - Verify permission settings

3. **Frontend Build Failure**
   - Ensure Node.js version compatibility
   - Check npm dependencies
   - Verify environment variables

4. **API Endpoint Not Responding**
   - Check Cloud Run/Cloud Function status
   - Verify URL is correct
   - Check firewall rules

## Next Steps

After completing this lab, you can:

- Explore more Gemini code generation features
- Learn microservice architecture patterns
- Implement more complex API endpoints
- Study Cloud Functions best practices
