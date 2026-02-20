# website-hosting-gsutil - Configure Cloud Storage Bucket for Website Hosting using gsutil - Step-by-Step Guide

## Lab Overview
This lab requires configuring an existing Cloud Storage bucket as a static website hosting environment. You need to set the index and error pages and ensure the resources in the bucket are publicly accessible, allowing the website to be accessed directly via a URL.

## Prerequisites
- Basic experience with the Google Cloud Console.
- Familiarity with core Cloud Storage concepts.
- Basic proficiency with `gsutil` commands.

## Estimated Time
- 5 - 10 minutes

---

## Task List

### Task 1: Configure Bucket for Website Hosting

In this task, you will set the designated bucket to website hosting mode and open permissions to all users.

1. **Set Environment Variables**:
   Automatically capture the bucket name in the current project.
   ```bash
   export BUCKET_NAME=$(gcloud storage buckets list --format="value(name)")
   echo "Current Bucket Name: $BUCKET_NAME"
   ```

2. **Set Index and Error Pages**:
   Use the `gsutil web set` command to set `index.html` as the main page and `error.html` as the custom error page.
   ```bash
   gsutil web set -m index.html -e error.html gs://$BUCKET_NAME
   ```
   - `-m index.html`: Specifies the file to display when a user accesses the root path.
   - `-e error.html`: Specifies the file to display when a 404 error occurs.

3. **Disable Uniform Bucket-Level Access (UBLA)**:
   To control individual object permissions using ACL, you must first disable UBLA. This is a **critical step**!
   ```bash
   gcloud storage buckets update gs://$BUCKET_NAME --no-uniform-bucket-level-access
   ```
   - This step allows you to set different Access Control Lists (ACL) for individual objects in the bucket.
   - If UBLA is enabled, all ACL-related `gsutil` commands will fail.

4. **Set Default Object ACL to Public Read**:
   Set default public permissions for all future objects uploaded to this bucket.
   ```bash
   gsutil defacl set public-read gs://$BUCKET_NAME
   ```
   - `public-read`: Newly uploaded files will automatically have public read permissions.

5. **Apply Public Read ACL to Existing Files**:
   Make all existing files in the bucket publicly readable. **This is the key step for passing validation!**
   ```bash
   gsutil -m acl set -a public-read gs://$BUCKET_NAME/*
   ```
   - `-m`: Enables multi-threaded parallel processing for faster batch operations.
   - `-a public-read`: Applies the predefined public read ACL.
   - `gs://$BUCKET_NAME/*`: Executes the operation on all objects in the bucket.

6. **Verify ACL Configuration**:
   Confirm that `index.html` has been correctly set with public read permissions.
   ```bash
   gsutil acl get gs://$BUCKET_NAME/index.html
   ```
   You should see output similar to the following, confirming that `allUsers` has the `READER` role:
   ```json
   [
     {
       "entity": "allUsers",
       "role": "READER"
     }
   ]
   ```

### Verification Steps

1. **Test Public Access Using curl** (Recommended, fastest method):
   ```bash
   curl -I https://storage.googleapis.com/$BUCKET_NAME/index.html
   ```
   If configured successfully, you should see `HTTP/2 200` status code.

2. **Test in Browser**:
   Enter the following URL in your browser:
   ```
   https://storage.googleapis.com/<YOUR-BUCKET-NAME>/index.html
   ```
   or
   ```
   http://<YOUR-BUCKET-NAME>.storage.googleapis.com/index.html
   ```
   Confirm that the content of `index.html` and the images are displayed correctly.

3. **Test Error Page**:
   Try accessing a non-existent file (e.g., `test.html`) to verify that `error.html` is shown.

---

## Execution Guide

### Common Issues and Solutions

#### 1. **ACL Command Fails: "Cannot use ACL API when uniform bucket-level access is enabled"**
   **Cause**: The bucket has Uniform Bucket-Level Access (UBLA) enabled, preventing ACL commands.
   
   **Solution**:
   ```bash
   # Disable UBLA
   gcloud storage buckets update gs://$BUCKET_NAME --no-uniform-bucket-level-access
   
   # Then execute ACL-related commands
   gsutil defacl set public-read gs://$BUCKET_NAME
   gsutil -m acl set -a public-read gs://$BUCKET_NAME/*
   ```

