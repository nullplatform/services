apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: k-8-s-{{ .service.slug }}-{{ .service.id }}-public
  namespace: {{ .k8s_namespace }}
  labels:
    nullplatform: "true"
    service: {{ .service.slug }}
    service_id: {{ .service.id }}
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/group.name: {{ .alb_name }}
    alb.ingress.kubernetes.io/load-balancer-name: {{ .alb_name }}
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80},{"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    alb.ingress.kubernetes.io/actions.response-404: >-
          {"type":"fixed-response","fixedResponseConfig":{"contentType":"text/plain","statusCode":"404","messageBody":"no scopes exposed through this service."}}
spec:
  ingressClassName: alb
  rules:
    - host: {{ .parameters.domain }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: response-404
                port:
                  name: use-annotation