# Endpoint Exposer — Installation Guide

This guide walks through registering the Endpoint Exposer service in nullplatform using OpenTofu.

## Overview

The installation process creates:
- A **service specification** (the form developers fill in to configure HTTP routes)
- **Action specifications** (read, create, update, delete)
- A **notification channel** (connects nullplatform events to the agent)

## Prerequisites

See [prerequisites.md](./prerequisites.md) for agent setup, Kubernetes permissions, and required repositories.

## Steps

### 1. Clone required repositories

```bash
git clone https://github.com/nullplatform/services /root/.np/nullplatform/services
git clone https://github.com/nullplatform/tofu-modules /root/.np/nullplatform/tofu-modules
```

> The agent cmdline resolves to `<base_clone_path>/<repository_org>/<repository_name>/<agent_service_path>/entrypoint/entrypoint`, which defaults to `/root/.np/nullplatform/services/endpoint-exposer/entrypoint/entrypoint`. Adjust the variables if you clone elsewhere.

### 2. Configure variables

```bash
cd install/tofu
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

| Variable | Required | Description |
|---|---|---|
| `nrn` | ✅ | Nullplatform Resource Name (`organization=<org-id>:account=<account-id>`) |
| `np_api_key` | ✅ | Nullplatform API key used by the agent |
| `tags_selectors` | ✅ | Tags to select the agent (e.g. `{ environment = "production" }`) |
| `github_token` | — | Only required if `repository_org`/`repository_name` point at a private fork. Not needed for the public `nullplatform/services` repo. |
| `repository_org` | — | Org that owns the spec repository (default: `nullplatform`) |
| `repository_name` | — | Spec repository name (default: `services`) |
| `repository_branch` | — | Branch to fetch specs from (default: `main`) |
| `spec_path` | — | In-repo path to `specs/service-spec.json.tpl` (default: `endpoint-exposer/install`) |
| `agent_service_path` | — | In-repo path where the agent runtime lives (default: `endpoint-exposer`) |
| `service_name` | — | Display name in nullplatform (default: `Endpoint Exposer`) |
| `overrides_enabled` | — | Set `true` to pass `--overrides-path` to the agent |
| `overrides_repo_path` | — | Absolute path to the overrides directory on the agent (required when `overrides_enabled = true`) |

### 3. Initialize OpenTofu

```bash
tofu init \
  -backend-config="bucket=<your-state-bucket>" \
  -backend-config="region=<aws-region>"
```

### 4. Plan and apply

```bash
tofu plan
tofu apply
```

## Domains

The `publicDomain` / `privateDomain` fields in the service spec are free-text strings. Developers type the concrete FQDN at scope-creation time (via the nullplatform UI, CLI, or API). The base domain must resolve to the appropriate Istio gateway in the target cluster (public or private).

## Overrides

If the account requires local configuration overrides (e.g. from a networking repo), enable the override flag so the agent receives `--overrides-path` as an argument:

```hcl
overrides_enabled   = true
overrides_repo_path = "/root/.np/nullplatform/scopes-networking/endpoint-exposer"
```

The agent cmdline becomes:
```
/root/.np/nullplatform/services/endpoint-exposer/entrypoint/entrypoint \
  --overrides-path=/root/.np/nullplatform/scopes-networking/endpoint-exposer
```

## Updating specs

To push spec changes after editing templates in `install/specs/`:

1. Merge your branch to `main` (or update `repository_branch` in tfvars)
2. Run `tofu apply` — the module fetches templates from GitHub on each run
