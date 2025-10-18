# New York Taxi Dataset Documentation

## Description
The New York Taxi dataset is a publicly available dataset in Google Cloud BigQuery that contains taxi trip records from New York City. This dataset is commonly used for data analysis, machine learning, and educational purposes.

## URL

## Category
documentation

## Target Audience
- Beginner to Advanced data analysts
- Data scientists working with transportation data
- Students learning BigQuery and data analysis

## Prerequisites
- Google Cloud Platform account
- Basic understanding of SQL/BigQuery
- Familiarity with taxi/transportation data concepts

## Related Labs
- ARC103: Analyze BigQuery Data in Connected Sheets: Challenge Lab

## Dataset Details

### Available Tables
The dataset includes several tables with taxi trip data:

- **tlc_yellow_trips_2022**: Yellow taxi trip records for 2022
- **tlc_green_trips_2022**: Green taxi (for-hire vehicle) trip records for 2022
- **tlc_for_hire_vehicles**: For-hire vehicle records

### Key Columns in tlc_yellow_trips_2022
- `pickup_datetime`: When the trip started
- `dropoff_datetime`: When the trip ended
- `trip_distance`: Distance of the trip in miles
- `fare_amount`: Base fare amount
- `tip_amount`: Tip amount
- `toll_amount`: Toll fees paid during the trip
- `total_amount`: Total amount charged
- `payment_type`: Payment method (1=Credit Card, 2=Cash, etc.)
- `pickup_location_id`: Taxi zone where trip started
- `dropoff_location_id`: Taxi zone where trip ended

## Common Use Cases
- Analyzing taxi demand patterns
- Understanding payment preferences
- Studying traffic patterns in NYC
- Machine learning model training for trip duration prediction
- Geographic analysis of pickup/dropoff locations

## Data Size and Update Frequency
- Contains millions of records per year
- Updated periodically as new data becomes available
- Each table contains comprehensive trip details

## Notes
- This is a public dataset that can be accessed without additional costs (standard BigQuery query charges apply)
- Perfect for learning BigQuery features like Connected Sheets integration
- Contains real-world data that demonstrates practical data analysis scenarios
- Commonly used in Google Cloud training and certification labs
