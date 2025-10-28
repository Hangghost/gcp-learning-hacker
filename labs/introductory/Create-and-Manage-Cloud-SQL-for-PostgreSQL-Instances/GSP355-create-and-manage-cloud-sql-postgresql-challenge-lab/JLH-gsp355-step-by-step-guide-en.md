# GSP355 - Create and Manage Cloud SQL for PostgreSQL Instances: Challenge Lab

## Overview

This challenge lab tests your ability to:
- Migrate a stand-alone PostgreSQL database to Cloud SQL for PostgreSQL using Database Migration Services
- Promote the Cloud SQL database to a stand-alone instance for reading and writing
- Secure the database using IAM DB Authentication
- Perform a point-in-time recovery on the database

## Prerequisites

Before starting this lab, ensure you have:
- A GCP project with billing enabled
- Basic knowledge of PostgreSQL and Cloud SQL
- Familiarity with Database Migration Service

## Task 1. Migrate a stand-alone PostgreSQL database to a Cloud SQL for PostgreSQL instance

### Step 1.1: Enable Required APIs

1. In Google Cloud Console, go to **APIs & Services > Library**
2. Enable the following APIs:
   - Database Migration API
   - Service Networking API

### Step 1.2: Prepare the Stand-alone PostgreSQL Database

1. **Connect to the VM:**
   ```bash
   # SSH into postgres-vm
   gcloud compute ssh postgres-vm --zone=YOUR_ZONE
   ```

2. **Install pglogical extension:**
   ```bash
   sudo apt update
   sudo apt install postgresql-13-pglogical
   ```

3. **Download and apply configuration files:**
   ```bash
   sudo su - postgres -c "gsutil cp gs://cloud-training/gsp918/pg_hba_append.conf ."
   sudo su - postgres -c "gsutil cp gs://cloud-training/gsp918/postgresql_append.conf ."
   sudo su - postgres -c "cat pg_hba_append.conf >> /etc/postgresql/13/main/pg_hba.conf"
   sudo su - postgres -c "cat postgresql_append.conf >> /etc/postgresql/13/main/postgresql.conf"
   sudo systemctl restart postgresql@13-main
   ```

4. **Switch to postgres user and access psql:**
   ```bash
   sudo su - postgres
   psql
   ```

5. **Create pglogical extensions:**
   ```sql
   \c postgres;
   CREATE EXTENSION pglogical;

   \c orders;
   CREATE EXTENSION pglogical;
   ```

6. **Create migration user (replace USERNAME with your lab-provided username):**
   ```sql
   CREATE USER migration_admin PASSWORD 'DMS_1s_cool!';
   ALTER DATABASE orders OWNER TO migration_admin;
   ALTER ROLE migration_admin WITH REPLICATION;
   ```

7. **Add primary key to inventory_items table:**
   ```sql
   \c orders;
   SELECT column_name FROM information_schema.columns WHERE table_name = 'inventory_items' AND column_name = 'id';
   ALTER TABLE inventory_items ADD PRIMARY KEY (id);
   ```

