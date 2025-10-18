# ARC103 - Analyze BigQuery Data in Connected Sheets: Challenge Lab

## Lab Overview
This is the **ARC103 - Analyze BigQuery Data in Connected Sheets: Challenge Lab**. This challenge lab tests your ability to analyze BigQuery data and use Connected Sheets in Google Cloud Platform.

## Prerequisites
- Basic understanding of Google Cloud Platform
- Familiarity with BigQuery concepts
- Experience with Google Sheets
- Access to Google Cloud project with BigQuery API enabled

## Learning Objectives
By the end of this lab, you will be able to:
- Connect BigQuery datasets to Google Sheets using Connected Sheets
- Use formulas to analyze BigQuery data in Sheets
- Create charts to visualize BigQuery data
- Extract and manipulate BigQuery data in Connected Sheets
- Transform existing column data to create new calculated columns

## Estimated Time
60-90 minutes

## Lab Scenario
You are a junior data analyst helping a newly formed development team with their initial work on a project analyzing taxi data in New York City. You need to assist the Taxi team with their analysis using Google Sheets.

## Task 1: Open Google Sheets and Connect to a BigQuery Dataset

### Instructions
1. Log in to Google Sheets using the provided lab credentials
2. Connect to the BigQuery public dataset: `new_york_taxi_trips.tlc_yellow_trips_2022`
3. Verify the connection is successful and you can see the data

### Expected Result
- Successfully connected to the BigQuery dataset
- Data preview visible in Google Sheets

## Task 2: Use a Formula to Count Rows That Meet Specific Criteria

### Instructions
1. Use a formula to count the number of taxi trips that include an airport fee
2. Verify the formula works correctly and returns the expected count

### Expected Result
- Formula correctly calculates the number of trips with airport fees
- Result displayed in the spreadsheet

## Task 3: Create Charts to Visualize BigQuery Data

### Instructions
1. Create a pie chart to identify which payment type is most frequently used to pay the fare amount
2. Use the following payment type code mapping:
   - 1: Credit Card
   - 2: Cash
   - 3: No charge
   - 4: Dispute
   - 5: Unknown
   - 6: Voided trip

### Expected Result
- Pie chart successfully created showing payment type distribution
- Chart accurately represents the data from the BigQuery dataset

## Task 4: Extract Data from BigQuery to Connected Sheets

### Instructions
1. Extract 10,000 rows of data from the following columns:
   - `pickup_datetime`
   - `dropoff_datetime`
   - `trip_distance`
   - `fare_amount`
2. Order the results by longest trip first

### Expected Result
- Successfully extracted 10,000 rows of data
- Data sorted by trip distance in descending order
- All specified columns included in the extraction

## Task 5: Calculate New Columns to Transform Existing Column Data

### Instructions
1. Calculate a new column that displays the percentage of each fare amount that was used to pay toll fees (based on the `toll_amount` column)
2. Verify the calculation is correct and shows the proper percentages

### Expected Result
- New column successfully added showing toll fee percentages
- Calculations are mathematically correct
- Percentages displayed in an understandable format

## Verification Steps

After completing each task, click "Check my progress" to verify the objective:

1. **Task 1 Verification**: Confirm BigQuery connection is successful
2. **Task 2 Verification**: Confirm formula correctly counts airport fee trips
3. **Task 3 Verification**: Confirm pie chart correctly shows payment type distribution
4. **Task 4 Verification**: Confirm successful extraction and sorting of 10,000 rows
5. **Task 5 Verification**: Confirm new column correctly calculates toll fee percentages

## Troubleshooting

### Common Issues and Solutions:
- **BigQuery Connection Failure**: Verify you're using the correct lab credentials and check your internet connection
- **Formula Calculation Errors**: Double-check formula syntax and ensure column names are correct
- **Chart Display Issues**: Verify data types are correct and check chart settings
- **Data Extraction Failure**: Confirm query syntax is correct and check quota limits

## Cleanup Instructions
```bash
# This lab doesn't require special cleanup steps
# Connected Sheets handles temporary data automatically
# Make sure to log out of all services after the lab ends
```

## Additional Resources
- [BigQuery Official Documentation](https://cloud.google.com/bigquery/docs)
- [Connected Sheets Guide](https://cloud.google.com/bigquery/docs/connected-sheets)
- [Google Sheets Functions Reference](https://support.google.com/docs/table/25273)
- [New York Taxi Dataset Documentation](https://cloud.google.com/bigquery/public-data/new-york-taxi)

## Technical Notes
- This lab uses publicly available New York taxi trip data
- Connected Sheets allows direct querying of BigQuery data within Google Sheets
- Lab completion time is approximately 60-90 minutes
- All operations are performed within the Google Sheets interface, no command line operations required
