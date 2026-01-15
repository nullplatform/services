# Endpoint-Exposer Plugin System

Sistema generalizado de plugins para el servicio endpoint-exposer que permite configurar y ejecutar plugins dinámicamente desde la service specification.

## Descripción

El sistema de plugins permite extender la funcionalidad de endpoint-exposer sin modificar el código del servicio. Los plugins se configuran en la service specification del platform y se ejecutan automáticamente durante los workflows.

## Arquitectura

### Componentes

1. **Plugin Entrypoint** (`plugins/entrypoint`): Script bash que:
   - Lee la service specification desde el platform
   - Itera sobre los plugins configurados
   - Ejecuta cada plugin con sus variables de entorno
   - Maneja errores gracefully sin romper el workflow

2. **Service Specification**: Configuración en el platform que define:
   - Lista de plugins a ejecutar
   - Configuración por plugin (path, ejecutable, env vars)
   - Estado de habilitación de cada plugin

3. **Plugins Externos**: Scripts ejecutables instalados en el sistema que:
   - Implementan funcionalidad específica
   - Reciben contexto via variables de entorno
   - Retornan exit codes para indicar éxito/fallo

## Configuración de Plugins

### Service Specification Format

Los plugins se configuran en la service specification del platform bajo `attributes.schema.plugins`:

```json
{
  "id": "61e26a5e-ba14-4e76-856d-25929c90f0f0",
  "slug": "endpoint-exposer",
  "name": "Endpoint Exposer",
  "type": "dependency",
  "attributes": {
    "schema": {
      "plugins": [
        {
          "name": "authorization-avp",
          "exec": "/entrypoint",
          "plugin_path": "/root/.np/nullplatform/services",
          "enabled": true,
          "environment": {
            "JWT_ISSUER": "https://custom.issuer.com",
            "JWT_ENABLED": "true",
            "LOG_LEVEL": "debug"
          }
        },
        {
          "name": "custom-monitoring",
          "exec": "/run.sh",
          "plugin_path": "/opt/plugins/monitoring",
          "enabled": false,
          "environment": {
            "METRICS_ENDPOINT": "https://metrics.example.com",
            "INTERVAL": "60"
          }
        }
      ],
      "properties": {
        ...
      }
    }
  }
}
```

### Campos de Configuración del Plugin

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `name` | string | Sí | Identificador único del plugin. Se usa para construir el path completo. |
| `exec` | string | Sí | Script ejecutable dentro del directorio del plugin (ej: `/entrypoint`, `/run.sh`). |
| `plugin_path` | string | Sí | Directorio base donde está instalado el plugin. |
| `enabled` | boolean | No (default: true) | Flag para habilitar/deshabilitar el plugin. |
| `environment` | object | No | Variables de entorno específicas del plugin (key-value pairs). |

### Path Resolution

El path completo del ejecutable se construye como:

```bash
PLUGIN_EXECUTABLE="$plugin_path/$name$exec"
```

**Ejemplo:**
- `plugin_path`: `/root/.np/nullplatform/services`
- `name`: `authorization-avp`
- `exec`: `/entrypoint`
- **Resultado**: `/root/.np/nullplatform/services/authorization-avp/entrypoint`

## Integración en Workflows

El plugin entrypoint se ejecuta como un step en los workflows:

```yaml
steps:
  - name: "build context"
    type: script
    file: "$SERVICE_PATH/scripts/istio/build_context"

  - name: "build httproutes"
    type: script
    file: "$SERVICE_PATH/scripts/istio/build_httproute"

  - name: "execute plugins"
    type: script
    file: "$SERVICE_PATH/plugins/entrypoint"  # Plugin execution

  - name: apply
    type: script
    file: "$SERVICE_PATH/scripts/common/apply"
```

**Nota:** El step de plugins debe ejecutarse **antes** del `apply` para que los recursos generados por plugins se apliquen correctamente.

## Flujo de Ejecución

1. **Context Validation**: Verifica que existe la variable `CONTEXT`

2. **Extract Service Spec ID**: Obtiene el ID desde:
   - `.service.specification.id`
   - `.service_specification_id`
   - `.specification.id`

3. **Fetch Service Specification**: Llama a `np service specification read --id $ID --format json`

4. **Extract Plugins Array**: Lee `.attributes.schema.plugins[]`