8. **Grant permissions to migration_admin user:**
   ```sql
   -- Grant permissions on pglogical schema
   GRANT USAGE ON SCHEMA pglogical TO migration_admin;
   GRANT ALL ON SCHEMA pglogical TO migration_admin;
   GRANT SELECT ON pglogical.tables TO migration_admin;
   GRANT SELECT ON pglogical.depend TO migration_admin;
   GRANT SELECT ON pglogical.local_node TO migration_admin;
   GRANT SELECT ON pglogical.local_sync_status TO migration_admin;
   GRANT SELECT ON pglogical.node TO migration_admin;
   GRANT SELECT ON pglogical.node_interface TO migration_admin;
   GRANT SELECT ON pglogical.queue TO migration_admin;
   GRANT SELECT ON pglogical.replication_set TO migration_admin;
   GRANT SELECT ON pglogical.replication_set_seq TO migration_admin;
   GRANT SELECT ON pglogical.replication_set_table TO migration_admin;
   GRANT SELECT ON pglogical.sequence_state TO migration_admin;
   GRANT SELECT ON pglogical.subscription TO migration_admin;

   -- Grant permissions on public schema
   GRANT USAGE ON SCHEMA public TO migration_admin;
   GRANT ALL ON SCHEMA public TO migration_admin;
   GRANT SELECT ON public.distribution_centers TO migration_admin;
   GRANT SELECT ON public.inventory_items TO migration_admin;
   GRANT SELECT ON public.order_items TO migration_admin;
   GRANT SELECT ON public.products TO migration_admin;
   GRANT SELECT ON public.users TO migration_admin;

   -- Change table ownership
   ALTER TABLE public.distribution_centers OWNER TO migration_admin;
   ALTER TABLE public.inventory_items OWNER TO migration_admin;
   ALTER TABLE public.order_items OWNER TO migration_admin;
   ALTER TABLE public.products OWNER TO migration_admin;
   ALTER TABLE public.users OWNER TO migration_admin;
   ```

9. **Grant permissions in postgres database:**
   ```sql
   \c postgres;
   GRANT USAGE ON SCHEMA pglogical TO migration_admin;
   GRANT ALL ON SCHEMA pglogical TO migration_admin;
   GRANT SELECT ON pglogical.tables TO migration_admin;
   GRANT SELECT ON pglogical.depend TO migration_admin;
   GRANT SELECT ON pglogical.local_node TO migration_admin;
   GRANT SELECT ON pglogical.local_sync_status TO migration_admin;
   GRANT SELECT ON pglogical.node TO migration_admin;
   GRANT SELECT ON pglogical.node_interface TO migration_admin;
   GRANT SELECT ON pglogical.queue TO migration_admin;
   GRANT SELECT ON pglogical.replication_set TO migration_admin;
   GRANT SELECT ON pglogical.replication_set_seq TO migration_admin;
   GRANT SELECT ON pglogical.replication_set_table TO migration_admin;
   GRANT SELECT ON pglogical.sequence_state TO migration_admin;
   GRANT SELECT ON pglogical.subscription TO migration_admin;
   ```

### Step 1.3: Create Database Migration Service Connection Profile

1. In Google Cloud Console, go to **Database Migration > Connection profiles**
2. Click **CREATE PROFILE**
3. Configure the profile:
   - **Source database engine**: PostgreSQL
   - **Connection profile name**: Choose a name (e.g., postgres-source-profile)
   - **Host**: Internal IP of postgres-vm
   - **Port**: 5432
   - **Username**: migration_admin
   - **Password**: DMS_1s_cool!
   - **Region**: YOUR_REGION (same as your lab region)

### Step 1.4: Create Migration Job

1. Go to **Database Migration > Migration jobs**
2. Click **CREATE MIGRATION JOB**
3. Configure the migration job:
   - **Migration job name**: Choose a name (e.g., postgres-migration-job)
   - **Source connection profile**: Select the profile you created
   - **Destination**:
     - **Destination instance ID**: YOUR_MIGRATED_INSTANCE_ID
     - **Password**: supersecret!
     - **Database version**: Cloud SQL for PostgreSQL 13
     - **Region**: YOUR_REGION
     - **Connections**: Enable both Public IP and Private IP
     - **Private IP**: Use automatically allocated IP range
     - **Edition**: Enterprise
     - **Machine type**: 2 vCPU, 8GB RAM
   - **Connectivity method**: VPC peering (default network)
   - **Migration job type**: Continuous

4. **Test the connection** and then **Create & Start** the migration job

5. **Wait for the migration to complete** - this may take several minutes

## Task 2. Promote a Cloud SQL to be a stand-alone instance for reading and writing data

1. In Google Cloud Console, go to **SQL**
2. Select your migrated Cloud SQL instance
3. Click **Promote** to promote the migration replica to a stand-alone instance
4. Wait for the promotion to complete - the migration job status will update to "Completed"

