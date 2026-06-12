# VPS Deployment Commands

Run these on your local machine to deploy to the VPS (mariano.fresno.ar):

## 1. Deploy docker-compose.yml

```bash
scp -i ~/.ssh/id_rsa -P 2222 \
  ~/bpf-application/docker-compose.yml \
  mariano-fresno@mariano.fresno.ar:/tmp/bpf-docker-compose.yml

ssh -i ~/.ssh/id_rsa -P 2222 mariano-fresno@mariano.fresno.ar "
  sudo cp /tmp/bpf-docker-compose.yml /var/www/bpf-application/docker-compose.yml
  rm /tmp/bpf-docker-compose.yml
"
```

## 2. Deploy monitoring/prometheus.yml

```bash
scp -i ~/.ssh/id_rsa -P 2222 \
  ~/bpf-application/monitoring/prometheus.yml \
  mariano-fresno@mariano.fresno.ar:/tmp/bpf-prometheus.yml

ssh -i ~/.ssh/id_rsa -P 2222 mariano-fresno@mariano.fresno.ar "
  sudo mkdir -p /var/www/bpf-application/monitoring
  sudo cp /tmp/bpf-prometheus.yml /var/www/bpf-application/monitoring/prometheus.yml
  sudo chown mariano-fresno:www-data /var/www/bpf-application/monitoring/prometheus.yml
  rm /tmp/bpf-prometheus.yml
"
```

## 3. Restart bpf-application stack

```bash
ssh -i ~/.ssh/id_rsa -P 2222 mariano-fresno@mariano.fresno.ar "
  cd /var/www/bpf-application && sudo docker compose up -d prometheus
"
```

## 4. Verify Prometheus agent is working

```bash
ssh -i ~/.ssh/id_rsa -P 2222 mariano-fresno@mariano.fresno.ar "
  docker logs bpf-application-prometheus-1 2>&1 | tail -20
"
```

## 5. Verify metrics on server-monitoring (192.168.1.58)

```bash
ssh -i ~/.ssh/id_rsa_dell_precision mariano@192.168.1.58 "
  curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job==\"bpf-groups-bridge\")'
"
```

## 6. Grafana dashboard

After the CI workflow runs (or manually), verify the dashboard at:
https://grafana-ai.fresno.ar/d/easycasual-bridge

## Required GitHub Secrets for bpf-observability CI

1. `GRAFANA_API_TOKEN` — Create a Grafana API key with Editor role:
   ```bash
   ssh -i ~/.ssh/id_rsa_dell_precision mariano@192.168.1.58 "
     curl -s -X POST -u 'admin:YOUR_GRAFANA_PASSWORD' \
       http://localhost:3000/api/auth/keys \
       -H 'Content-Type: application/json' \
       -d '{\"name\":\"ci-deploy\",\"role\":\"Editor\"}'
   "
   ```
   Add the returned token to bpf-observability repo secrets.

2. `VPS_SSH_KEY` — NOT needed with current approach (dashboards only).
   The alert rules are handled by the cron job on 192.168.1.58 that pulls from GitHub.
