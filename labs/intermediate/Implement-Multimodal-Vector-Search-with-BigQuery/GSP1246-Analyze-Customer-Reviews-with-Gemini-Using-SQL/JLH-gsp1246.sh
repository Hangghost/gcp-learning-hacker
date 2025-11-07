#!/bin/bash

# GSP1246 - Analyze Customer Reviews with Gemini Using SQL
# https://www.skills.google/paths/1803/course_templates/1232/labs/598655

# This script provides guidance for completing the lab
# Most steps require manual interaction with BigQuery Studio and Gemini

set -e

echo "=== GSP1246 - Analyze Customer Reviews with Gemini Using SQL ==="
echo "This lab focuses on BigQuery ML with Gemini for customer review analysis"
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

# Check Vertex AI access
check_vertex_ai() {
    print_status "Checking Vertex AI access..."

    if ! gcloud services list --enabled | grep -q aiplatform.googleapis.com; then
        print_error "Vertex AI API is not enabled. Please enable it in the console."
        exit 1
    fi

    print_status "Vertex AI API is enabled"
}

# Main lab guidance
main() {
    print_status "Starting GSP1246 lab guidance..."

    check_gcloud
    check_auth
    get_project
    check_bigquery
    check_vertex_ai

    echo ""
    print_step "LAB INSTRUCTIONS - MANUAL STEPS REQUIRED"
    echo "=================================================="
    echo ""
    echo "This lab requires extensive manual interaction with BigQuery Studio and Gemini."
    echo "Many queries take time to process (up to 3 minutes for image analysis)."
    echo ""

    echo "TASK 1: Create cloud resource connection and grant IAM roles"
    echo "-----------------------------------------------------------"
    echo "1. Go to BigQuery in the Cloud Console"
    echo "2. Click DONE on the welcome dialog"
    echo "3. Click + Add data > Search for 'Vertex AI'"
    echo "4. Select Vertex AI > BigQuery Federation"
    echo "5. Choose 'Vertex AI remote models, remote functions and BigLake (Cloud Resource)'"
    echo "6. Connection ID: gemini_conn"
    echo "7. Location: Multi-region > US"
    echo "8. Click Create connection"
    echo "9. Copy the service account ID from connection info"
    echo ""
    echo "10. Go to IAM & Admin > Grant Access"
    echo "11. Add service account as principal"
    echo "12. Grant 'Vertex AI User' role"
    echo ""

    echo "TASK 2: Review data and grant storage permissions"
    echo "--------------------------------------------------"
    echo "1. Go to Cloud Storage > Buckets"
    echo "2. Select your project bucket (ends with -bucket)"
    echo "3. Open gsp1246 folder"
    echo "4. Review images/ folder and customer_reviews.csv"
    echo ""
    echo "5. Go back to bucket root > Permissions > Grant access"
    echo "6. Add service account as principal"
    echo "7. Grant 'Storage Object Admin' role"
    echo ""

    echo "TASK 3: Create dataset and tables"
    echo "----------------------------------"
    echo "1. Back in BigQuery > + Create dataset"
    echo "2. Dataset ID: gemini_demo"
    echo "3. Location: Multi-region > US"
    echo ""
    echo "4. + Create SQL Query - Load customer reviews:"
    echo "   (See lab documentation for the full LOAD DATA query)"
    echo "5. Run the query to create customer_reviews table"
    echo ""
    echo "6. + Create SQL Query - Create object table:"
    echo "   (See lab documentation for the full CREATE EXTERNAL TABLE query)"
    echo "7. Run the query to create review_images table"
    echo ""

    echo "TASK 4: Create Gemini model"
    echo "-----------------------------"
    echo "1. + Create SQL Query:"
    echo "   CREATE OR REPLACE MODEL \`gemini_demo.gemini_flash\`"
    echo "   REMOTE WITH CONNECTION \`us.gemini_conn\`"
    echo "   OPTIONS (endpoint = 'model_id | disablehighlight')"
    echo "2. Run the query"
    echo ""

    echo "TASK 5: Analyze customer reviews"
    echo "----------------------------------"
    echo "1. Keywords analysis query (see documentation)"
    echo "   - Wait ~30 seconds for processing"
    echo "   - Query results: SELECT * FROM \`gemini_demo.customer_reviews_keywords\`"
    echo ""
    echo "2. Sentiment analysis query (see documentation)"
    echo "   - Wait ~20 seconds for processing"
    echo "   - Create cleaned_data_view (see documentation)"
    echo "   - Generate sentiment count reports"
    echo "   - Create bar chart with CHART button"
    echo ""

    echo "TASK 6: Respond to customer reviews"
    echo "-------------------------------------"
    echo "1. Marketing response for customer 5576 (see documentation)"
    echo "   - Format results into marketing column"
    echo ""
    echo "2. Customer service response for customer 8844 (see documentation)"
    echo "   - Format results into Response and Actions columns"
    echo ""

    echo "TASK 7: Analyze review images"
    echo "------------------------------"
    echo "1. Image analysis query (see documentation)"
    echo "   - This takes ~3 minutes to process!"
    echo "   - Query results: SELECT * FROM \`gemini_demo.review_images_results\`"
    echo "2. Format results to separate summary and keywords columns"
    echo ""

    print_status "Lab guidance completed!"
    print_warning "Remember: This lab requires extensive manual BigQuery operations"
    print_warning "Many queries have processing times - be patient!"
    print_warning "Complete all tasks in the console and check your progress"
}

# Run main function
main "$@"
