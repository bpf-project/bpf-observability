# Backend High Latency (P95 > 5s)

Las peticiones HTTP al backend están tardando más de 5 segundos en el percentil 95.

## Impacto
- UX degradada: la app se siente lenta o se congela.
- Los timeouts de cliente pueden causar errores visibles al usuario.
- Stripe webhooks pueden timeout → fallar pagos.

## Causas comunes
1. **Database queries lentas** — sin indexes, join pesado, full table scan.
2. **Event loop blocked** — Node.js / Python CPU-bound, no async.
3. **Memory pressure** — GC压力大, swap activo.
4. **Dependencia externa lenta** — Stripe API, OpenAI, etc.
5. **Contenedor CPU throttled** — limits de Docker alcanzados.

## Diagnóstico

### 1. Verificar dashboard de infra
Revisar dashboard "EasyCasual - Backend Infrastructure" en Grafana:
- CPU usage
- Resident memory (RSS)
- Event loop lag
- GC rate/duration

### 2. Verificar métricas en vivo
```bash
curl -s http://localhost:3000/metrics | grep http_request_duration_seconds_bucket
curl -s http://localhost:3000/metrics | grep process_cpu_seconds_total
```

### 3. Verificar database
```bash
# Si usas PostgreSQL:
docker exec -it <postgres-container> psql -c "SELECT query, state, duration FROM pg_stat_activity ORDER BY duration DESC LIMIT 10;"
```

### 4. Verificar recursos del sistema
```bash
docker stats backend --no-stream
free -m
top -bn1 | head -20
```

## Resolución

| Síntoma | Solución |
|---------|----------|
| CPU 100% | `docker restart backend`, verificar code hotspot |
| Swap activo | Aumentar memory limit del container |
| DB query lenta | Revisar slow query log, agregar indexes |
| GC frecuente | Aumentar heap size, revisar memory leaks |
| Dep externa lenta | Verificar rate limits, retry con backoff |

## Prevención
- Monitorear `easycasual_backend_http_request_duration_seconds_bucket` continuamente.
- Alertar a P95 > 3s (warning) antes de llegar a 5s.
- DB slow query log activo.
- APM integrado si es posible.
