# GSP920 - Securing a Cloud SQL for PostgreSQL Instance

## Lab Overview

Customer-managed encryption keys (CMEK) let you use your own cryptographic keys for data at rest in Cloud SQL. After adding customer-managed encryption keys, whenever an API call is made, Cloud SQL uses your key to access data.

This lab provides you with step-by-step guidance on how to secure a Cloud SQL for PostgreSQL instance. You first deploy a new Cloud SQL instance using a CMEK. Once you have created the Cloud SQL for PostgreSQL instance, you configure pgAudit to selectively record and track SQL operations performed against that instance, and finally you configure and test Cloud SQL IAM database authentication.

## What you'll do

- Setup CMEK for Cloud SQL for PostgreSQL.
- Enable and configure pgAudit on a Cloud SQL for PostgreSQL instance.
- Configure Cloud SQL for PostgreSQL IAM database authentication.

## Target Audience

The content of this hands-on lab will be most applicable to PostgreSQL Database Administrators. This lab is designed to give professionals hands-on experience setting up and configuring Google Cloud resources to support PostgreSQL.

## Estimated Time

Approximately 90 minutes

## Lab Steps

### Task 1. Create a Cloud SQL for PostgreSQL instance with CMEK enabled

In this task, you create a Cloud SQL for PostgreSQL instance with CMEK enabled. It is imperative that you keep the keys safe as you cannot manage your database without them.

#### Create a per-product, per-project service account for Cloud SQL

You can create the service account you require for Cloud SQL CMEK using the `gcloud beta services identity create` command.

1. In Cloud Shell, run the following to create the service account:

```bash
export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
gcloud beta services identity create \
    --service=sqladmin.googleapis.com \
    --project=$PROJECT_ID
```

1. Click the **Authorize** button if prompted.

This creates the service account that you will bind to the CMEK in a later step.

#### Create a Cloud Key Management Service keyring and key

In this section, you create a Cloud KMS keyring and key to use with CMEK.

1. In Cloud Shell, run the following command to create the Cloud KMS keyring:

```bash
export KMS_KEYRING_ID=cloud-sql-keyring
export ZONE=$(gcloud compute instances list --filter="NAME=bastion-vm" --format=json | jq -r .[].zone | awk -F "/zones/" '{print $NF}')
export REGION=${ZONE::-2}
gcloud kms keyrings create $KMS_KEYRING_ID \
    --location=$REGION
```

1. In Cloud Shell, run the following command to create the Cloud KMS key:

```bash
export KMS_KEY_ID=cloud-sql-key
gcloud kms keys create $KMS_KEY_ID \
 --location=$REGION \
 --keyring=$KMS_KEYRING_ID \
 --purpose=encryption
```

1. In Cloud Shell, run the following command to bind the key to the service account:

```bash
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format 'value(projectNumber)')
gcloud kms keys add-iam-policy-binding $KMS_KEY_ID \
    --location=$REGION \
    --keyring=$KMS_KEYRING_ID \
    --member=serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloud-sql.iam.gserviceaccount.com \
    --role=roles/cloudkms.cryptoKeyEncrypterDecrypter
```

The service account name is the same name that was returned by the `gcloud beta services identity create` command in the previous sub-task.

#### Create a Cloud SQL instance with CMEK enabled

In this section, you create a Cloud SQL for PostgreSQL instance with CMEK enabled. It is not possible to patch an existing instance to enable CMEK, so you should bear this in mind if you plan to use CMEK to encrypt your data.

In order to access your Cloud SQL instance from external development or application environments, you can configure the Cloud SQL instance with a public IP address and control access by allowlisting the IP address of those environments. This limits access to the public interface to those address ranges that you specify.

You treat the Compute Engine VM instance in the lab as a development environment and therefore need the to allow list the external IP address of that instance. You also add the external IP address of the Cloud Shell to the allowlist to make it easier to complete tasks later in the lab.

