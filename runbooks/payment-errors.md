# Payment Checkout Errors

**Alert:** `PaymentCheckoutErrors` — error rate > success rate for 3m  
**Severity:** critical

## Impacto
- Los usuarios no pueden pagar por suscripciones/premium.
- Revenue directo afectado.
- Stripe puede flaggear la cuenta si el error rate es muy alto.

## Diagnóstico

### 1. Verificar Stripe status
```bash
# Verificar estado de Stripe API
curl -s https://status.stripe.com/v2/components.json | jq '.[] | select(.status != "operative")'
```

### 2. Verificar configuración de Stripe
```bash
# Verificar que las keys son correctas
docker logs --tail 100 backend 2>&1 | grep -i "stripe\|payment\|checkout\|error"
```

### 3. Verificar tipos de error
```bash
curl -s http://localhost:3000/metrics | grep payment_attempts_total
```

## Escenarios comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `card_declined` | Tarjeta inválida/expired | No es problema del sistema, esperar |
| `rate_limit` | Rate limit de Stripe | Esperar, reducir throughput |
| `authentication_required` | 3D Secure no completado | Verificar integración de redirect |
| `api_error` | Error de Stripe API | Verificar status.stripe.com |
| `invalid_request` | Bug en payload enviado | Hotfix backend |

## Resolución

```bash
# 1. Identificar error específico
docker logs --tail 200 backend 2>&1 | grep -i "stripe"

# 2. Si es problema de Stripe
# Esperar — ver status.stripe.com

# 3. Si es bug en payload
# Hotfix y re-deploy: docker compose pull && docker compose up -d backend

# 4. Verificar keys
# Asegurar que STRIPE_SECRET_KEY y STRIPE_PUBLISHABLE_KEY son correctas
```

## Prevención
- Retry con exponential backoff para errores temporales.
- Monitorear tipo de error (no solo rate).
- Circuit breaker para Stripe API.
- Test de integración con Stripe test mode.
