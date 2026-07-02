# AssumeRole IAM scaffolding for rds-postgres-server and rds-postgres-db

**Date:** 2026-07-02
**Status:** Approved for planning

## 1. Context

The nullplatform agent runs in EKS and authenticates to AWS via IRSA. Today,
`rds-postgres-server/requirements/` creates managed IAM policies and attaches
them **directly to an externally supplied role** (via the `role_name`
variable) — in practice, the agent's own role. AWS caps managed policies per
role at 10; each service adds ~3-5, which doesn't scale.

The reference for the fix is `nullplatform/scopes-static-files`
(`static-files/requirements/aws`): a dedicated **permissions role** holds a
scope's policies, with a trust policy naming the agent's role as the only
principal allowed to `sts:AssumeRole` on it. The module creates the role and
outputs its ARN; it does **not** touch the agent's own role or permissions —
granting the agent itself permission to call `AssumeRole` on this ARN is
handled entirely outside the module (per its README: wired into the agent's
own `assume_role_arns`, by whatever stack composes agent + scope modules
together).

This is the only source of truth for this design — an earlier internal
proposal (branch `feature/iam-assumerone-rds`, doc
`databases/rds-postgres-server/docs/iam-assume-role-proposal.md`) explored a
different, per-service-instance shape, but was superseded and is **not**
used here.

We replicate the reference's mechanism for two of our own modules, using
`cluster_name` as the identifying variable — same role it plays in the
reference. (Note: the current `rds-postgres-server` variable `name`, example
value `"prod-us-east-1"`, already reads as a cluster/environment identifier,
so renaming it to `cluster_name` is a closer fit to its original intent.)

## 2. Scope

This work touches **only** two folders:

- `databases/rds-postgres-server/requirements/` (existing, modified)
- `databases/rds-postgres-db/requirements/` (new)

**In scope:** the AssumeRole mechanics — creating each module's dedicated IAM
role and trust policy, and outputting its ARN — plus attaching each service's
already-documented minimal permissions to that role (existing 4 policies for
`rds-postgres-server`, one new Secrets Manager policy for `rds-postgres-db`).

**Out of scope (explicitly, "otro paso"):**
- Any change to `build_context` or other entrypoint scripts that would
  actually call `aws sts assume-role` at runtime and export temporary
  credentials.
