apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: {{ .service_slug }}-{{ .service_id }}-authz-private
  namespace: gateways
  labels:
    app.kubernetes.io/name: {{ .service_slug }}
    nullplatform.com/service-id: "{{ .service_id }}"
    nullplatform.com/managed-by: endpoint-exposer
spec:
  # Apply to the private Gateway workload
  selector:
    matchLabels:
      gateway.networking.k8s.io/gateway-name: gateway-private
  action: CUSTOM
  provider:
    name: opa-ext-authz
  rules:
  {{- range .rules }}
  # Rule for: {{ .method }} {{ .path }} (scope: {{ .scope_slug }})
  - to:
    - operation:
        hosts: ["{{ $.private_domain }}"]
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
