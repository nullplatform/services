apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ .service_name }}-{{ .service_id }}-public
  namespace: {{ .k8s_namespace }}
  labels:
    nullplatform: "true"
    service: {{ .service_name }}
    service_id: {{ .service_id }}
spec:
  parentRefs:
    - name: {{ .gateway_name }}
      namespace: {{ .gateway_namespace }}
      group: gateway.networking.k8s.io
      kind: Gateway
  hostnames:
    - {{ .public_domain }}
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: response-404
          port: 80
          weight: 0
