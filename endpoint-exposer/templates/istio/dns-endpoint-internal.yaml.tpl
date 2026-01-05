apiVersion: externaldns.k8s.io/v1alpha1
kind: DNSEndpoint
metadata:
  name: {{ .service.slug }}-{{ .service.id }}-dns-internal
  namespace: {{ .k8s_namespace }}
  labels:
    nullplatform: "true"
    service: {{ .service.slug }}
    service_id: {{ .service.id }}
    visibility: internal
spec:
  endpoints:
  - dnsName: {{ if has . "parameters" }}{{ if has .parameters "private_domain" }}{{ .parameters.private_domain }}{{ else }}{{ .service.attributes.private_domain }}{{ end }}{{ else }}{{ .service.attributes.private_domain }}{{ end }}
    recordTTL: 60
    recordType: A
    targets:
    - "{{ .gateway_ip }}"
