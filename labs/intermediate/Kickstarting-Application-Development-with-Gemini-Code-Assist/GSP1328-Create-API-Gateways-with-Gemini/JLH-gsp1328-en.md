# GSP1328 - Create API Gateways with Gemini

## Overview

Gemini is an AI-powered collaborator helping development teams build, deploy, and operate applications faster and more efficiently.

In this lab, you will learn how Gemini for Developers can be used to assist in writing new code segments, extracting code for micro service decomposition, and building an API Gateway as part of the Cymbal Superstore project.

The labs in this course covers a typical software development life cycle (SDLC) from the application developers point of view. Other aspects of the SDLC (requirements, security, monitoring, etc.) will be covered in other courses.

## Objectives

This lab focuses on utilizing Gemini for Developers in the following ways:

- Use Gemini Chat to guide you through the steps needed to deploy an API Gateway service.

## What you'll learn

Cymbal Superstore is a thriving online shopping platform seeking continuous improvements to stay competitive in the market. As part of the ongoing development efforts, a new feature named 'New Products' is designed, allowing users to easily discover the latest additions to the store's inventory.

In this lab, we will be implementing this new feature - Specifically adding a new endpoint service called 'New Products'. All of the existing code will be provided as part of the lab setup, as well as any infrastructure services needed for the lab. The code will be in a folder called 'cymbal-superstore'.

## Task 1. Investigate the Code and Deploy the Cloud Function

### Set environment variables

1. In Cloud Shell, run the following command to set the necessary environment variables.

```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=Lab Region
export ZONE=Lab Zone
```

### Investigate the code

Along with Gemini's ability to explain code segments you are not familiar with, it can also create comments for you to add to your code to increase understanding during future maintenance cycles.

1. Click the **Open Editor** option visible at the top right of the Cloud Shell window to open the editor.

2. Click on **Menu** on the left, and navigate to **File** > **Open Folder...**.

3. Select the **cymbal-superstore** directory, and click **OK**.

4. Click the arrow next to **Gemini** at the top right of the file.

5. Click on **Select Gemini Code Assist Project**, to select the project to use for Gemini. From the list, select `GCP Project ID` project.

6. Highlight the entire code block using **Ctrl+A** or **Cmd+A**, and press the Yellow or Blue light bulb to display the Gemini assist options and then select `Gemini: Explain this`. This opens a **GEMINI: CHAT** panel and will explain the whole code in the chat.

7. If a general answer is supplied, then type `Explain in more detail` in the chat prompt.

### Deploy the Cloud Function

Let's now deploy the Cloud Function.

1. Switch back to the Cloud Shell terminal using the **Open Terminal** button present on the tool bar of the Cloud Shell window. In the Cloud Shell terminal, run the below command to create a Cloud Function named `newproducts`.

```bash
cd ~/cymbal-superstore/functions
gcloud functions deploy newproducts --runtime nodejs20 --trigger-http --allow-unauthenticated --region $REGION
```

**Note:** If the cloud function creation fails due to missing permissions, rerun the above command.

2. Test the new function by navigating to the URL from a new browser tab, and verify that JSON data is returned as expected.

## Task 2. Create a Middleware API

To separate and safeguard our backend service from a public website, we ideally employ an API proxy. We can accomplish this in Google Cloud using Apigee, Endpoints. In our case, let's use API Gateway service.

1. In Cloud Shell, set environment variables used for the API Gateway

```bash
export CONFIG_ID=newproducts-api-config
export API_ID=newproducts-api
export GATEWAY_ID=store
export OPENAPI_SPEC=newproducts.yaml
```

2. Let's create a new file named `newproducts.yaml`.

```bash
cd ~/cymbal-superstore/gateway
touch newproducts.yaml
```

3. Let's ask **Gemini** for some assistance for creating the OpenAPI spec. Switch back to the editor using the **Open Editor** option on the tool bar of the Cloud Shell window.

4. Open the `functions` folder and select the `index.js` file in the editor. Start a new chat by clicking on the **plus** (**+**) icon and enter the following prompt.

```
"Create an OpenAPI specification for this Cloud Function. The function returns a list of products from Firestore. The function URL is: [Cloud Function URL]"
```

5. You can use the generated code and paste it into the `newproducts.yaml` file under the `gateway` folder, and make necessary edits, if necessary, or use the following code.

The file should look similar to this:

```yaml
swagger: "2.0"
info:
  title: "newproducts"
  description: "A Cloud Function that returns a list of products from Firestore."
  version: "1.0.0"
host: "Lab Default Region-PROJECT_ID.cloudfunctions.net"
schemes:
- "https"
paths:
  /newproducts:
    get:
      summary: "Get a list of products from Firestore."
      operationId: "newproducts"
      produces:
      - "application/json"
      responses:
        "200":
          description: "A list of products."
          schema:
            type: "array"
            items:
              type: "object"
              properties:
                id:
                  type: "string"
                name:
                  type: "string"
                price:
                  type: "number"
                quantity:
                  type: "integer"
                imgfile:
                  type: "string"
                timestamp:
                  type: "string"
                actualdateadded:
                  type: "string"
```

## Task 3. Create the API Gateway service

1. Switch back to the Cloud Shell terminal using the **Open Terminal** button the tool bar of the Cloud Shell window, and enable the API gateway service using the following command.

```bash
gcloud services enable apigateway.googleapis.com
```

2. Ask Gemini for the steps creating the API Gateway. Enter the following prompt in the chat.

```
"Guide me through the steps to create an API Gateway in Google Cloud using the OpenAPI specification I just created."
```

