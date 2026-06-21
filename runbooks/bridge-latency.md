# High Bridge Latency

**Alert:** `HighBridgeLatency` — P95 relay duration > 5s for 2m  
**Severity:** warning

## ¿Qué es?
El 95% de los mensajes relayados por el bridge están tardando más de 5 segundos en procesarse. Esto puede indicar problemas de red, carga alta o problemas de base de datos.

## Causas comunes
1. **Red congestionada** — la conexión entre bridge y backend está lenta.
2. **Backend lento** — el backend está procesando peticiones lento (verificar backend latency).
3. **Carga alta** — muchos grupos simultáneos saturando el bridge.
4. **Database slow** — queries de mensajes/ubicación lentas.

## Pasos para diagnosticar

### 1. Verificar dashboard del Bridge
Abrir dashboard EasyCasual - Group Messages Bridge en Grafana.

### 2. Verificar correlación con backend
```bash
# Verificar si el backend tiene latencia alta
curl -s http://localhost:3000/metrics | grep http_request_duration
```

### 3. Verificar recursos del container
```bash
docker stats group-messages-bridge --no-stream  # CPU, memoria
```

## Resolución

| Síntoma | Solución |
|---------|----------|
| CPU al máximo | `docker compose restart group-messages-bridge` |
| Memoria alta | Verificar memory leaks en el bridge, considerar reinicio |
| Latencia backend alta | Ver runbook `backend-latency.md` |
| Pico transitorio | Esperar — puede ser un spike de tráfico |

## Prevención
- Monitorear correlación entre bridge latency y backend latency.
- Considerar threshold dinámico basado en horario (más tráfico = más latencia esperada).
