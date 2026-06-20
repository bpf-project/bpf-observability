# Bridge Down

El servicio **Group Messages Bridge** no responde. Prometheus no puede hacer scrape en el endpoint `/metrics`.

## Impacto
- Los mensajes de grupo no se propagan.
- Los usuarios no reciben notificaciones de grupo.
- No se registran métricas de relay/messages.

## Diagnóstico rápido

### 1. Verificar estado del container
```bash
docker ps --filter name=group-messages-bridge --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 2. Ver logs del container
```bash
docker logs --tail 50 group-messages-bridge
```

### 3. Intentar ping al endpoint
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:3002/metrics
```

## Escenarios comunes

| Código | Causa | Solución |
|--------|-------|----------|
| Container stopped | Crash por OOM, error fatal | `docker compose up -d group-messages-bridge`, revisar logs |
| HTTP 000 | Container no listening | `docker restart group-messages-bridge` |
| HTTP 500 | Backend inaccesible | Verificar backend esté activo (`docker ps`) |
| Timeout | Red congestionada / rathole caído | `systemctl status rathole-reverse-client` (cloud) |

## Recuperación

```bash
# 1. Reiniciar el servicio
docker compose up -d group-messages-bridge

# 2. Verificar que levanta
docker logs --tail 20 -f group-messages-bridge

# 3. Confirmar métricas
curl -s http://localhost:3002/metrics | head -5
```

## Si el problema persiste

1. Verificar que el rathole reverse tunnel está activo: `systemctl status rathole-reverse-client`
2. Verificar que el backend está activo: `docker ps | grep backend`
3. Escalar: revisar infraestructura cloud VPS (CPU, RAM, disco)
