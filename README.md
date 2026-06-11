# BPF Observability

This repository contains the observability configuration (dashboards, alerts, etc.) for the BPF Project, specifically for the **EasyCasual** application.

## Contents

- **/dashboards**: Grafana dashboard JSON files.
  - [EasyCasual - Group Messages Bridge](./dashboards/easycasual-bridge.json)
- **/prometheus**: Prometheus alerting rules and recording rules.
  - [Bridge Alerts](./prometheus/alerts.yml)

## Setup

### Grafana

1. Import the JSON files from the `dashboards/` directory into your Grafana instance.
2. Ensure you have a Prometheus datasource configured.

### Prometheus

Include the `prometheus/alerts.yml` in your Prometheus server configuration:

\`\`\`yaml
rule_files:
  - "alerts.yml"
\`\`\`

## Dashboards

### EasyCasual - Group Messages Bridge

Monitoring for the `group-messages-bridge` service.
- **Message Detection Rate**: Rate of new messages detected in WhatsApp groups.
- **Relay Latency (P95)**: 95th percentile of the time taken to relay messages to the backend.
