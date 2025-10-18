# ARC103 - Analyze BigQuery Data in Connected Sheets: Challenge Lab - Step-by-Step Guide

## Lab Overview
This is a practical step-by-step guide for the ARC103 Challenge Lab, created based on the content from GSP072, GSP469, and GSP870 labs. This guide will walk you through completing all 5 tasks.

## Prerequisites
- Google Cloud account with lab credentials
- Internet connection and Chrome browser
- Basic Google Sheets operation knowledge

## Estimated Time
60-90 minutes

---

## Task 1: Open Google Sheets and Connect to BigQuery Dataset

### Step Details
1. **Open Google Sheets**
   - Click the lab's **Start Lab** button to get temporary credentials
   - Open [Google Sheets homepage](https://docs.google.com/spreadsheets/) in a new incognito window
   - Sign in using the lab-provided credentials

2. **Create a new spreadsheet**
   - Click **Blank Spreadsheet** button on the Google Sheets homepage
   - Create a blank spreadsheet and wait for it to load completely

3. **Connect to BigQuery dataset**
   - In the spreadsheet, select **Data** > **Data Connectors** > **Connect to BigQuery**
   - Click **Get Connected** in the pop-up window
   - Navigate to: **YOUR PROJECT ID** > **Public datasets** > **new_york_taxi_trips**
   - Select **tlc_yellow_trips_2022** and click **Connect**
   - Wait about one minute until you see the success message

### Verification Steps
- Confirm successful connection to `new_york_taxi_trips.tlc_yellow_trips_2022` dataset
- Should be able to see data preview
- Click **Check my progress** to verify Task 1

---

## Task 2: Use Formula to Count Trips with Airport Fees

### Step Details
1. **Create new sheet for calculations**
   - Click the **+** button at the bottom of the spreadsheet to create a new sheet
   - Rename the sheet to **"Airport Fee Analysis"**

2. **Use COUNTIF formula to count trips with airport fees**
   ```
   =COUNTIF(tlc_yellow_trips_2022!airport_fee, ">0")
   ```

3. **Verify formula results**
   - Formula should return the total number of trips with airport fees
   - Confirm result is positive and reasonable

### Verification Steps
- Confirm formula calculates correctly and returns expected trip count
- Click **Check my progress** to verify Task 2

---

## Task 3: Create Pie Chart to Show Payment Type Distribution

### Step Details
1. **Return to original data sheet**
   - Switch back to the `tlc_yellow_trips_2022` sheet

2. **Create pie chart**
   - Click the **Chart** button in the spreadsheet
   - Select **New Sheet** and click **Create**
   - In Chart editor, select **Pie chart** as the chart type

3. **Set up chart data**
   - Drag the `payment_type` field to the **Label** field
   - Drag any numeric field (such as `fare_amount`) to the **Value** field
   - In **Value** settings, change the aggregation function to **Count**

4. **Apply chart settings**
   - Click **Apply** to generate the pie chart

### Verification Steps
- Confirm pie chart correctly shows distribution of different payment types
- Chart should show proportions of credit card, cash, and other payment methods
- Click **Check my progress** to verify Task 3

---

## Task 4: Extract Data from BigQuery to Connected Sheets

### Step Details
1. **Open data extraction tool**
   - Return to the `tlc_yellow_trips_2022` sheet
   - Click the **Extract** button in the spreadsheet
   - Select **New sheet** and click **Create**

2. **Set extraction parameters**
   - In the Extract editor, click **Edit** in the Columns section
   - Select the following fields:
     - `pickup_datetime`
     - `dropoff_datetime`
     - `trip_distance`
     - `fare_amount`

3. **Set sorting options**
   - In the **Sort** section, click **Add**
   - Select the `trip_distance` field
   - Choose **Desc** (descending order)

4. **Set row limit**
   - Set **Row limit** to **10000** (extract 10,000 rows)

5. **Execute data extraction**
   - Click **Apply** to start data extraction

### Verification Steps
- Confirm successful extraction of 10,000 rows of data
- Verify data is sorted by trip distance in descending order
- Confirm all specified fields are included
- Click **Check my progress** to verify Task 4

---

## Task 5: Calculate Toll Fee Percentage of Fare Amount

### Step Details
1. **Open calculated columns tool**
   - Return to the `tlc_yellow_trips_2022` sheet
   - Click the **Calculated columns** button in the spreadsheet

2. **Create calculated column**
   - In the **Calculated column name** field, enter `toll_percentage`
   - Enter the following formula:
     ```
     =IF(fare_amount>0, tolls_amount/fare_amount*100, 0)
     ```

3. **Apply calculated column**
   - Click **Add** to add the calculated column
   - Click **Apply** to apply the calculation

### Verification Steps
- Confirm the new `toll_percentage` column calculates correctly
- Verify percentage calculation logic is correct
- Confirm results are displayed in percentage format
- Click **Check my progress** to verify Task 5

---

## Troubleshooting Guide

### Common Issues and Solutions

**Problem: Unable to connect to BigQuery dataset**
- Confirm you're signed in with correct lab credentials
- Check internet connection
- Confirm selecting correct public dataset path: `new_york_taxi_trips.tlc_yellow_trips_2022`

**Problem: Formula shows error**
- Confirm field name spelling is correct (case-sensitive)
- Check formula syntax is correct
- Confirm data types match

**Problem: Chart fails to load**
- Check internet connection
- Try refreshing the page
- Confirm correct data fields are selected

**Problem: Data extraction fails**
- Confirm query syntax is correct
- Check if Row limit is set reasonably
- Confirm field names are correct

**Problem: Calculated column shows error**
- Confirm formula logic is correct
- Check handling of division by zero cases
- Confirm field names match the dataset

---

## Cleanup Steps

After lab completion:
1. Close all open Google Sheets documents
2. Sign out of the lab account (especially if using a shared computer)
3. The lab environment will automatically clean up temporary resources

---

## Additional Resources

- [BigQuery Official Documentation](https://cloud.google.com/bigquery/docs)
- [Connected Sheets Guide](https://cloud.google.com/bigquery/docs/connected-sheets)
- [Google Sheets Functions Reference](https://support.google.com/docs/table/25273)
- [New York Taxi Dataset Documentation](https://cloud.google.com/bigquery/public-data/new-york-taxi)

---

## Technical Notes

- This lab uses publicly available New York taxi trip data (2022)
- Connected Sheets allows direct querying and analysis of BigQuery data within Google Sheets
- All operations are performed within the Google Sheets interface, no command line operations required
- Lab completion time is approximately 60-90 minutes

**Good luck with the lab!** 🎉
