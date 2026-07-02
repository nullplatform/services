# RDS Postgres AssumeRole — runtime wiring

**Date:** 2026-07-02
**Status:** Approved for planning
**Extends:** `docs/superpowers/specs/2026-07-02-rds-postgres-assume-role-design.md`

## 1. Context

The previous spec/plan created a dedicated per-cluster IAM role for
`rds-postgres-server` and `rds-postgres-db`, each with a trust policy naming
the nullplatform agent role as the only principal allowed to
`sts:AssumeRole` on it. It explicitly left two things out of scope:

1. Granting the agent itself permission to call `sts:AssumeRole` on those
   roles. **Done manually** (out-of-band, not in this repo): an inline
   policy `assume-rds-postgres-roles` on `nullplatform-api-private-agent-role`
   in AWS account `235494813897`, granting `sts:AssumeRole` on both role
   ARNs.
2. Actually calling `sts:AssumeRole` at runtime and running the rest of the
   workflow (`build_context`, `do_tofu`, etc.) under the assumed role's
   credentials instead of the agent's own.

This spec covers (2): the runtime wiring, mirroring the mechanism already
implemented and proven in `nullplatform/scopes-static-files`
(`static-files/utils/assume_role`, `assume_role_lib`, `assume_role_step`).

## 2. How the reference mechanism works

`scopes-static-files` resolves and assumes its role via three scripts under
`static-files/utils/`:

- **`assume_role_lib`** — pure helpers, no side effects. `resolve_assume_role_arn`
  picks the ARN to assume with this precedence: (1) an explicit env var
  override, (2) the AWS IAM provider entry (category `identity-access-control`,
  already dimension-resolved by the platform into `CONTEXT.providers[...]`)
  matching a selector, (3) a per-account default env var. Empty result means
  "use the agent's own credentials."
- **`assume_role`** — sourceable script. If the resolved ARN is non-empty,
  calls `aws sts assume-role` and exports `AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`. If empty, no-ops.
- **`assume_role_step`** — the actual workflow step. Reads
  `CONTEXT.providers["identity-access-control"]`, resolves the ARN via
  `assume_role_lib`, sources `assume_role`. Runs **first**, before any other
  AWS-touching step, in every AWS workflow.

The AWS IAM provider itself is a `nullplatform_provider_config` resource
(type `aws-iam-configuration`), created via the
`tofu-modules/nullplatform/identity-access-control` module, with
`attributes.iam_role_arns.arns = [{ selector, arn }, ...]` — one entry per
scope/service that needs a distinct role.

## 3. Scope

**In scope**, duplicated identically for `rds-postgres-server` and
`rds-postgres-db` (confirmed: no shared-scripts mechanism exists between
these two service folders today, and none is being introduced — matches how
`build_context`/`do_tofu` are already duplicated, not shared):

- Three new scripts per service under `scripts/aws/`: `assume_role_lib`,
  `assume_role`, `assume_role_step`, ported from
  `scopes-static-files/static-files/utils/` with names adapted (see below).
- A new first step, `assume role`, added to all 5 AWS-touching workflows per
  service (`create.yaml`, `update.yaml`, `delete.yaml`, `link.yaml`,
  `unlink.yaml` — 10 files total), before the existing `build context` step
  (which itself makes AWS calls — S3 bucket create/head — so assume-role
  must run before it, not just before `do_tofu`).
- `provider_categories: [identity-access-control]` added to each service's
  `values.yaml` (neither has any `provider_categories` key today).
- **Testing only**, in `PAE/services-testing` (not the `services` repo): a
  `module "identity_access_control"` registering both role ARNs (already
  created and confirmed via `tofu apply` — see prior spec) under selectors
  `rds-postgres-server` / `rds-postgres-db`, so the mechanism has something
  real to resolve if a workflow is ever run against this test account.

**Out of scope:**
- Actually executing a live workflow (`create`, etc.) to prove the full loop
  end-to-end — would provision a real RDS instance (cost, VPC dependency).
  Confirmed with the user: code + provider registration only, no live run
  this round.
- Any change to what `build_context` / `do_tofu` / other existing scripts
  actually do — they keep making the same AWS calls, just now authenticated
  as the assumed role instead of the agent's own credentials.
- Changing the manually-applied agent inline policy — already done and
  correct for both role ARNs.

## 4. Design

### Naming (both services, substituting the service name)

- Selector: full service name — `"rds-postgres-server"` / `"rds-postgres-db"`.
- Override env var: `RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN` /
  `RDS_POSTGRES_DB_ASSUME_ROLE_ARN` (analogous to
  `STATIC_FILES_ASSUME_ROLE_ARN`).
- Default-fallback env var: `RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN_DEFAULT` /
  `RDS_POSTGRES_DB_ASSUME_ROLE_ARN_DEFAULT` (analogous to
  `STATIC_FILES_ASSUME_ROLE_ARN_DEFAULT`).
