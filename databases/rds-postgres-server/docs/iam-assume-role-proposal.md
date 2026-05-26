# Rediseño de permisos IAM del agente nullplatform
## Migración a modelo AssumeRole por servicio

**Fecha:** Mayo 2025  
**Área:** Infraestructura / Plataforma  
**Estado:** Propuesta para aprobación

---

## 1. Contexto

El agente de nullplatform es el componente responsable de ejecutar acciones de infraestructura (provisionar bases de datos, configurar servicios, gestionar permisos, etc.). Corre como un pod en Kubernetes (EKS) y se autentica en AWS mediante **IRSA** (IAM Roles for Service Accounts): el pod tiene un service account asociado a un IAM role de AWS.

Cada tipo de servicio que incorporamos a la plataforma (RDS, caches, colas, etc.) requiere un conjunto de permisos IAM específicos. Actualmente esos permisos se adjuntan **directamente** al rol del agente.

---

## 2. El problema: límite de AWS en managed policies por rol

AWS impone un límite de **10 managed policies por IAM role** (ampliable a 20 mediante una solicitud de Service Quota, pero estructuralmente no escala).

Cada servicio agrega entre 3 y 5 policies al rol del agente. El ritmo de crecimiento es:

```
Servicios configurados    Policies adjuntas    Estado
─────────────────────────────────────────────────────
1 servicio                4 policies           OK
2 servicios               8 policies           OK
3 servicios               12 policies          LÍMITE SUPERADO ✗
```

Este límite **ya está siendo alcanzado** con la incorporación de servicios como RDS PostgreSQL.

---

## 3. El modelo actual vs. el modelo propuesto

### Modelo actual — Rol central compartido

```
┌─────────────────────────────────────────────────────┐
│                    Agent IAM Role                   │
│                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│  │ rds_policy  │  │  s3_policy  │  │  ec2_policy │ │
│  ├─────────────┤  ├─────────────┤  ├─────────────┤ │
│  │ sm_policy   │  │ cache_policy│  │ queue_policy│ │
│  └─────────────┘  └─────────────┘  └─────────────┘ │
│                    ↑ LÍMITE AWS ↑                   │
└─────────────────────────────────────────────────────┘
           │
           │  todas las acciones de AWS
           ▼
    Todos los servicios
```

**Problemas:**
- Acumula permisos de todos los servicios en un solo rol
- Supera el límite de AWS con 3+ servicios
- Si el agente es comprometido, tiene acceso a todo
- Difícil auditar qué permisos corresponden a qué servicio

---

### Modelo propuesto — Rol dedicado por instancia con AssumeRole de ARN exacto

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          Agent IAM Role                                  │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ inline: assumerole-rds-svc-abc123                                │   │
│  │   sts:AssumeRole → arn:aws:iam::123456:role/nullplatform-rds-    │   │
│  │                    svc-abc123  (ARN exacto, sin wildcard)        │   │
│  ├──────────────────────────────────────────────────────────────────┤   │
│  │ inline: assumerole-rds-svc-def456                                │   │
│  │   sts:AssumeRole → arn:aws:iam::123456:role/nullplatform-rds-    │   │
│  │                    svc-def456  (ARN exacto, sin wildcard)        │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│    (1 inline policy por instancia activa — no cuentan contra el límite)  │
└──────────────────────────────────────────────────────────────────────────┘
          │                              │
          │ AssumeRole (ARN exacto)      │ AssumeRole (ARN exacto)
          ▼                              ▼
