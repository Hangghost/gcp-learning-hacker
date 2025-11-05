# GSP328 - Develop Serverless Applications on Cloud Run: Challenge Lab Step-by-Step Guide

## Overview

This is the complete step-by-step guide for **GSP328 - Develop Serverless Applications on Cloud Run: Challenge Lab**. This lab is a challenge lab that requires you to migrate Pet Theory's monolithic billing application to a serverless architecture.

**Note:** This is a Challenge Lab, and you will not receive step-by-step instructions. You need to use the skills learned in this course to complete the tasks.

## Architecture Overview

Pet Theory wants to migrate its monolithic billing application to a serverless architecture. This lab includes the following components:

- **Staging Architecture**: Public billing service and frontend service
- **Production Architecture**: Private billing service and frontend service with secure inter-service communication
- **Service Accounts**: For secure inter-service communication
- **Cloud Run**: Serverless container platform
- **Cloud Build**: Container build service

## Environment Setup

### 1. Configure Project and Region

```bash
# Set default project
export PROJECT_ID=$(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
gcloud config set project $PROJECT_ID

# Set Cloud Run region
export REGION=
gcloud config set run/region $REGION

# Set Cloud Run platform
gcloud config set run/platform managed
```

### 2. Clone the Code Repository

```bash
# Clone Pet Theory repository
git clone https://github.com/rosera/pet-theory.git
cd pet-theory/lab07
```

## Task 1: Enable a Public Service

### Objective
Deploy a public billing REST API service.

### Detailed Steps

1. **Build Container Image**
   ```bash
   # Build billing-staging-api:0.1 image
   gcloud builds submit --tag gcr.io/$PROJECT_ID/billing-staging-api:0.1 ./unit-api-billing
   ```

2. **Deploy Cloud Run Service**
   ```bash
   # Deploy public billing service
   gcloud run deploy public-billing-service \
     --image gcr.io/$PROJECT_ID/billing-staging-api:0.1 \
     --platform managed \
     --region $REGION \
     --allow-unauthenticated
   ```

3. **Test Service**
   ```bash
   # Get service URL
   export PUBLIC_BILLING_URL=$(gcloud run services describe public-billing-service \
     --platform managed \
     --region $REGION \
     --format "value(status.url)")

   # Test service response
   curl -X GET $PUBLIC_BILLING_URL
   ```

## Task 2: Deploy Frontend Service

### Objective
Deploy an unauthenticated frontend service to display billing information.

### Detailed Steps

1. **Build Container Image**
   ```bash
   # Build frontend-staging:0.1 image
   gcloud builds submit --tag gcr.io/$PROJECT_ID/frontend-staging:0.1 ./staging-frontend-billing
   ```

2. **Deploy Cloud Run Service**
   ```bash
   # Deploy frontend service
   gcloud run deploy frontend-staging-service \
     --image gcr.io/$PROJECT_ID/frontend-staging:0.1 \
     --platform managed \
     --region $REGION \
     --allow-unauthenticated
   ```

3. **Test Service**
   ```bash
   # Get service URL
   export FRONTEND_STAGING_URL=$(gcloud run services describe frontend-staging-service \
     --platform managed \
     --region $REGION \
     --format "value(status.url)")

   # Test service response
   curl -X GET $FRONTEND_STAGING_URL
   ```

## Task 3: Deploy Private Service

### Objective
Deploy a private billing service that requires authentication.

### Detailed Steps

1. **Delete Existing Public Service**
   ```bash
   # Delete public billing service
   gcloud run services delete public-billing-service --region $REGION --quiet
   ```

2. **Build New Version Container Image**
   ```bash
   # Build billing-staging-api:0.2 image
   gcloud builds submit --tag gcr.io/$PROJECT_ID/billing-staging-api:0.2 ./staging-api-billing
   ```

3. **Deploy Service Requiring Authentication**
   ```bash
   # Deploy private billing service
   gcloud run deploy private-billing-service \
     --image gcr.io/$PROJECT_ID/billing-staging-api:0.2 \
     --platform managed \
     --region $REGION \
     --no-allow-unauthenticated
   ```

4. **Set Environment Variables**
   ```bash
   # Get private billing service URL
   export BILLING_URL=$(gcloud run services describe private-billing-service \
     --platform managed \
     --region $REGION \
     --format "value(status.url)")
   ```

5. **Test Authenticated Access**
   ```bash
   # Test access using identity token
   curl -X GET -H "Authorization: Bearer $(gcloud auth print-identity-token)" $BILLING_URL
   ```

## Task 4: Create Billing Service Account

### Objective
Create a service account for the billing service in the production environment.

### Detailed Steps

```bash
# Create billing service account
gcloud iam service-accounts create billing-service \
  --display-name "Billing Service Cloud Run" \
  --description "Service account for billing service"
```

## Task 5: Deploy Production Billing Service

### Objective
Deploy the production version of the billing service using the service account.

### Detailed Steps

1. **Build Production Image**
   ```bash
   # Build billing-prod-api:0.1 image
   gcloud builds submit --tag gcr.io/$PROJECT_ID/billing-prod-api:0.1 ./prod-api-billing
   ```