5. **Iterate Plugins**: Para cada plugin:
   - Verifica si está habilitado (`enabled: true`)
   - Valida que existan `plugin_path` y `exec`
   - Construye path completo del ejecutable
   - Verifica que el archivo existe y es ejecutable
   - Exporta variables de entorno del plugin
   - Ejecuta el plugin
   - Captura exit code y logs

6. **Summary Report**: Muestra resumen de plugins ejecutados/saltados/fallidos

## Comportamiento y Casos de Uso

### Caso 1: Plugin Habilitado y Exitoso

**Input:**
```json
{
  "name": "auth-plugin",
  "plugin_path": "/opt/plugins",
  "exec": "/entrypoint",
  "enabled": true,
  "environment": {
    "JWT_ISSUER": "https://issuer.com"
  }
}
```

**Output:**
```
========================================
Plugin 1/1: auth-plugin
========================================
Status: ENABLED
Executable: /opt/plugins/auth-plugin/entrypoint
Environment variables:
  export JWT_ISSUER='https://issuer.com'

Executing plugin...
----------------------------------------
[plugin output here]
----------------------------------------
Plugin 'auth-plugin' completed successfully (exit code: 0)
```

### Caso 2: Plugin Deshabilitado

**Input:**
```json
{
  "name": "monitoring-plugin",
  "enabled": false,
  ...
}
```

**Output:**
```
========================================
Plugin 1/1: monitoring-plugin
========================================
Status: DISABLED
Skipping plugin 'monitoring-plugin'
```

### Caso 3: Plugin No Encontrado

**Input:**
```json
{
  "name": "missing-plugin",
  "plugin_path": "/opt/does-not-exist",
  "exec": "/run.sh",
  "enabled": true
}
```

**Output:**
```
========================================
Plugin 1/1: missing-plugin
========================================
Status: ENABLED
Executable: /opt/does-not-exist/missing-plugin/run.sh
WARNING: Plugin executable not found at path: /opt/does-not-exist/missing-plugin/run.sh
Skipping plugin 'missing-plugin'
```

**Nota:** El workflow continúa sin fallar.

### Caso 4: Plugin Falla con Error

**Input:** Plugin retorna exit code != 0

**Output:**
```
----------------------------------------
ERROR: Plugin 'failing-plugin' failed with exit code: 1
WARNING: Continuing with remaining plugins despite failure
```

**Nota:** Por diseño, los plugins fallidos no rompen el workflow completo. Esto puede configurarse en el futuro con un flag `fail_on_error`.

### Caso 5: Sin Plugins Configurados

**Input:** Service specification sin `attributes.schema.plugins`

**Output:**
```
No plugins configured in service specification
Path checked: .attributes.schema.plugins

Plugin execution completed (no plugins configured)
```

**Exit Code:** 0 (éxito)

## Variables de Entorno Disponibles

Los plugins tienen acceso a todas las variables de entorno del workflow, incluyendo:

### Variables del Context
- `CONTEXT`: JSON completo del contexto de ejecución
- `SERVICE_ID`, `SERVICE_SLUG`: Información del servicio
- `SCOPE_ID`, `SCOPE_DOMAIN`: Información del scope
- `K8S_NAMESPACE`: Namespace de Kubernetes
- `GATEWAY_NAME`: Nombre del gateway de Istio

### Variables del Workflow
- `ACTION`: Acción del workflow (create/update/delete/apply)
- `OUTPUT_DIR`: Directorio para archivos generados
- `SERVICE_PATH`: Path del servicio

### Variables del Plugin
- Variables definidas en `environment` del plugin en la service specification

## Desarrollo de Plugins

### Estructura Básica de un Plugin

```bash
#!/bin/bash
set -euo pipefail

# 1. Validar variables de entorno requeridas
if [ -z "${REQUIRED_VAR:-}" ]; then
  echo "ERROR: REQUIRED_VAR is not set"
  exit 1
fi

# 2. Leer configuración del CONTEXT
SCOPE_ID=$(echo "$CONTEXT" | jq -r '.scope.id')

# 3. Ejecutar lógica del plugin
echo "Executing plugin logic for scope: $SCOPE_ID"

# 4. Generar outputs (opcional)
OUTPUT_FILE="$OUTPUT_DIR/plugin-output-$SCOPE_ID.yaml"
cat > "$OUTPUT_FILE" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: plugin-config
data:
  key: value
EOF

# 5. Exit con código apropiado
echo "Plugin completed successfully"
exit 0
```

### Buenas Prácticas

