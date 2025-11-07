#!/bin/bash

# GSP1289 - Create a RAG Application with BigQuery
# https://www.skills.google/paths/1803/course_templates/1232/labs/598656

# This script provides guidance for completing the lab
# Most steps require manual interaction with BigQuery Studio

set -e

echo "=== GSP1289 - Create a RAG Application with BigQuery ==="
echo "This lab focuses on implementing RAG pipeline to reduce AI hallucinations"
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
    print_status "Starting GSP1289 lab guidance..."

    check_gcloud
    check_auth
    get_project
    check_bigquery
    check_vertex_ai

    echo ""
    print_step "LAB INSTRUCTIONS - MANUAL STEPS REQUIRED"
    echo "=================================================="
    echo ""
    echo "This lab demonstrates RAG pipeline implementation in BigQuery."
    echo "Most steps require manual SQL execution in BigQuery Studio."
    echo ""

    echo "TASK 1: Create source connection and grant IAM permissions"
    echo "----------------------------------------------------------"
    echo "1. Go to BigQuery in the Cloud Console"
    echo "2. Click + Add > Connections to external data sources"
    echo "3. Choose 'Vertex AI remote models, remote functions BigLake and Spanner (Cloud Resource)'"
    echo "4. Connection ID: embedding_conn"
    echo "5. Click Create connection"
    echo "6. Copy the service account ID from connection details"
    echo ""
    echo "7. Go to IAM & Admin > IAM > Grant access"
    echo "8. Add service account as principal"
    echo "9. Grant 'BigQuery Data Owner' and 'Vertex AI User' roles"
    echo "10. Enable Vertex AI API in APIs & Services"
    echo ""

    echo "TASK 2: Generate embeddings"
    echo "----------------------------"
    echo "1. In BigQuery, create dataset: CustomerReview"
    echo "2. Create embedding model (see documentation for SQL)"
    echo "3. Load customer reviews data from CSV (see documentation)"
    echo "4. Generate embeddings from review text (see documentation)"
    echo "   - This creates the customer_reviews_embedded table"
    echo "5. Review the embedding results"
    echo ""

    echo "TASK 3: Search vector space and retrieve similar items"
    echo "-----------------------------------------------------"
    echo "1. Create vector index (optional for small datasets, see documentation)"
    echo "2. Perform vector search for 'service' query (see documentation)"
    echo "   - This creates the vector_search_result table"
    echo "3. Review search results - should show relevant customer reviews"
    echo ""

    echo "TASK 4: Generate improved answer with RAG"
    echo "------------------------------------------"
    echo "1. Create Gemini model connection (see documentation for SQL)"
    echo "2. Generate enhanced response using retrieved context (see documentation)"
    echo "   - Uses data from vector_search_result table"
    echo "   - Should provide more accurate, grounded responses"
    echo ""
    echo "3. Compare RAG vs non-RAG responses:"
    echo "   - Test without RAG: Direct Gemini query without context"
    echo "   - Test with RAG: Query using retrieved context"
    echo "   - Note the difference in accuracy and relevance"
    echo ""

    echo "EXPLORATORY QUESTIONS:"
    echo "----------------------"
    echo "1. Test RAG effectiveness:"
    echo "   - Create query without vector search context"
    echo "   - Compare responses for accuracy and hallucination reduction"
    echo ""
    echo "2. Code optimization:"
    echo "   - Instead of separate vector search table, embed search in generation"
    echo "   - Consider using subqueries for real-time retrieval"
    echo ""

    print_status "Lab guidance completed!"
    print_warning "Remember: This lab requires extensive BigQuery SQL operations"
    print_warning "Focus on understanding RAG pipeline and its benefits"
    print_warning "Experiment with the exploratory questions for deeper learning"
}

# Run main function
main "$@"
