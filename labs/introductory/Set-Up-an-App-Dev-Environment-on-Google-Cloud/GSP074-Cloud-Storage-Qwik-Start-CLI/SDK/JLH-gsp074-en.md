# GSP074 - Cloud Storage: Qwik Start - CLI/SDK

## Lab Overview
Cloud Storage allows world-wide storage and retrieval of any amount of data at any time. You can use Cloud Storage for a range of scenarios including serving website content, storing data for archival and disaster recovery, or distributing large data objects to users via direct download.

In this hands-on lab you will learn how to create a storage bucket, upload objects to it, create folders and subfolders in it, and make objects publicly accessible using the Google Cloud command line.

Throughout this lab you'll be able to verify your work in the console by going to **Navigation menu** > **Cloud Storage**. You'll just need to refresh your browser after each command is run to see the new items you've created.

## Prerequisites
- Google Cloud Platform account
- Basic familiarity with Google Cloud Console
- Understanding of Cloud Storage basic concepts

## Objectives
By the end of this lab, you will be able to:
- Create a Cloud Storage bucket
- Upload objects to the storage bucket
- Create folders and subfolders in the bucket
- Make objects in a storage bucket publicly accessible

## Estimated Time
30-45 minutes

## Lab Steps

### Step 1: Set the region
In this task, you will set the project region for this lab.

**Instructions:**
1. Set the compute region for your project:
   ```bash
   gcloud config set compute/region "REGION"
   ```

**Expected Result:**
Region has been successfully set.

