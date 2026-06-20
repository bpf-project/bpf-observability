# Backend 5xx Error Rate > 5%

Más del 5% de las peticiones HTTP al backend están devolviendo errores 5xx.

## Impacto
- Operaciones críticas fallan: auth, creación de posts, pagos.
- El usuario ve mensajes de error genéricos.
- Stripe webhooks pueden fallar → suscripciones inconsistentes.

## Diagnóstico

### 1. Verificar errores por ruta
Revisar dashboard "EasyCasual - Backend Funnel" → panel "HTTP Errors by Code":
- Identificar qué rutas están fallando
- Verificar si es 500 (internal), 502 (bad gateway), 503 (unavailable), 504 (gateway timeout)

### 2. Verificar logs del backend
```bash
docker logs --tail 200 backend 2>&1 | grep -E "500|502|503|504|error|exception|traceback"
```

### 3. Verificar dependencias
```bash
# Database connectivity
docker exec -it <postgres-container> pg_isready

# Redis connectivity (si aplica)
docker exec -it backend redis-cli ping  # si hay Redis
```

### 4. Verificar métricas en vivo
```bash
curl -s http://localhost:3000/metrics | grep http_responses_total
```

## Escenarios y resolución

| Error | Causa probable | Solución |
|-------|---------------|----------|
| 500 Internal Server Error | Exception no capturada, code bug | Ver logs, hotfix, deploy |
| 502 Bad Gateway | Backend no responde | `docker restart backend` |
| 503 Service Unavailable | DB down, mantenimiento | Verificar database, restart |
| 504 Gateway Timeout | Query lenta, dependency timeout | Ver `backend-latency.md`, kill slow queries |
| Pattern: todas las rutas | Sistema colapsado | `docker restart backend`, verificar infra |

## Prevención
- Circuit breaker en dependencias externas.
- Retry con backoff en database connections.
- Graceful shutdown en deploys.
