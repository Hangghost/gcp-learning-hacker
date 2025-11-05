# GSP527 - Kickstarting Application Development with Gemini Code Assist: Challenge Lab

## Challenge Overview

This is a challenge lab where you're given a scenario and a set of tasks. Instead of following step-by-step instructions, you will use the skills learned from the labs in the course to figure out how to complete the tasks on your own! An automated scoring system (shown on this page) will provide feedback on whether you have completed your tasks correctly.

When you take a challenge lab, you will not be taught new Google Cloud concepts. You are expected to extend your learned skills, like changing default values and reading and researching error messages to fix your own mistakes.

To score 100% you must successfully complete all tasks within the time period!

This lab is recommended for students who have enrolled in the [Application Development with Gemini Code Assist](enter URL) skills badge. Are you ready for the challenge?

## Scenario Description

### Cymbal Direct: Implementing new features for the online store

You've recently joined the development team for the Cymbal Superstore, a thriving online shopping platform. A new feature, 'Products Out of Stock', is required to inform the restock team. An initial implementation of the `/outofstock` endpoint needs development, deployment, and rigorous testing.

Your goal is to leverage Gemini Code Assist in completing this feature, specifically focusing on developing the backend logic, extracting it into a microservice, exposing it securely, debugging issues, and ensuring it's well-tested.

A good way of increasing the efficiency of Generative AI assisted coding is to do Test-Driven Development (TDD). In this approach, you first develop the tests that your completed code should pass, and then you build the code accordingly. Because Gemini will be creating the code for you, you need a quick way to validate if that code is production-ready.

All necessary existing code and infrastructure services for the Cymbal Superstore will be provided as part of the lab setup in the `cymbal-superstore` folder. Are you ready for the challenge?

## Task Overview

Based on the skills you learned in GSP1328, GSP1329, and GSP1330, this challenge requires you to use Gemini Code Assist to:

1. **Set up the development environment and configure Gemini assistance**
2. **Develop and run unit tests for the `/outofstock` functionality**
3. **Develop and test the `/outofstock` endpoint in the backend**
4. **Extract the core logic into a new Cloud Function and deploy it**
5. **Create an API Gateway to expose the outofstock Cloud Function**

## Detailed Step-by-Step Guide

### Task 1: Set up the development environment and configure Gemini assistance

#### Step 1.1: Set environment variables
```bash
export PROJECT_ID=$(gcloud config get-value project)
export REGION=Lab Region
export ZONE=Lab Zone
```

#### Step 1.2: Copy necessary files
```bash
gsutil -m cp -r gs://spls/gsp527/cymbal-superstore .
```

**Note:** The Cloud Storage bucket used here is different from previous labs (`gs://spls/gsp527/` instead of `gs://duet-appdev/`).

#### Step 1.3: Open the project in the editor and configure Gemini
1. Open the Cloud Shell editor
2. Open the `cymbal-superstore` folder
3. Click the Gemini icon
4. Select the correct Google Cloud project for Gemini assistance

### Task 2: Develop and run unit tests for the `/outofstock` functionality

#### Step 2.1: Examine existing tests
1. Open the `backend/index.test.ts` file in the editor
2. Use Gemini Chat to explain any parts of the existing tests that are unclear

#### Step 2.2: Generate new tests with Gemini
1. Add a comment at the bottom of `index.test.ts`:
```typescript
// Create unit tests for the GET /outofstock endpoint
// Test that it returns a 200 status code
// Test that it returns an array of 2 out of stock products
```

2. Select the comment and use Gemini to generate code

#### Step 2.3: Run the tests
```bash
cd ~/cymbal-superstore/backend
npm run test
```

**Expected Result:** The tests should fail because the `/outofstock` endpoint is not yet implemented.

### Task 3: Develop and test the `/outofstock` endpoint in the backend

#### Step 3.1: Examine existing code
1. Open the `backend/index.ts` file in the editor
2. Review the existing endpoint implementations (especially `/products` and `/newproducts`)

#### Step 3.2: Generate the `/outofstock` endpoint with Gemini
1. Find the `/outofstock endpoint code goes here` placeholder
2. Replace it with a descriptive comment:
```typescript
// Create a GET route for /outofstock that returns products that are out of stock (quantity = 0)
// The products should be retrieved from Firestore collection "inventory"
// Return the products as JSON array
```

3. Select the comment and use Gemini to generate code

#### Step 3.3: Test the endpoint
1. Start the backend service:
```bash
cd ~/cymbal-superstore/backend
npm run start
```

2. Test the endpoint in another terminal:
```bash
curl localhost:8000/outofstock
```

3. Verify that the returned JSON contains 2 out-of-stock products
4. Run tests to ensure they pass:
```bash
npm run test
```

### Task 4: Extract the core logic into a new Cloud Function and deploy it

#### Step 4.1: Examine the functions directory
1. Navigate to the `cymbal-superstore/functions` directory
2. Review the existing `index.js` file structure

#### Step 4.2: Generate Cloud Function code with Gemini
1. Add a comment in `functions/index.js`:
```javascript
// Create an HTTP Cloud Function that returns products that are out of stock
// Route: /outofstock
// Query Firestore collection "inventory" for products where quantity = 0
// Return JSON array of out of stock products
```

2. Use Gemini to generate code

#### Step 4.3: Get the deployment command
1. Open Gemini Chat
2. Ask for the correct gcloud command:
```
What is the gcloud command to deploy this /outofstock Cloud Function with HTTP trigger and allow unauthenticated access?
```

