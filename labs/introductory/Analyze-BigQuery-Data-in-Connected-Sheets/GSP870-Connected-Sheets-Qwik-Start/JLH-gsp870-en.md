# Connected Sheets: Qwik Start

## Lab Title
Connected Sheets Qwik Start: Connecting BigQuery Data Warehouse to Google Sheets

## Prerequisites
- Standard internet browser (Chrome recommended)
- Access to a Google Cloud account
- Basic knowledge of Google Sheets

## Objectives
By the end of this lab, you will be able to:
- Connect a BigQuery dataset to Google Sheets
- Use formulas to find the percentage of taxi trips that included a tip
- Use charts to inspect popularity and trends of payment types
- Use pivot tables to find out when taxi rides are the most expensive
- Use extracts to import raw data from BigQuery to Connected Sheets
- Use calculated columns to create a new column from transformations/combinations of existing columns
- Use scheduled refresh to set up automatic data refreshes for your analyses

## Estimated Time
60 minutes

## Lab Steps

### Step 1: Open Google Sheets
Start the lab and open Google Sheets.

**Instructions:**
1. Click the **Start Lab** button. On the left is a panel populated with the temporary credentials that you must use for this lab.
2. In a new incognito window, open the [Google Sheets home page](https://docs.google.com/spreadsheets/)
3. In the Google **Sign in** page, paste the username from the **Connection Details** panel, then copy and paste the password
4. If you see the **Choose an account** page, click **Use another account**
5. Click through the subsequent pages:
   - Accept the terms and conditions
   - Do not add recovery options or two-factor authentication (because this is a temporary account)
   - Do not sign up for free trials
6. In your **Google Sheets** tab, click on the **Blank Spreadsheet** button under **Start a New Spreadsheet** to create a new sheet

**Expected Result:**
You will see a blank Google Sheets spreadsheet, ready to connect to a BigQuery dataset.

### Step 2: Connect to a BigQuery Dataset
Connect the public Chicago taxi trips dataset to Google Sheets.

**Instructions:**
1. Select **Data** > **Data Connectors** > **Connect to BigQuery**
2. If you see a **Connect and Analyze big data in Sheets** pop-up, click **Get Connected**
3. Select **YOUR PROJECT ID** > **Public datasets** > **chicago_taxi_trips**
4. Select **taxi_trips** and click **Connect**
5. Wait about a minute until you see a success message

**Expected Result:**
You have successfully connected a BigQuery dataset to Google Sheets!

### Step 3: Formulas
Learn how to use formulas with Connected Sheets. First, find out how many taxi companies there are in Chicago.

**Instructions:**
1. Select **Function** > **COUNTUNIQUE** and add it to a new sheet
2. Ensure **New Sheet** is selected and click **Create**
3. Modify the value of your cell at **row 1**, **column A** to:
   ```
   =COUNTUNIQUE(taxi_trips!company)
   ```
4. Click **Apply**

Next, find the percentage of taxi rides in Chicago that included a tip:

5. Using the `COUNTIF` function, find the total number of trips that included a tip. Copy and paste this function into the cell at **row1**, **column D**:
   ```
   =COUNTIF(taxi_trips!tips,">0")
   ```
6. Click **Apply**
7. Now, use the `COUNTIF` function to find the total number of trips where the fare was greater than 0. Add this function into the cell at **row1**, **column E**:
   ```
   =COUNTIF(taxi_trips!fare,">0")
   ```
8. Click **Apply**
9. Finally, compare the values from the previous two steps. Add this function into the cell at **row1**, **column F**:
   ```
   =D1/E1
   ```

**Expected Result:**
Around 38.6% of taxi trips in Chicago included a tip (your results may vary depending on the date the data is accessed).

### Step 4: Charts
What forms of payments are people using for their taxi rides? How has revenue from mobile payments changed over time?

**Instructions:**
1. Return to the **taxi_trips** tab by clicking on it at the bottom of your **Google Sheets** page
2. Click on the **Chart** button. Ensure **New Sheet** is selected and click **Create**
3. In the Chart editor window, under Chart type, select **Pie chart**
4. Various columns of the data are listed to the right. Drag **payment_type** to the **Label** field. Then drag **fare** into the **Value** field and click **Apply**
5. The value of **Cash** payments slightly edges out the value of **Credit Card** payments
6. Under **Value** > **Fare**, change Sum to **Count**. Click **Apply**
7. Now, the **Cash** transactions significantly outnumber **Credit Card** transactions

Next, find out how mobile payments have changed over time:

8. Return to the **taxi_trips** tab by selecting it at the bottom of your **Google Sheets** page
9. Select the **Chart** button. Ensure **New Sheet** is selected and click **Create**
10. Click on the **Chart Type** dropdown and select the first option under **Line**
11. Drag **trip_start_timestamp** to the **X-axis** field
12. Check the **Group by** option and select **Year-Month** from the dropdown list
13. Drag **fare** into the **Series** field
14. Click **Apply**
15. Under **Filter** click **Add > payment_type**
16. Select the **Showing all items** status dropdown
17. Click on the **Filter by Condition** dropdown and select **Text contains** from the list
18. Input **mobile** in the **Value** field
19. Click **OK**
20. Click **Apply** to generate a new line chart

**Expected Result:**
You should see that mobile payments have been on a general upward trend.

### Step 5: Pivot Tables
At which time of day are there the highest amount of taxi rides? Analyze this using pivot tables.

**Instructions:**
1. Return to the **taxi_trips** tab by selecting it at the bottom of your **Google Sheets** page
2. Click on the **Pivot table** button
3. Ensure **New sheet** is selected and click **Create**
4. Drag **trip_start_timestamp** into the **Rows** field
5. Choose **Hour** for the Group By option
6. Drag **fare** into the **Values** field
7. Select **COUNTA** for the **Summarize by** option
8. Click **Apply**

Next, break it down by day of the week:

9. Drag **trip_start_timestamp** to the **Columns** field
10. Select **Day of the week** under the **Group by** option
11. Click **Apply**
12. Select the data range B3:H26 and select **Format** > **Number** > **Number**
13. Click on the decrease decimal place button twice to make the data easier to read

Apply conditional formatting:

14. Select all your data cells by clicking on the top left cell (first value for Sunday) and then shift + clicking on the bottom right cell (last value for Saturday)
15. With all your cells selected, click **Format** > **Conditional formatting**
16. Select **Color scale**
17. Select the colors under **Preview** and choose **White to Green**
18. Click **Done**
19. Close the **Conditional Formatting** window by clicking the **x**

Find the most expensive times:

20. In the **Values** field, change the **Summarize by** option to **Average**
21. Click **Apply**

**Expected Result:**
Monday early morning taxi fares are the most expensive!

### Step 6: Using Extract
Import a subset of data from BigQuery into Connected Sheets.

**Instructions:**
1. Return to the **taxi_trips** tab by selecting it at the bottom of your **Google Sheets** page
2. Click on the **Extract** button
3. Ensure **New sheet** is selected and click **Create**
4. In the **Extract editor** window, click **Edit** under the Columns section and select the columns **trip_start_timestamp**, **fare**, **tips**, and **tolls**
5. Click **Add** under the **Sort** section and select **trip_start_timestamp**. Click on **Desc** to toggle between ascending and descending order
6. Under **Row limit**, leave 25000 as it is to import 25000 rows
7. Click **Apply**

**Expected Result:**
You have just extracted thousands of rows of raw data from BigQuery into Connected Sheets!

### Step 7: Calculated Columns
Create a calculated column to calculate tip percentage.

**Instructions:**
1. Return to the **taxi_trips** tab by selecting it at the bottom of your **Google Sheets** page
2. Click on the **Calculated columns** button
3. Enter `tip_percentage` into the **Calculated column name** field
4. Then copy and paste the following formula into the formula field:
   ```
   =IF(fare>0,tips/fare*100,0)
   ```
5. Click **Add**
6. Click **Apply**

**Expected Result:**
You can now see the percentage of the fare that was tipped under the **tip_percentage** column.

### Step 8: Refresh All / Scheduled Refresh
Learn how to update your analyses or schedule automatic updates.

**Instructions:**
1. To update a chart or table, select it then click the **Refresh** button
2. You can also click the **Refresh options** button, located beside the name of your dataset, followed by **Refresh all** to update all Connected Sheets analyzes to the latest data
3. To schedule a refresh, click on **Schedule refresh** near the bottom of the Refresh options sidebar
4. Finally, choose your desired frequency and time for the automatic data refreshes
5. Click **Save**

## Verification
Click *Check my progress* buttons in each task to verify objectives are met.

## Troubleshooting
Common issues and their solutions:
- **Connection to BigQuery fails**: Ensure you're using the correct project ID and public dataset path
- **Formulas show errors**: Double-check syntax and field name spelling
- **Charts fail to load**: Check internet connection and try refreshing the page
- **Data extraction times out**: Reduce row count or simplify query conditions

## Cleanup
After the lab:
1. Close all open Google Sheets documents
2. Sign out of the Google account (especially if using a shared computer)
3. The lab environment will automatically clean up temporary resources

## Additional Resources
- [Connected Sheets Official Documentation](https://cloud.google.com/bigquery/docs/connected-sheets)
- [Google Sheets Functions Reference](https://support.google.com/docs/table/25273)
- [BigQuery Public Datasets](https://cloud.google.com/bigquery/public-data)

## Notes
This lab demonstrates how to combine the power of BigQuery's data analytics with the familiar interface of Google Sheets, making it easy for non-data analysts to work with massive datasets.
