# gcloud CLI Setup and Usage

## Overview
The Google Cloud CLI (gcloud) is a command-line tool for managing Google Cloud resources and services.

## Installation

### macOS
```bash
# Using Homebrew
brew install google-cloud-sdk

# Or download from Google
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### Linux
```bash
# Download and install
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### Windows
1. Download the installer from [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
2. Run the installer and follow the prompts

## Initial Setup

### 1. Initialize gcloud
```bash
gcloud init
```

### 2. Authenticate
```bash
gcloud auth login
```

### 3. Set default project
```bash
gcloud config set project PROJECT_ID
```

### 4. Set default region/zone
```bash
gcloud config set compute/region REGION
gcloud config set compute/zone ZONE
```

## Common Commands

### Project Management
```bash
# List projects
gcloud projects list

# Create project
gcloud projects create PROJECT_ID

# Set active project
gcloud config set project PROJECT_ID
```

### Compute Engine
```bash
# List instances
gcloud compute instances list

# Create instance
gcloud compute instances create INSTANCE_NAME --zone=ZONE

# SSH to instance
gcloud compute ssh INSTANCE_NAME --zone=ZONE
```

### Storage
```bash
# List buckets
gsutil ls

# Create bucket
gsutil mb gs://BUCKET_NAME

# Copy files
gsutil cp FILE gs://BUCKET_NAME/
```

### IAM
```bash
# List service accounts
gcloud iam service-accounts list

# Create service account
gcloud iam service-accounts create SERVICE_ACCOUNT_NAME

# Grant roles
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member="serviceAccount:SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/ROLE_NAME"
```

## Configuration

### View current configuration
```bash
gcloud config list
```

### Set configuration
```bash
gcloud config set property value
```

### Switch configurations
```bash
gcloud config configurations create CONFIG_NAME
gcloud config configurations activate CONFIG_NAME
```

## Useful Tips

1. **Use tab completion**: Enable bash completion for gcloud
2. **Set aliases**: Create shortcuts for frequently used commands
3. **Use filters**: Filter output with `--filter` flag
4. **Format output**: Use `--format` for custom output formats
5. **Enable logging**: Use `--log-http` for debugging

## Troubleshooting

- **Authentication issues**: Run `gcloud auth login` again
- **Permission errors**: Check IAM roles and policies
- **Project not found**: Verify project ID and permissions
- **Zone/region errors**: Check availability and quotas

## Resources
- [gcloud CLI Documentation](https://cloud.google.com/sdk/gcloud)
- [gcloud Reference](https://cloud.google.com/sdk/docs/reference)
- [gcloud Cheat Sheet](https://cloud.google.com/sdk/docs/cheat-sheet)
