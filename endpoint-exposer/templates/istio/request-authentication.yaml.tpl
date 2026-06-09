apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: cognito-jwt-{{ .suffix }}
  namespace: {{ .gateway_namespace }}
  labels:
    nullplatform.com/managed-by: endpoint-exposer
spec:
  selector:
    matchLabels:
      gateway.networking.k8s.io/gateway-name: {{ .gateway_name }}
  jwtRules:
    - issuer: {{ .issuer }}
      jwksUri: {{ .jwks_uri }}
