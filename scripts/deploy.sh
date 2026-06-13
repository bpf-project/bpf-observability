#!/bin/bash
# Script para desplejar observabilidad
GRAFANA_URL=${GRAFANA_URL:-"http://localhost:3000"}
GRAFANA_TOKEN=${GRAFANA_TOKEN:-""}
PROMETHEUS_URL=${PROMETHEUS_URL:-"http://localhost:9090"}
VPS_PROMETHEUS_URL=${VPS_PROMETHEUS_URL:-"http://127.0.0.1:19091"}
BPF_APP_PATH=${BPF_APP_PATH:-"/var/www/bpf-application"}

echo "🚀 Iniciando despliegue..."

if [ -n "$GRAFANA_TOKEN" ]; then
    for dashboard in dashboards/*.json; do
        jq -n --slurpfile db "$dashboard" "{"dashboard": $db[0], "overwrite": true}" > /tmp/db_payload.json
        curl -s -X POST -H "Authorization: Bearer $GRAFANA_TOKEN" -H "Content-Type: application/json" -d @/tmp/db_payload.json "$GRAFANA_URL/api/dashboards/db" | jq .
    done
fi

cp prometheus/alerts.yml /home/mariano-fresno/server-monitoring/prometheus_rules/easycasual/ 2>/dev/null
curl -s -X POST "$PROMETHEUS_URL/-/reload"

# Deploy Prometheus config to bpf-application if the file exists
if [ -f prometheus/prometheus.yml ]; then
    echo "📡 Deploying Prometheus config to $BPF_APP_PATH/monitoring/prometheus.yml"
    docker run --rm -v "${BPF_APP_PATH}/monitoring:/mnt" alpine sh -c 'cat > /mnt/prometheus.yml << ENDOFCONFIG
'"$(cat prometheus/prometheus.yml)"'
ENDOFCONFIG' 2>/dev/null
    echo "🔄 Reloading VPS Prometheus"
    curl -s -X POST "$VPS_PROMETHEUS_URL/-/reload"
fi
