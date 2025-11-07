#!/bin/bash

# GSP1258 - Develop Code with Gemini in BigQuery
# https://www.skills.google/paths/1803/course_templates/1232/labs/598654

# This script provides guidance for completing the lab
# Most steps require manual interaction with BigQuery Studio and Gemini

set -e

echo "=== GSP1258 - Develop Code with Gemini in BigQuery ==="
echo "This lab focuses on using Gemini AI features in BigQuery Studio"
echo "Most steps require manual interaction with the BigQuery console"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if gcloud is available
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        print_error "gcloud CLI is not installed. Please install it first."
        exit 1
    fi

    print_status "gcloud CLI found"
}

# Check if user is authenticated
check_auth() {
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 > /dev/null; then
        print_error "You are not authenticated with gcloud. Please run 'gcloud auth login' first."
        exit 1
    fi

    print_status "gcloud authentication verified"
}

# Get current project
get_project() {
    PROJECT_ID=$(gcloud config get-value project)
    if [ -z "$PROJECT_ID" ]; then
        print_error "No project set. Please run 'gcloud config set project PROJECT_ID' first."
        exit 1
    fi

    print_status "Current project: $PROJECT_ID"
}

# Check BigQuery access
check_bigquery() {
    print_status "Checking BigQuery access..."

    if ! gcloud services list --enabled | grep -q bigquery.googleapis.com; then
        print_error "BigQuery API is not enabled. Please enable it in the console."
        exit 1
    fi

    print_status "BigQuery API is enabled"
}

# Main lab guidance
main() {
    print_status "Starting GSP1258 lab guidance..."

    check_gcloud
    check_auth
    get_project
    check_bigquery

    echo ""
    print_step "LAB INSTRUCTIONS - MANUAL STEPS REQUIRED"
    echo "=================================================="
    echo ""
    echo "This lab requires manual interaction with BigQuery Studio."
    echo "Please follow these steps in the Google Cloud Console:"
    echo ""

    echo "TASK 1: Review menu and order_item tables"
    echo "------------------------------------------"
    echo "1. Go to BigQuery in the Cloud Console"
    echo "2. Click DONE on the welcome dialog"
    echo "3. Expand your project -> coffee_on_wheels dataset"
    echo "4. Click menu table and review schema"
    echo "   - Note which fields use FLOAT datatype"
    echo "5. Click order_item table and review schema"
    echo "   - Note which fields use INTEGER datatype"
    echo ""

    echo "TASK 2: Generate SQL query using natural language"
    echo "--------------------------------------------------"
    echo "1. Click + to create new SQL query tab"
    echo "2. Click the Gemini SQL generation button"
    echo "3. Enter prompt: 'Show the menu IDs and total revenue from the order_item table with the top three highest and top three lowest by total revenue.'"
    echo "4. Click Generate and Insert"
    echo "5. Select query and click Explain this query"
    echo "6. Click Start chatting and review explanation"
    echo "7. Click RUN to execute query"
    echo ""

    echo "TASK 3: Transform a query"
    echo "-------------------------"
    echo "1. Create new SQL query tab"
    echo "2. Use SQL generation tool with prompt:"
    echo "   'Join the menu table with the order item table, return the menu_id, the item_name, and show the top three highest items and bottom three lowest items by total_revenue.'"
    echo "3. Generate, Insert, and RUN"
    echo "4. Select query and use Transform tool with prompt:"
    echo "   'Format the total revenue column so that there are only two decimal places. Use the ROUND function to do so.'"
    echo "5. Generate, Insert, and RUN"
    echo ""

    echo "TASK 4: Code review, debugging, and suggestions"
    echo "------------------------------------------------"
    echo "1. Create new SQL query tab and paste the provided erroneous query:"
    echo "   (See the lab documentation for the full query)"
    echo "2. Click RUN to see the error"
    echo "3. Use Gemini chat to debug:"
    echo "   - Ask: 'Why am I getting this error?'"
    echo "   - Paste the query"
    echo "   - Ask for suggestions"
    echo "4. Apply fixes and test"
    echo "5. Request further refinement for decimal formatting"
    echo ""

    print_status "Lab guidance completed!"
    print_warning "Remember: Most steps require manual interaction with BigQuery Studio and Gemini"
    print_warning "Complete all tasks in the console and answer the reflection questions"
}

# Run main function
main "$@"
