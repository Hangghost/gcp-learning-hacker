# Cloud SQL IAM Database Authentication

## Description
Cloud SQL IAM database authentication allows you to use Google Cloud IAM accounts to authenticate to PostgreSQL databases instead of built-in database users. This simplifies user management and provides fine-grained access control.

## URL
https://cloud.google.com/sql/docs/postgres/iam-logins

## Category
documentation

## Target Audience
- Database administrators
- Security administrators
- DevOps engineers
- Application developers

## Prerequisites
- Cloud SQL for PostgreSQL instance
- Google Cloud IAM users or service accounts
- Database admin privileges
- Understanding of IAM concepts

## Related Labs
- GSP920: Securing a Cloud SQL for PostgreSQL Instance

## Notes
IAM authentication features:
- Use Google accounts for database access
- Automatic user provisioning
- Integration with Google Cloud IAM
- Support for service accounts
- Fine-grained permissions at database level
- OAuth 2.0 access tokens for authentication

Key benefits:
- Centralized user management
- No need to manage database passwords
- Automatic credential rotation
- Audit trails through Cloud Audit Logs
- Compliance with enterprise security policies

Implementation steps:
1. Enable IAM authentication on Cloud SQL instance
2. Create IAM database users
3. Grant database-level permissions
4. Use OAuth access tokens for authentication
