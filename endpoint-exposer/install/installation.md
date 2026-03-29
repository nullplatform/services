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

> The `repo_path` variable defaults to `/root/.np/nullplatform/services/endpoint-exposer`. Adjust if you clone elsewhere.

### 2. Configure variables

```bash
cd install/tofu
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

| Variable | Required | Description |
|---|---|---|
| `nrn` | ✅ | Nullplatform Resource Name (`organization:account`) |
| `np_api_key` | ✅ | Nullplatform API key |
| `tags_selectors` | ✅ | Tags to select the agent (e.g. `{ environment = "production" }`) |
| `github_token` | ✅ | GitHub token with `contents: read` on `nullplatform/services` |
| `git_branch` | — | Branch to fetch specs from (default: `main`) |
| `repo_path` | — | Path where endpoint-exposer is located on the agent |
| `overrides_enabled` | — | Set `true` to enable config overrides |
| `overrides_repo_path` | — | Full path to the overrides directory on the agent |

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

## Overrides

If the account requires local configuration overrides (e.g. from a networking repo), enable the override flag so the agent appends `--overrides-path` to its command:

```hcl
overrides_enabled   = true
overrides_repo_path = "/root/.np/nullplatform/scopes-networking/endpoint-exposer"
```

This results in the agent running:
```
/root/.np/nullplatform/services/endpoint-exposer/entrypoint \
  --service-path=/root/.np/nullplatform/services/endpoint-exposer \
  --overrides-path=/root/.np/nullplatform/scopes-networking/endpoint-exposer
```

## Updating specs

To push spec changes after editing templates in `specs/`:

1. Merge your branch to `main` (or update `git_branch` in tfvars)
2. Run `tofu apply` — the module fetches templates from GitHub on each run
