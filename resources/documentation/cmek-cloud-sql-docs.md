# Customer-Managed Encryption Keys (CMEK) for Cloud SQL

## Description
Customer-managed encryption keys (CMEK) allow you to use your own cryptographic keys for data at rest in Cloud SQL. This provides additional control over your data encryption and helps meet compliance requirements for key management.

## URL
https://cloud.google.com/sql/docs/postgres/cmek

## Category
documentation

## Target Audience
- Security administrators
- Compliance officers
- Database administrators
- Cloud architects

## Prerequisites
- Google Cloud KMS key
- Cloud SQL instance (cannot be applied to existing instances)
- Appropriate IAM permissions for KMS
- Understanding of encryption concepts

## Related Labs
- GSP920: Securing a Cloud SQL for PostgreSQL Instance

## Notes
CMEK features:
- Use your own encryption keys for Cloud SQL data
- Keys managed through Cloud KMS
- Support for key rotation and versioning
- Integration with Cloud HSM for hardware-backed keys
- Audit logging of key usage
- Compliance with regulatory requirements

Important considerations:
- CMEK can only be enabled during instance creation
- Keys must be in the same region as the Cloud SQL instance
- Service account requires cryptoKeyEncrypterDecrypter role
- Key deletion will make data inaccessible
- Automatic key rotation recommended
