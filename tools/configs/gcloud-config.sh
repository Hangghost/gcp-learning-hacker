#!/bin/bash

# GCP Learning Hacker - gcloud Configuration Script
# This script helps set up gcloud CLI for the learning environment

set -e

echo "🚀 GCP Learning Hacker - gcloud Setup"
echo "======================================"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed. Please install it first:"
    echo "   macOS: brew install google-cloud-sdk"
    echo "   Linux: curl https://sdk.cloud.google.com | bash"
    echo "   Windows: Download from https://cloud.google.com/sdk/docs/install"
    exit 1
fi

echo "✅ gcloud CLI is installed"

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "🔐 Please authenticate with your Google account:"
    gcloud auth login
else
    echo "✅ Already authenticated"
fi

# List available projects
echo ""
echo "📋 Available projects:"
gcloud projects list --format="table(projectId,name,projectNumber)"

# Set project
echo ""
read -p "Enter your GCP project ID: " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Project ID cannot be empty"
    exit 1
fi

# Set the project
gcloud config set project $PROJECT_ID
echo "✅ Project set to: $PROJECT_ID"

# Set default region and zone
echo ""
echo "🌍 Setting default region and zone..."
read -p "Enter your preferred region (e.g., us-central1): " REGION
read -p "Enter your preferred zone (e.g., us-central1-a): " ZONE

if [ -n "$REGION" ]; then
    gcloud config set compute/region $REGION
    echo "✅ Default region set to: $REGION"
fi

if [ -n "$ZONE" ]; then
    gcloud config set compute/zone $ZONE
    echo "✅ Default zone set to: $ZONE"
fi

# Enable common APIs
echo ""
echo "🔧 Enabling common GCP APIs..."
APIS=(
    "compute.googleapis.com"
    "storage.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "iam.googleapis.com"
    "cloudsql.googleapis.com"
    "container.googleapis.com"
)

for api in "${APIS[@]}"; do
    echo "Enabling $api..."
    gcloud services enable $api
done

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Current configuration:"
gcloud config list

echo ""
echo "Next steps:"
echo "1. Explore the labs/beginner/ directory"
echo "2. Start with lab 01-first-gcp-project.md"
echo "3. Check the notes/ directory for learning materials"
echo ""
echo "Happy learning! 🎓☁️"
