# BPF Observability

This repository contains the observability configuration (dashboards, alerts, etc.) for the BPF Project, specifically for the **EasyCasual** application.

## Contents

- **/dashboards**: Grafana dashboard JSON files.
  - [EasyCasual - Group Messages Bridge](./dashboards/easycasual-bridge.json)
  - [EasyCasual - Backend Funnel & Product Metrics](./dashboards/easycasual-backend-funnel.json)
  - [EasyCasual - Backend HTTP Errors](./dashboards/easycasual-backend-http-errors.json)
- **/prometheus**: Prometheus configuration and alerting rules.
  - [Federation Scrape Config](./prometheus/prometheus.yml)
  - [Bridge Alerts](./prometheus/alerts.yml)
- **/docs**: Architecture and operational documentation.
  - [Observability Architecture](./docs/architecture.md)

## Architecture

The Cloud Server runs a Prometheus **Federation Server** that scrapes the backend and bridge metrics and re-exposes them via `/federate`. The On-prem central Prometheus scrapes this federation endpoint through a rathole bidirectional tunnel.

```
Backend & Bridge (Cloud Server) → Prometheus Federation Server → Rathole Tunnel → Central Prometheus (On-prem) → Grafana
```

See [docs/architecture.md](./docs/architecture.md) for the full diagram and rathole tunnel details.

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

For the federation scrape job, use the config in `prometheus/prometheus.yml`:

\`\`\`yaml
scrape_configs:
  - job_name: 'bpf-cloud-agent'
    metrics_path: /federate
    params:
      match[]:
        - '{__name__=~".+"}'
    static_configs:
      - targets: ['host.docker.internal:19091']  # via rathole tunnel
\`\`\`

## Dashboards

### EasyCasual - Group Messages Bridge

Monitoring for the `group-messages-bridge` service.
- **Overview**: Service health, configured groups, message cache size, and process start time.
- **Messages**: Detected, published, omitted, publish ratio, message rates, and omitted reasons.
- **HTTP Errors**: 4xx/5xx/429 response rates plus top error routes.
- **Relay**: Relay request rate, duration count/sum, and latency quantiles.
- **Process**: CPU, resident/virtual/heap memory, and file descriptors.
- **Node.js Runtime**: Heap totals, heap spaces, active resources, handles, requests, and version info.
- **Event Loop and GC**: Event loop lag summaries/percentiles and garbage collection rates/durations.

### EasyCasual - Backend Funnel & Product Metrics

Monitoring for the `bpf-application` backend and the product funnel events it receives.
- **Overview**: Backend health, product event rate, contact-click rate, and reported active-usage averages.
- **Product Funnel**: Events by type, contact clicks by method and source, acquisition and activation events, and monetization-intent events.
- **Activation**: Login, signup, search, and payment page views; new users created; first posts created; and next-day returning logins.
- **Latency**: OTP send/verify p95, post creation p95, and search p95 grouped by the main request dimensions.
- **Runtime**: Backend memory, CPU, event-loop lag, active handles, and active requests.

### EasyCasual - Backend HTTP Errors

Monitoring for HTTP response codes emitted by the backend APIs.
- **Overview**: 4xx, 5xx, total responses, and 429 rate.
- **Errors by API Group**: Error rate split by major backend API surface.
- **Top Error Routes**: Highest-error routes across the backend.
- **Status Codes**: Error rate grouped by exact HTTP status code.