### Step 2: Create a bucket
In this lab you use [gcloud storage](https://cloud.google.com/sdk/gcloud/reference/storage) and [gsutil](https://cloud.google.com/storage/docs/gsutil) commands.

When you create a bucket you must follow the universal bucket naming rules, below.

**Bucket naming rules**
- Do not include sensitive information in the bucket name, because the bucket namespace is global and publicly visible.
- Bucket names must contain only lowercase letters, numbers, dashes (-), underscores (_), and dots (.). Names containing dots require [verification](https://cloud.google.com/storage/docs/domain-name-verification).
- Bucket names must start and end with a number or letter.
- Bucket names must contain 3 to 63 characters. Names containing dots can contain up to 222 characters, but each dot-separated component can be no longer than 63 characters.
- Bucket names cannot be represented as an IP address in dotted-decimal notation (for example, 192.168.5.4).
- Bucket names cannot begin with the "goog" prefix.
- Bucket names cannot contain "google" or close misspellings of "google".
- Also, for DNS compliance and future compatibility, you should not use underscores (_) or have a period adjacent to another period or dash. For example, ".." or "-." or ".-" are not valid in DNS names.

Use the make bucket (`buckets create`) command to make a bucket, replacing `<YOUR_BUCKET_NAME>` with a unique name that follows the bucket naming rules:

```bash
gcloud storage buckets create gs://<YOUR-BUCKET-NAME>
```

This command is creating a bucket with default settings. To see what those default settings are, use the Cloud console **Navigation menu** > **Cloud Storage**, then click on your bucket name, and click on the **Configuration** tab.

That's it — you've just created a Cloud Storage bucket!

**Note:** If the bucket name is already taken, either by you or someone else, the command returns:
`Creating gs://YOUR-BUCKET-NAME/...`
`ServiceException: 409 Bucket YOUR-BUCKET-NAME already exists.` Try again with a different bucket name.

**Expected Result:**
Cloud Storage bucket has been successfully created.

### Step 3: Upload an object into your bucket
Use Cloud Shell to upload an object into a bucket.

**Instructions:**
1. To download this image (ada.jpg) into your bucket, enter this command into Cloud Shell:

   ```bash
   curl https://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Ada_Lovelace_portrait.jpg/800px-Ada_Lovelace_portrait.jpg --output ada.jpg
   ```

2. Use the `gcloud storage cp` command to upload the image from the location where you saved it to the bucket you created:

   ```bash
   gcloud storage cp ada.jpg gs://YOUR-BUCKET-NAME
   ```

   **Note:** When typing your bucket name, you can use the tab key to autocomplete it.

You can see the image load into your bucket from the command line.

You've just stored an object in your bucket!

3. Now remove the downloaded image:

   ```bash
   rm ada.jpg
   ```

**Expected Result:**
Object has been successfully uploaded to the Cloud Storage bucket.

### Step 4: Download an object from your bucket
- Use the `gcloud storage cp` command to download the image you stored in your bucket to Cloud Shell:

  ```bash
  gcloud storage cp -r gs://YOUR-BUCKET-NAME/ada.jpg .
  ```

If successful, the command returns:

`Copying gs://YOUR-BUCKET-NAME/ada.jpg...
/ [1 files][360.1 KiB/2360.1 KiB]
Operation completed over 1 objects/360.1 KiB.`

You've just downloaded the image from your bucket.

**Expected Result:**
Object has been successfully downloaded from the Cloud Storage bucket.

### Step 5: Copy an object to a folder in the bucket
- Use the `gcloud storage cp` command to create a folder called `image-folder` and copy the image (ada.jpg) into it:

  ```bash
  gcloud storage cp gs://YOUR-BUCKET-NAME/ada.jpg gs://YOUR-BUCKET-NAME/image-folder/
  ```

  **Note:** Compared to local file systems, [folders in Cloud Storage](https://cloud.google.com/sdk/gcloud/reference/storage/folders) have limitations, but many of the same operations are supported.

If successful, the command returns:

`Copying gs://YOUR-BUCKET-NAME/ada.jpg [Content-Type=image/png]...
- [1 files] [ 360.1 KiB/ 360.1 KiB]
Operation completed over 1 objects/360.1 KiB`

The image file has been copied into a new folder in your bucket.

**Expected Result:**
Object has been successfully copied to a folder in the bucket.

### Step 6: List contents of a bucket or folder
- Use the `gcloud storage ls` command to list the contents of the bucket:

  ```bash
  gcloud storage ls gs://YOUR-BUCKET-NAME
  ```

If successful, the command returns a message similar to:

`gs://YOUR-BUCKET-NAME/ada.jpg
gs://YOUR-BUCKET-NAME/image-folder/`

That's everything currently in your bucket.

**Expected Result:**
Bucket contents have been successfully listed.

### Step 7: List details for an object
- Use the `gcloud storage ls` command, with the `l` flag to get some details about the image file you uploaded to your bucket:

  ```bash
  gcloud storage ls -l gs://YOUR-BUCKET-NAME/ada.jpg
  ```

If successful, the command returns a message similar to:

`306768  2017-12-26T16:07:570Z  gs://YOUR-BUCKET-NAME/ada.jpg
TOTAL: 1 objects, 30678 bytes (360.1 KiB)`

Now you know the image's size and date of creation.

**Expected Result:**
Object details have been successfully retrieved.

### Step 8: Make your object publicly accessible
- Use the `gsutil acl ch` command to grant all users read permission for the object stored in your bucket:

  ```bash
  gsutil acl ch -u AllUsers:R gs://YOUR-BUCKET-NAME/ada.jpg
  ```

If successful, the command returns:

`Updated ACL on gs://YOUR-BUCKET-NAME/ada.jpg`

Your image is now public, and can be made available to anyone.

**Expected Result:**
Object permissions have been successfully set to public.

### Step 9: Verify object is publicly accessible
- Go to **Navigation menu** > **Cloud Storage**, then click on the name of your bucket.

You should see your image with the **Public link** box. Click the **Copy URL** and open the URL in a new browser tab.

**Note:** Who are you looking at? This is [Ada Lovelace](https://en.wikipedia.org/wiki/Ada_Lovelace), credited with being the first computer programmer. She worked with mathematician and computer pioneer Charles Babbage, who proposed the [Analytical Engine](https://en.wikipedia.org/wiki/Analytical_Engine).

**Expected Result:**
Object has been successfully made publicly accessible and can be accessed via the public URL.

### Step 10: Remove public access
1. To remove this permission, use the command:

   ```bash
   gsutil acl ch -d AllUsers gs://YOUR-BUCKET-NAME/ada.jpg
   ```

If successful, the command returns:

`Updated ACL on gs://YOUR-BUCKET-NAME/ada.jpg`

You have removed public access to this object.

2. Verify that you've removed public access by clicking the **Refresh** button in the console. The checkmark will be removed.

**Expected Result:**
Public access to the object has been successfully removed.

### Step 11: Delete objects
1. Use the `gcloud storage rm` command to delete an object - the image file in your bucket:

   ```bash
   gcloud storage rm gs://YOUR-BUCKET-NAME/ada.jpg
   ```

If successful, the command returns:

`Removing gs://YOUR-BUCKET-NAME/ada.jpg...`

2. Refresh the console. The copy of the image file is no longer stored on Cloud Storage (though the copy you made in the `image-folder/` folder still exists).

**Expected Result:**
Object has been successfully deleted from the Cloud Storage bucket.

## Verification
To verify that the lab was completed successfully:
1. Confirm the bucket was created
2. Confirm objects were uploaded and are accessible
3. Confirm folder structure is correct
4. Confirm public access permissions were set and removed correctly
5. Confirm objects were deleted properly

## Troubleshooting
Common issues and their solutions:
- **Bucket name conflicts**: Choose a unique bucket name
- **Permission errors**: Ensure you have sufficient GCP permissions
- **Object not found**: Check object paths and names are correct
- **Public access failure**: Verify ACL command syntax is correct
- **Deletion failure**: Ensure object exists and you have delete permissions

## Cleanup
To avoid charges, clean up resources by following these steps:
1. Delete all objects in the bucket:
   ```bash
   gcloud storage rm -r gs://YOUR-BUCKET-NAME/**
   ```

2. Delete the bucket:
   ```bash
   gcloud storage buckets delete gs://YOUR-BUCKET-NAME
   ```

## Additional Resources
- [Cloud Storage Documentation](https://cloud.google.com/storage/docs/)
- [gcloud storage Command Reference](https://cloud.google.com/sdk/gcloud/reference/storage)
- [gsutil Tool Guide](https://cloud.google.com/storage/docs/gsutil)
- [Cloud Storage Security Best Practices](https://cloud.google.com/storage/docs/best-practices)
- [Ada Lovelace Wikipedia Page](https://en.wikipedia.org/wiki/Ada_Lovelace)

## Notes
This lab demonstrates basic Cloud Storage operations. Key learning points include:
- Cloud Storage bucket naming rules and limitations
- Object operations using gcloud and gsutil commands
- ACL permission management and public access control
- Object versioning and lifecycle management
- Cloud Storage role in disaster recovery and archiving
