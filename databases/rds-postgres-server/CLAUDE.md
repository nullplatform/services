# rds-postgres-server

## ¿Qué es este servicio?

Servicio de infraestructura de nullplatform que provisiona y administra instancias compartidas de **Amazon RDS PostgreSQL** en AWS. Permite a las aplicaciones obtener bases de datos dedicadas con un simple "link".

## Arquitectura en dos módulos Terraform

| Módulo | Qué provisiona | Cuándo corre |
|---|---|---|
| `deployment/` | La instancia RDS completa (security group, Secrets Manager, RDS, subnet group) | Al crear/actualizar/eliminar el *servicio* |
| `permissions/` | Database + user + grants por aplicación | Al hacer *link* o *unlink* |

### Flujo de vida

```
Service create/update/delete:
  build_context → do_tofu (deployment/) → write_service_outputs

Link/unlink:
  build_context → build_permissions_context → do_tofu (permissions/) → write_link_outputs
```

## Módulo requirements/

Se ejecuta **por instancia de servicio** (no por tipo). Crea el IAM role del servicio con sus policies, y le da al agente permiso explícito para asumirlo:

- `aws_iam_role` `nullplatform-rds-<SERVICE_ID>` — rol del servicio con trust policy hacia el agent role
- `nullplatform_<name>_rds_policy` — gestión de instancias RDS y subnet groups
- `nullplatform_<name>_rds_sg_policy` — security groups EC2
- `nullplatform_<name>_rds_s3_policy` — buckets S3 `np-service-*` (tfstate)
- `nullplatform_<name>_rds_secretsmanager_policy` — ciclo de vida del secret de master password
- `aws_iam_role_policy` `assumerole-rds-<SERVICE_ID>` — inline policy en el agent role que permite `sts:AssumeRole` sobre el ARN exacto del service role

Variables: `name` (requerido), `service_id` (requerido — determina el ARN exacto del service role), `agent_role_name` (requerido — nombre del IAM role del agente).

Output: `service_role_arn`.

## Decisiones de diseño importantes

- **Unlink NO elimina la DB ni el user** — solo revoca grants. Decisión intencional de retención de datos. Re-linkear es idempotente.
- **Username del link** es determinístico: `np_<16-char-link-id>`. La password usa `keepers: { link_id }` para ser estable entre re-applies.
- **Un bucket S3 por instancia** (`np-service-<SERVICE_ID>`) — permite múltiples instancias RDS independientes en la misma cuenta.
- **tfstate del link** se guarda en el mismo bucket que el servicio, bajo un prefix separado.

## Variables de entorno que recibe la app al linkear

`DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD` (secret), `DB_NAME`

## Parámetros configurables

**Servicio:** `instance_class` (db.t3.micro), `allocated_storage` (20 GB), `postgres_version` (14/15/16 — solo en creación)

**Link:** `db_name` (solo en creación), `access_level` (read/write/read-write)

---

## Problema activo: límite de IAM policies por rol (2025-05)

### Contexto

El agente de nullplatform es un pod en EKS con un service account asociado a un IAM role via IRSA (`eks.amazonaws.com/role-arn`). Al configurar cada tipo de servicio se adjuntan las policies del `requirements/` a ese rol de agente.

**El límite de AWS es 10 managed policies por rol** (ampliable a 20 con Service Quota, pero no escala). Con 4 policies por servicio, el límite se alcanza al configurar el tercer servicio.

### Solución diseñada: AssumeRole por servicio

En lugar de adjuntar las policies directamente al rol del agente, cada servicio crea su **propio IAM role** con sus policies. El agente hace `sts:AssumeRole` sobre el rol del servicio antes de ejecutar los scripts.

```
Flujo actual:
  Agent Role ← [rds_policy, rds_sg_policy, rds_sm_policy, rds_s3_policy, ...]
  (acumula policies de todos los servicios → límite AWS)

Flujo propuesto:
  Agent Role ←─ sts:AssumeRole ─→ RDS Service Role
                                    ├─ rds_policy
                                    ├─ rds_sg_policy
                                    ├─ rds_sm_policy
                                    └─ rds_s3_policy
```

### Cambios necesarios por repositorio

**`rds-postgres-server/requirements/`**
- Crear `aws_iam_role` `nullplatform-rds-<SERVICE_ID>` con trust policy que permite AssumeRole desde el agent role
- Adjuntar las 4 policies existentes al nuevo service role (no al agent role)
- Crear `aws_iam_role_policy` `assumerole-rds-<SERVICE_ID>` en el agent role:
  ```hcl
  resource "aws_iam_role_policy" "agent_assumerole" {
    name = "assumerole-rds-${var.service_id}"
    role = var.agent_role_name
    policy = jsonencode({
      Statement = [{
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nullplatform-rds-${var.service_id}"
      }]
    })
  }
  ```
- Variables nuevas: `service_id` (requerida), `agent_role_name` (requerida)
- Eliminar variable `role_name` (ya no se adjunta nada al agent role)
- Agregar output `service_role_arn`
- Al destruir (`tofu destroy`), el inline policy se elimina automáticamente — el agente pierde permiso de asumir ese rol

**`rds-postgres-server/scripts/aws/build_context`**
- Antes de correr Tofu, hacer `aws sts assume-role --role-arn $SERVICE_ROLE_ARN`
- Exportar `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`
- El `SERVICE_ROLE_ARN` se deriva por convención: `arn:aws:iam::<ACCOUNT_ID>:role/nullplatform-rds-<SERVICE_ID>`

**`tofu-modules/nullplatform/agent`**
- Agregar `outputs.tf` con output `iam_role_arn` (expone `var.aws_iam_role_arn`)
- **No se agrega ninguna policy de AssumeRole aquí** — eso lo maneja cada `requirements/` por instancia

**Infra base del agente**
- No requiere cambios de IAM para AssumeRole: los inline policies los crea `requirements/` por cada instancia
- Cada inline policy tiene nombre único `assumerole-rds-<SERVICE_ID>`, no hay riesgo de colisión entre instancias

### Convención de naming para service roles

```
arn:aws:iam::<ACCOUNT_ID>:role/nullplatform-<SERVICE_TYPE>-<SERVICE_ID>
```

Ejemplo: `arn:aws:iam::123456789012:role/nullplatform-rds-svc-abc123`

Esto permite derivar el ARN en `build_context` sin necesidad de guardarlo como atributo del servicio.

### Modelo de seguridad resultante

- El agente **solo puede asumir roles de instancias que fueron explícitamente configuradas** via `requirements/`
- No hay wildcard: cada permiso es `sts:AssumeRole` sobre un ARN exacto
- Los inline policies no cuentan contra el límite de 10 managed policies — pueden crearse ilimitadamente
- El ciclo de vida del permiso está atado al ciclo de vida del servicio: si se destruye `requirements/`, el agente pierde acceso

### Estado

- [ ] Implementar cambios en `requirements/` (service role + inline policy por instancia)
- [ ] Modificar `build_context` para AssumeRole
- [ ] Agregar output al módulo `agent/`
