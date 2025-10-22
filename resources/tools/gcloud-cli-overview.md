# Google Cloud CLI (gcloud) Overview

## Description
Official documentation for the Google Cloud CLI (gcloud command-line tool). Complete guide to installing, configuring, and using gcloud for managing Google Cloud resources.

## URL
https://cloud.google.com/sdk/gcloud

## Category
tools

## Target Audience
- Beginner
- Intermediate
- Advanced

## Prerequisites
- Google Cloud Platform account
- Command-line interface access
- Basic command-line knowledge

## Related Labs
- GSP001: Google Cloud Platform Fundamentals: Core Infrastructure
- GSP002: Getting Started with Google Cloud Platform
- GSP154: Video Intelligence: Qwik Start
- Most GCP labs requiring command-line operations

## Key Topics Covered
- Installation and setup
- Authentication methods
- Project and account management
- Resource management commands
- Configuration and properties
- Command-line completion
- Scripting and automation
- Troubleshooting

## Essential Commands
- **gcloud auth**: Authentication and authorization
- **gcloud config**: Configuration management
- **gcloud projects**: Project management
- **gcloud iam**: Identity and Access Management
- **gcloud compute**: Compute Engine management
- **gcloud storage**: Cloud Storage operations
- **gcloud services**: API service management
- **gcloud builds**: Cloud Build operations

## Configuration
- Project selection: `gcloud config set project PROJECT_ID`
- Region/Zone settings: `gcloud config set compute/region REGION`
- Account switching: `gcloud config set account ACCOUNT`
- Default settings management

## Authentication Methods
- User account authentication
- Service account key files
- Application Default Credentials
- Cloud Shell automatic authentication

## Notes
gcloud CLI is the primary command-line tool for Google Cloud Platform. It supports all GCP services and provides both interactive and scripting capabilities. Essential for automation, CI/CD pipelines, and infrastructure as code. Includes tab completion and comprehensive help system.