1. In Cloud Shell, run the following command to find the external IP address of the `bastion-vm` VM instance:

```bash
export AUTHORIZED_IP=$(gcloud compute instances describe bastion-vm \
    --zone=$ZONE \
    --format 'value(networkInterfaces[0].accessConfigs.natIP)')
echo Authorized IP: $AUTHORIZED_IP
```

1. In Cloud Shell, run the following command to find the external IP address of the Cloud Shell:

```bash
export CLOUD_SHELL_IP=$(curl ifconfig.me)
echo Cloud Shell IP: $CLOUD_SHELL_IP
```

1. In Cloud Shell, run the following command to create your Cloud SQL for PostgreSQL instance with:

```bash
export KEY_NAME=$(gcloud kms keys describe $KMS_KEY_ID \
    --keyring=$KMS_KEYRING_ID --location=$REGION \
    --format 'value(name)')

export CLOUDSQL_INSTANCE=postgres-orders
gcloud sql instances create $CLOUDSQL_INSTANCE \
    --project=$PROJECT_ID \
    --authorized-networks=${AUTHORIZED_IP}/32,$CLOUD_SHELL_IP/32 \
    --disk-encryption-key=$KEY_NAME \
    --database-version=POSTGRES_13 \
    --cpu=1 \
    --memory=3840MB \
    --region=$REGION \
    --root-password=supersecret!
```

1. Enter 'y' if prompted after entering the command.

### Task 2. Enable and configure pgAudit on a Cloud SQL for PostgreSQL database

In this task, you enable and configure the pgAudit database extension which enables fine-grained control of logging of all types of database activity.

1. In Cloud Shell, run the following command to add the pgAudit database flags to your Cloud SQL instance:

```bash
gcloud sql instances patch $CLOUDSQL_INSTANCE \
    --database-flags cloudsql.enable_pgaudit=on,pgaudit.log=all
```

1. Enter 'y' if prompted to confirm and continue.

**Note:** Wait for the patch command to complete before continuing. When you see the message that `Patching Cloud SQL instance...done`, you can proceed to the next step.

1. In Cloud Console, on the **Navigation menu** (), click **SQL**.
2. Click on the Cloud SQL instance named `postgres-orders`.
3. In the Cloud SQL **Overview** panel, top menu, click **Restart** to restart the instance after the patch that you ran in step 1.

If prompted again, click **Restart** again in the pop-up dialog.

**Note:** It can take a few minutes to restart your Cloud SQL for PostgreSQL instance. When you see the message that the instance has been successfully restarted (`Restarted postgres-orders`), you can proceed to the next step.

1. In Cloud console, in the **Connect to this instance** section, click **Open Cloud Shell**.

**Note:** If you receive an error message and are not able to connect, wait a few minutes to provide some time after restart for the instance to be accessible again, and then repeat step 6.

A command to connect to the instance will auto-populate in Cloud Shell.

1. Run that command as is, and enter the password `supersecret!` when prompted.

A **psql** session will start in Cloud Shell.

1. In **psql**, run the following command to create the `orders` database and enable the pgAudit extension to log all reads and writes:

```sql
CREATE DATABASE orders;
\c orders;
```

1. Enter the password `supersecret!` again.
2. In **psql**, run the following command to create and configure the database extension:

```sql
CREATE EXTENSION pgaudit;
ALTER DATABASE orders SET pgaudit.log = 'read,write';
```

#### Enable Audit Logging in Cloud Console

In this section, you enable Audit Logging in Cloud Console.

1. In Cloud Console, on the **Navigation menu** (), click **IAM & Admin** > **Audit Logs**.

**Note:** If you see a message at the top of the page that states `you don't have permission to view inherited audit logs configuration data for one or more parent resources`, you can safely ignore the message and continue to the next step.

