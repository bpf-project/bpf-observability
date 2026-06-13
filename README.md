# BPF Observability

This repository contains the observability configuration (dashboards, alerts, etc.) for the BPF Project, specifically for the **EasyCasual** application.

## Contents

- **/dashboards**: Grafana dashboard JSON files.
  - [EasyCasual - Group Messages Bridge](./dashboards/easycasual-bridge.json)
  - [EasyCasual - Backend Funnel & Product Metrics](./dashboards/easycasual-backend-funnel.json)
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
- **Overview**: Service health, configured groups, message cache size, and process start time.
- **Messages**: Detected, published, omitted, publish ratio, message rates, and omitted reasons.
- **Relay**: Relay request rate, duration count/sum, and latency quantiles.
- **Process**: CPU, resident/virtual/heap memory, and file descriptors.
- **Node.js Runtime**: Heap totals, heap spaces, active resources, handles, requests, and version info.
- **Event Loop and GC**: Event loop lag summaries/percentiles and garbage collection rates/durations.

### EasyCasual - Backend Funnel & Product Metrics

Monitoring for the `bpf-application` backend and the product funnel events it receives.
- **Overview**: Backend health, product event rate, contact-click rate, and reported active-usage averages.
- **Product Funnel**: Events by type, contact clicks by method, acquisition and activation events, and monetization-intent events.
- **Latency**: OTP send/verify p95, post creation p95, and search p95 grouped by the main request dimensions.
- **Runtime**: Backend memory, CPU, event-loop lag, active handles, and active requests.