- Granting the agent permission to assume these roles (wiring their ARNs into
  the agent's own `assume_role_arns` or equivalent) — done centrally, outside
  either module, per the reference architecture.
- Defining infrastructure-permission policies **beyond what each service's
  README already documents as required**. `rds-postgres-server` keeps its 4
  existing policies (RDS, EC2/SG, Secrets Manager, S3) untouched in content —
  they're just re-attached to the new role instead of an externally supplied
  `role_name`. `rds-postgres-db` gets exactly one new policy — the
  `secretsmanager:GetSecretValue` permission its README already documents as
  needed — attached to its new role; nothing beyond that minimal, already-
  documented requirement.

## 3. Design

### Common pattern (both modules)

New variables (mirroring the reference):
- `cluster_name` (string, required) — identifies the cluster; drives the
  role's default name and the default agent role ARN.
- `agent_role_arn` (string, optional, default `""`) — override for the agent
  role ARN when it doesn't follow the `nullplatform-<cluster_name>-agent-role`
  convention. Same validation regex as the reference
  (`^arn:aws:iam::[0-9]{12}:role/.+`).
- `additional_agent_role_arns` (list(string), optional, default `[]`) — extra
  trusted principals, appended to `agent_role_arn` in the trust policy. Same
  validation as the reference.
- `role_name` (string, optional, default `""`) — override for the generated
  role name.
- `iam_create_role` (bool, optional, default `true`) — when false, the module
  creates nothing (matches the reference's escape hatch).
- `iam_resource_tags_json` (map(string), optional, default `{}`) — tags
  applied to the role.

New `data.tf`:
```hcl
data "aws_caller_identity" "current" {}
```

New `locals.tf`:
```hcl
locals {
  iam_module_name = "requirements-<service>"
  iam_create      = var.iam_create_role

  role_name      = var.role_name != "" ? var.role_name : "nullplatform-${var.cluster_name}-<service>-role"
  agent_role_arn = var.agent_role_arn != "" ? var.agent_role_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nullplatform-${var.cluster_name}-agent-role"

  iam_default_tags = merge(var.iam_resource_tags_json, {
    ManagedBy = "<service>"
    Module    = local.iam_module_name
  })
}
```
(`<service>` is the full service name — `rds-postgres-server` or
`rds-postgres-db` — not an abbreviation, so names stay unambiguous if another
RDS engine (e.g. `rds-mysql-server`) is added later. Concretely:
`iam_module_name = "requirements-rds-postgres-server"` /
`"requirements-rds-postgres-db"`, and `role_name` defaults to
`"nullplatform-${var.cluster_name}-rds-postgres-server-role"` /
`"...-rds-postgres-db-role"`. All AWS-side `name` values use hyphens
uniformly, including the 4 existing `rds-postgres-server` policies, which
currently use underscores — see "rds-postgres-server specifics" below.)

`main.tf` addition, both modules — the target role and trust policy (policy
attachments are module-specific, covered below):
```hcl
resource "aws_iam_role" "nullplatform_<service>" {
  count = local.iam_create ? 1 : 0

  name        = local.role_name
  description = "Permissions role assumed by the nullplatform agent role for <service> in cluster ${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = concat([local.agent_role_arn], var.additional_agent_role_arns) }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.iam_default_tags
}
```
(HCL resource **labels** use underscores per normal convention — concretely
`aws_iam_role.nullplatform_rds_postgres_server` and
`aws_iam_role.nullplatform_rds_postgres_db` — while the `name` attribute
value, which AWS sees, is the hyphenated `local.role_name`.)

**Deviation from the reference:** the reference hardcodes `ManagedBy` to the
generic constant `"nullplatform-custom-scope-role"`. Here, `ManagedBy` is the
name of the service folder that actually creates and owns the resource —
`"rds-postgres-server"` or `"rds-postgres-db"` — a literal specific to each
module, same as `iam_module_name` already is. `Module` stays as the more
specific `requirements-<service>` identifier for the exact submodule.

New `versions.tf` (both modules, matching the reference — these modules have
no `providers.tf`/`backend.tf` today, they're consumed as modules by another
stack, same as `scopes-static-files`):
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

`output.tf` additions, both modules (naming matches the reference):
`permissions_role_arn`, `permissions_role_name`, `permissions_role_id` —
each `local.iam_create ? aws_iam_role.nullplatform_rds_postgres_server[0].<attr> : ""`
(or `..._rds_postgres_db[0]` in the other module).

### rds-postgres-server specifics

- `variables.tf`: rename `name` → `cluster_name` (module has no live state
  anywhere — confirmed safe, no deploy/import concerns); drop `role_name`'s
  old meaning (previously nullable, pointed at an externally managed role) —
  `role_name` is repurposed as the reference's override variable (see common
  pattern above); add `agent_role_arn`, `additional_agent_role_arns`,
  `iam_create_role`, `iam_resource_tags_json`.
- `main.tf`: the 4 existing `aws_iam_policy` resources get their `name`
  changed to the hyphenated convention and re-keyed on `cluster_name` — no
  content (Statement) changes:
  - `nullplatform_${var.name}_rds_policy` → `nullplatform-${var.cluster_name}-rds-policy`
  - `nullplatform_${var.name}_rds_sg_policy` → `nullplatform-${var.cluster_name}-rds-sg-policy`
  - `nullplatform_${var.name}_rds_secretsmanager_policy` → `nullplatform-${var.cluster_name}-rds-secretsmanager-policy`
  - `nullplatform_${var.name}_rds_s3_policy` → `nullplatform-${var.cluster_name}-rds-s3-policy`

  The 4 `aws_iam_role_policy_attachment` resources change their `count` from
  `var.role_name != null ? 1 : 0` to `local.iam_create ? 1 : 0`, and attach to
  `aws_iam_role.nullplatform_rds_postgres_server[0].name`.
- `output.tf`: keep the 4 existing policy ARN outputs, add the 3 new
  `permissions_role_*` outputs.

### rds-postgres-db specifics

- Brand-new `requirements/` folder: `data.tf`, `locals.tf`, `main.tf`,
  `variables.tf`, `output.tf`, `versions.tf` — the common pattern above, plus
  one policy:
  ```hcl
  resource "aws_iam_policy" "nullplatform_rds_postgres_db_secretsmanager_policy" {
    count       = local.iam_create ? 1 : 0
    name        = "nullplatform-${var.cluster_name}-rds-postgres-db-secretsmanager-policy"
    description = "Policy for reading the RDS master password from Secrets Manager"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:nullplatform/rds/*"
      }]
    })
  }

  resource "aws_iam_role_policy_attachment" "rds_postgres_db_secretsmanager" {
    count      = local.iam_create ? 1 : 0
    role       = aws_iam_role.nullplatform_rds_postgres_db[0].name
    policy_arn = aws_iam_policy.nullplatform_rds_postgres_db_secretsmanager_policy[0].arn
  }
  ```
  The resource is scoped to the `nullplatform/rds/*` secret-name prefix that
  `rds-postgres-server`'s `deployment/main.tf` actually uses
  (`name = "nullplatform/rds/${var.instance_name}/master"`) and to this
  account, instead of `*`. Region is left wildcarded since RDS instances
  aren't pinned to one region across the fleet; the trailing `*` after the
  secret name is required because Secrets Manager appends a random suffix to
  the full ARN that isn't knowable ahead of time. This is intentionally
  tighter than `rds-postgres-server`'s own existing Secrets Manager policy
  (still `Resource = "*"`, untouched since it's out of scope), but there's no
  reason to carry that permissiveness into a brand-new policy when we know
  the exact naming convention.

  The policy name uses the full `rds-postgres-db` service name rather than
  the bare `rds-*` pattern `rds-postgres-server`'s policies use — both
  services can be deployed against the same `cluster_name`, and
  `rds-postgres-server` already owns
  `nullplatform-<cluster_name>-rds-secretsmanager-policy` for its own
  (different, full-CRUD) Secrets Manager policy. Reusing that name for
  `rds-postgres-db`'s policy collides in IAM (policy names are account-wide
  unique) — confirmed by an actual `tofu apply` against a real AWS account
  with both modules deployed together, which is exactly the kind of
  cross-module collision `tofu validate` run per-module can't catch.
- `output.tf`: add a `secretsmanager_policy_arn` output alongside the 3
  `permissions_role_*` outputs, mirroring `rds-postgres-server`'s existing
  `rds_secretsmanager_policy_arn` output.

### Documentation

- `databases/rds-postgres-server/README.md`: update the existing "AWS IAM
  Permissions" section to mention the dedicated role and the
  `cluster_name`/`agent_role_arn` variables.
- `databases/rds-postgres-db/README.md`: add a short "AWS IAM Permissions"
  subsection under "Requirements" pointing at the new `requirements/` module
  (mirroring how `rds-postgres-server`'s README already does this), noting it
  creates the dedicated role and the `secretsmanager:GetSecretValue` policy.

## 4. Testing / validation

Neither module has a test harness or CI pipeline in this repo. Validation for
this change is:
- `tofu validate` (or `terraform validate`) in each `requirements/` folder —
  catches syntax errors and invalid references without needing AWS
  credentials.
- Manual review of the rendered `jsonencode(...)` trust policy document for
  correctness (principal, action).

A live `tofu plan`/`apply` isn't feasible here since these modules have no
backend/provider config of their own (they're consumed by another stack) and
we have no target AWS account in this session.

## 5. Open follow-ups (not part of this change)

- Grant the agent permission to actually assume these new roles — add their
  ARNs to the agent's own `assume_role_arns` (or equivalent), wired by
  whatever stack composes the agent and these service modules together.
- Wire `build_context` (or equivalent) in each service's entrypoint to call
  `sts assume-role` using the new role's ARN output and export temporary
  credentials before `tofu apply`.
- Decide where `cluster_name` and `agent_role_arn` actually get sourced from
  when these modules are invoked (presumably the consuming stack/pipeline
  already knows the cluster it's deploying into).