1. In the **Filter** box under **Data access audit logs configuration**, type `Cloud SQL`, and select the entry in the drop-down list.
2. Enable the checkbox for **Cloud SQL** on the left, and then enable the following checkboxes in the **Info Panel** on the right:
   - **Admin read**
   - **Data read**
   - **Data write**
3. Click **Save** in the **Info Panel**.

#### Populate a database on Cloud SQL for PostgreSQL

In this section, you populate the `orders` database with data provided to you.

1. Click the **+** icon on the Cloud Shell title bar to open a new tab in the Cloud Shell.
2. In the new tab, run the following to download the data and database population scripts:

```bash
export SOURCE_BUCKET=gs://spls/gsp920
gsutil -m cp ${SOURCE_BUCKET}/create_orders_db.sql .
gsutil -m cp ${SOURCE_BUCKET}/DDL/distribution_centers_data.csv .
gsutil -m cp ${SOURCE_BUCKET}/DDL/inventory_items_data.csv .
gsutil -m cp ${SOURCE_BUCKET}/DDL/order_items_data.csv .
gsutil -m cp ${SOURCE_BUCKET}/DDL/products_data.csv .
gsutil -m cp ${SOURCE_BUCKET}/DDL/users_data.csv .
```

1. Continue in the new tab, and run the following to create and populate the database:

```bash
export CLOUDSQL_INSTANCE=postgres-orders
export POSTGRESQL_IP=$(gcloud sql instances describe $CLOUDSQL_INSTANCE --format="value(ipAddresses[0].ipAddress)")
export PGPASSWORD=supersecret!
psql "sslmode=disable user=postgres hostaddr=${POSTGRESQL_IP}" \
    -c "\i create_orders_db.sql"
```

1. Exit the terminal session in the new tab:

```bash
exit
```

1. Return to your **psql** session in the original Cloud Shell tab, and run the following to further log all `SELECT` operations on a particular relation (such as the `order_items` table):

```sql
CREATE ROLE auditor WITH NOLOGIN;
ALTER DATABASE orders SET pgaudit.role = 'auditor';
GRANT SELECT ON order_items TO auditor;
```

1. Run the first `SELECT` query below:

```sql
SELECT
    users.id  AS users_id,
    users.first_name  AS users_first_name,
    users.last_name  AS users_last_name,
    COUNT(DISTINCT order_items.order_id ) AS order_items_order_count,
    COALESCE(SUM(order_items.sale_price ), 0) AS order_items_total_revenue
FROM order_items
LEFT JOIN users ON order_items.user_id = users.id
GROUP BY 1, 2, 3
ORDER BY 4 DESC
LIMIT 500;
```

1. The output is 500 rows long, so you can enter `q` to close the results and return to the `orders=>` prompt.
2. Repeat the steps 5-6 for the other two query tabs in the code block.
3. Run the following to exit **psql**:

```sql
\q
```

#### View pgAudit logs

In this step you will view the logging of your database updates and queries in the pgAudit logs.

1. In Cloud Console, on the **Navigation menu** (), click **View all products**. Under **Observability**, click **Logging** to open the **Logs Explorer** page.
2. In the **Query** tab of the **Logs Explorer**, paste the following, and click **Run query**:

```
resource.type="cloudsql_database"
logName="projects/(GCP Project)/logs/cloudaudit.googleapis.com%2Fdata_access"
protoPayload.request.@type="type.googleapis.com/google.cloud.sql.audit.v1.PgAuditEntry"
```

1. In the histogram displayed, you can see the audit activity associated with your DDL inserts and the `SELECT` queries you ran earlier.

1. Click on the last bar on the histogram, which corresponds to the `SELECT` queries you ran.

In the **Query results** panel below the histogram, the log entries are listed.

1. Expand a log entry, and under `protoPayload.request` you will see the `SELECT` query.

### Task 3. Configure Cloud SQL IAM database authentication