1. **Idempotencia**: El plugin debe poder ejecutarse múltiples veces sin efectos secundarios
2. **Error Handling**: Validar inputs y manejar errores gracefully
3. **Logging**: Imprimir logs claros y descriptivos
4. **Exit Codes**: Usar exit 0 para éxito, != 0 para fallo
5. **Context Awareness**: Decidir acciones basadas en `ACTION` (create/update/delete)
6. **Output Files**: Generar archivos en `$OUTPUT_DIR` para que se apliquen con kubectl

### Template Example con Gomplate

```bash
#!/bin/bash
set -euo pipefail

# Construir contexto para template
PLUGIN_CONTEXT_PATH="$OUTPUT_DIR/plugin-context-$SCOPE_ID.json"
echo "$CONTEXT" | jq \
  --arg custom_field "$CUSTOM_VALUE" \
  '. + {custom_field: $custom_field}' > "$PLUGIN_CONTEXT_PATH"

# Renderizar template
PLUGIN_OUTPUT="$OUTPUT_DIR/plugin-resource-$SCOPE_ID.yaml"
gomplate -c .="$PLUGIN_CONTEXT_PATH" \
  --file "$PLUGIN_PATH/templates/resource.yaml.tmpl" \
  --out "$PLUGIN_OUTPUT"

echo "Generated resource: $PLUGIN_OUTPUT"
```

## Testing

### Test Local

```bash
# Setup
export CONTEXT='{"service":{"specification":{"id":"test-spec-id"}}}'
export OUTPUT_DIR="/tmp/test-output"
mkdir -p "$OUTPUT_DIR"

# Mock np CLI para testing
np() {
  cat <<EOF
{
  "id": "test-spec-id",
  "attributes": {
    "schema": {
      "plugins": [
        {
          "name": "test-plugin",
          "exec": "/entrypoint",
          "plugin_path": "/tmp/test-plugin",
          "enabled": true,
          "environment": {
            "TEST_VAR": "test_value"
          }
        }
      ]
    }
  }
}
EOF
}
export -f np

# Ejecutar entrypoint
bash /Users/javisolis/dev/null/services/endpoint-exposer/plugins/entrypoint
```

### Verificación

```bash
# Verificar exit code
echo $?  # Debe ser 0

# Verificar outputs generados
ls -la "$OUTPUT_DIR"

# Verificar logs
# Buscar mensajes de éxito/error en la salida
```

## Troubleshooting

### Plugin No se Ejecuta

1. Verificar que `enabled: true` en service specification
2. Verificar que el path del ejecutable es correcto
3. Verificar que el archivo tiene permisos de ejecución (`chmod +x`)
4. Verificar que todas las variables de entorno requeridas están disponibles

### Plugin Falla

1. Revisar logs del plugin en la salida del workflow
2. Ejecutar plugin manualmente con las mismas variables de entorno
3. Verificar que las dependencias del plugin están instaladas
4. Verificar que el CONTEXT tiene la información necesaria

### Service Specification No se Encuentra

1. Verificar que el CONTEXT incluye `.service.specification.id`
2. Verificar que el comando `np service specification read` funciona
3. Verificar que el usuario tiene permisos para leer la specification

## Mejoras Futuras

Funcionalidades consideradas para implementación futura:

1. **Plugin Versioning**: Soporte para versiones específicas de plugins
2. **Conditional Execution**: Expresiones `enabled_if` para ejecutar plugins solo bajo ciertas condiciones
3. **Plugin Dependencies**: Definir orden de ejecución basado en dependencias entre plugins
4. **Output Capture**: Capturar outputs de plugins y pasarlos a steps subsecuentes
5. **Retry Logic**: Reintentos automáticos para plugins fallidos
6. **Timeout**: Timeout configurable por plugin
7. **Parallel Execution**: Ejecutar plugins independientes en paralelo
8. **Plugin Discovery**: Auto-descubrir plugins en directorios locales
9. **Fail Fast Mode**: Flag `fail_on_error` para detener workflow si un plugin falla

## Compatibilidad

Este sistema es **100% backward compatible**:

- Si no hay plugins configurados, el entrypoint termina exitosamente sin hacer nada
- Los workflows existentes continúan funcionando sin cambios
- Los plugins son opt-in y no afectan el funcionamiento normal del servicio

## Referencias

- [Plan de Implementación](/Users/javisolis/.claude/plans/velvet-brewing-nest.md)
- [Workflow de Create](../workflows/istio/create.yaml)
- [Service Specification Schema](https://docs.nullplatform.com/service-specifications)
