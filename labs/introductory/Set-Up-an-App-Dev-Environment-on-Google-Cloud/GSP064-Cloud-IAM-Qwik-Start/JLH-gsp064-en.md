# GSP064 - Cloud IAM: Qwik Start

## Lab Overview
Google Cloud's Identity and Access Management (IAM) service lets you create and manage permissions for Google Cloud resources. Cloud IAM unifies access control for Google Cloud services into a single system and provides a consistent set of operations.

In this hands-on lab, you sign in with 2 different sets of credentials to experience how granting and revoking permissions works from Google Cloud Project Owner and Viewer roles.

## Prerequisites
- Google Cloud Platform account
- Basic familiarity with Google Cloud Console
- Understanding of Cloud IAM basic concepts (helpful but not required)
- A .txt or .html file available (if you're looking for more advanced practice with Cloud IAM, be sure to check out the following Google Cloud Skills Boost lab, [IAM Custom Roles](https://www.cloudskillsboost.google/catalog_lab/955))

## Objectives
By the end of this lab, you will be able to:
- Assign a role to a second user
- Remove assigned roles associated with Cloud IAM

## Estimated Time
30-45 minutes

## Lab Steps

### Step 1: Explore the IAM console and project level roles
In this task, you will explore the IAM console and understand project level roles.

**Instructions:**
1. Return to the **Username 1** Cloud Console page.
2. Select **Navigation menu** > **IAM & Admin** > **IAM**. You are now in the "IAM & Admin" console.
3. Click **+GRANT ACCESS** button at the top of the page.
4. Scroll down to **Basic** in Select a role section and mouse over.

There are three roles:

- Editor
- Owner
- Viewer

These are *primitive roles* in Google Cloud. Primitive roles set project-level permissions and unless otherwise specified, they control access and management to all Google Cloud services.

The following table pulls definitions from the Google Cloud IAM article, [Basic roles](https://cloud.google.com/iam/docs/understanding-roles#primitive_roles), which gives a brief overview of browser, viewer, editor, and owner role permissions:

| **Role Name** | **Permissions** |
| --- | --- |
| roles/viewer | Permissions for read-only actions that do not affect state, such as viewing (but not modifying) existing resources or data. |
| roles/editor | All viewer permissions, plus permissions for actions that modify state, such as changing existing resources. |
| roles/owner | All editor permissions and permissions for the following actions:<br>• Manage roles and permissions for a project and all resources within the project.<br>• Set up billing for a project. |

Since you are able to manage roles and permissions for this project, Username 1 has Project owner permissions.

**Expected Result:**
You can see the three basic roles and their permission descriptions.

### Step 2: Explore the editor role
Now switch to the **Username 2** console.

**Instructions:**
1. Navigate to the IAM & Admin console, select **Navigation menu** > **IAM & Admin** > **IAM**.
2. Search through the table to find Username 1 and Username 2 and examine the roles they are granted. The Username 1 and Username 2 roles are listed inline and to the right of each user.

You should see:

- Username 2 has the "Viewer" role granted to it.
- The **+GRANT ACCESS** button at the top is grayed out—if you try to click on it you get the message, "You need permissions for this action. Required permission(s): resource manager.projects.setIamPolicy".

This is one example of how IAM roles affect what you can and cannot do in Google Cloud.

**Expected Result:**
Username 2 can only see viewer permissions and cannot grant access.

### Step 3: Prepare a Cloud Storage bucket for access testing
Ensure that you are in the **Username 1** Cloud Console.

#### Create a bucket

**Instructions:**
1. Create a Cloud Storage bucket with a unique name. From the Cloud Console, select **Navigation menu** > **Cloud Storage** > **Buckets**.
2. Click **+CREATE**.

**Note:** If you get a permissions error for bucket creation, sign out and then sign in back in with the Username 1 credentials.

1. Update the following fields, leave all others at their default values:

| **Property** | **Value** |
| --- | --- |
| **Name**: | *globally unique name (create it yourself!) and click **CONTINUE**. |
| **Location Type:** | Multi-Region |

Note the bucket name. You will use it in a later step.

1. Click **CREATE**.
2. If prompted, Public access will be prevented, click **Confirm**.

**Note:** If you get a permissions error for bucket creation, sign out and then sign in back in with the Username 1 credentials.

#### Upload a sample file

**Instructions:**
1. On the Bucket Details page click **UPLOAD FILES**.
2. Browse your computer to find a file to use. Any text or html file will do.
3. Click on the three dots at the end of the line containing the file and click **Rename**.
4. Rename the file 'sample.txt'.
5. Click **RENAME**.

**Expected Result:**
Bucket created and sample.txt file uploaded.

### Step 4: Verify project viewer access

**Instructions:**
1. Switch to the **Username 2** console.
2. From the Console, select **Navigation menu** > **Cloud Storage** > **Buckets**. Verify that this user can see the bucket.

Username 2 has the "Viewer" role prescribed which allows them read-only actions that do not affect state. This example illustrates this feature—they can view Cloud Storage buckets and files that are hosted in the Google Cloud project that they've been granted access to.

**Expected Result:**
Username 2 can view the bucket contents.

### Step 5: Remove project access
Switch to the **Username 1** console.

#### Remove Project Viewer for Username 2

**Instructions:**
1. Select **Navigation menu** > **IAM & Admin** > **IAM**. Then click the pencil icon inline and to the right of **Username 2**.

**Note:** You may have to widen the screen to see the pencil icon.

1. Remove Project Viewer access for **Username 2** by clicking the trashcan icon next to the role name. Then click **SAVE**.

Notice that the user has disappeared from the Member list! The user has no access now.

**Note:** It can take up to 80 seconds for such a change to take effect as it propagates. Read more about Google Cloud IAM in the Google Cloud IAM Resource Documentation, [Frequently asked questions](https://cloud.google.com/iam/docs/faq).

#### Verify that Username 2 has lost access

**Instructions:**
1. Switch to **Username 2** Cloud Console. Ensure that you are still signed in with Username 2's credentials and that you haven't been signed out of the project after permissions were revoked. If signed out, sign in back with the proper credentials.
2. Navigate back to Cloud Storage by selecting **Navigation menu** > **Cloud Storage** > **Buckets**.

You should see a permission error.

**Note**: As mentioned before, it can take up to 80 seconds for permissions to be revoked. If you haven't received a permission error, wait a 2 minutes and then try refreshing the console.

**Expected Result:**
Username 2 can no longer access Cloud Storage resources.

### Step 6: Add Cloud Storage permissions

**Instructions:**
1. Copy **Username 2** name from the **Lab Connection** panel.
2. Switch to **Username 1** console. Ensure that you are still signed in with Username 1's credentials. If you are signed out, sign in back with the proper credentials.
3. In the Console, select **Navigation menu** > **IAM & Admin** > **IAM**.
4. Click **+GRANT ACCESS** button and paste the **Username 2** name into the **New principals** field.
5. In the **Select a role** field, select **Cloud Storage** > **Storage Object Viewer** from the drop-down menu.
6. Click **SAVE**.

#### Verify access

**Instructions:**
1. Switch to the **Username 2** console. You'll still be on the Storage page.

**Username 2** doesn't have the Project Viewer role, so that user can't see the project or any of its resources in the Console. However, this user has specific access to Cloud Storage, the Storage Object Viewer role - check it out now.

1. Click **Activate Cloud Shell** to open the Cloud Shell command line. If prompted click **Continue**.

   [the icon that activates cloud shell](https://cdn.qwiklabs.com/ep8HmqYGdD%2FkUncAAYpV47OYoHwC8%2Bg0WK%2F8sidHquE%3D)

2. Open up a Cloud Shell session and then enter in the following command, replace `[YOUR_BUCKET_NAME]` with the name of the bucket you created earlier:

`gsutil ls gs://[YOUR_BUCKET_NAME]`

You should receive a similar output:

`gs://[YOUR_BUCKET_NAME]/sample.txt`

**Note:** If you see `AccessDeniedException`, wait a minute and run the previous command again.

**Expected Result:**
Username 2 can now view Cloud Storage bucket contents through gsutil commands.

## Verification
Steps to verify successful completion of the lab:

1. **Step 3**: Bucket created and file uploaded
2. **Step 4**: Username 2 can view the bucket
3. **Step 5**: Username 2 loses project access
4. **Step 6**: Username 2 gains Cloud Storage specific permissions

## Troubleshooting
Common issues and their solutions:
- **Permissions error creating bucket**: Make sure you're using Username 1 credentials and re-login
- **IAM changes not taking effect immediately**: Wait 80 seconds for permissions to propagate
- **Cloud Shell access denied**: Ensure you're using Username 2 credentials with correct permissions
- **gsutil command failure**: Check bucket name spelling and ensure region settings are correct

## Cleanup
Instructions for cleaning up resources to avoid charges:
1. Delete the Cloud Storage bucket:
   ```bash
   gsutil rm -r gs://[YOUR_BUCKET_NAME]
   ```
2. Remove IAM permissions (if needed):
   - Return to IAM console to remove any test permissions

## Additional Resources
- [Google Cloud IAM Documentation](https://cloud.google.com/iam/docs)
- [Basic IAM Roles](https://cloud.google.com/iam/docs/understanding-roles#primitive_roles)
- [IAM Custom Roles Lab](https://www.cloudskillsboost.google/catalog_lab/955)
- [IAM Frequently Asked Questions](https://cloud.google.com/iam/docs/faq)

## Notes
This lab demonstrates basic IAM role concepts:
- Primitive roles (Viewer, Editor, Owner) operate at project level
- Service-specific roles can provide more granular permission control
- IAM changes may take time to propagate
- Permissions can be granted and revoked dynamically