**Note:** You may get a variety of responses. Sometimes Gemini responds with an overview and you need to ask for more details. Other times the answer may use generic names so you need to adjust accordingly.

3. In the Cloud Shell terminal, create an API in Google Cloud API Gateway service using the OpenAPI Specification.

```bash
cd ~/cymbal-superstore
gcloud api-gateway apis create $API_ID
```

4. Create a new API configuration in Google Cloud API Gateway.

```bash
cd ~/cymbal-superstore/gateway
gcloud api-gateway api-configs create $CONFIG_ID \
    --api=$API_ID --openapi-spec=$OPENAPI_SPEC
```

If this command fails with the following error.

```
ERROR: (gcloud.api-gateway.api-configs.create) API Config has a backend with no address. If using OpenAPI, each 'x-google-backend' extension requires the 'address' field to be set.
```

Refer to this [document](https://cloud.google.com/endpoints/docs/openapi/openapi-extensions#x-google-backend) to gain some insight.

5. To remediate the above error, add the following code in the `newproducts.yaml` file.

```yaml
x-google-backend:
        address: https://Lab Default Region-Project Name.cloudfunctions.net/newproducts
```

6. The `newproducts.yaml` file should finally look like the following:

```yaml
swagger: "2.0"
info:
  title: "newproducts"
  description: "A Cloud Function that returns a list of products from Firestore."
  version: "1.0.0"
host: "Lab Default Region-PROJECT_ID.cloudfunctions.net"
schemes:
- "https"
paths:
  /newproducts:
    get:
      summary: "Get a list of products from Firestore."
      operationId: "newproducts"
      x-google-backend:
        address: https://Lab Default Region-PROJECT_ID.cloudfunctions.net/newproducts
      produces:
      - "application/json"
      responses:
        "200":
          description: "A list of products."
          schema:
            type: "array"
            items:
              type: "object"
              properties:
                id:
                  type: "string"
                name:
                  type: "string"
                price:
                  type: "number"
                quantity:
                  type: "integer"
                imgfile:
                  type: "string"
                timestamp:
                  type: "string"
                actualdateadded:
                  type: "string"
```

7. Now, try creating the API configuration again.

```bash
gcloud api-gateway api-configs create $CONFIG_ID \
    --api=$API_ID --openapi-spec=$OPENAPI_SPEC
```

8. Finally, create the gateway based on the configuration file.

```bash
gcloud api-gateway gateways create $GATEWAY_ID \
    --api=$API_ID --api-config=$CONFIG_ID \
    --location=$REGION --project=$PROJECT_ID
```

9. Verify the gateway was created and deployed.

```bash
gcloud api-gateway gateways describe $GATEWAY_ID \
    --location=$REGION --project=$PROJECT_ID
```

Note down the **defaultHostname** value from the output, that should be similar to this: `store-2srcbsle.uc.gateway.dev`. You will require this in the later stages of the lab.

10. From the browser, open the new tab and enter the **defaultHostname** noted down earlier and append `/newproducts` to it. The URL should look similar to this: `https://store-2srcbsle.uc.gateway.dev/newproducts`

You should see 10 JSON records as displayed in the output below.

## Task 4. Update the Frontend Website

In this section, let's update the frontend to reflect the new `GATEWAY_ID` hostname.

1. In Cloud Shell Terminal, navigate to `frontend` folder:

```bash
cd ~/cymbal-superstore/frontend
```

2. Verify that one of the files, `.env.production` or `env.production` is available. To ensure which file is available run the below command:

```bash
ls -all
```

3. Update the available file `.env.production` or `env.production` to update the URL to reference the API Gateway. Replace the comment `YOUR_ENDPOINT_URL_HERE` with gateway's **defaultHostname**, noted down earlier. Do not forget to exclude the `/newproducts` path.

4. Switch back to the Cloud Shell terminal and rebuild the frontend.

```bash
cd ~/cymbal-superstore/frontend
npm install && npm run build
```

5. Upload all files and directories from the `build` directory to a Google Cloud Storage bucket.

```bash
gcloud storage cp -r build/* gs://${PROJECT_ID}-cymbal-frontend --cache-control=no-cache,no-store,max-age=0
```

6. Use the website's External IP address to display the Cymbal Superstore home page. Using **Navigation menu ()**, navigate to **View All Products > Networking > Network services > Load Balancing**. Click on `cymbal-url-map` and note down the IP under **Frontend**.

7. Open a new browser tab and enter the IP noted down earlier. Click on `New Arrivals!` link on the homepage.

You will be then be redirected to the new page, with the 10 products. The 10 products shown confirm the backend has properly fetched the new products from the database.

## Congratulations!

You have successfully established an API Gateway to act as a security proxy between a public website and the backend service with Gemini's assistance.

## Related Resources

- [API Gateway Documentation](https://cloud.google.com/api-gateway/docs)
- [Cloud Functions Documentation](https://cloud.google.com/functions/docs)
- [OpenAPI Specification](https://swagger.io/specification/)

## Troubleshooting

### Common Issues

1. **Cloud Function Deployment Failure**
   - Ensure you have sufficient permissions
   - Check if region settings are correct
   - Verify code syntax

2. **API Gateway Creation Failure**
   - Check OpenAPI specification format
   - Ensure Cloud Function URL is correct
   - Verify API Gateway service is enabled

3. **Frontend Not Loading**
   - Check Cloud Storage bucket permissions
   - Verify build process completed
   - Ensure environment variables are set correctly

## Next Steps

After completing this lab, you can:

- Explore more Gemini for Developers features
- Learn about other GCP API management services
- Implement more complex microservice architectures
