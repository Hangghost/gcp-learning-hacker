# GSP761 - Developing a REST API with Go and Cloud Run

## Lab Overview

For the labs in the [Serverless Cloud Run Development](https://www.cloudskillsboost.google/course_templates/741) course, you will read through a fictitious business scenario and assist the characters with their serverless migration plan.

Twelve years ago, Lily started the Pet Theory chain of veterinary clinics. As the chain of clinics has grown, Lily spends more time on the phone with insurance companies than treating pets. If only the insurance companies could see the totals of the treatments online!

In previous labs in this series, Ruby, the computer consultant, and Patrick, the DevOps Engineer, moved Pet Theory's customer database to a serverless Firestore database in the cloud, and then opened up access so customers can make appointments online. Since Pet Theory's Ops team is a single person, they need a serverless solution that doesn't require a lot of ongoing maintenance.

In this lab, you'll help Ruby and Patrick to give insurance companies access to customer data without exposing Personal Identifiable Information (PII). You will build a secure Representational State Transfer (REST) API gateway using Cloud Run, which is serverless. This will let the insurance companies see the total cost of treatments without seeing customers' PII.

## Objectives

In this lab, you will:

- Develop a REST API with Go
- Import test customer data into Firestore
- Connect the REST API to the Firestore database
- Deploy the REST API to Cloud Run

## Prerequisites

This is an intermediate level lab. This assumes familiarity with the Cloud Console and Cloud Shell environments. This lab is part of a series. Taking the previous labs could be helpful, but is not necessary:

- Importing Data to a Serverless Database
- Build a Serverless Web App with Firebase and Firestore
- Build a Serverless App that Creates PDF Files

Help Ruby manage the activities necessary to build the REST API for Pet Theory.

## Task 1. Enable Google APIs

For this lab, 2 APIs have been enabled for you:

| Name | API |
|------|-----|
| Cloud Build | cloudbuild.googleapis.com |
| Cloud Run Admin | run.googleapis.com |

## Task 2. Developing the REST API

1. Activate your project:

```bash
gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
```

2. Clone the pet-theory repository and access the source code:

```bash
git clone https://github.com/rosera/pet-theory.git && cd pet-theory/lab08
```

3. Use your favorite text editor, or use the Code Editor button in the Cloud Shell ribbon, to view the `go.mod` and `go.sum` files.

4. Create the file `main.go` and add the below contents to the file:

```go
package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
)

func main() {
  port := os.Getenv("PORT")
  if port == "" {
      port = "8080"
  }
  http.HandleFunc("/v1/", func(w http.ResponseWriter, r *http.Request) {
      fmt.Fprintf(w, "{status: 'running'}")
  })
  log.Println("Pets REST API listening on port", port)
  if err := http.ListenAndServe(":"+port, nil); err != nil {
      log.Fatalf("Error launching Pets REST API server: %v", err)
  }
}
```

**Note:** In the above code, you create an endpoint to test that the service is up and running as expected. By appending "/v1/" to the service URL, you can verify the application is functioning as expected. Cloud Run deploys containers, so you need to provide a container definition. A file named `Dockerfile` tells Cloud Run which Go version to use, which files to include in the app, and how to start the code.

5. Now create a file named `Dockerfile` and add the following to it:

```dockerfile
FROM gcr.io/distroless/base-debian12
WORKDIR /usr/src/app
COPY server .
CMD [ "/usr/src/app/server" ]
```

The file `server` is the execution binary built from `main.go`.

6. Run the following command to build the binary:

```bash
go build -o server
```

7. After running the build command, make sure that you have the necessary Dockerfile and server in the same directory:

```bash
ls -la
```

```
.
├── Dockerfile
├── go.mod
├── go.sum
├── main.go
└── server
```

For most Cloud Run Go based apps, a template Dockerfile like the one above can typically be used without modifying it.

8. Deploy your simple REST API by running:

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1
```

This command builds a container with your code and puts it in the Artifact Registry of your project. You can see the container if you click: **Navigation menu** (), click **View All Products** > **CI/CD** > **Artifact Registry** and click **gcr.io** repository. If you don't see `rest-api`, click **Refresh**.

*Navigation menu icon*

*Artifact Registry diagram*

Click **Check my progress** to verify that you've performed the above task.

Build an image with Cloud Build

9. Once the container has been built, deploy it:

```bash
gcloud run deploy rest-api \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1 \
  --platform managed \
  --region "Filled in at lab startup." \
  --allow-unauthenticated \
  --max-instances=2
```

10. When the deployment is complete, you will see a message like this:

```
Service [rest-api] revision [rest-api-00001] has been deployed and is serving
traffic at https://rest-api-[hash].a.run.app
```

Click **Check my progress** to verify the objective.

REST API service deployed

11. Click on the Service URL at the end of that message to open it in a new browser tab. Append `/v1/` to the end of the URL and then press **Enter**.

You should see this message:

```
{"status": "running"}
```

The REST API is up and running. With the prototype service available, in the next section the API will be used to retrieve "customer" information from a Firestore database.

## Task 3. Import test customer data

Ruby and Patrick have previously created a test database of 10 customers, with some proposed treatments for one customer's cat.

Help Patrick configure the Firestore database and import the customer test data. First, enable Firestore in your project.

1. Return to the Cloud Console and click the **Navigation menu** (), click **View All Products** > **Databases** > **Firestore**.

   *Navigation menu icon*

2. Click the **Create a Firestore Database** button.

3. Select **Standard Edition**.

4. Under Configuration options, select **Firestore Native**.

5. For Security rules, choose **Open**.

6. For **Location type** select **Region**.

7. Select the region `REGION` from the list available and click **Create Database**.

Wait for the database to be created before proceeding.

Click **Check my progress** to verify the objective.

Firestore database created

8. Migrate the import files into a Cloud Storage bucket that has been created for you:

```bash
gsutil mb -c standard -l Region gs://$GOOGLE_CLOUD_PROJECT-customer
```

```bash
gsutil cp -r gs://spls/gsp645/2019-10-06T20:10:37_43617 gs://$GOOGLE_CLOUD_PROJECT-customer
```

9. Now import this data into Firebase:

```bash
gcloud beta firestore import gs://$GOOGLE_CLOUD_PROJECT-customer/2019-10-06T20:10:37_43617/
```

Reload the Cloud Console browser to see the Firestore results.

10. In Firestore, click **customers** under "Default". You should see the imported pet data, browse around. If you don't see any data, try refreshing the page.

Nice work, the Firestore database has been successfully created and populated with test data!

## Task 4. Connect the REST API to the Firestore database

In this section you'll help Ruby create another end-point in the REST API that will look like this:

```
https://rest-api-[hash].a.run.app/v1/customer/22530
```

For example, that URL should return the total amounts for all proposed, accepted, and rejected treatments for the customer with id 22530, if they exist in the Firestore database:

```json
{
  "status": "success",
  "data": {
    "proposed": 1602,
    "approved": 585,
    "rejected": 489
  }
}
```

**Note:** If the customer doesn't exist in the database, status code 404 (not found) and an error message should be returned instead.

This new functionality requires a package to access the Firestore database and another one to handle cross-origin resource sharing (CORS).

1. Get the value of the $GOOGLE_CLOUD_PROJECT environment variable

```bash
echo $GOOGLE_CLOUD_PROJECT
```

2. Open the existing `main.go` file in the pet-theory/lab08 directory.

**Note:** Update the contents of main.go using the value shown for $GOOGLE_CLOUD_PROJECT.

3. Replace the content of the file with the code below, ensure the `PROJECT_ID` is set to:

```go
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"cloud.google.com/go/firestore"
	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"google.golang.org/api/iterator"
)

  var client *firestore.Client

  func main() {
    var err error
    ctx := context.Background()
    client, err = firestore.NewClient(ctx, "Filled in at lab startup.")
    if err != nil {
    log.Fatalf("Error initializing Cloud Firestore client: %v", err)
  }

  port := os.Getenv("PORT")
  if port == "" {
    port = "8080"
  }

  r := mux.NewRouter()
  r.HandleFunc("/v1/", rootHandler)
  r.HandleFunc("/v1/customer/{id}", customerHandler)

  log.Println("Pets REST API listening on port", port)
  cors := handlers.CORS(
    handlers.AllowedHeaders([]string{"X-Requested-With", "Authorization", "Origin"}),
    handlers.AllowedOrigins([]string{"https://storage.googleapis.com"}),
    handlers.AllowedMethods([]string{"GET", "HEAD", "POST", "OPTIONS", "PATCH", "CONNECT"}),
  )

	if err := http.ListenAndServe(":"+port, cors(r)); err != nil {
    log.Fatalf("Error launching Pets REST API server: %v", err)
	}
}
```

4. Add handler support at the bottom of the file:

```go
func rootHandler(w http.ResponseWriter, r *http.Request) {
  fmt.Fprintf(w, "{status: 'running'}")
}