┌──────────────────────┐     ┌──────────────────────┐
│ nullplatform-rds-    │     │ nullplatform-rds-    │
│ svc-abc123           │     │ svc-def456           │
│ ┌──────────────────┐ │     │ ┌──────────────────┐ │
│ │ rds_policy       │ │     │ │ rds_policy       │ │
│ │ rds_sg_policy    │ │     │ │ rds_sg_policy    │ │
│ │ rds_sm_policy    │ │     │ │ rds_sm_policy    │ │
│ │ rds_s3_policy    │ │     │ │ rds_s3_policy    │ │
│ └──────────────────┘ │     │ └──────────────────┘ │
└──────────────────────┘     └──────────────────────┘
```

**El agente asume el rol correspondiente únicamente durante la ejecución del servicio en cuestión. Solo puede asumir roles de instancias que fueron explícitamente configuradas — no hay wildcards.**

---

## 4. Cómo funciona el flujo de ejecución

```
┌────────────────────────────────────────────────────────────────────┐
│                    Flujo de ejecución propuesto                    │
│                                                                    │
│  1. nullplatform dispara acción (ej: crear base de datos RDS)      │
│                          │                                         │
│                          ▼                                         │
│  2. Agente recibe el evento con contexto del servicio              │
│     (SERVICE_ID, SERVICE_TYPE, parámetros de configuración)        │
│                          │                                         │
│                          ▼                                         │
│  3. build_context deriva el ARN del service role:                  │
│     arn:aws:iam::<ACCOUNT>:role/nullplatform-rds-<SERVICE_ID>      │
│                          │                                         │
│                          ▼                                         │
│  4. aws sts assume-role → credenciales temporales (1h)             │
│     [AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN]  │
│                          │                                         │
│                          ▼                                         │
│  5. tofu apply/destroy corre con las credenciales del service role │
│     (solo tiene acceso a los recursos RDS de este servicio)        │
│                          │                                         │
│                          ▼                                         │
│  6. Credenciales temporales expiran automáticamente                │
└────────────────────────────────────────────────────────────────────┘
```

---

## 5. Beneficios

### 5.1 Escalabilidad sin límites

| | Modelo actual | Modelo propuesto |
|---|---|---|
| Servicios soportados | ~2 (antes de llegar al límite) | Ilimitados |
| Managed policies en el rol del agente | Crece con cada servicio (límite: 10) | **0 managed policies** |
| Inline policies en el rol del agente | 0 | 1 por instancia activa (sin límite de cantidad) |
| Permiso del agente sobre AWS | Wildcard implícito sobre todo | Solo los ARNs exactos de instancias configuradas |
| Requiere solicitud de quota a AWS | Sí (y aún así no escala) | No |

### 5.2 Seguridad — Principio de menor privilegio

**Aislamiento por servicio:** Si el script de un servicio tiene un bug o es explotado, las credenciales temporales obtenidas solo permiten operar sobre los recursos de ese servicio específico. Con el modelo actual, cualquier ejecución tiene acceso a todo.

**Credenciales temporales con expiración automática:** Las credenciales que obtiene el agente via AssumeRole expiran en 1 hora. No hay secretos de larga vida que rotar o que puedan filtrarse de forma persistente.

**Auditoría granular en CloudTrail:** Cada AssumeRole queda registrado con el contexto del servicio. Es posible responder "¿qué acciones de AWS realizó el agente al provisionar el servicio X?" con precisión quirúrgica.

**Blast radius acotado:** Un incidente de seguridad en el agente está contenido al rol asumido en ese momento, no a la totalidad de permisos acumulados.

### 5.3 Operacional

**Independencia de configuración:** Agregar o modificar permisos de un servicio no requiere tocar el rol del agente. Cada equipo puede gestionar los permisos de su servicio de forma independiente.

**Trazabilidad de permisos:** Queda explícito qué permisos necesita cada servicio — están declarados en su propio módulo `requirements/`, no dispersos en un rol central.

---

## 6. Alcance de cambios

La implementación requiere cambios acotados en tres puntos:

### Módulo `requirements/` de cada servicio (ej: `rds-postgres-server`)

Se ejecuta **por instancia de servicio** (recibe `service_id` como variable requerida). Crea:

1. Un IAM role dedicado `nullplatform-rds-<SERVICE_ID>` con trust policy hacia el agent role
2. Las 4 managed policies adjuntas al service role (no al agent role)
3. Un inline policy en el agent role con nombre `assumerole-rds-<SERVICE_ID>` que permite `sts:AssumeRole` **sobre el ARN exacto** de esa instancia:
   ```json
   {
     "Effect": "Allow",
     "Action": "sts:AssumeRole",
     "Resource": "arn:aws:iam::ACCOUNT_ID:role/nullplatform-rds-SERVICE_ID"
   }
   ```

Al destruir (`tofu destroy`), el inline policy se elimina automáticamente — el agente pierde el permiso de asumir ese rol.

Variables nuevas requeridas: `service_id`, `agent_role_name`.

### Script `build_context` de cada servicio
- Agregar 3 líneas para hacer AssumeRole y exportar credenciales temporales antes de correr Tofu
- Sin cambios en la lógica de provisioning

### Módulo `agent/` (tofu-modules)
- Agregar un output que exponga el ARN del rol del agente (ya disponible como variable)
- **No se agrega ninguna inline policy de AssumeRole aquí** — eso lo gestiona cada `requirements/` por instancia

**No hay cambios en:** Helm charts, lógica de workflows, APIs de nullplatform, infraestructura de EKS, ni en cómo se invocan los servicios.

---

## 7. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Sesión AssumeRole expira durante un apply largo | Configurable hasta 12h en el service role; operaciones de RDS típicamente < 20min |
| Complejidad de debugging si AssumeRole falla | El error es explícito ("access denied on assume-role"); fácil de identificar en logs |
| Migración de servicios existentes | Los servicios existentes continúan funcionando hasta que se migre su `requirements/` — no hay corte |
| El agente no puede asumir el rol si `requirements/` no fue ejecutado | Es el comportamiento esperado: el acceso es opt-in por diseño. El error en `build_context` es claro e inmediato |
| Muchas inline policies en el agent role a largo plazo | AWS no impone límite práctico en inline policies; además se limpian solas al destruir el servicio |

---

## 8. Próximos pasos

1. Implementar el cambio en `rds-postgres-server` como servicio piloto
2. Validar en entorno de staging que el flujo completo (create → link → unlink → delete) funcione correctamente
3. Replicar el patrón en los demás servicios en orden de incorporación
4. Actualizar la documentación del módulo `requirements/` como estándar para futuros servicios

---

*El cambio no es disruptivo: es completamente retrocompatible y puede migrarse servicio por servicio sin downtime.*
