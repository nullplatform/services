apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: {{ .service_slug }}-{{ .service_id }}-authz-{{ .suffix }}
  namespace: {{ .gateway_namespace }}
  labels:
    app.kubernetes.io/name: {{ .service_slug }}
    nullplatform.com/service-id: "{{ .service_id }}"
    nullplatform.com/managed-by: endpoint-exposer
spec:
  selector:
    matchLabels:
      gateway.networking.k8s.io/gateway-name: {{ .gateway_name }}
  action: CUSTOM
  provider:
    name: {{ .provider_name }}
  rules:
  - to:
    - operation:
        hosts:
          - {{ .domain }}
        methods:
{{ range .methods }}          - {{ . }}
{{ end }}        paths:
{{ range .paths }}          - {{ . }}
{{ end }}
