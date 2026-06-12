# VPS Deployment

The bpf-application on the VPS (mariano.fresno.ar) needs sudo to deploy docker-compose.yml and monitoring/prometheus.yml.

## Option 1: Run the deploy script

```bash
~/deploy-vps.sh
```

This will copy the files and restart the Prometheus container. **You'll need to enter your VPS sudo password.**

## Option 2: Manual deployment

```bash
# 1. Copy files to VPS
scp -i ~/.ssh/id_rsa -P 2222 \
  ~/bpf-application/docker-compose.yml \
  mariano-fresno@mariano.fresno.ar:/tmp/bpf-docker-compose.yml

scp -i ~/.ssh/id_rsa -P 2222 \
  ~/bpf-application/monitoring/prometheus.yml \
  mariano-fresno@mariano.fresno.ar:/tmp/bpf-prometheus.yml

# 2. Deploy on VPS (requires sudo password)
ssh -i ~/.ssh/id_rsa -P 2222 mariano-fresno@mariano.fresno.ar '
  sudo cp /tmp/bpf-docker-compose.yml /var/www/bpf-application/docker-compose.yml
  sudo cp /tmp/bpf-prometheus.yml /var/www/bpf-application/monitoring/prometheus.yml
  cd /var/www/bpf-application && sudo docker compose down prometheus
  sudo docker compose up -d prometheus
'
```

## After deployment

Verify Prometheus is running and scraping the bridge:

```bash
ssh -i ~/.ssh/id_rsa -P 2222 mariano-fresno@mariano.fresno.ar "
  docker ps | grep prometheus
  docker logs bpf-application-prometheus-1 2>&1 | tail -5
"
```

Then on the local server (192.168.1.58), verify the metrics are arriving:

```bash
ssh -i ~/.ssh/id_rsa_dell_precision mariano@192.168.1.58 "
  curl -s http://localhost:9090/api/v1/targets | python3 -c '
import sys, json
for t in json.load(sys.stdin)[\"data\"][\"activeTargets\"]:
    print(t[\"labels\"].get(\"job\",\"\"), t[\"health\"])
'
"
```

You should see `bpf-groups-bridge: up`.

## Summary of what was implemented

### bpf-application
- **docker-compose.yml**: Added Prometheus service in agent mode with remote_write
- **monitoring/prometheus.yml**: Scrapes `group-messages-bridge:3002`, remote_write to `127.0.0.1:9090` (rathole → local Prometheus)

### server-monitoring (192.168.1.58)
- **docker-compose.yml**: Added easycasual dashboard provisioning
- **provisioning/dashboards/dashboards.yml**: Two providers — default (no folder) + EasyCasual folder
- **scripts/render_dashboards.sh**: Copies easycasual/ dashboards to separate provisioned dir
- **scripts/pull-observability-alerts.sh**: Cron-pulls alert rules from GitHub
- **Prometheus**: Already has `--web.enable-remote-write-receiver`

### bpf-observability
- **.github/workflows/deploy.yml**: Imports dashboards to EasyCasual folder via Grafana API
- **GRAFANA_API_TOKEN** secret: Service account token for Grafana API access

### Grafana (grafana-ai.fresno.ar)
- **EasyCasual folder** with `easycasual-bridge` dashboard
- Existing dashboards remain in root (no folder change)
