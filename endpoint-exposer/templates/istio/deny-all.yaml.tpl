apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-all-{{ .suffix }}
  namespace: {{ .gateway_namespace }}
  labels:
    nullplatform.com/managed-by: endpoint-exposer
spec:
  selector:
    matchLabels:
      gateway.networking.k8s.io/gateway-name: {{ .gateway_name }}
  action: ALLOW
