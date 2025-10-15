#!/bin/bash

# BigQuery: Qwik Start - Console - Automation Script
# GSP072
# This script automates the BigQuery lab steps

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command succeeded
check_command() {
    if [ $? -eq 0 ]; then
        print_success "$1 completed successfully"
    else
        print_error "$1 failed"
        exit 1
    fi
}

print_status "Starting BigQuery: Qwik Start - Console Lab Automation"
echo "=================================================="

# Check if gcloud is installed and authenticated
print_status "Checking gcloud authentication..."
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed. Please install Google Cloud SDK first."
    exit 1
fi

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    print_error "Not authenticated with gcloud. Please run 'gcloud auth login' first."
    exit 1
fi
print_success "gcloud authentication verified"

# Set default project (prompt user if not set)
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    print_warning "No default project set"
    read -p "Enter your GCP Project ID: " PROJECT_ID
    gcloud config set project $PROJECT_ID
    check_command "Project configuration"
fi
print_status "Using project: $PROJECT_ID"

# Task 1: Open BigQuery (Manual step - just verify BigQuery API is enabled)
print_status "Task 1: Verifying BigQuery API is enabled..."
if ! gcloud services list --enabled | grep -q bigquery-json.googleapis.com; then
    print_status "Enabling BigQuery API..."
    gcloud services enable bigquery-json.googleapis.com
    check_command "BigQuery API enablement"
else
    print_success "BigQuery API is already enabled"
fi

# Task 2: Query a public dataset (Manual step - provide instructions)
print_status "Task 2: Query public dataset"
echo "Please perform the following steps manually in the Google Cloud Console:"
echo "1. Navigate to BigQuery in the Console"
echo "2. Click '+' (SQL query) to create a new query"
echo "3. Run this query:"
echo ""
echo "#standardSQL"
echo "SELECT"
echo " weight_pounds, state, year, gestation_weeks"
echo "FROM"
echo " \`bigquery-public-data.samples.natality\`"
echo "ORDER BY weight_pounds DESC LIMIT 10;"
echo ""
read -p "Press Enter after completing Task 2..."

# Task 3: Create a new dataset
print_status "Task 3: Creating babynames dataset..."
bq mk babynames
check_command "Dataset creation"

# Task 4: Load data into a new table
print_status "Task 4: Creating names_2014 table and loading data..."
bq load \
  --source_format=CSV \
  --schema="name:string,gender:string,count:integer" \
  babynames.names_2014 \
  gs://spls/gsp072/baby-names/yob2014.txt
check_command "Table creation and data loading"

# Task 5: Preview the table (Manual step - provide instructions)
print_status "Task 5: Preview table"
echo "Please perform the following steps manually in the Google Cloud Console:"
echo "1. In BigQuery Explorer, click on 'babynames' dataset"
echo "2. Click on 'names_2014' table"
echo "3. Click the 'Preview' tab to view the data"
echo ""
read -p "Press Enter after completing Task 5..."

# Task 6: Query custom dataset (Manual step - provide instructions)
print_status "Task 6: Query custom dataset"
echo "Please perform the following steps manually in the Google Cloud Console:"
echo "1. Click '+' (SQL query) to create a new query"
echo "2. Run this query:"
echo ""
echo "#standardSQL"
echo "SELECT"
echo " name, count"
echo "FROM"
echo " \`babynames.names_2014\`"
echo "WHERE"
echo " gender = 'M'"
echo "ORDER BY count DESC LIMIT 5;"
echo ""
read -p "Press Enter after completing Task 6..."

# Task 7: Test understanding (Manual step)
print_status "Task 7: Test your understanding"
echo ""
echo "BigQuery is a fully-managed enterprise data warehouse that enables super-fast SQL queries."
echo ""
read -p "Is this statement True or False? (Type 'True' or 'False'): " answer
if [ "$answer" = "True" ] || [ "$answer" = "true" ] || [ "$answer" = "TRUE" ]; then
    print_success "Correct! The statement is True."
else
    print_warning "The correct answer is True. BigQuery is indeed a fully-managed enterprise data warehouse."
fi

echo ""
print_success "Lab automation completed!"
echo "=================================================="
print_status "Lab Summary:"
echo "- Created dataset: babynames"
echo "- Created table: names_2014 with baby names data"
echo "- Demonstrated public dataset querying"
echo "- Demonstrated custom dataset querying"
echo ""
print_status "Don't forget to clean up resources when you're done:"
echo "1. In BigQuery Console, delete the 'babynames' dataset"
echo "2. This will remove all tables and prevent any charges"

# Optional: Ask if user wants to cleanup now
read -p "Would you like to cleanup the dataset now? (y/N): " cleanup
if [ "$cleanup" = "y" ] || [ "$cleanup" = "Y" ]; then
    print_status "Cleaning up resources..."
    bq rm -r babynames
    check_command "Resource cleanup"
fi

print_success "BigQuery Qwik Start lab automation completed successfully!"