- Session name prefix in the `sts assume-role` call: `np-rds-postgres-server-`
  / `np-rds-postgres-db-` (analogous to `np-static-files-`), suffixed with
  `${SERVICE_ID:-workflow}`.

### `scripts/aws/assume_role_lib` (per service)

Direct port of `static-files/utils/assume_role_lib`, renaming the env vars
per the naming section above. No other logic changes — `arn_for_selector`
and `resolve_assume_role_arn` are generic (they take the selector as a
parameter already).

### `scripts/aws/assume_role` (per service)

Direct port of `static-files/utils/assume_role`, renaming
`STATIC_FILES_ASSUME_ROLE_ARN` to the per-service env var name and the
session-name prefix. Same behavior: assumes the role and exports the 3
`AWS_*` variables if an ARN was resolved; no-ops (agent credentials apply)
otherwise; returns non-zero only if `sts:AssumeRole` itself fails.

### `scripts/aws/assume_role_step` (per service)

Direct port of `static-files/utils/assume_role_step`, with:
- `STATIC_FILES_ASSUME_ROLE_SELECTOR` default changed to the service's full
  name.
- Sources the per-service `assume_role_lib` and `assume_role` (same
  directory, `scripts/aws/`).
- Same error message and exit-1 behavior on `sts:AssumeRole` failure.

### Workflow YAML wiring (10 files: 5 workflows × 2 services)

Every one of `create.yaml`, `update.yaml`, `delete.yaml`, `link.yaml`,
`unlink.yaml` in both `databases/rds-postgres-server/workflows/aws/` and
`databases/rds-postgres-db/workflows/aws/` gets this step prepended before
the existing first step (`build context`):

```yaml
  - name: assume role
    type: script
    file: $SERVICE_PATH/scripts/aws/assume_role_step
    output:
      - name: AWS_ACCESS_KEY_ID
        type: environment
      - name: AWS_SECRET_ACCESS_KEY
        type: environment
      - name: AWS_SESSION_TOKEN
        type: environment
```

No other step in any workflow needs its own `output` block changed — the
engine's `output: type: environment` mechanism (already used by `build
context` for `REGION`, etc., in these same files) makes exported variables
available to every later step in the same workflow run, not just the next
one.

### `values.yaml` addition (both services)

Append to each service's `values.yaml`:
```yaml
provider_categories:
  - identity-access-control
```

### Testing-only: `PAE/services-testing/main.tf`

```hcl
module "identity_access_control" {
  source = "git::https://github.com/nullplatform/tofu-modules.git//nullplatform/identity-access-control?ref=v5.1.0"

  nrn = var.nrn
  attributes = {
    iam_role_arns = {
      arns = [
        { selector = "rds-postgres-server", arn = module.service_requirements_rds_postgres_server.permissions_role_arn },
        { selector = "rds-postgres-db", arn = module.service_requirements_rds_postgres_db.permissions_role_arn },
      ]
    }
  }
}
```

`?ref=v5.1.0` matches the version already used for this same module in
`testing-static-scope` (the analogous consuming stack for the static-files
scope).

## 5. Testing / validation

Same constraints as the prior spec — no CI, no test harness for Terraform or
bash scripts in this repo. Validation for this change:
- `tofu init -backend=false && tofu validate` is not applicable here (no new
  Terraform in the `services` repo itself — only bash scripts and YAML).
- Bash scripts: `bash -n <script>` (syntax check) at minimum for each new
  script; manual read-through comparing against the `static-files` original
  line-by-line for the renamed identifiers.
- YAML: each modified workflow file should parse as valid YAML (e.g.
  `python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))"` or
  equivalent) and the new step block should match the exact shape of the
  existing `build context` step's `output` block.
- `PAE/services-testing`: `tofu init -upgrade && tofu validate`, then
  `AWS_PROFILE=providers-test tofu plan` to confirm the new
  `identity_access_control` module resolves correctly and only adds the one
  new resource (`nullplatform_provider_config`) with no changes to existing
  resources. **Apply is out of scope for this session** unless explicitly
  requested again, same as the rest of this real-account work.

## 6. Open follow-ups (not part of this change)

- Actually running a live `create` workflow end-to-end to prove the full
  chain (agent → assume-role → temporary credentials → `tofu apply` under
  the target role) — deferred, real-cost action.
- Whether `write_service_outputs`, `write_link_outputs`,
  `delete_tfstate_bucket`, and `build_permissions_context` need any changes
  — they don't call `sts:AssumeRole` themselves, and they run after `assume
  role` in the same workflow, so they inherit the assumed credentials
  automatically. No code changes anticipated, but worth double-checking
  during implementation that none of them independently reference
  `AWS_PROFILE` or other credential sources that could bypass the assumed
  role.
