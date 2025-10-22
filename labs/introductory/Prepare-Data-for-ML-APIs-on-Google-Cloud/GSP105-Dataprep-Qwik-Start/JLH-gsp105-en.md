# GSP105-Dataprep: Qwik Start

## Lab Title
Dataprep: Qwik Start

## Prerequisites
- Basic knowledge of GCP

## Objectives
By the end of this lab, you will be able to:
- Import data
- Correct mismatched data
- Transform data
- Join data

## Estimated Time
Approximately 60 minutes

## Lab Steps

### Step 1: Create a Cloud Storage bucket in your project
This step guides you through creating a Cloud Storage bucket.

**Instructions:**
1. In the Cloud Console, select **Navigation menu** > **Cloud Storage** > **Buckets**.
2. Click **Create bucket**.
3. In the **Create a bucket** dialog, **Name** the bucket a unique name. Leave other settings at their default value.
4. Uncheck **Enforce public access prevention on this bucket** for `Choose how to control access to objects`.
5. Click **Create**.

**Expected Result:**
You have successfully created your bucket.

### Step 2: Initialize Cloud Dataprep
This step will initialize the Cloud Dataprep service.

**Instructions:**
1. Open **Cloud Shell** and run the following command:
```bash
gcloud beta services identity create --service=dataprep.googleapis.com
```
2. In the Cloud console, go to the **Navigation menu**, click **View All Products** and under **Analytics** select **Alteryx Designer Cloud**.
3. Check to accept the Google Dataprep Terms of Service, then click **Accept**.
4. Check to authorize sharing your account information with Trifacta, then click **Agree and Continue**.
5. Click **Allow** to allow Trifacta to access project data.
6. Click your student username to sign in to Cloud Dataprep by Trifacta. Your username is the **Username** in the left panel in your lab.
7. Click **Allow** to grant Cloud Dataprep access to your Google Cloud lab account.
8. Check to agree to Trifacta Terms of Service, and then click **Accept**.
9. Click **Continue** on the **First time setup** screen to create the default storage location.

**Expected Result:**
Dataprep service is successfully initialized and opened.

### Step 3: Create a flow
This step will guide you to create a new data flow in Dataprep.

