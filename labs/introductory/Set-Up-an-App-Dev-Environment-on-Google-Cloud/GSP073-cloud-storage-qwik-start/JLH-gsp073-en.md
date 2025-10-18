# GSP073 - Cloud Storage: Qwik Start - Cloud Console

## Overview

Cloud Storage allows world-wide storage and retrieval of any amount of data at any time. You can use Cloud Storage for a range of scenarios including serving website content, storing data for archival and disaster recovery, or distributing large data objects to users via direct download.

## Prerequisites

- Basic knowledge of Google Cloud Platform
- Cloud Storage API enabled
- Basic familiarity with Cloud Console operations

## Objectives

By the end of this lab, you will be able to:
- Create a Cloud Storage bucket
- Upload objects to the bucket
- Create folders and subfolders in the bucket
- Make objects in a storage bucket publicly accessible

## Estimated Time

30-45 minutes

## Lab Steps

### Step 1: Create a Bucket

Buckets are the basic containers that hold your data in Cloud Storage.

**Instructions:**

1. In the Cloud console, go to **Navigation menu** > **Cloud Storage** > **Buckets**
2. Click **+ Create**
3. Enter your bucket information and click **Continue** to complete each step:
   - **Name your bucket:** Enter a unique name for your bucket. For this lab, you can use your **Project ID** as the bucket name because it will always be unique.
   
   **Bucket naming rules:**
   - Do not include sensitive information in the bucket name, because the bucket namespace is global and publicly visible
   - Bucket names must contain only lowercase letters, numbers, dashes (-), underscores (_), and dots (.)
   - Bucket names must start and end with a number or letter
   - Bucket names must contain 3 to 63 characters
   - Bucket names cannot be represented as an IP address in dotted-decimal notation
   - Bucket names cannot begin with the "goog" prefix
   - Choose **Region** for **Location type** and `<filled in at lab start>` for **Location**
   - Choose **Standard** for **default storage class**
   - Choose **Uniform** for **Access control** and **uncheck** *Enforce public access prevention on this bucket* to turn it off

4. Leave the rest of the fields as their default values and click **Create**

**Expected Result:**
You should see the newly created bucket appear in the bucket list.

**Note:** If you are prompted with "Public access will be prevented", uncheck *Enforce public access prevention on this bucket* and click **Confirm**.

### Step 2: Upload an Object into the Bucket

**Instructions:**

1. Right-click on the kitten image in the lab and download it to your computer. Save the image as **kitten.png**, renaming it on download
2. In the Cloud Storage browser page, click the name of the bucket that you created
3. In the **Objects** tab, click **Upload** > **Upload files**
4. In the file dialog, go to the file that you downloaded and select it
5. Ensure the file is named **kitten.png**. If it is not, click the **three dot** icon for your file, select **Rename** from the dropdown, and rename the file to **kitten.png**

**Expected Result:**
After the upload completes, you should see the file name and information about the file, such as its size and type.

### Step 3: Share a Bucket Publicly

**Instructions:**

1. Click the **Permissions** tab above the list of files
2. Ensure the view is set to **Principals**. Click **Grant Access** to view the **Add principals** pane
3. In the **New principals** box, enter *allUsers*
4. In the **Select a role** drop-down, select **Cloud Storage** > **Storage Object Viewer**
5. Click **Save**
6. In the **Are you sure you want to make this resource public?** window, click **Allow public access**

**Verification:**
1. Click the **Objects** tab to return to the list of objects. Your object's **Public access** column should read **Public to internet**
2. Press the **Copy URL** button for your object and paste it into a separate tab to view your image

**Note:** If your object does not appear to be public after following the previous steps, you may need to refresh your browser page.

### Step 4: Create Folders

**Instructions:**

1. In the **Objects** tab, click **Create folder**
2. Enter **folder1** for **Name** and click **Create**

**Create a subfolder and upload a file to it:**

1. Click **folder1**
2. Click **Create folder**
3. Enter **folder2** for **Name** and click **Create**
4. Click **folder2**
5. Click **Upload** > **Upload files**
6. In the file dialog, navigate to the screenshot that you downloaded and select it

**Expected Result:**
You should see the folder in the bucket with an image of a folder icon to distinguish it from objects.

### Step 5: Delete a Folder

**Instructions:**

1. Click the arrow next to **Bucket details** to return to the buckets level
2. Select the bucket
3. Click on the **Delete** button
4. In the window that opens, type `DELETE` to confirm the deletion of the folder
5. Click **Delete** to permanently delete the folder and all objects and subfolders in it

## Verification

Complete the following checks to confirm successful lab completion:

1. **Bucket Creation**: Bucket appears in Cloud Storage browser
2. **Object Upload**: kitten.png file appears in bucket's object list
3. **Public Access**: Object's public access status shows "Public to internet"
4. **Folder Structure**: Successfully created nested structure folder1/folder2
5. **URL Access**: Image accessible via public URL

## Troubleshooting

Common issues and their solutions:

- **Bucket Name Conflict**: Ensure using unique bucket name, recommend using Project ID
- **Public Access Failure**: Confirm "Enforce public access prevention" option is unchecked
- **Upload Failure**: Check file size limits and network connectivity
- **Permission Errors**: Ensure you have appropriate IAM permissions to manage Cloud Storage

## Cleanup

To avoid charges, clean up created resources:

1. Return to Cloud Storage browser
2. Select your created bucket
3. Click **Delete**
4. In confirmation dialog, type `DELETE`
5. Click **Delete** to permanently remove bucket and all contents

## Additional Resources

- [Cloud Storage Documentation](https://cloud.google.com/storage/docs)
- [Cloud Storage Best Practices](https://cloud.google.com/storage/docs/best-practices)
- [Cloud Storage Security Guide](https://cloud.google.com/storage/docs/security)
- [Cloud Storage Pricing](https://cloud.google.com/storage/pricing)

## Related Labs

- GSP074: Cloud Storage: Qwik Start - CLI
- GSP075: Cloud Storage: Qwik Start - gsutil
- GSP076: Cloud Storage: Qwik Start - Cloud Console

## Notes

Record your personal notes and observations here:

- Importance of bucket naming
- Security considerations for public access
- Best practices for folder structure
- Cost optimization recommendations
