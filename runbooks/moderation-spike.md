# High Report Volume (Moderation Spike)

**Alert:** `HighReportVolume` — >50 moderation reports created in 1 hour  
**Severity:** warning

## Impacto
- Moderation team puede estar saturado.
- Potencial abuse campaign coordinada.
- Contenido nocivo puede estar propagándose.

## Causas comunes
1. **Abuse campaign** — bots o usuarios maliciosos reportando en masa.
2. **Bug en contenido** — una feature que genera contenido ofensivo involuntariamente.
3. **Event external** — algo en medios/noticias que genera wave de contenido reportado.
4. **False positive wave** — muchos usuarios reportando por confusión (no entendieron la feature).
5. **Competitor attack** — coordinated reporting para hacer caer el servicio.

## Diagnóstico

### 1. Verificar tipo de reports
```bash
# Verificar qué tipo de contenido se está reportando
docker logs --tail 500 backend 2>&1 | grep -i "report\|moderation"
```

### 2. Verificar dashboard
Revisar dashboard "EasyCasual - Backend Funnel" para correlacionar con otros metrics:
- Spike en nuevos usuarios (bots creando accounts)?
- Spike en post creation (spam)?

### 3. Verificar fuentes
```bash
# Verificar si viene de pocos usuarios (coordinated) o muchos (organic reaction)
docker exec -it <postgres-container> psql -c "SELECT reporter_id, count(*) FROM reports GROUP BY reporter_id ORDER BY count DESC LIMIT 20;"
```

## Resolución

| Escenario | Acción |
|-----------|--------|
| Coordinated attack | Rate-limit reporting endpoint, activar CAPTCHA |
| Bug en contenido | Hotfix, rollback si es deploy reciente |
| Organic reaction | Monitorear, actuar sobre casos confirmados |
| Bot wave | Activar bot detection, rate-limit new accounts |
| False positive | Comunicar a usuarios, mejorar UX de reporting |

## Prevención
- Rate-limitar endpoint de reports (max 5/hour per user).
- CAPTCHA después de N reports.
- Dashboard de moderation con drill-down por tipo.
- Alerta intermedia a 20/hour (early warning).
