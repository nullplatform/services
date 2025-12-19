apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ .service.slug }}-{{ .service.id }}-route
  namespace: {{ .k8s_namespace }}
  labels:
    nullplatform: "true"
    service: {{ .service.slug }}
    service_id: {{ .service.id }}
spec:
  parentRefs:
    - name: gateway-public
      namespace: gateways
  hostnames:
    - {{ if has . "parameters" }}{{ if has .parameters "public_domain" }}{{ .parameters.public_domain }}{{ else if has .parameters "domain" }}{{ .parameters.domain }}{{ else }}{{ .service.attributes.domain }}{{ end }}{{ else }}{{ .service.attributes.domain }}{{ end }}
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: response-404
          port: 80
          weight: 0