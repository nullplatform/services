# Endpoint Exposer — Agent Prerequisites

## Repositories

The agent pod must have the following repository cloned at the expected path:

| Repository | Default path on agent |
|---|---|
| [nullplatform/services](https://github.com/nullplatform/services) | `/root/.np/nullplatform/services/endpoint-exposer` |

Override the default path via the `repo_path` variable in `terraform.tfvars`.

## Required tooling on the agent pod

- `np` CLI (nullplatform CLI)
- `kubectl`
- `jq`
- `gomplate`

## Kubernetes Access

The agent runs in a Kubernetes pod and must have `kubectl` access to the cluster. The pod's service account must have RBAC permissions to manage HTTPRoute resources in the target namespace.

---

### Required ClusterRole / Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: endpoint-exposer-agent
  namespace: nullplatform   # or the namespace defined in values.yaml K8S_NAMESPACE
rules:
  - apiGroups: ["gateway.networking.k8s.io"]
    resources: ["httproutes"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
```

---

### Gateway API CRDs

The Kubernetes cluster must have the [Gateway API CRDs](https://gateway-api.sigs.k8s.io/guides/#installing-gateway-api) installed:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
```

Verify the CRDs are available:

```bash
kubectl get crd httproutes.gateway.networking.k8s.io
```

---

### Gateway resource

A `Gateway` resource must exist in the cluster for both public and private traffic. The gateway names and namespaces are configured in `values.yaml` (or via the scope's configuration).

## GitHub Token

A GitHub personal access token with `contents: read` permission on the `nullplatform/services` repository is required to fetch spec templates during `tofu apply`.

Set it in `terraform.tfvars` as `github_token`.
