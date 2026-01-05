apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ .service.slug }}-{{ .service.id }}-route-internal
  namespace: {{ .k8s_namespace }}
  labels:
    nullplatform: "true"
    service: {{ .service.slug }}
    service_id: {{ .service.id }}
    visibility: internal
spec:
  parentRefs:
    - name: gateway-public
      namespace: gateways
  hostnames:
    - {{ if has . "parameters" }}{{ if has .parameters "private_domain" }}{{ .parameters.private_domain }}{{ else }}{{ .service.attributes.private_domain }}{{ end }}{{ else }}{{ .service.attributes.private_domain }}{{ end }}
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: response-404F
          port: 80
          weight: 0
