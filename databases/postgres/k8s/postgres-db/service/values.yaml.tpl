# Bitnami PostgreSQL Helm chart values
nameOverride: "{{ .projectName }}-postgres"
fullnameOverride: "{{ .projectName }}-postgres"

# Use existing secret for authentication
auth:
  existingSecret: "{{ .projectName }}-postgres-credentials"
  secretKeys:
    adminPasswordKey: "postgres-password"
    userPasswordKey: "password"
  database: "{{ .dbName }}"
  username: "postgres"

global:
  security:
    allowInsecureImages: true

image:
  registry: docker.io
  repository: bitnamisecure/postgresql
  tag: latest

# Persistence configuration
readReplicas:
  persistence:
    enabled: false

primary:
  persistence:
    enabled: false
    size: 10Gi
  
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 256Mi

{{- if .piiEnabled }}
  securityContext:
    enabled: true
    runAsNonRoot: true
    runAsUser: 1001
    fsGroup: 1001
{{- end }}

# Service configuration
service:
  type: ClusterIP
  ports:
    postgresql: 5432

# Common labels
commonLabels:
  usage-type: "{{ .usageType }}"
  pii-enabled: "{{ .piiEnabled }}"

# Metrics (optional)
metrics:
  enabled: false