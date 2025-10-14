# gsutil Commands Reference

## Description
Comprehensive guide to gsutil, Google Cloud Storage's command-line tool for advanced storage operations, access control management, and batch processing.

## URL
https://cloud.google.com/storage/docs/gsutil

## Category
tools

## Target Audience
- Intermediate
- Advanced

## Prerequisites
- Google Cloud SDK installed
- gsutil configured with authentication
- Understanding of Cloud Storage concepts
- Command-line familiarity

## Related Labs
- GSP074: Cloud Storage: Qwik Start - CLI/SDK
- GSP075: Cloud Storage: Qwik Start - gsutil

## Key Commands Covered
- `gsutil ls` - List buckets and objects
- `gsutil mb` - Make bucket
- `gsutil rb` - Remove bucket
- `gsutil cp` - Copy objects
- `gsutil mv` - Move objects
- `gsutil rm` - Remove objects
- `gsutil acl ch` - Change access control lists
- `gsutil acl get` - Get access control lists
- `gsutil iam ch` - Change IAM policies
- `gsutil iam get` - Get IAM policies
- `gsutil versioning` - Manage object versioning
- `gsutil lifecycle` - Configure lifecycle policies
- `gsutil cors` - Configure CORS settings

## Common Use Cases
- Advanced access control management (ACLs and IAM)
- Batch operations on multiple objects
- Lifecycle policy configuration
- Cross-cloud storage operations
- Automated backup and synchronization
- Performance optimization and monitoring

## ACL Operations (Key for GSP074)
- `gsutil acl ch -u AllUsers:R gs://bucket/object` - Make object publicly readable
- `gsutil acl ch -d AllUsers gs://bucket/object` - Remove public access
- `gsutil acl get gs://bucket/object` - View current ACL
- `gsutil acl set private gs://bucket/object` - Make object private

## Notes
Powerful command-line tool for advanced Cloud Storage operations. Essential for automation, batch processing, and fine-grained access control. Particularly useful for scenarios requiring ACL management beyond basic IAM permissions.
