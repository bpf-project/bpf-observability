# Backend Down

**Alert:** `BackendDown` — `up{job="bpf-application-backend"} == 0` for 1m  
**Severity:** critical

## Impacto
**Todo el ecosistema EasyCasual está caído:**
- App móvil no funciona (no hay API)
- Bridge no puede relay (depende del backend)
- Stripe webhooks no se procesan → subscriptions rotas
- Búsqueda, posts, login — todo offline

## Diagnóstico inmediato

### 1. Verificar container
```bash
ssh -i ~/digital_ocean/vps-digital-ocean mariano-fresno@77.42.43.120 -p 2222 -4
docker ps -a | grep backend     # ¿Running o exited?
docker logs --tail 100 backend  # Últimos logs
```

### 2. Verificar dependencias
```bash
docker ps -a | grep postgres    # Database online?
docker ps -a | grep redis       # Cache online?
```

### 3. Verificar sistema
```bash
df -h                           # Disk full?
free -h                         # OOM?
dmesg -T | tail -20             # Kernel OOM killer?
```

## Resolución por causa

| Síntoma | Solución |
|---------|----------|
| Container exited (OOM) | `docker compose restart backend` |
| Database down | `docker compose restart postgres`, verificar backups |
| Disk full | `docker system prune -f`, `rm /var/log/*.old`, verificar metrics retention |
| Bad deploy | `docker compose pull && docker compose up -d backend` (revert) |
| Network | Verificar rathole tunnel y firewall |

## Procedimiento de emergencia

```bash
# 1. Intentar reinicio
docker compose restart backend

# 2. Si no arranca, revisar logs
docker logs --tail 200 backend

# 3. Si es code error, revertir
docker compose pull @previous && docker compose up -d backend

# 4. Verificar recovery
curl -s http://localhost:3000/health
```

## Prevención
- Healthchecks en docker-compose con `restart: unless-stopped`.
- Monitorear disk space y memory en dashboard infra.
- Backup automático de database nightly.