In this task, you configure Cloud SQL IAM database authentication. All of the database access and update tasks you have performed so far have used built-in PostgreSQL user accounts. You can also create Cloud SQL for PostgreSQL users using Cloud IAM accounts. Database users can authenticate to Cloud SQL using Cloud IAM instead of using built-in database accounts and fine-grained permissions at the database level can be granted to those users.

In this task, you configure the lab user account as a Cloud SQL IAM user, grant that user access to the `orders.order_items` database table using the **postgres** administrator account, and then test access to the `orders.order_items` database table from the command line using the **psql** command line utility.

The authentication process that is used in this task is explained in detail in the [IAM authentication documentation for Cloud SQL for PostgreSQL](https://cloud.google.com/sql/docs/postgres/iam-logins#logging-in-as-a-user).

#### Test database access using a Cloud IAM user before Cloud SQL IAM authentication is configured.

You attempt to access the database using a Cloud IAM user before Cloud SQL IAM authentication has been enabled in order to establish that the Cloud IAM user cannot initially access the data. You will see this connection attempt fail before you proceed to the next section to address the issue.

- In Cloud Shell, test access to the `orders` database using the lab student account as the username:

```bash
export USERNAME=$(gcloud config list --format="value(core.account)")
export CLOUDSQL_INSTANCE=postgres-orders
export POSTGRESQL_IP=$(gcloud sql instances describe $CLOUDSQL_INSTANCE --format="value(ipAddresses[0].ipAddress)")
export PGPASSWORD=$(gcloud auth print-access-token)
psql --host=$POSTGRESQL_IP $USERNAME --dbname=orders
```

This connection attempt fails, and you see an authentication failed message similar to the following because the Cloud SQL IAM user has not been created yet:

```
psql --host=$POSTGRESQL_IP $USERNAME --dbname=orders
psql: error: connection to server at "35.226.251.234", port 5432 failed: FATAL:  password authentication failed for user "student-01-22fa974575e4@qwiklabs.net"
connection to server at "35.226.251.234", port 5432 failed: FATAL:  password authentication failed for user "student-01-22fa974575e4@qwiklabs.net"
```

Cloud SQL IAM database authentication uses OAuth 2.0 access tokens is the Cloud IAM user password, which are short-lived and only valid for one hour so you should regenerate the token every time you need to authenticate. The access token should always be passed into the **psql** command using the **PGPASSWORD** environment variable as the buffer for the **psql** password parameter is too small to hold the OAuth 2.0 token string.

#### Create a Cloud SQL IAM user

In this section, you create a Cloud SQL IAM user and confirm that Cloud SQL IAM user authentication has been enabled.

1. In Cloud Console, on the **Navigation menu** (), click **SQL**
2. Click on the Cloud SQL instance named `postgres-orders`.

In the **Configuration** panel on the right, note that the **Database flags and parameters** list includes **pgAudit.log** and **cloudsql.enable_pgaudit** only.

1. In the **SQL menu** (left panel) under **Primary instance**, click **Users** to open the **Users** panel.
2. Click **Add user account**.
3. Select **Cloud IAM**.
4. In the **Principal** box enter the lab student name: `[USERNAME]`
5. Click **Add**.

Wait for the new user to be successfully added.

On the main overview page for instance, in the **Configuration** panel on the right, note **cloudsql.iam_authentication** has been added to the **Database flags and parameters** list.

#### Grant the Cloud IAM user access to a Cloud SQL database table

You now connect to the `postgres-orders` instance using the built in `postgres` administrator account and grant access to the `orders.order_items` table to the Cloud IAM user.

1. On the main overview page for instance, in the **Connect to this instance** section, click **Open Cloud Shell**.

A command to connect to the instance will auto-populate in Cloud Shell.

1. Run that command as is, and enter the password `supersecret!` when prompted.
2. Enter the following SQL command to switch to the `orders` database:

```sql
\c orders
```

When prompted for a password enter `supersecret!` again.

1. Enter the following SQL command to grant the lab user all permissions on the `order_items` table. The Cloud IAM username for the lab has been inserted into this query for you.

```sql
GRANT ALL PRIVILEGES ON TABLE order_items TO "[IAM Username]";
\q
```

#### Test database access using a Cloud IAM user after Cloud SQL IAM authentication is configured.

You now repeat the attempt to access the database using a Cloud IAM user after Cloud SQL IAM authentication has been enabled in order to establish that the Cloud IAM user can now access the data.

You can now test access to the database again using the Cloud IAM user instead of the built-in `postgres` user:

1. In the Cloud Shell, run the following command to connect to the database using the Cloud IAM database user:

```bash
export PGPASSWORD=$(gcloud auth print-access-token)
psql --host=$POSTGRESQL_IP $USERNAME --dbname=orders
```

This connection succeeds, and you are now connected to the instance using Cloud IAM user authentication.

1. Test your access permission by running this query:

```sql
SELECT COUNT(*) FROM order_items;
```

This now returns a successful result:

```
orders=> SELECT COUNT(*) FROM order_items;
 count
--------
 198553
(1 row)
```

1. Confirm that you do not have access to one of the other tables by running this query:

```sql
SELECT COUNT(*) FROM users;
```

This query does not return a successful result:

```
orders=> SELECT COUNT(*) FROM users;
ERROR:  permission denied for table users
```

## Verification

After successfully completing this lab, you should be able to:

1. Create a secure Cloud SQL for PostgreSQL instance using CMEK
2. Configure pgAudit to log database activities
3. View audit logs in Cloud Logging
4. Set up database user authentication using Cloud IAM accounts
5. Grant and test database-level permissions

## Troubleshooting

### Common Issues

- **CMEK setup failure**: Ensure the service account is created correctly and has proper KMS permissions
- **pgAudit not logging**: Verify database flags are set correctly and instance has been restarted
- **IAM authentication failure**: Ensure Cloud IAM user is created and token hasn't expired (valid for 1 hour)
- **Permission denied**: Check that database-level permissions have been granted correctly

### Check instance status

```bash
gcloud sql instances describe $CLOUDSQL_INSTANCE --format="value(state)"
```

### Restart instance if needed

```bash
gcloud sql instances restart $CLOUDSQL_INSTANCE
```

## Cleanup

To avoid additional charges, delete the resources you created after completing the lab:

1. Delete the Cloud SQL instance:

```bash
gcloud sql instances delete $CLOUDSQL_INSTANCE
```

2. Delete the KMS key and keyring:

```bash
gcloud kms keys versions destroy 1 --key=$KMS_KEY_ID --keyring=$KMS_KEYRING_ID --location=$REGION
gcloud kms keys delete $KMS_KEY_ID --keyring=$KMS_KEYRING_ID --location=$REGION
gcloud kms keyrings delete $KMS_KEYRING_ID --location=$REGION
```

3. Remove IAM policy bindings if needed.

## Additional Resources

- [Cloud SQL for PostgreSQL Documentation](https://cloud.google.com/sql/docs/postgres)
- [Customer-managed encryption keys (CMEK)](https://cloud.google.com/sql/docs/postgres/cmek)
- [pgAudit extension](https://cloud.google.com/sql/docs/postgres/pg-audit)
- [Cloud SQL IAM database authentication](https://cloud.google.com/sql/docs/postgres/iam-logins)
- [Cloud KMS Documentation](https://cloud.google.com/kms/docs)
- [Cloud Audit Logs](https://cloud.google.com/logging/docs/audit)

## Related Labs

- GSP918: Create and Manage Cloud SQL for PostgreSQL Instances
- GSP919: Connect an App to a Cloud SQL for PostgreSQL Instance

## Notes

- CMEK provides an additional layer of security but requires careful key management
- pgAudit can log all database activity, which is important for auditing
- IAM authentication allows database access using existing Google accounts
- Remember to rotate KMS keys regularly to maintain security
- Monitor Cloud Audit Logs to track database activities
