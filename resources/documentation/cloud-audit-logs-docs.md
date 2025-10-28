# Cloud Audit Logs

## Description
Cloud Audit Logs provides a record of activities and events in Google Cloud resources. It helps you answer questions about who did what, when, and where in your Google Cloud projects.

## URL
https://cloud.google.com/logging/docs/audit

## Category
documentation

## Target Audience
- Security administrators
- Compliance officers
- DevOps engineers
- IT auditors

## Prerequisites
- Google Cloud project
- Appropriate IAM permissions (Logging Viewer, Private Logs Viewer)
- Understanding of audit concepts

## Related Labs
- GSP920: Securing a Cloud SQL for PostgreSQL Instance

## Notes
Cloud Audit Logs features:
- Admin Activity audit logs (default enabled)
- Data Access audit logs (must be enabled)
- System Event audit logs (default enabled)
- Policy Denied audit logs (default enabled)
- 400-day retention for most logs
- Integration with Cloud Logging and BigQuery
- Real-time monitoring and alerting

Audit log types:
- Admin Activity: Administrative operations
- Data Access: Access to user data (read/write)
- System Event: Google Cloud system operations
- Policy Denied: Access denied by IAM policy

Key use cases:
- Security monitoring and incident response
- Compliance auditing (SOX, PCI-DSS, HIPAA)
- Forensic analysis
- Troubleshooting access issues
- Regulatory reporting
