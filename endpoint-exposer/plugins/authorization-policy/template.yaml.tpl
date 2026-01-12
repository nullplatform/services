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
  # Apply to the Gateway workload
  selector:
    matchLabels:
      gateway.networking.k8s.io/gateway-name: {{ .gateway_name }}
  action: CUSTOM
  provider:
    name: {{ .opa_provider }}
  rules:
  {{- range .rules }}
  # Rule for: {{ .method }} {{ .path }} (scope: {{ .scope_slug }})
  - to:
    - operation:
        hosts: ["{{ $.domain }}"]
        {{- if ne .method "" }}
        methods: ["{{ .method }}"]
        {{- end }}
        paths:
        {{- if eq .path_type "Exact" }}
        - "{{ .path }}"
        {{- else if eq .path_type "PathPrefix" }}
        - "{{ .path }}*"
        {{- else if eq .path_type "RegularExpression" }}
        # Regex: {{ .path_regex }}
        # Note: Istio AuthorizationPolicy doesn't support regex in paths
        # Using prefix matching as fallback for regex patterns
        - "{{ .path_prefix }}*"
        {{- end }}
  {{- end }}