**Instructions:**
1. Click **Flows** icon, then the **Create** button, then select **Blank Flow**.
2. Click on **Untitled Flow**, then name and describe the flow. Since this lab uses 2016 data from the [United States Federal Elections Commission 2016](https://www.fec.gov/data/browse-data/?tab=bulk-data), name the flow "FEC-2016", and then describe the flow as "United States Federal Elections Commission 2016".
3. Click **OK**.

**Expected Result:**
The FEC-2016 flow page opens.

### Step 4: Import datasets
In this section you import and add data to the FEC-2016 flow.

**Instructions:**
1. Click **Add Datasets**, then select the **Import Datasets** link.
2. In the left menu pane, select **Cloud Storage** to import datasets from Cloud Storage, then click on the pencil to edit the file path.
3. Type `gs://spls/gsp105` in the **Choose a file or folder** text box, then click **Go**.
4. Click **us-fec/**.
5. Click the **+** icon next to `cn-2016.txt` to create a dataset shown in the right pane. Click on the title in the dataset in the right pane and rename it "Candidate Master 2016".
6. In the same way add the `itcont-2016-orig.txt` dataset, and rename it "Campaign Contributions 2016".
7. Both datasets are listed in the right pane; click **Import & Add to Flow**.

**Expected Result:**
Both datasets are listed as a flow.

### Step 5: Prep the candidate file
This step will prepare the candidate master file for data processing.

**Instructions:**
1. By default, the Candidate Master 2016 dataset is selected. In the right pane, click **Edit Recipe**.
2. In the grid view, click to select the tallest bin in Column5's histogram, which represents the year 2016. This creates a step where these values are selected.
3. In the **Suggestions** panel on the right, in the **Keep rows** section, click **Add** to add this step to your recipe.
4. In Column6 (State), hover over and click on the mismatched (red) portion of the header to select the mismatched rows.
5. Click **X** in the top of the Suggestions panel to cancel the transformation, then click on the flag icon in Column6 and change it to a "String" column.
6. In the histogram for Column7, click the "P" bin to filter on just the presidential candidates.
7. In the right Suggestions panel, click **Add** to accept the step to the recipe.

**Expected Result:**
Candidate file has been prepped according to the recipe.

### Step 6: Wrangle the Contributions file and join it to the Candidates file
This step will wrangle the contributions file and join it with the candidates file.

**Instructions:**
1. Click on **FEC-2016** (the dataset selector) at the top of the grid view page.
2. Click to select the grayed out **Campaign Contributions 2016**.
3. In the right pane, click **Add** > **Recipe**, then click **Edit Recipe**.
4. Click the **recipe** icon at the top right of the page, then click **Add New Step**.
5. Insert the following Wrangle language command in the Search box:
```
replacepatterns col: * with: '' on: `{start}"|"{end}` global: true
```
6. Click **Add** to add the transform to the recipe.
7. Add another new step to the recipe. Click **New Step**, then type "Join" in the Search box.
8. Click **Join datasets** to open the Joins page.
9. Click on "Candidate Master 2016" to join with Campaign Contributions 2016, then **Accept** in the bottom right.
10. On the right side, hover in the **Join keys** section, then click on the pencil (Edit icon).
11. In the **Add Key** panel, in the **Suggested join keys** section, click **column2 = column11**.
12. Click **Save and Continue**.
13. Click **Next**, then check the checkbox to the left of the "Column" label to add all columns of both datasets to the joined dataset.
14. Click **Review**, and then **Add to Recipe** to return to the grid view.

**Expected Result:**
Contributions file has been wrangled and successfully joined to the Candidates file.

### Step 7: Summary of data
This step will generate a useful summary by aggregating, averaging, and counting contributions, grouped by candidate ID, name, and party affiliation.

**Instructions:**
1. At the top of the **Recipe** panel on the right, click on **New Step** and enter the following formula in the **Transformation** search box to preview the aggregated data:
```
pivot value:sum(column16),average(column16),countif(column16 > 0) group: column2,column24,column8
```
2. Click **Add** to open a summary table of major US presidential candidates and their 2016 campaign contribution metrics.

**Expected Result:**
A summary table of presidential candidates and their campaign contributions is generated.

### Step 8: Rename columns
This step will rename columns to make the data easier to interpret.

**Instructions:**
1. Add each of the renaming and rounding steps individually to the recipe by clicking **New Step**, then enter:
```
rename type: manual mapping: [column24,'Candidate_Name'], [column2,'Candidate_ID'],[column8,'Party_Affiliation'], [sum_column16,'Total_Contribution_Sum'], [average_column16,'Average_Contribution_Sum'], [countif,'Number_of_Contributions']
```
2. Then click **Add**.
3. Add in this last **New Step** to round the Average Contribution amount:
```
set col: Average_Contribution_Sum value: round(Average_Contribution_Sum)
```
4. Then click **Add**.

**Expected Result:**
Columns are successfully renamed and formatted.

## Verification
Verify the final summary table displayed in Dataprep to confirm that the data has been correctly transformed and columns renamed.

## Troubleshooting
- **Service Account Permissions Issues**: Ensure the Dataprep service account has permissions to access the Cloud Storage bucket.
- **Dataset Import Failure**: Check if the `gs://spls/gsp105` path is correct and if the files exist.
- **Wrangle Command Errors**: Carefully review the syntax of the Wrangle language commands.

## Cleanup
Since Cloud Dataprep is a serverless service, no manual cleanup is required. All resources will be automatically released after the lab concludes.

## Additional Resources
- [Dataprep by Alteryx Designer Cloud (Trifacta)](https://www.alteryx.com/products/designer-cloud)
- [Bucket naming guidelines](https://cloud.google.com/storage/docs/naming-buckets)
- [United States Federal Elections Commission 2016](https://www.fec.gov/data/browse-data/?tab=bulk-data)
- [GCP Command Fixes Guide](../../docs/gcp-command-fixes.md)

## Notes
This lab demonstrates the powerful capabilities of Dataprep for data cleaning, transformation, and joining.
