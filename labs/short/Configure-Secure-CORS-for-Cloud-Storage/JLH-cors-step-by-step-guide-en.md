# CORS-001 - Configure Secure CORS for Cloud Storage - Step-by-Step Guide

## Lab Overview

This Challenge Lab aims to configure secure Cross-Origin Resource Sharing (CORS) settings on a Google Cloud Storage bucket. Your research partner needs to access public data stored in Cloud Storage from their web application at http://example.com, but is currently encountering cross-origin access errors.

You need to configure CORS settings to allow only GET requests from http://example.com, following the principle of least privilege.

## Prerequisites

- Basic understanding of Google Cloud Storage and CORS concepts
- Familiarity with gcloud/gsutil commands
- Created Cloud Storage bucket (provided by Lab environment)

## Estimated Time

15-20 minutes

## Task List

### Task 1: Check Existing CORS Configuration

First, you need to check the current CORS configuration of the target bucket to understand the current state.

**Step Details:**

1. Confirm your current project:
   ```
   gcloud config get-value project
   ```

**Verification Steps:**
- Command executes successfully and displays current project ID

### Task 2: Get Bucket Name and Set Variable

**Step Details:**

1. List all Cloud Storage buckets in the project and record the target bucket name to a variable:
   ```
   BUCKET_NAME=$(gsutil ls | grep -o 'gs://[^ ]*' | head -1) && echo "Using bucket: $BUCKET_NAME"
   ```

**Verification Steps:**
- Variable is set: `echo $BUCKET_NAME`
- Displays correct gs:// URL

### Task 3: Check Existing CORS Configuration

**Step Details:**

1. Check the current CORS configuration of the target bucket:
   ```
   gsutil cors get $BUCKET_NAME
   ```

   If no CORS is configured, you will see an empty response or error message.

**Verification Steps:**
- Command executes successfully and displays current CORS configuration (may be empty)

### Task 4: Create CORS Configuration File

According to task requirements, you need to create a CORS configuration that allows only GET requests from http://example.com.

**Step Details:**

1. Create CORS configuration file. Use the following command to directly create the `cors-config.json` file:
   ```
   cat > cors-config.json << 'EOF'
   [
     {
       "origin": ["http://example.com"],
       "method": ["GET"],
       "responseHeader": ["Content-Type"],
       "maxAgeSeconds": 3600
     }
   ]
   EOF
   ```

   **Alternative**: If the heredoc command above has issues when copying and pasting, use the following single-line command:
   ```
   printf '[\n  {\n    "origin": ["http://example.com"],\n    "method": ["GET"],\n    "responseHeader": ["Content-Type"],\n    "maxAgeSeconds": 3600\n  }\n]\n' > cors-config.json
   ```

   This command will directly create a file with correct JSON content, no editor required.

**Explanation:**
- `origin`: Allows requests only from http://example.com
- `method`: Allows only GET requests
- `responseHeader`: Allowed response headers
- `maxAgeSeconds`: Cache time for preflight requests (1 hour)

**Verification Steps:**
- Configuration file created: `ls -la cors-config.json`
- Configuration file content is correct: `cat cors-config.json`

### Task 5: Apply CORS Configuration to Cloud Storage Bucket

Now apply the created CORS configuration to the target bucket.

**Step Details:**

1. Apply CORS configuration to the bucket:
   ```
   gsutil cors set cors-config.json $BUCKET_NAME
   ```

   This command will set the CORS rules you defined to the specified bucket.

**Explanation:**
- `gsutil cors set`: Sets the bucket's CORS configuration
- First parameter is the configuration file path
- Second parameter is the target bucket's gs:// URI

**Verification Steps:**
- Command executes successfully with no error messages
- Check if configuration is applied correctly:
  ```
  gsutil cors get $BUCKET_NAME
  ```

  You should be able to see the CORS configuration you set.

### Task 6: Final Verification

**Step Details:**

1. Check CORS configuration again:
   ```
   gsutil cors get $BUCKET_NAME
   ```

   Confirm configuration is applied correctly.

2. Test if configuration allows requests from specified origin (optional but recommended):
   ```
   curl -H "Origin: http://example.com" -H "Access-Control-Request-Method: GET" -X OPTIONS -v $BUCKET_NAME/test-file 2>&1 | grep -i "access-control-allow-origin"
   ```

**Verification Steps:**
- CORS configuration displays correctly
- Requests from http://example.com are allowed

## Execution Guide

### Common Issues and Solutions

1. **Bucket not found**: Ensure you are using the correct bucket name. You can view all available buckets using `gsutil ls`.

2. **Permission error**: Ensure you have sufficient permissions to modify the bucket's CORS configuration. In Lab environments, this is usually already configured.

3. **JSON format error**: Ensure the `cors-config.json` file has correct JSON format. Check content using `cat cors-config.json`.

4. **Configuration not taking effect**: Wait a few minutes for the configuration to take effect, then check again.

### Tips and Tricks

- **Principle of least privilege**: This configuration only allows necessary origins (http://example.com) and methods (GET), following security best practices.
- **Preflight requests**: For some browsers, complex CORS requests will send preflight requests (OPTIONS) first. Ensure your configuration includes necessary headers.
- **Multiple origins support**: If you need to support multiple origins, you can add more URLs to the `origin` array.

### Cleanup Steps

After completing the Lab, if you need to clean up resources:

1. Remove CORS configuration (if needed):
   ```
   gsutil cors set '[]' $BUCKET_NAME
   ```

2. Delete temporary configuration file:
   ```
   rm cors-config.json
   ```

## Additional Resources

- [Cloud Storage CORS Official Documentation](https://cloud.google.com/storage/docs/configuring-cors)
- [Cross-Origin Resource Sharing (CORS) Concepts](https://developer.mozilla.org/zh-TW/docs/Web/HTTP/CORS)
- [gsutil cors Command Reference](https://cloud.google.com/storage/docs/gsutil/commands/cors)

## Technical Notes

- CORS is part of browser security mechanisms to prevent malicious websites from accessing resources from other origins
- Cloud Storage CORS configuration is managed through `gsutil cors` commands
- Principle of least privilege in this context means allowing only necessary origins and HTTP methods
- Preflight requests are used to check the security of complex CORS requests
- `maxAgeSeconds` parameter controls how long browsers cache preflight request results