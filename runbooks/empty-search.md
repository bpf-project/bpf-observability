# High Empty Search Rate (>30%)

Más del 30% de las búsquedas de posts devuelven 0 resultados.

## Impacto
- Los usuarios encuentran la app "vacía" y pueden desistarse.
- La activación de nuevos usuarios se ve afectada.
- La retención puede caer drásticamente.

## Causas comunes
1. **Data index stale** — los posts no están siendo indexados correctamente.
2. **Search service issue** — el servicio de búsqueda (database query) tiene un problema.
3. **Query parameters incorrectos** — el backend está enviando filtros erróneos (location, category).
4. **Data migration en progreso** — un migration está bloqueando reads.
5. **Geography coverage** — nuevos usuarios en zonas sin contenido.

## Diagnóstico

### 1. Verificar tasa vs histórico
Revisar dashboard "EasyCasual - Backend Funnel" → panel de búsqueda.

### 2. Verificar data freshness
```bash
# Verificar último post indexado
curl -s http://localhost:3000/metrics | grep search_results_total

# Verificar database connectivity
docker exec -it <postgres-container> psql -c "SELECT count(*) FROM posts ORDER BY created_at DESC LIMIT 5;"
```

### 3. Verificar logs del backend
```bash
docker logs --tail 200 backend 2>&1 | grep -i "search\|query\|empty"
```

## Resolución

| Síntoma | Solución |
|---------|----------|
| Indexing lag | Trigger reindex, verificar job de indexing |
| Query bug | Hotfix en backend, re-deploy |
| Data vacía en región | Seed data, relax geographic filter |
| Database issue | Verificar database health, verificar connection pool |

## Prevención
- Monitorear tasa de empty search continuamente.
- Alertar a 20% (warning) antes de llegar a 30%.
- Verificar que el index de búsqueda se actualiza en tiempo real.
- A/B test: verificar que nuevos usuarios ven contenido relevante.