#### 2. **Permission Error: "Failed to set acl...Please ensure you have OWNER-role access"**
   **Cause**: UBLA may still be enabled, or you don't have sufficient permissions.
   
   **Solution**:
   - Verify UBLA is disabled: `gcloud storage buckets describe gs://$BUCKET_NAME --format="default(iamConfiguration)"`
   - Use batch ACL setting: `gsutil -m acl set -a public-read gs://$BUCKET_NAME/*`

#### 3. **Qwiklabs Validation Fails**
   **Cause**: The validation script checks object-level ACL, not bucket-level IAM permissions.
   
   **Solution**: You must execute Step 5 "Apply Public Read ACL to Existing Files":
   ```bash
   gsutil -m acl set -a public-read gs://$BUCKET_NAME/*
   ```
   
   **Verify the configuration**:
   ```bash
   gsutil acl get gs://$BUCKET_NAME/index.html
   ```
   You should see `"entity": "allUsers"` and `"role": "READER"`.

#### 4. **Bucket Not Found**
   If there are multiple buckets in the project, the automatic capture command might pick up more than one. Manually check `gsutil ls` and specify the correct `BUCKET_NAME`.

#### 5. **Website is Accessible but Validation Fails**
   Setting only IAM permissions (`gsutil iam ch` or `gcloud storage buckets add-iam-policy-binding`) may not be sufficient to pass validation. Qwiklabs validation scripts typically check **object-level ACL**, so you must execute:
   ```bash
   gsutil -m acl set -a public-read gs://$BUCKET_NAME/*
   ```

### Tips and Tricks
- **Static Website URL Formats**: Cloud Storage provides two main access URL formats:
  - `storage.googleapis.com/BUCKET_NAME/index.html` (API access format)
  - `BUCKET_NAME.storage.googleapis.com/index.html` (CNAME/website access format)
- **Caching**: If you modify a file but the page doesn't update, it might be due to browser caching or Cloud Storage cache settings. Use incognito mode for testing.

### Cleanup Steps
To remove public access and clear website configuration:
```bash
# Remove public access permission
gsutil iam ch -d allUsers:objectViewer gs://$BUCKET_NAME

# Clear website configuration
gsutil web set gs://$BUCKET_NAME
```

## Extra Resources
- [Google Cloud Documentation: Hosting a Static Website](https://cloud.google.com/storage/docs/hosting-static-website)
- [gsutil web Command Reference](https://cloud.google.com/storage/docs/gsutil/commands/web)

## Technical Notes

### gsutil vs gcloud storage
- This lab uses the `gsutil` tool. Although `gcloud storage` is a newer tool, `gsutil` remains the most direct way to configure website hosting attributes (like `-m` and `-e`) in many existing challenge labs.

### IAM Permissions vs ACL (Access Control List)
This is the most confusing aspect of this lab:

- **IAM Permissions** (Bucket-level):
  - Use `gsutil iam ch` or `gcloud storage buckets add-iam-policy-binding`
  - Sets permissions at the entire bucket level
  - This is the only option when UBLA is enabled
  - **However**: Qwiklabs validation scripts typically don't check IAM permissions

- **ACL** (Object-level):
  - Use `gsutil acl ch` or `gsutil acl set`
  - Sets permissions directly on each object
  - Can only be used when UBLA is **disabled**
  - **Important**: Qwiklabs validation scripts typically check object ACL

### Uniform Bucket-Level Access (UBLA)
- **UBLA Enabled**: Exclusively uses IAM, cannot set individual object ACL (more modern, more secure)
- **UBLA Disabled**: Can use ACL to set permissions on individual objects (traditional approach, more flexible)
- Many Qwiklabs validation scripts were designed before UBLA existed, so they expect ACL usage
- This is why you must first disable UBLA, then set object-level ACL

### Complete Flow to Pass Validation
1. Set website configuration (`gsutil web set`)
2. **Disable UBLA** (`gcloud storage buckets update --no-uniform-bucket-level-access`)
3. Set default ACL (`gsutil defacl set public-read`)
4. **Apply ACL to existing objects** (`gsutil -m acl set -a public-read gs://$BUCKET_NAME/*`) ← Critical!
5. Verify configuration (`gsutil acl get gs://$BUCKET_NAME/index.html`)
