**GSP355 \- Create and Manage Cloud SQL for PostgreSQL Instances: Challenge Lab**

**Task 1\. Migrate a stand-alone PostgreSQL database to a Cloud SQL for PostgreSQL instance**

Prepare the stand-alone PostgreSQL database for migration

Enable  **Database Migration API** and the **Service Networking API**

**VM machine \-\> SSH**

sudo apt install postgresql-13-pglogical

sudo su \- postgres \-c "gsutil cp gs://cloud-training/gsp918/pg\_hba\_append.conf ."  
sudo su \- postgres \-c "gsutil cp gs://cloud-training/gsp918/postgresql\_append.conf ."  
sudo su \- postgres \-c "cat pg\_hba\_append.conf \>\> /etc/postgresql/13/main/pg\_hba.conf"  
sudo su \- postgres \-c "cat postgresql\_append.conf \>\> /etc/postgresql/13/main/postgresql.conf"  
sudo systemctl restart postgresql@13-main

sudo su \- postgres

psql

\\c postgres;

CREATE EXTENSION pglogical;

\\c orders;

CREATE EXTENSION pglogical;

【REMEMBER to replace the Username that Lab provided)】  
【Tool: [https://www.unit-conversion.info/texttools/replace-text/](https://www.unit-conversion.info/texttools/replace-text/】) 】

CREATE USER migration\_admin PASSWORD 'DMS\_1s\_cool\!';  
ALTER DATABASE orders OWNER TO migration\_admin;  
ALTER ROLE migration\_admin WITH REPLICATION;

\\c orders;

SELECT column\_name FROM information\_schema.columns WHERE table\_name \= 'inventory\_items' AND column\_name \= 'id';  
ALTER TABLE inventory\_items ADD PRIMARY KEY (id);

GRANT USAGE ON SCHEMA pglogical TO migration\_admin;  
GRANT ALL ON SCHEMA pglogical TO migration\_admin;  
GRANT SELECT ON pglogical.tables TO migration\_admin;  
GRANT SELECT ON pglogical.depend TO migration\_admin;  
GRANT SELECT ON pglogical.local\_node TO migration\_admin;  
GRANT SELECT ON pglogical.local\_sync\_status TO migration\_admin;  
GRANT SELECT ON pglogical.node TO migration\_admin;  
GRANT SELECT ON pglogical.node\_interface TO migration\_admin;  
GRANT SELECT ON pglogical.queue TO migration\_admin;  
GRANT SELECT ON pglogical.replication\_set TO migration\_admin;  
GRANT SELECT ON pglogical.replication\_set\_seq TO migration\_admin;  
GRANT SELECT ON pglogical.replication\_set\_table TO migration\_admin;  
GRANT SELECT ON pglogical.sequence\_state TO migration\_admin;  
GRANT SELECT ON pglogical.subscription TO migration\_admin;

GRANT USAGE ON SCHEMA public TO migration\_admin;  
GRANT ALL ON SCHEMA public TO migration\_admin;  
GRANT SELECT ON public.distribution\_centers TO migration\_admin;  
GRANT SELECT ON public.inventory\_items TO migration\_admin;  
GRANT SELECT ON public.order\_items TO migration\_admin;  
GRANT SELECT ON public.products TO migration\_admin;  
GRANT SELECT ON public.users TO migration\_admin;

ALTER TABLE public.distribution\_centers OWNER TO migration\_admin;  
ALTER TABLE public.inventory\_items OWNER TO migration\_admin;  
ALTER TABLE public.order\_items OWNER TO migration\_admin;  
ALTER TABLE public.products OWNER TO migration\_admin;  
ALTER TABLE public.users OWNER TO migration\_admin;

\\c postgres;

GRANT USAGE ON SCHEMA pglogical TO migration\_admin;  
GRANT ALL ON SCHEMA pglogical TO migration\_admin;  
GRANT SELECT ON pglogical.tables TO migration\_admin;  
GRANT SELECT ON pglogical.depend TO migration\_admin;  
GRANT SELECT ON pglogical.local\_node TO migration\_admin;  
GRANT SELECT ON pglogical.local\_sync\_status TO migration\_admin;  
GRANT SELECT ON pglogical.node TO migration\_admin;  
GRANT SELECT ON pglogical.node\_interface TO migration\_admin;  
GRANT SELECT ON pglogical.queue TO migration\_admin;  
GRANT SELECT ON pglogical.replication\_set TO migration\_admin;  
GRANT SELECT ON pglogical.replication\_set\_seq TO migration\_admin;  
GRANT SELECT ON pglogical.replication\_set\_table TO migration\_admin;  
GRANT SELECT ON pglogical.sequence\_state TO migration\_admin;  
GRANT SELECT ON pglogical.subscription TO migration\_admin;

Migrate the stand-alone PostgreSQL database to a Cloud SQL for PostgreSQL instance

Go to Google Console \-\> Database Migration Service

**Task 2\. Promote a Cloud SQL to be a stand-alone instance for reading and writing data**

Go to CloudSQL \-\> click Promote

**Task 3\. Implement Cloud SQL for PostgreSQL IAM database authentication**  
supersecret\!

\\c orders;

supersecret\!

【Note replace the TABLE\_NAME and USER\_NAME】  
GRANT ALL PRIVILEGES ON TABLE \[TABLE\_NAME\] TO "Qwiklabs\_User\_Account\_Name";

SELECT COUNT(\*) FROM \[TABLE\_NAME\]

**Task 4\. Configure and test point-in-time recovery**  
date \-u \--rfc-3339=ns | sed \-r 's/ /T/; s/\\.(\[0-9\]{3}).\*/\\.\\1Z/'  
(Save this timestamp for later task)

supersecret\!

\\c orders;

supersecret\!

insert into distribution\_centers values(-80.1918,25.7617,'Miami FL',11);

\\q

【 In the Cloud Shell 】  
gcloud auth login \--quiet

gcloud projects get-iam-policy $DEVSHELL\_PROJECT\_ID

export INSTANCE\_ID=        

gcloud sql instances clone $INSTANCE\_ID  postgres-orders-pitr \--point-in-time 'CHANGE\_TIMESTAMP'  
