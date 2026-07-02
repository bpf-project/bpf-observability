# Bridge Ingestion Source Disconnected

**Alert:** `SourceDisconnected` — bridge_connected_status == 0 for 5m  
**Severity:** warning

## Impacto
- No se están ingestado nuevos mensajes/publicaciones desde la fuente especificada (`whatsapp`, `facebook-group` o `web-page`).
- La plataforma EasyCasual puede quedar desactualizada por falta de nuevas oportunidades de la fuente afectada.

## Diagnóstico

### 1. Identificar la fuente afectada
Observa la etiqueta `source` de la alerta para identificar cuál falló (`whatsapp`, `facebook-group`, `web-page`).

### 2. WhatsApp (`source="whatsapp"`)
Si la fuente es WhatsApp, la causa suele ser que el cliente de whatsmeow se desvinculó o no puede iniciar sesión.
1. Revisa los logs de `notifications-service`:
   ```bash
   docker logs --tail 200 notifications
   ```
2. Chequea el estado detallado desde el bridge:
   ```bash
   curl -s http://localhost:3457/api/whatsapp/groups
   ```
   O consulta directamente el estado del backend de notificaciones:
   ```bash
   curl -s http://localhost:3001/notifications/status
   ```
3. Si el estado es `UNPAIRED` o `DISCONNECTED`, es necesario volver a vincular la cuenta escaneando el código QR o generando un código de emparejamiento desde la interfaz de administración.

### 3. Facebook (`source="facebook-group"`)
Si la fuente es Facebook, usualmente la sesión / cookies de Playwright expiraron o falló el último raspado programado.
1. Verifica si existen cookies en el bridge:
   ```bash
   curl -s http://localhost:3457/api/facebook/auth/session/active
   ```
2. Si no hay cookies o la sesión no es válida, ve a la UI de administración del bridge y realiza el login de Facebook para guardar las cookies.
3. Revisa los logs del bridge para ver si hay bloqueos/captchas de Facebook o timeouts de Playwright:
   ```bash
   docker logs --tail 200 group-messages-bridge | grep -i "facebook"
   ```

### 4. Web Directory (`source="web-page"`)
Si la fuente es un scrap de página web, usualmente la estructura del sitio cambió o la página está caída, lo que causa fallas continuas de scraping.
1. Revisa los logs del bridge buscando errores de scraping para la fuente específica:
   ```bash
   docker logs --tail 200 group-messages-bridge | grep -i "web-page"
   ```
2. Verifica si el sitio objetivo está online:
   ```bash
   curl -s -I <url-de-la-fuente-en-config>
   ```

## Resolución

| Fuente | Causa | Solución |
|---|---|---|
| `whatsapp` | Desvinculado / Sin auth | Escanear QR en UI o generar pairing code |
| `facebook-group` | Cookies expiradas | Re-autenticar sesión en UI de admin |
| `facebook-group` | Bloqueo temporal / Captcha | Usar VNC en la UI para resolver el captcha manualmente |
| `web-page` | Estructura web cambió | Actualizar selectores en la configuración del bridge |
