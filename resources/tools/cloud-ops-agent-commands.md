# Cloud Operations Agent Commands

## Description
Commands and procedures for installing and managing the Google Cloud Operations (Ops) Agent, which collects metrics and logs from VM instances for Cloud Monitoring and Cloud Logging.

## Installation Commands

### Install Ops Agent Repository and Agent
```bash
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
```

### Check Agent Status
```bash
sudo systemctl status google-cloud-ops-agent
```

### View Agent Logs
```bash
sudo journalctl -u google-cloud-ops-agent -f
```

### Restart Agent
```bash
sudo systemctl restart google-cloud-ops-agent
```

### Update Agent Configuration
```bash
sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null <<EOF
logging:
  receivers:
    syslog:
      type: files
      include_paths:
      - /var/log/syslog
      - /var/log/messages
  service:
    pipelines:
      default_pipeline:
        receivers: [syslog]

metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
      collection_interval: 60s
  service:
    pipelines:
      default_pipeline:
        receivers: [hostmetrics]
EOF

sudo systemctl restart google-cloud-ops-agent
```

## Category
tools

## Target Audience
- System administrators
- DevOps engineers
- Cloud architects

## Prerequisites
- GCP project
- VM instances running Linux
- Appropriate IAM permissions

## Related Labs
- GSP089: Cloud Monitoring: Qwik Start

## Notes
- Ops Agent replaces the legacy Monitoring and Logging agents
- Automatically collects system metrics and logs
- Can be configured for custom application metrics
- Supports both structured and unstructured logs
- Integrates with Cloud Monitoring and Cloud Logging
