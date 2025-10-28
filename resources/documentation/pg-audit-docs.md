# pgAudit Extension for Cloud SQL PostgreSQL

## Description
pgAudit is a PostgreSQL extension that provides detailed session and object audit logging. It helps organizations comply with regulatory requirements by tracking database activity including SELECT, INSERT, UPDATE, and DELETE operations.

## URL
https://cloud.google.com/sql/docs/postgres/pg-audit

## Category
documentation

## Target Audience
- Database administrators
- Security professionals
- Compliance officers
- DevOps engineers

## Prerequisites
- Cloud SQL for PostgreSQL instance
- Database admin privileges
- Understanding of PostgreSQL auditing concepts
- Knowledge of compliance requirements

## Related Labs
- GSP920: Securing a Cloud SQL for PostgreSQL Instance

## Notes
pgAudit features:
- Detailed audit logging of database operations
- Configurable logging levels (read, write, function, role)
- Integration with Cloud Audit Logs
- Support for regulatory compliance (SOX, PCI-DSS, HIPAA)
- Minimal performance impact
- JSON and CSV output formats

Key configuration parameters:
- `pgaudit.log`: Controls what operations to log
- `pgaudit.log_catalog`: Include catalog objects
- `pgaudit.log_level`: Logging level (debug, info, notice, warning)
- `pgaudit.log_parameter`: Include parameter values in logs