2. **Deploy Production Billing Service**
   ```bash
   # Deploy using service account
   gcloud run deploy billing-production-service \
     --image gcr.io/$PROJECT_ID/billing-prod-api:0.1 \
     --platform managed \
     --region $REGION \
     --no-allow-unauthenticated \
     --service-account billing-service@$PROJECT_ID.iam.gserviceaccount.com
   ```

3. **Set Environment Variables**
   ```bash
   # Get production billing service URL
   export PROD_BILLING_URL=$(gcloud run services describe billing-production-service \
     --platform managed \
     --region $REGION \
     --format "value(status.url)")
   ```

4. **Test Service**
   ```bash
   # Test using identity token
   curl -X GET -H "Authorization: Bearer $(gcloud auth print-identity-token)" $PROD_BILLING_URL
   ```

## Task 6: Frontend Service Account

### Objective
Create a frontend service account with Cloud Run invoker permissions.

### Detailed Steps

```bash
# Create frontend service account
gcloud iam service-accounts create frontend-prod-service \
  --display-name "Billing Service Cloud Run Invoker" \
  --description "Service account for frontend service with invoker permissions"

# Grant Cloud Run invoker role
gcloud run services add-iam-policy-binding billing-production-service \
  --member="serviceAccount:frontend-prod-service@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.invoker" \
  --region $REGION
```

## Task 7: Redeploy Frontend Service

### Objective
Redeploy the frontend service using the new service account to enable it to invoke the private billing service.

### Detailed Steps

1. **Build Production Frontend Image**
   ```bash
   # Build frontend-prod:0.1 image
   gcloud builds submit --tag gcr.io/$PROJECT_ID/frontend-prod:0.1 ./prod-frontend-billing
   ```

2. **Redeploy Frontend Service**
   ```bash
   # Redeploy using service account
   gcloud run deploy frontend-production-service \
     --image gcr.io/$PROJECT_ID/frontend-prod:0.1 \
     --platform managed \
     --region $REGION \
     --allow-unauthenticated \
     --service-account frontend-prod-service@$PROJECT_ID.iam.gserviceaccount.com
   ```

3. **Test Complete System**
   ```bash
   # Get frontend service URL
   export FRONTEND_PROD_URL=$(gcloud run services describe frontend-production-service \
     --platform managed \
     --region $REGION \
     --format "value(status.url)")

   # Test frontend service (should be able to invoke backend billing service)
   curl -X GET $FRONTEND_PROD_URL
   ```

## Validation Checkpoints

### Validation for Each Task

1. **Task 1**: Public billing service can be accessed anonymously
2. **Task 2**: Frontend service can be accessed anonymously
3. **Task 3**: Private billing service requires authentication
4. **Task 4**: Billing service account has been created
5. **Task 5**: Production billing service uses service account and requires authentication
6. **Task 6**: Frontend service account has invoker permissions
7. **Task 7**: Frontend service uses service account and can invoke billing service

### Troubleshooting Common Issues

- **Build Failures**: Ensure Cloud Build API is enabled
- **Deployment Failures**: Check region settings and service account permissions
- **Authentication Failures**: Verify identity tokens and service account configuration
- **Permission Errors**: Check IAM policies and role assignments

## Cleanup Resources

```bash
# Delete all services
gcloud run services delete frontend-production-service --region $REGION --quiet
gcloud run services delete billing-production-service --region $REGION --quiet
gcloud run services delete private-billing-service --region $REGION --quiet
gcloud run services delete frontend-staging-service --region $REGION --quiet

# Delete service accounts
gcloud iam service-accounts delete frontend-prod-service@$PROJECT_ID.iam.gserviceaccount.com --quiet
gcloud iam service-accounts delete billing-service@$PROJECT_ID.iam.gserviceaccount.com --quiet

# Delete container images (optional)
gcloud container images delete gcr.io/$PROJECT_ID/billing-staging-api:0.1 --quiet
gcloud container images delete gcr.io/$PROJECT_ID/billing-staging-api:0.2 --quiet
gcloud container images delete gcr.io/$PROJECT_ID/billing-prod-api:0.1 --quiet
gcloud container images delete gcr.io/$PROJECT_ID/frontend-staging:0.1 --quiet
gcloud container images delete gcr.io/$PROJECT_ID/frontend-prod:0.1 --quiet
```

## Learning Highlights

- **Serverless Architecture**: Cloud Run provides fully managed container platform
- **Service Accounts**: Used for secure inter-service communication
- **Authentication & Authorization**: IAM and service accounts for access control
- **CI/CD**: Cloud Build for automated container builds
- **Microservices**: Breaking monolithic applications into independent services

## Related Resources

- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Service Accounts Overview](https://cloud.google.com/iam/docs/service-accounts)
- [Cloud Build Documentation](https://cloud.google.com/cloud-build/docs)
- Related Labs:
  - GSP644: Develop Serverless Applications on Cloud Run
  - GSP650: Build a Resilient, Asynchronous System with Cloud Run and Pub/Sub
  - GSP761: Developing a REST API with Go and Cloud Run
  - GSP762: Creating PDFs with Go and Cloud Run

---

*This guide is based on Google Cloud Skills Boost GSP328 Challenge Lab content. Please adjust parameters according to your actual environment.*
