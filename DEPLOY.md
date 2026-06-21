# Deployment Guide

This guide covers deploying the bpf-observability stack — the Prometheus federation configuration on the VPS, and the Grafana dashboards via CI.

## Architecture Overview

Metrics flow from the bpf-application services on the VPS (mariano.fresno.ar) to the on-prem Prometheus through a rathole bidirectional tunnel, using **federation** (not agent mode or remote_write):

```
Backend (port 3000) ──┐
                       ├──→ Prometheus Federation Server (port 19091) ──→ Rathole Tunnel ──→ Central Prometheus (on-prem, port 9090) ──→ Grafana
Bridge (port 3002) ───┘
```

See [docs/architecture.md](./docs/architecture.md) for the full architecture diagram.

## Repository Contents

| Path | What it is | Where it lives |
|---|---|---|
| `prometheus/prometheus.yml` | Federation scrape config for the on-prem central Prometheus | On-prem Prometheus server |
| `prometheus/alerts.yml` | Alerting rules for the EasyCasual services | On-prem Prometheus server |
| `dashboards/*.json` | Grafana dashboard JSON files | Imported to Grafana via CI |

## Deploying the VPS Federation Server

The federation server configuration lives in the **bpf-application** repository at `monitoring/prometheus.yml`. When that file changes, deploy it to the VPS along with any `docker-compose.yml` updates.

### Option 1: Deploy script

```bash
~/deploy-vps.sh
```

This copies the files and restarts the Prometheus container. **You'll need to enter your VPS sudo password.**

### Option 2: Manual deployment

```bash
# 1. Copy docker-compose.yml to VPS
scp -i ~/.ssh/id_rsa -P 2222 \
  ~/bpf-application/docker-compose.yml \
  mariano-fresno@mariano.fresno.ar:/tmp/bpf-docker-compose.yml

# 2. Copy prometheus.yml to VPS
scp -i ~/.ssh/id_rsa -P 2222 \
  ~/bpf-application/monitoring/prometheus.yml \
  mariano-fresno@mariano.fresno.ar:/tmp/bpf-prometheus.yml

# 3. Deploy on VPS (requires sudo)
ssh -i ~/.ssh/id_rsa -P 2222 mariano-fresno@mariano.fresno.ar '
  sudo cp /tmp/bpf-docker-compose.yml /var/www/bpf-application/docker-compose.yml
  sudo cp /tmp/bpf-prometheus.yml /var/www/bpf-application/monitoring/prometheus.yml
  cd /var/www/bpf-application && sudo docker compose down prometheus
  sudo docker compose up -d prometheus
  rm /tmp/bpf-docker-compose.yml /tmp/bpf-prometheus.yml
'
```

## Deploying the On-prem Configuration

The on-prem Prometheus configuration (this repo's `prometheus/prometheus.yml` and `prometheus/alerts.yml`) must be placed on the on-prem server (192.168.1.58) in the server-monitoring Prometheus provisioning directories.

The `prometheus/alerts.yml` alert rules are deployed by a cron job on 192.168.1.58 that pulls them from GitHub:

```bash
# The cron job on 192.168.1.58 runs:
ssh -i ~/.ssh/id_rsa_dell_precision mariano@192.168.1.58 "
  cd /path/to/server-monitoring/prometheus && \
  git pull origin main
"
```

The federation scrape config (`prometheus/prometheus.yml`) is already provisioned in the on-prem Prometheus server. If you need to update it, sync it manually:

```bash
scp -i ~/.ssh/id_rsa_dell_precision \
  ~/bpf-observability/prometheus/prometheus.yml \
  mariano@192.168.1.58:/path/to/server-monitoring/prometheus/prometheus.yml
```

Then restart the on-prem Prometheus:

```bash
ssh -i ~/.ssh/id_rsa_dell_precision mariano@192.168.1.58 "
  # Restart the Prometheus container in server-monitoring
  docker compose -f /path/to/server-monitoring/docker-compose.yml restart prometheus
"
```

## Deploying Grafana Dashboards

Dashboards are deployed automatically via the GitHub Actions workflow (`.github/workflows/deploy.yml`) on every push to `main` that touches `dashboards/`.

### Setting up the Grafana API token

The CI workflow requires a `GRAFANA_API_TOKEN` secret with Editor role:

```bash
ssh -i ~/.ssh/id_rsa_dell_precision mariano@192.168.1.58 "
  curl -s -X POST -u 'admin:YOUR_GRAFANA_PASSWORD' \
    http://localhost:3000/api/auth/keys \
    -H 'Content-Type: application/json' \
    -d '{\"name\":\"ci-deploy\",\"role\":\"Editor\"}'
"
```

Add the returned token to the **bpf-observability** repository secrets as `GRAFANA_API_TOKEN`.

### Manual dashboard import

To trigger a dashboard import manually:

```bash
gh workflow run deploy.yml --repo gymnerd-ar/bpf-observability
```

## Verification

### Verify the VPS federation server

```bash
ssh -i ~/.ssh/id_rsa -P 2222 mariano-fresno@mariano.fresno.ar "
  docker ps | grep prometheus
  docker logs bpf-application-prometheus-1 2>&1 | tail -20
"
```

Query the federation endpoint directly (from the VPS) to confirm it has scraped data:

```bash
ssh -i ~/.ssh/id_rsa -P 2222 mariano-fresno@mariano.fresno.ar "
  curl -s 'http://localhost:19091/api/v1/targets' | \
    python3 -c '
import sys, json
for t in json.load(sys.stdin)["data"]["activeTargets"]:
    print(t["labels"].get("job", ""), t["health"])
'
"
```

You should see `bpf-groups-bridge: up` and `bpf-application-backend: up`.

### Verify the on-prem central Prometheus

```bash
ssh -i ~/.ssh/id_rsa_dell_precision mariano@192.168.1.58 "
  curl -s http://localhost:9090/api/v1/targets | \
    python3 -c '
import sys, json
for t in json.load(sys.stdin)["data"]["activeTargets"]:
    print(t["labels"].get("job", ""), t["health"])
'
"
```

You should see `bpf-cloud-agent: up`.

### Verify the Grafana dashboard

Open https://grafana-ai.fresno.ar/d/easycasual-bridge and confirm data is flowing.

## Troubleshooting

### Federation target shows down on the on-prem server

The rathole tunnel may have dropped. Restart the rathole clients:

```bash
# On the VPS
ssh -i ~/.ssh/id_rsa -P 2222 mariano-fresno@mariano.fresno.ar "
  cd /path/to/rathole && docker compose restart
"

# On the on-prem server
ssh -i ~/.ssh/id_rsa_dell_precision mariano@192.168.1.58 "
  cd /path/to/rathole && docker compose restart
"
```

### Dashboard not updating

The CI workflow only deploys dashboards that match `dashboards/*.json`. Ensure the JSON file is in the correct directory. Check the GitHub Actions run logs for import errors.

### No metrics but targets are up

The federation server on the VPS has a 30-minute retention window. If the federation server has been down for longer than 30 minutes, the on-prem server may see gaps. Restart the VPS Prometheus to force a fresh scrape cycle.