func customerHandler(w http.ResponseWriter, r *http.Request) {
  id := mux.Vars(r)["id"]
  ctx := context.Background()
  customer, err := getCustomer(ctx, id)
  if err != nil {
    w.WriteHeader(http.StatusInternalServerError)
    fmt.Fprintf(w, `{"status": "fail", "data": '%s'}`, err)
    return
  }
  if customer == nil {
    w.WriteHeader(http.StatusNotFound)
    msg := fmt.Sprintf("`Customer \"%s\" not found`", id)
    fmt.Fprintf(w, fmt.Sprintf(`{"status": "fail", "data": {"title": %s}}`, msg))
    return
  }
  amount, err := getAmounts(ctx, customer)
  if err != nil {
    w.WriteHeader(http.StatusInternalServerError)
    fmt.Fprintf(w, `{"status": "fail", "data": "Unable to fetch amounts: %s"}`, err)
    return
  }
  data, err := json.Marshal(amount)
  if err != nil {
    w.WriteHeader(http.StatusInternalServerError)
    fmt.Fprintf(w, `{"status": "fail", "data": "Unable to fetch amounts: %s"}`, err)
    return
  }
  fmt.Fprintf(w, fmt.Sprintf(`{"status": "success", "data": %s}`, data))
}
```

5. Add Customer support to the bottom of the file:

```go
type Customer struct {
  Email string `firestore:"email"`
  ID    string `firestore:"id"`
  Name  string `firestore:"name"`
  Phone string `firestore:"phone"`
}

