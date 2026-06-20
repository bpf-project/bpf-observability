# Stripe Webhook Failures

**Alert:** `StripeWebhookFailures` — webhook error rate > 0 for 2m  
**Severity:** critical

## Impacto
- Los eventos de Stripe (payment succeeded, subscription updated, refunded) **no se procesan**.
- Las suscripciones pueden quedar desincronizadas.
- Los usuarios pagan pero no reciben acceso.

## Diagnóstico

### 1. Verificar secreto de webhook
```bash
docker exec -it backend env | grep STRIPE_WEBHOOK_SECRET
```

### 2. Verificar URL en Stripe Dashboard
- Ir a Stripe Dashboard > Developers > Webhooks
- Verificar que la URL del endpoint es correcta y reachable

### 3. Verificar logs
```bash
docker logs --tail 200 backend 2>&1 | grep -i "webhook"
```

## Resolución

| Error | Causa | Solución |
|-------|-------|----------|
| `invalid_signature` | Webhook secret incorrecto | Verificar `STRIPE_WEBHOOK_SECRET` |
| 500 | Bug en handler | Hotfix + deploy |
| Timeout | Handler lento | Optimizar, aumentar timeout |
| 404 | URL incorrecta | Corregir en Stripe Dashboard |

```bash
# Resend failed events from Stripe Dashboard
# Or test locally: stripe listen --forward-to localhost:3000/api/webhooks/stripe
```