#### Step 4.4: Grant Cloud Functions Service Agent permissions
Before deploying, ensure the Cloud Functions service account has the necessary permissions. The service account ID will be in the format `service-<PROJECT_NUMBER>@gcf-admin-robot.iam.gserviceaccount.com`.

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:service-PROJECT_NUMBER@gcf-admin-robot.iam.gserviceaccount.com" \
    --role="roles/cloudfunctions.serviceAgent"
```
**Note:** Replace `PROJECT_NUMBER` with your actual Google Cloud Project Number. You can find this in the Google Cloud Console Dashboard.

#### Step 4.5: Deploy the Cloud Function
Execute the command provided by Gemini, similar to:
```bash
gcloud functions deploy outofstock --runtime nodejs20 --trigger-http --allow-unauthenticated --region=$REGION
```

#### Step 4.6: Test the deployed Cloud Function
1. Get the Cloud Function URL from the deployment output
2. Open the URL in a browser
3. Verify that it returns JSON containing 2 out-of-stock products

### Task 5: Create an API Gateway to expose the outofstock Cloud Function

#### Step 5.1: Set environment variables
```bash
export CONFIG_ID=outofstock-api-config
export API_ID=outofstock-api
export GATEWAY_ID=store
export OPENAPI_SPEC=outofstock.yaml
```

#### Step 5.2: Create gateway directory and OpenAPI specification file
```bash
cd ~/cymbal-superstore
mkdir gateway
cd gateway
touch outofstock.yaml
```

#### Step 5.3: Generate OpenAPI specification with Gemini
1. Open Gemini Chat
2. Provide the Cloud Function URL and request an OpenAPI specification:
```
Create an OpenAPI 2.0 specification for a Cloud Function that returns out of stock products.
The function URL is: [YOUR_CLOUD_FUNCTION_URL]
The endpoint should be /outofstock and return a JSON array of products.
```

3. Paste the generated specification into the `outofstock.yaml` file

#### Step 5.4: Enable API Gateway service
```bash
gcloud services enable apigateway.googleapis.com
```

#### Step 5.5: Create API and configuration
1. Ask Gemini Chat for the gcloud commands to create an API and configuration
2. Execute the provided commands:
```bash
gcloud api-gateway apis create $API_ID
gcloud api-gateway api-configs create $CONFIG_ID --api=$API_ID --openapi-spec=$OPENAPI_SPEC
```

#### Step 5.6: Create and deploy API Gateway
1. Ask Gemini Chat for the command to create an API Gateway
2. Execute the provided command:
```bash
gcloud api-gateway gateways create $GATEWAY_ID --api=$API_ID --api-config=$CONFIG_ID --location=$REGION
```

#### Step 5.7: Verify API Gateway
1. Check gateway status:
```bash
gcloud api-gateway gateways describe $GATEWAY_ID --location=$REGION
```

2. Note the `defaultHostname`
3. Test in browser: `https://[defaultHostname]/outofstock`
4. Verify it returns JSON with 2 out-of-stock products

## Troubleshooting Guide

### Common Issues

#### Gemini unable to generate code
- Ensure the correct GCP project is selected
- Check that Cloud AI Companion API is enabled
- Verify comment format is correct and descriptive

#### Cloud Function deployment failure
- Check region settings
- Ensure code syntax is correct
- Verify permission settings

#### API Gateway creation failure
- Check OpenAPI specification format
- Ensure Cloud Function URL is correct
- Verify API Gateway service is enabled

#### Test failures
- Check if test data matches expectations
- Verify endpoint logic
- Check response format

### Debugging Tips

#### Using Gemini Chat for debugging
1. Copy the error message
2. Paste the error in Gemini Chat
3. Provide relevant code snippets
4. Ask for specific solutions

#### Firestore query issues
- Remember that Firestore doesn't support multiple inequality filters
- Use application logic for post-filtering
- Consider composite indexes

#### Test-Driven Development (TDD) approach
1. Write tests first
2. Use Gemini to generate code that makes tests pass
3. Refactor and optimize
4. Run tests again

## Scoring Criteria

This challenge lab uses an automated scoring system. Here are the key checkpoints:

- ✅ **Task 2**: Unit tests created and runnable
- ✅ **Task 3**: `/outofstock` endpoint working in backend
- ✅ **Task 4**: Cloud Function deployed and running
- ✅ **Task 5**: API Gateway created and exposing Cloud Function

## Learning Outcomes

Upon completing this challenge, you will demonstrate the ability to:

1. **Work Independently**: Apply learned skills without step-by-step guidance
2. **Problem Solving**: Use Gemini effectively to debug and fix issues
3. **Architecture Design**: Extract monolithic app logic into microservices
4. **API Management**: Expose services securely using API Gateway
5. **Testing Practices**: Implement comprehensive unit test coverage

## Resources and References

### Related Labs
- **GSP1328**: Create API Gateways with Gemini
- **GSP1329**: Code Generation with Gemini
- **GSP1330**: Unit Testing with Gemini

### GCP Services Documentation
- [Cloud Functions](https://cloud.google.com/functions/docs)
- [API Gateway](https://cloud.google.com/api-gateway/docs)
- [Gemini for Developers](https://cloud.google.com/gemini/docs)

### Best Practices
- Use descriptive comments when working with Gemini
- Write tests first, then implement features (TDD)
- Test changes regularly
- Use appropriate error handling

## Next Steps

Congratulations on completing this challenge! You have now demonstrated the skill of developing complete features using Gemini Code Assist without guidance.

Consider exploring:
- More complex microservice architectures
- Continuous Integration/Continuous Deployment (CI/CD) pipelines
- Advanced testing techniques
- Production environment deployment practices