func getCustomer(ctx context.Context, id string) (*Customer, error) {
  query := client.Collection("customers").Where("id", "==", id)
  iter := query.Documents(ctx)

  var c Customer
  for {
    doc, err := iter.Next()
    if err == iterator.Done {
	break
    }
    if err != nil {
	return nil, err
    }
    err = doc.DataTo(&c)
    if err != nil {
	return nil, err
    }
  }
  return &c, nil
}

func getAmounts(ctx context.Context, c *Customer) (map[string]int64, error) {
  if c == nil {
    return map[string]int64{}, fmt.Errorf("Customer should be non-nil: %v", c)
  }
  result := map[string]int64{
    "proposed": 0,
    "approved": 0,
    "rejected": 0,
  }
  query := client.Collection(fmt.Sprintf("customers/%s/treatments", c.Email))
  if query == nil {
    return map[string]int64{}, fmt.Errorf("Query is nil: %v", c)
  }
  iter := query.Documents(ctx)
  for {
    doc, err := iter.Next()
    if err == iterator.Done {
	break
    }
    if err != nil {
	return nil, err
    }
    treatment := doc.Data()
    result[treatment["status"].(string)] += treatment["cost"].(int64)
  }
  return result, nil
}
```

6. **Save** the file.

## Task 5. Pop quiz

Which function responds to URLs with the pattern `/v1/customer/`? `customerHandler`

Which statement returns success to the client? `fmt.Fprintf(w, fmt.Sprintf(`{"status": "success", "data": %s}`

Which functions read from the Firestore database? `getCustomer and getAmounts`

## Task 6. Deploying a new revision

1. Rebuild the source code:

```bash
go build -o server
```

2. Build a new image for the REST API:

```bash
gcloud builds submit \
  --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2
```

Click **Check my progress** to verify the objective.

Build image revision 0.2

3. Deploy the updated image:

```bash
gcloud run deploy rest-api \
  --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2 \
  --platform managed \
  --region "Filled in at lab startup." \
  --allow-unauthenticated \
  --max-instances=2
```

4. When the deployment is complete, you will see a similar message to before. The URL for your REST API did not change when you deployed the new version:

```
Service [rest-api] revision [rest-api-00002] has been deployed and is serving
traffic at https://rest-api-[hash].a.run.app
```

5. Go back to the browser tab that already points to that URL (with `/v1/` at the end). Refresh it and make sure you get the same message as before, that indicates that the API status is still running.

```
{"status": "running"}
```

6. Append `/customer/22530` to the application URL in your browser's address bar. You should get this JSON response, listing the sum total of the customer's proposed, approved and rejected treatments:

```json
{
  "status": "success",
  "data": {
    "proposed": 1602,
    "approved": 585,
    "rejected": 489
  }
}
```

7. Here are some additional client IDs you can put in the URL instead of 22530:

- 34216
- 70156 (all amounts should be zero)
- 12345 (client/pet doesn't exist, should return an error e.g. **Query is nil**)

You have built a scalable, low-maintenance, serverless REST API that reads from a database.

## Congratulations!

Congratulations! In this lab, you helped Ruby and Patrick successfully build a prototype REST API for Pet Theory. You created a REST API that connects to a Firestore database and deployed it to Cloud Run. You also tested the API to ensure it works as expected.

## Google Cloud training and certification

...helps you make the most of Google Cloud technologies. [Our classes](https://cloud.google.com/training) include technical skills and best practices to help you get up to speed quickly and continue your learning journey. We offer fundamental to advanced level training, with on-demand, live, and virtual options to suit your busy schedule. [Certifications](https://cloud.google.com/certification/) help you validate and prove your skill and expertise in Google Cloud technologies.

**Manual Last Updated May 6, 2025**

**Lab Last Tested May 6, 2025**

Copyright 2025 Google LLC. All rights reserved. Google and the Google logo are trademarks of Google LLC. All other company and product names may be trademarks of the respective companies with which they are associated.
