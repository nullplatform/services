apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: {{ .service.slug }}-{{ .service.id }}-dns
  namespace: {{ .k8s_namespace }}
  labels:
    nullplatform: "true"
    service: {{ .service.slug }}
    service_id: {{ .service.id }}
spec:
  endpoints:
  - dnsName: {{ if has . "parameters" }}{{ if has .parameters "public_domain" }}{{ .parameters.public_domain }}{{ else if has .parameters "domain" }}{{ .parameters.domain }}{{ else }}{{ .service.attributes.domain }}{{ end }}{{ else }}{{ .service.attributes.domain }}{{ end }}
    recordTTL: 60
    recordType: A
    targets:
    - "{{ .gateway_ip }}"
