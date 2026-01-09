# Authorization Policy Plugin

Este plugin genera recursos `AuthorizationPolicy` de Istio que delegan la autorización a OPA (Open Policy Agent) para validar JWT tokens.

## Descripción

El plugin procesa las rutas configuradas en el HTTPRoute y genera un AuthorizationPolicy que:
- Se aplica al Gateway (no requiere sidecar en los pods de aplicación)
- Delega la validación a OPA usando `action: CUSTOM` con provider `opa-ext-authz`
- Respeta los mismos tipos de matching de path (Exact, PathPrefix, RegularExpression)
- OPA valida JWT tokens según la policy configurada en Rego

## Configuración

La configuración se agrega en el service specification bajo `parameters.authorization`:

```json
{
  "publicDomain": "api.example.com",
  "authorization": {
    "enabled": true
  },
  "routes": [
    {
      "method": "GET",
      "path": "/api/users",
      "scope": "user-service"
    },
    {
      "method": "POST",
      "path": "/api/users/:id",
      "scope": "user-service"
    }
  ]
}
```

### Parámetros

| Parámetro | Tipo | Requerido | Default | Descripción |
|-----------|------|-----------|---------|-------------|
| `enabled` | boolean | No | `false` | Activa o desactiva la validación JWT via OPA para todas las rutas del servicio |

## Funcionamiento

1. **Deshabilitado por defecto**: Si `authorization.enabled` no es `true`, el script termina sin generar nada.

2. **Procesamiento de rutas**: Para cada ruta en `routes`:
   - Detecta el tipo de path (Exact, PathPrefix, RegularExpression)
   - Convierte paths con parámetros (`:id`) a prefix matching
   - Genera una regla de autorización que coincide con el path y método

3. **Delegación a OPA**: El AuthorizationPolicy usa `action: CUSTOM` con provider `opa-ext-authz`:
   ```yaml
   spec:
     action: CUSTOM
     provider:
       name: opa-ext-authz
     rules:
     - to:
       - operation:
           hosts: ["api.example.com"]
           methods: ["GET"]
           paths: ["/api/users"]
   ```

4. **Validación JWT en OPA**: Cuando una request coincide con las reglas, OPA evalúa:
   - Si el token JWT es válido (firma, emisor, expiración)
   - Si tiene los claims requeridos (configurados en la policy Rego)
   - Si el método HTTP está permitido

5. **Salida**: Genera `authorization-policy-{SERVICE_ID}.yaml` en el `OUTPUT_DIR` y se aplica al namespace `gateways`

## Tipos de Path Matching

### Exact Match
```json
{
  "path": "/api/users",
  "method": "GET"
}
```
Genera:
```yaml
paths:
- "/api/users"
methods: ["GET"]
```

### Path with Parameters (RegularExpression)
```json
{
  "path": "/api/users/:id",
  "method": "GET"
}
```
Genera:
```yaml
# Note: Istio AuthorizationPolicy no soporta regex en paths
# Se usa prefix matching como fallback
paths:
- "/api/users/*"
methods: ["GET"]
```

### Wildcard Prefix
```json
{
  "path": "/api/*",
  "method": "GET"
}
```
Genera:
```yaml
paths:
- "/api/*"
methods: ["GET"]
```

## Ejemplo Completo

### Configuración del Servicio
```json
{
  "publicDomain": "api.example.com",
  "authorization": {
    "enabled": true
  },
  "routes": [
    {
      "method": "GET",
      "path": "/api/config",
      "scope": "config-service"
    },
    {
      "method": "GET",
      "path": "/api/leaderboard",
      "scope": "leaderboard-service"
    },
    {
      "method": "POST",
      "path": "/api/admin/:resource",
      "scope": "admin-service"
    }
  ]
}
```

### AuthorizationPolicy Generado
```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: my-service-123-authz
  namespace: gateways
  labels:
    app.kubernetes.io/name: my-service
    nullplatform.com/service-id: "123"
    nullplatform.com/managed-by: endpoint-exposer
spec:
  # Apply to the Gateway workload (not service pods)
  selector:
    matchLabels:
      gateway.networking.k8s.io/gateway-name: gateway-public
  action: CUSTOM
  provider:
    name: opa-ext-authz
  rules:
  # Rule for: GET /api/config (scope: config-service)
  - to:
    - operation:
        hosts: ["api.example.com"]
        methods: ["GET"]
        paths:
        - "/api/config"

  # Rule for: GET /api/leaderboard (scope: leaderboard-service)
  - to:
    - operation:
        hosts: ["api.example.com"]
        methods: ["GET"]
        paths:
        - "/api/leaderboard"

  # Rule for: POST /api/admin/:resource (scope: admin-service)
  - to:
    - operation:
        hosts: ["api.example.com"]
        methods: ["POST"]
        paths:
        - "/api/admin/*"
```

## Testing

### Generar un JWT de prueba

Puedes usar el JWT de ejemplo de Istio (configurado en la policy OPA):

```bash
TOKEN="eyJhbGciOiJSUzI1NiIsImtpZCI6IkRIRmJwb0lVcXJZOHQyenBBMnFYZkNtcjVWTzVaRXI0UnpIVV8tZW52dlEiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjQ2ODU5ODk3MDAsImZvbyI6ImJhciIsImlhdCI6MTUzMjM4OTcwMCwiaXNzIjoidGVzdGluZ0BzZWN1cmUuaXN0aW8uaW8iLCJzdWIiOiJ0ZXN0aW5nQHNlY3VyZS5pc3Rpby5pbyJ9.CfNW-W_F_zdHuqIzOWOQW7gJQqZzHk3qVHlKx_W4mbQ7QH0pKm9RG6zKnRW-3cjKrxGUWfPwFODNNvqHVNEKCNMDfHO_SbxWc4v2lmYu3qHx_VGQzHU-xVJGqKY4eG4Z0-kJqBGiJPx-kHXW-P3gKcGaZyUQMPZQKIIqLCKWqLGqGcHZGzQ8YZr_Q1F_F6qL_KX6E5_XUZzqCjCKLqvKvZqZWqGqhZYqGkKYqZqZYqGqKY"
```

### Sin token JWT
```bash
curl -X GET https://api.example.com/api/config
# Response: 401 Unauthorized
# Body: "Authorization header required"
```

### Con token JWT válido
```bash
curl -X GET https://api.example.com/api/config \
  -H "Authorization: Bearer $TOKEN"
# Response: 200 OK (si el servicio responde)
# Headers inyectados por OPA: x-user-id, x-validated-by
```

### Con token JWT inválido
```bash
curl -X GET https://api.example.com/api/config \
  -H "Authorization: Bearer invalid-token"
# Response: 401 Unauthorized
# Body: "Invalid or expired token"
```

## Limitaciones

1. **Regex no soportado**: Istio AuthorizationPolicy no soporta expresiones regulares en `paths`. Paths con parámetros (`:id`) se convierten a prefix matching (`/api/users/*`).

2. **Policy global por servicio**: La policy se aplica a nivel Gateway para todas las rutas del servicio. No puedes tener rutas con auth y rutas públicas en el mismo servicio.

3. **Requiere OPA configurado**: Necesitas tener OPA desplegado con el extension provider `opa-ext-authz` configurado en el mesh config de Istio.

4. **No requiere sidecar**: Esta solución aplica autorización a nivel Gateway, por lo que NO necesitas inyectar Istio sidecar en los pods de aplicación.

## Archivos

- `template.yaml.tpl`: Template de gomplate para el recurso AuthorizationPolicy
- `generate`: Script bash que procesa routes y genera el YAML
- `README.md`: Esta documentación