## Task 3. Implement Cloud SQL for PostgreSQL IAM database authentication

### Step 3.1: Add VM's Public IP to Authorized Networks

1. In Cloud SQL instance, go to **Connections > Networking**
2. Under **Public IP**, click **ADD A NETWORK**
3. Add the external IP of the postgres-vm virtual machine

### Step 3.2: Create Cloud IAM User

1. In Cloud SQL instance, go to **Users**
2. Click **ADD USER ACCOUNT**
3. Select **Cloud IAM**
4. Enter the Qwiklabs user account name as the principal

### Step 3.3: Grant Permissions and Test Access

1. In Cloud SQL instance, go to **Overview > Connect to this instance**
2. Click **Open Cloud Shell**
3. Connect to the database:
   ```sql
   -- Enter password: supersecret!
   \c orders;
   -- Enter password again: supersecret!
   ```

4. Grant SELECT permission (replace TABLE_NAME and QWIKLABS_USER with actual values):
   ```sql
   GRANT SELECT ON TABLE_NAME TO "QWIKLABS_USER_ACCOUNT_NAME";
   ```

5. Test the access:
   ```sql
   SELECT COUNT(*) FROM TABLE_NAME;
   ```

## Task 4. Configure and test point-in-time recovery

### Step 4.1: Enable Point-in-Time Recovery

1. In Cloud SQL instance, go to **Overview**
2. Click **EDIT > Data Protection**
3. Enable **Point-in-time recovery**
4. Set **Number of retained transaction log days** to the required value

### Step 4.2: Record Timestamp for Recovery

1. Run this command to get current timestamp:
   ```bash
   date -u --rfc-3339=ns | sed -r 's/ /T/; s/\.([0-9]{3}).*/\.\1Z/'
   ```
2. **Save this timestamp** for later use

### Step 4.3: Make Changes to Database

1. Connect to the database via Cloud Shell:
   ```sql
   -- Password: supersecret!
   \c orders;
   -- Password: supersecret!
   ```

2. Add a row to distribution_centers table:
   ```sql
   INSERT INTO distribution_centers VALUES (-80.1918, 25.7617, 'Miami FL', 11);
   ```

3. Exit psql:
   ```sql
   \q
   ```

### Step 4.4: Create Point-in-Time Recovery Clone

1. In Cloud Shell, run:
   ```bash
   gcloud auth login --quiet
   gcloud projects get-iam-policy $DEVSHELL_PROJECT_ID
   export INSTANCE_ID=YOUR_MIGRATED_INSTANCE_ID
   gcloud sql instances clone $INSTANCE_ID postgres-orders-pitr --point-in-time 'YOUR_SAVED_TIMESTAMP'
   ```

2. Wait for the clone to be created - this will create a new instance called `postgres-orders-pitr`

## Verification

- **Task 1**: Migration job completed successfully
- **Task 2**: Cloud SQL instance promoted to stand-alone
- **Task 3**: IAM user can successfully query the table
- **Task 4**: Point-in-time recovery clone created successfully

## Troubleshooting

- **Migration fails**: Check that pglogical is properly configured and all permissions are granted
- **Connection issues**: Verify IP addresses and network configurations
- **IAM authentication fails**: Ensure the user account format is correct
- **Point-in-time recovery fails**: Check timestamp format and ensure backups are enabled

## Cleanup

After completing the lab, you can:
1. Delete the cloned instance (postgres-orders-pitr)
2. Delete the migration job
3. Delete the Cloud SQL instance (if not needed)
4. Delete the VM instance (if not needed)

## Additional Resources

- [Database Migration Service Documentation](https://cloud.google.com/database-migration/docs)
- [Cloud SQL IAM Database Authentication](https://cloud.google.com/sql/docs/postgres/authentication)
- [Point-in-Time Recovery](https://cloud.google.com/sql/docs/postgres/backup-recovery/pitr)
