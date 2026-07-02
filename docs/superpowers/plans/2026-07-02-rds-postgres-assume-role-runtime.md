# RDS Postgres AssumeRole Runtime Wiring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `rds-postgres-server` and `rds-postgres-db` actually assume their dedicated IAM roles at runtime — porting the `assume_role`/`assume_role_lib`/`assume_role_step` mechanism already proven in `nullplatform/scopes-static-files`, wiring it as the first step of every AWS-touching workflow, and (for testing only) registering the two real role ARNs as an `identity-access-control` provider in the sandbox nullplatform account.

**Architecture:** Each service gets its own copy (no sharing between services — matches how `build_context`/`do_tofu` are already duplicated) of three scripts under `scripts/aws/`: a pure ARN-resolution library, a credential-exchange script, and the workflow step that ties them together. The step is prepended to every workflow YAML so all later steps in that same run inherit the assumed role's temporary credentials via the engine's existing `output: type: environment` propagation.

**Tech Stack:** Bash, YAML (nullplatform workflow steps), OpenTofu (only for the testing-stack provider registration).

**Design spec:** `docs/superpowers/specs/2026-07-02-rds-postgres-assume-role-runtime-design.md`

## Global Constraints

- Scripts are duplicated per service (`rds-postgres-server`, `rds-postgres-db`) — no shared-scripts mechanism is introduced.
- Selector = the full service name: `"rds-postgres-server"` / `"rds-postgres-db"`.
- Override env var: `RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN` / `RDS_POSTGRES_DB_ASSUME_ROLE_ARN`. Default-fallback env var: `RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN_DEFAULT` / `RDS_POSTGRES_DB_ASSUME_ROLE_ARN_DEFAULT`.
- STS session-name prefix: `np-rds-postgres-server-` / `np-rds-postgres-db-`, suffixed with `${SERVICE_ID:-workflow}`.
- The new `assume role` step goes **first** in every workflow, before `build context` (which itself makes AWS calls).
- No change to what `build_context`/`do_tofu`/other existing scripts do — only which credentials they run under.
- No live workflow execution (e.g. an actual `create`) as part of this plan — code and provider registration only.
- No change to the manually-applied agent inline policy (`assume-rds-postgres-roles` on `nullplatform-api-private-agent-role`) — already correct.

---

### Task 1: `rds-postgres-server` — assume-role scripts + workflow wiring

**Files:**
- Create: `databases/rds-postgres-server/scripts/aws/assume_role_lib`
- Create: `databases/rds-postgres-server/scripts/aws/assume_role`
- Create: `databases/rds-postgres-server/scripts/aws/assume_role_step`
- Modify: `databases/rds-postgres-server/workflows/aws/create.yaml`
- Modify: `databases/rds-postgres-server/workflows/aws/update.yaml`
- Modify: `databases/rds-postgres-server/workflows/aws/delete.yaml`
- Modify: `databases/rds-postgres-server/workflows/aws/link.yaml`
- Modify: `databases/rds-postgres-server/workflows/aws/unlink.yaml`
- Modify: `databases/rds-postgres-server/values.yaml`

**Interfaces:**
- Produces: after this task, every `rds-postgres-server` AWS workflow starts by running `scripts/aws/assume_role_step`, which — if a role ARN resolves — exports `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` for every later step in the same workflow run (via the workflow engine's `output: type: environment`, the same mechanism `build context` already uses for `REGION` etc. in these same files). Task 2 does not depend on this — it's an independent, mirrored implementation for the sibling service.

- [ ] **Step 1: Create `scripts/aws/assume_role_lib`**

```bash
#!/bin/bash
# Sourceable library of PURE helpers for assume-role resolution.
#
# Input is the AWS IAM provider exactly as it appears in
# CONTEXT.providers["identity-access-control"] — the platform already resolved it
# for the service's dimensions (most-specific config whose dimensions are a subset
# of the service's wins). These helpers only pick the selector, so they make NO
# np/aws calls and have no side effects on source — fully unit-testable.
#
# Requires (at call time): jq.

# arn_for_selector <iam_provider_attributes_json> <selector>
# Given CONTEXT.providers["identity-access-control"], echoes the ARN whose entry
# in .iam_role_arns.arns[] matches <selector>, or "" if none. First match wins.
# Returns "" on empty/malformed input (never crashes).
arn_for_selector() {
  local json="$1" selector="$2"
  [ -n "$json" ] || return 0
  [ -n "$selector" ] || return 0
  printf '%s' "$json" | jq -r --arg sel "$selector" '
    [ .iam_role_arns.arns[]?
      | select(.selector == $sel)
      | .arn ]
    | first // ""' 2>/dev/null || true
}

# resolve_assume_role_arn <iam_provider_json> <selector>
# Echoes the ARN to assume ("" = use agent credentials):
#   1. $RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN env var (explicit override)
#   2. AWS IAM provider entry matching <selector> (already dimension-resolved
#      by the platform via CONTEXT.providers["identity-access-control"])
#   3. $RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN_DEFAULT env var (per-account agent default)
# Note: RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN="" (explicitly empty) is treated the same as
# unset — the chain continues to the next source.
resolve_assume_role_arn() {
  local iam_json="$1" selector="$2" arn=""

  arn="${RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN:-}"

  if [ -z "$arn" ] && [ -n "$iam_json" ] && [ -n "$selector" ]; then
    arn=$(arn_for_selector "$iam_json" "$selector")
  fi

  arn="${arn:-${RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN_DEFAULT:-}}"
  printf '%s' "$arn"
}
```

- [ ] **Step 2: Create `scripts/aws/assume_role`**

```bash
#!/bin/bash
# Sourceable helper — do NOT execute directly.
# Reads RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN from the environment. If set, calls
# sts:AssumeRole and exports temporary credentials so all subsequent AWS calls
# (including tofu) use that role. If empty, does nothing — the agent's
# credentials (pod IRSA) handle auth.
#
# Requires: aws CLI, jq.
# Expects:  RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN (set by scripts/aws/assume_role_step),
#           SERVICE_ID (optional, used for the session name).

if [ -n "${RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN:-}" ]; then
  echo "   🔑 Assuming role: $RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN"

  _ar_sts_error=$(mktemp)
  if ! ASSUMED_CREDS=$(aws sts assume-role \
    --role-arn "$RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN" \
    --role-session-name "np-rds-postgres-server-${SERVICE_ID:-workflow}" \
    --output json 2>"$_ar_sts_error"); then
    echo "   ❌ sts:AssumeRole failed for $RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN" >&2
    cat "$_ar_sts_error" >&2
    rm -f "$_ar_sts_error"
    return 1
  fi
  rm -f "$_ar_sts_error"

  _ar_access_key=$(echo "$ASSUMED_CREDS"    | jq -r '.Credentials.AccessKeyId // ""')
  _ar_secret_key=$(echo "$ASSUMED_CREDS"    | jq -r '.Credentials.SecretAccessKey // ""')
  _ar_session_token=$(echo "$ASSUMED_CREDS" | jq -r '.Credentials.SessionToken // ""')

  if [ -z "$_ar_access_key" ] || [ -z "$_ar_secret_key" ] || [ -z "$_ar_session_token" ]; then
    echo "   ❌ sts:AssumeRole returned incomplete credentials for $RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN" >&2
    return 1
  fi

  export AWS_ACCESS_KEY_ID="$_ar_access_key"
  export AWS_SECRET_ACCESS_KEY="$_ar_secret_key"
  export AWS_SESSION_TOKEN="$_ar_session_token"

  echo "   ✅ Role assumed successfully"
else
  echo "   ✅ assume_role=skipped (using agent credentials)"
fi
```

- [ ] **Step 3: Create `scripts/aws/assume_role_step`**

```bash
#!/bin/bash
# Dedicated workflow step: resolve the target IAM role and assume it, exporting
# temporary credentials so every subsequent step (including tofu) inherits them.
#
# Runs FIRST in each AWS-touching workflow. The workflow YAML must declare
# AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN as
# output:environment so the engine propagates them to the following steps.
#
# The AWS IAM provider (category "identity-access-control") is read from
# CONTEXT.providers[...], where the platform has ALREADY resolved it for the
# service's dimensions. Requires "identity-access-control" to be listed in
# provider_categories (values.yaml and/or the workflow).
#
# Resolution precedence (see resolve_assume_role_arn in assume_role_lib):
#   $RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN -> IAM provider by selector
#     -> $RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN_DEFAULT -> agent credentials
#
# Requires: aws CLI, jq. Expects: CONTEXT (engine-injected), SERVICE_ID (optional).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assume_role_lib"

RDS_POSTGRES_SERVER_ASSUME_ROLE_SELECTOR="${RDS_POSTGRES_SERVER_ASSUME_ROLE_SELECTOR:-rds-postgres-server}"

# IAM provider as resolved for the service's dimensions by the platform.
IAM_PROVIDER=$(echo "${CONTEXT:-}" | jq -c '.providers["identity-access-control"] // {}' 2>/dev/null)

RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN=$(resolve_assume_role_arn "$IAM_PROVIDER" "$RDS_POSTGRES_SERVER_ASSUME_ROLE_SELECTOR")
export RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN

# scripts/aws/assume_role performs sts:AssumeRole and exports AWS_* when an ARN is set,
# or no-ops (leaving agent credentials in place) when empty. Non-zero only when
# sts:AssumeRole itself fails.
if ! source "$SCRIPT_DIR/assume_role"; then
  echo "   ❌ assume_role step failed: could not assume $RDS_POSTGRES_SERVER_ASSUME_ROLE_ARN" >&2
  echo "" >&2
  echo "💡 Possible causes:" >&2
  echo "   • The agent's role is not allowed to sts:AssumeRole the target role" >&2
  echo "   • The target role does not exist or does not trust the agent role" >&2
  echo "   • There is no role ARN configured for selector=$RDS_POSTGRES_SERVER_ASSUME_ROLE_SELECTOR" >&2
  echo "" >&2
  exit 1
fi
```

- [ ] **Step 4: Make the 3 scripts executable and syntax-check them**

```bash
chmod +x databases/rds-postgres-server/scripts/aws/assume_role_lib \
         databases/rds-postgres-server/scripts/aws/assume_role \
         databases/rds-postgres-server/scripts/aws/assume_role_step

bash -n databases/rds-postgres-server/scripts/aws/assume_role_lib
bash -n databases/rds-postgres-server/scripts/aws/assume_role
bash -n databases/rds-postgres-server/scripts/aws/assume_role_step
```
Expected: all three `bash -n` calls produce no output and exit 0 (syntax OK).

- [ ] **Step 5: Prepend the `assume role` step to `workflows/aws/create.yaml`**

Current file:
```yaml
steps:
  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: REGION
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: apply

  - name: write service outputs
    type: script
    file: $SERVICE_PATH/scripts/aws/write_service_outputs
```

Replace with (only the new step added, nothing else changed):
```yaml
steps:
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

  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: REGION
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: apply

  - name: write service outputs
    type: script
    file: $SERVICE_PATH/scripts/aws/write_service_outputs
```

- [ ] **Step 6: Prepend the same `assume role` step to `workflows/aws/update.yaml`**

Current file is identical to `create.yaml`. Apply the exact same edit as Step 5 (same new step block, prepended before the existing `build context` step; the rest of the file — `tofu` with `TOFU_ACTION: apply` and `write service outputs` — is unchanged).

- [ ] **Step 7: Prepend the same `assume role` step to `workflows/aws/delete.yaml`**

Current file:
```yaml
steps:
  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: REGION
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: destroy

  - name: cleanup tfstate bucket
    type: script
    file: $SERVICE_PATH/scripts/aws/delete_tfstate_bucket
```

Replace with:
```yaml
steps:
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

  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: REGION
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: destroy

  - name: cleanup tfstate bucket
    type: script
    file: $SERVICE_PATH/scripts/aws/delete_tfstate_bucket
```

- [ ] **Step 8: Prepend the same `assume role` step to `workflows/aws/link.yaml`**

Current file:
```yaml
steps:
  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: REGION
        type: environment
      - name: TFSTATE_BUCKET
        type: environment
      - name: LINK_ID
        type: environment
      - name: LINK_NAME
        type: environment
      - name: SCOPE_ID
        type: environment
      - name: SCOPE_NRN
        type: environment
      - name: LINK_ACCESS_LEVEL
        type: environment

  - name: build permissions context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_permissions_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: apply

  - name: write link outputs
    type: script
    file: $SERVICE_PATH/scripts/aws/write_link_outputs
```

Replace with:
```yaml
steps:
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

  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: REGION
        type: environment
      - name: TFSTATE_BUCKET
        type: environment
      - name: LINK_ID
        type: environment
      - name: LINK_NAME
        type: environment
      - name: SCOPE_ID
        type: environment
      - name: SCOPE_NRN
        type: environment
      - name: LINK_ACCESS_LEVEL
        type: environment

  - name: build permissions context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_permissions_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: apply

  - name: write link outputs
    type: script
    file: $SERVICE_PATH/scripts/aws/write_link_outputs
```

- [ ] **Step 9: Prepend the same `assume role` step to `workflows/aws/unlink.yaml`**

Current file:
```yaml
steps:
  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: REGION
        type: environment
      - name: TFSTATE_BUCKET
        type: environment
      - name: LINK_ID
        type: environment
      - name: LINK_NAME
        type: environment
      - name: SCOPE_ID
        type: environment
      - name: SCOPE_NRN
        type: environment
      - name: LINK_ACCESS_LEVEL
        type: environment

  - name: build permissions context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_permissions_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: destroy
```

Replace with:
```yaml
steps:
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

  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: REGION
        type: environment
      - name: TFSTATE_BUCKET
        type: environment
      - name: LINK_ID
        type: environment
      - name: LINK_NAME
        type: environment
      - name: SCOPE_ID
        type: environment
      - name: SCOPE_NRN
        type: environment
      - name: LINK_ACCESS_LEVEL
        type: environment

  - name: build permissions context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_permissions_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: destroy
```

- [ ] **Step 10: Validate all 5 modified YAML files parse correctly**

```bash
for f in create update delete link unlink; do
  python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" \
    "databases/rds-postgres-server/workflows/aws/${f}.yaml" \
    && echo "OK: ${f}.yaml"
done
```
Expected: `OK: create.yaml`, `OK: update.yaml`, `OK: delete.yaml`, `OK: link.yaml`, `OK: unlink.yaml` — no YAML errors.

- [ ] **Step 11: Add `provider_categories` to `values.yaml`**

Current file:
```yaml
# RDS PostgreSQL Service — Static Configuration
# These values are not exposed in the NP UI. They configure the execution
# environment for the agent running this service.
#
# NOTE: In scripts, $VALUES is a FILE PATH (set by np service workflow exec --values).
#       It is NOT JSON content. Read values with yaml_value() from build_context.

# Named AWS profile for local testing (e.g. SSO profile with RDS access)
# If set and AWS_PROFILE is not already in the environment, build_context
# will export it so Terraform and AWS CLI use the correct credentials.
# Run "aws sso login --profile <name>" before starting np-agent locally.
aws_profile: ""
```

Append at the end:
```yaml

# Provider categories the platform must resolve into CONTEXT.providers before
# running workflow steps. identity-access-control is required by
# scripts/aws/assume_role_step to look up the AssumeRole target ARN.
provider_categories:
  - identity-access-control
```

- [ ] **Step 12: Validate the updated `values.yaml` parses correctly**

```bash
python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" \
  databases/rds-postgres-server/values.yaml && echo "OK: values.yaml"
```
Expected: `OK: values.yaml`, no errors.

- [ ] **Step 13: Confirm `AWS_PROFILE` (local-testing override) doesn't fight the assumed role**

`build_context` and `build_permissions_context` reference `AWS_PROFILE` (an
existing, unrelated mechanism for local testing — see `values.yaml`'s
`aws_profile` key). Confirm this is harmless now that `assume_role` also
exports `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`/`AWS_SESSION_TOKEN`:

```bash
grep -n "AWS_PROFILE" databases/rds-postgres-server/scripts/aws/build_context \
  databases/rds-postgres-server/scripts/aws/build_permissions_context
```

Read the matched lines. Expected: `AWS_PROFILE` is only exported when
`aws_profile` is set in `values.yaml` (a local-dev-only opt-in, empty by
default) — it does not unset or override `AWS_ACCESS_KEY_ID` etc. The AWS
CLI/SDK credential chain prefers explicit access-key env vars over
`AWS_PROFILE` when both are present, so an assumed role always wins if one
was resolved. No code change needed; this step is a documented confirmation,
not a fix. If the grep shows `build_context` unsetting or overriding
`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`/`AWS_SESSION_TOKEN`, stop and
report back instead of proceeding.

- [ ] **Step 14: Commit**

```bash
git add databases/rds-postgres-server/scripts/aws/assume_role_lib \
        databases/rds-postgres-server/scripts/aws/assume_role \
        databases/rds-postgres-server/scripts/aws/assume_role_step \
        databases/rds-postgres-server/workflows/aws/create.yaml \
        databases/rds-postgres-server/workflows/aws/update.yaml \
        databases/rds-postgres-server/workflows/aws/delete.yaml \
        databases/rds-postgres-server/workflows/aws/link.yaml \
        databases/rds-postgres-server/workflows/aws/unlink.yaml \
        databases/rds-postgres-server/values.yaml
git commit -m "feat(rds-postgres-server): assume the AssumeRole IAM role at runtime"
```

---

### Task 2: `rds-postgres-db` — assume-role scripts + workflow wiring

**Files:**
- Create: `databases/rds-postgres-db/scripts/aws/assume_role_lib`
- Create: `databases/rds-postgres-db/scripts/aws/assume_role`
- Create: `databases/rds-postgres-db/scripts/aws/assume_role_step`
- Modify: `databases/rds-postgres-db/workflows/aws/create.yaml`
- Modify: `databases/rds-postgres-db/workflows/aws/update.yaml`
- Modify: `databases/rds-postgres-db/workflows/aws/delete.yaml`
- Modify: `databases/rds-postgres-db/workflows/aws/link.yaml`
- Modify: `databases/rds-postgres-db/workflows/aws/unlink.yaml`
- Modify: `databases/rds-postgres-db/values.yaml`

**Interfaces:**
- Consumes: nothing from Task 1 — independent, mirrored implementation.
- Produces: same shape as Task 1 (`assume_role_step` as the first step of every workflow, exporting the 3 `AWS_*` variables), scoped to `rds-postgres-db`'s own role/selector/env-var names.

- [ ] **Step 1: Create `scripts/aws/assume_role_lib`**

```bash
#!/bin/bash
# Sourceable library of PURE helpers for assume-role resolution.
#
# Input is the AWS IAM provider exactly as it appears in
# CONTEXT.providers["identity-access-control"] — the platform already resolved it
# for the service's dimensions (most-specific config whose dimensions are a subset
# of the service's wins). These helpers only pick the selector, so they make NO
# np/aws calls and have no side effects on source — fully unit-testable.
#
# Requires (at call time): jq.

# arn_for_selector <iam_provider_attributes_json> <selector>
# Given CONTEXT.providers["identity-access-control"], echoes the ARN whose entry
# in .iam_role_arns.arns[] matches <selector>, or "" if none. First match wins.
# Returns "" on empty/malformed input (never crashes).
arn_for_selector() {
  local json="$1" selector="$2"
  [ -n "$json" ] || return 0
  [ -n "$selector" ] || return 0
  printf '%s' "$json" | jq -r --arg sel "$selector" '
    [ .iam_role_arns.arns[]?
      | select(.selector == $sel)
      | .arn ]
    | first // ""' 2>/dev/null || true
}

# resolve_assume_role_arn <iam_provider_json> <selector>
# Echoes the ARN to assume ("" = use agent credentials):
#   1. $RDS_POSTGRES_DB_ASSUME_ROLE_ARN env var (explicit override)
#   2. AWS IAM provider entry matching <selector> (already dimension-resolved
#      by the platform via CONTEXT.providers["identity-access-control"])
#   3. $RDS_POSTGRES_DB_ASSUME_ROLE_ARN_DEFAULT env var (per-account agent default)
# Note: RDS_POSTGRES_DB_ASSUME_ROLE_ARN="" (explicitly empty) is treated the same as
# unset — the chain continues to the next source.
resolve_assume_role_arn() {
  local iam_json="$1" selector="$2" arn=""

  arn="${RDS_POSTGRES_DB_ASSUME_ROLE_ARN:-}"

  if [ -z "$arn" ] && [ -n "$iam_json" ] && [ -n "$selector" ]; then
    arn=$(arn_for_selector "$iam_json" "$selector")
  fi

  arn="${arn:-${RDS_POSTGRES_DB_ASSUME_ROLE_ARN_DEFAULT:-}}"
  printf '%s' "$arn"
}
```

- [ ] **Step 2: Create `scripts/aws/assume_role`**

```bash
#!/bin/bash
# Sourceable helper — do NOT execute directly.
# Reads RDS_POSTGRES_DB_ASSUME_ROLE_ARN from the environment. If set, calls
# sts:AssumeRole and exports temporary credentials so all subsequent AWS calls
# (including tofu) use that role. If empty, does nothing — the agent's
# credentials (pod IRSA) handle auth.
#
# Requires: aws CLI, jq.
# Expects:  RDS_POSTGRES_DB_ASSUME_ROLE_ARN (set by scripts/aws/assume_role_step),
#           SERVICE_ID (optional, used for the session name).

if [ -n "${RDS_POSTGRES_DB_ASSUME_ROLE_ARN:-}" ]; then
  echo "   🔑 Assuming role: $RDS_POSTGRES_DB_ASSUME_ROLE_ARN"

  _ar_sts_error=$(mktemp)
  if ! ASSUMED_CREDS=$(aws sts assume-role \
    --role-arn "$RDS_POSTGRES_DB_ASSUME_ROLE_ARN" \
    --role-session-name "np-rds-postgres-db-${SERVICE_ID:-workflow}" \
    --output json 2>"$_ar_sts_error"); then
    echo "   ❌ sts:AssumeRole failed for $RDS_POSTGRES_DB_ASSUME_ROLE_ARN" >&2
    cat "$_ar_sts_error" >&2
    rm -f "$_ar_sts_error"
    return 1
  fi
  rm -f "$_ar_sts_error"

  _ar_access_key=$(echo "$ASSUMED_CREDS"    | jq -r '.Credentials.AccessKeyId // ""')
  _ar_secret_key=$(echo "$ASSUMED_CREDS"    | jq -r '.Credentials.SecretAccessKey // ""')
  _ar_session_token=$(echo "$ASSUMED_CREDS" | jq -r '.Credentials.SessionToken // ""')

  if [ -z "$_ar_access_key" ] || [ -z "$_ar_secret_key" ] || [ -z "$_ar_session_token" ]; then
    echo "   ❌ sts:AssumeRole returned incomplete credentials for $RDS_POSTGRES_DB_ASSUME_ROLE_ARN" >&2
    return 1
  fi

  export AWS_ACCESS_KEY_ID="$_ar_access_key"
  export AWS_SECRET_ACCESS_KEY="$_ar_secret_key"
  export AWS_SESSION_TOKEN="$_ar_session_token"

  echo "   ✅ Role assumed successfully"
else
  echo "   ✅ assume_role=skipped (using agent credentials)"
fi
```

- [ ] **Step 3: Create `scripts/aws/assume_role_step`**

```bash
#!/bin/bash
# Dedicated workflow step: resolve the target IAM role and assume it, exporting
# temporary credentials so every subsequent step (including tofu) inherits them.
#
# Runs FIRST in each AWS-touching workflow. The workflow YAML must declare
# AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN as
# output:environment so the engine propagates them to the following steps.
#
# The AWS IAM provider (category "identity-access-control") is read from
# CONTEXT.providers[...], where the platform has ALREADY resolved it for the
# service's dimensions. Requires "identity-access-control" to be listed in
# provider_categories (values.yaml and/or the workflow).
#
# Resolution precedence (see resolve_assume_role_arn in assume_role_lib):
#   $RDS_POSTGRES_DB_ASSUME_ROLE_ARN -> IAM provider by selector
#     -> $RDS_POSTGRES_DB_ASSUME_ROLE_ARN_DEFAULT -> agent credentials
#
# Requires: aws CLI, jq. Expects: CONTEXT (engine-injected), SERVICE_ID (optional).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/assume_role_lib"

RDS_POSTGRES_DB_ASSUME_ROLE_SELECTOR="${RDS_POSTGRES_DB_ASSUME_ROLE_SELECTOR:-rds-postgres-db}"

# IAM provider as resolved for the service's dimensions by the platform.
IAM_PROVIDER=$(echo "${CONTEXT:-}" | jq -c '.providers["identity-access-control"] // {}' 2>/dev/null)

RDS_POSTGRES_DB_ASSUME_ROLE_ARN=$(resolve_assume_role_arn "$IAM_PROVIDER" "$RDS_POSTGRES_DB_ASSUME_ROLE_SELECTOR")
export RDS_POSTGRES_DB_ASSUME_ROLE_ARN

# scripts/aws/assume_role performs sts:AssumeRole and exports AWS_* when an ARN is set,
# or no-ops (leaving agent credentials in place) when empty. Non-zero only when
# sts:AssumeRole itself fails.
if ! source "$SCRIPT_DIR/assume_role"; then
  echo "   ❌ assume_role step failed: could not assume $RDS_POSTGRES_DB_ASSUME_ROLE_ARN" >&2
  echo "" >&2
  echo "💡 Possible causes:" >&2
  echo "   • The agent's role is not allowed to sts:AssumeRole the target role" >&2
  echo "   • The target role does not exist or does not trust the agent role" >&2
  echo "   • There is no role ARN configured for selector=$RDS_POSTGRES_DB_ASSUME_ROLE_SELECTOR" >&2
  echo "" >&2
  exit 1
fi
```

- [ ] **Step 4: Make the 3 scripts executable and syntax-check them**

```bash
chmod +x databases/rds-postgres-db/scripts/aws/assume_role_lib \
         databases/rds-postgres-db/scripts/aws/assume_role \
         databases/rds-postgres-db/scripts/aws/assume_role_step

bash -n databases/rds-postgres-db/scripts/aws/assume_role_lib
bash -n databases/rds-postgres-db/scripts/aws/assume_role
bash -n databases/rds-postgres-db/scripts/aws/assume_role_step
```
Expected: all three `bash -n` calls produce no output and exit 0.

- [ ] **Step 5: Prepend the `assume role` step to `workflows/aws/create.yaml`**

Current file:
```yaml
steps:
  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: TFSTATE_BUCKET
        type: environment
      - name: OUTPUT_DIR
        type: environment
      - name: SERVER_HOSTNAME
        type: environment
      - name: SERVER_PORT
        type: environment
      - name: SERVER_MASTER_SECRET_ARN
        type: environment
      - name: DB_NAME
        type: environment
      - name: DB_USERNAME
        type: environment

  - name: build db setup context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_db_setup_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment
      - name: TOFU_IMPORT_DB_NAME
        type: environment
      - name: SETUP_SKIPPED
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: apply

  - name: write service outputs
    type: script
    file: $SERVICE_PATH/scripts/aws/write_service_outputs
```

Replace with (only the new step added, nothing else changed):
```yaml
steps:
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

  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: TFSTATE_BUCKET
        type: environment
      - name: OUTPUT_DIR
        type: environment
      - name: SERVER_HOSTNAME
        type: environment
      - name: SERVER_PORT
        type: environment
      - name: SERVER_MASTER_SECRET_ARN
        type: environment
      - name: DB_NAME
        type: environment
      - name: DB_USERNAME
        type: environment

  - name: build db setup context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_db_setup_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment
      - name: TOFU_IMPORT_DB_NAME
        type: environment
      - name: SETUP_SKIPPED
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: apply

  - name: write service outputs
    type: script
    file: $SERVICE_PATH/scripts/aws/write_service_outputs
```

- [ ] **Step 6: Prepend the `assume role` step to `workflows/aws/update.yaml`**

Current file (this one is short — only `build context`, no other steps):
```yaml
steps:
  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: TFSTATE_BUCKET
        type: environment
```

Replace with:
```yaml
steps:
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

  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: TFSTATE_BUCKET
        type: environment
```

- [ ] **Step 7: Prepend the `assume role` step to `workflows/aws/delete.yaml`**

Current file:
```yaml
steps:
  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: TFSTATE_BUCKET
        type: environment
      - name: OUTPUT_DIR
        type: environment
      - name: SERVER_HOSTNAME
        type: environment
      - name: SERVER_PORT
        type: environment
      - name: SERVER_MASTER_SECRET_ARN
        type: environment
      - name: DB_NAME
        type: environment
      - name: DB_USERNAME
        type: environment

  - name: build db setup context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_db_setup_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment
      - name: SETUP_SKIPPED
        type: environment

  - name: reassign owned objects
    type: script
    file: $SERVICE_PATH/scripts/aws/reassign_owned

  - name: tofu destroy role
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: destroy
      # Destroy only the user. The database is preserved with master as owner
      # so data remains available for potential future use.
      TOFU_TARGETS: "postgresql_role.app_user,random_password.user"

  - name: cleanup tfstate bucket
    type: script
    file: $SERVICE_PATH/scripts/aws/delete_tfstate_bucket
```

Replace with:
```yaml
steps:
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

  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: TFSTATE_BUCKET
        type: environment
      - name: OUTPUT_DIR
        type: environment
      - name: SERVER_HOSTNAME
        type: environment
      - name: SERVER_PORT
        type: environment
      - name: SERVER_MASTER_SECRET_ARN
        type: environment
      - name: DB_NAME
        type: environment
      - name: DB_USERNAME
        type: environment

  - name: build db setup context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_db_setup_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment
      - name: SETUP_SKIPPED
        type: environment

  - name: reassign owned objects
    type: script
    file: $SERVICE_PATH/scripts/aws/reassign_owned

  - name: tofu destroy role
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: destroy
      # Destroy only the user. The database is preserved with master as owner
      # so data remains available for potential future use.
      TOFU_TARGETS: "postgresql_role.app_user,random_password.user"

  - name: cleanup tfstate bucket
    type: script
    file: $SERVICE_PATH/scripts/aws/delete_tfstate_bucket
```

- [ ] **Step 8: Prepend the `assume role` step to `workflows/aws/link.yaml`**

Current file:
```yaml
steps:
  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TFSTATE_BUCKET
        type: environment
      - name: LINK_ID
        type: environment
      - name: LINK_NAME
        type: environment
      - name: SCOPE_ID
        type: environment
      - name: SCOPE_NRN
        type: environment
      - name: LINK_ACCESS_LEVEL
        type: environment
      - name: SERVER_HOSTNAME
        type: environment
      - name: SERVER_PORT
        type: environment
      - name: SERVER_MASTER_SECRET_ARN
        type: environment
      - name: DB_NAME
        type: environment
      - name: DB_USERNAME
        type: environment

  - name: build permissions context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_permissions_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: apply

  - name: write link outputs
    type: script
    file: $SERVICE_PATH/scripts/aws/write_link_outputs
```

Replace with:
```yaml
steps:
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

  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TFSTATE_BUCKET
        type: environment
      - name: LINK_ID
        type: environment
      - name: LINK_NAME
        type: environment
      - name: SCOPE_ID
        type: environment
      - name: SCOPE_NRN
        type: environment
      - name: LINK_ACCESS_LEVEL
        type: environment
      - name: SERVER_HOSTNAME
        type: environment
      - name: SERVER_PORT
        type: environment
      - name: SERVER_MASTER_SECRET_ARN
        type: environment
      - name: DB_NAME
        type: environment
      - name: DB_USERNAME
        type: environment

  - name: build permissions context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_permissions_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: apply

  - name: write link outputs
    type: script
    file: $SERVICE_PATH/scripts/aws/write_link_outputs
```

- [ ] **Step 9: Prepend the `assume role` step to `workflows/aws/unlink.yaml`**

Current file:
```yaml
steps:
  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TFSTATE_BUCKET
        type: environment
      - name: LINK_ID
        type: environment
      - name: LINK_NAME
        type: environment
      - name: SCOPE_ID
        type: environment
      - name: SCOPE_NRN
        type: environment
      - name: LINK_ACCESS_LEVEL
        type: environment
      - name: SERVER_HOSTNAME
        type: environment
      - name: SERVER_PORT
        type: environment
      - name: SERVER_MASTER_SECRET_ARN
        type: environment
      - name: DB_NAME
        type: environment
      - name: DB_USERNAME
        type: environment
      - name: LINK_NEVER_CREATED
        type: environment

  - name: build permissions context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_permissions_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: destroy
      # Destroy only grant resources. The database and user are preserved at
      # service level — data survives unlink and access can be re-granted later.
      TOFU_TARGETS: "postgresql_default_privileges.sequences,postgresql_grant.sequences,postgresql_default_privileges.tables,postgresql_grant.tables,postgresql_grant.schema_usage,postgresql_grant.connect"
```

Replace with:
```yaml
steps:
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

  - name: build context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TFSTATE_BUCKET
        type: environment
      - name: LINK_ID
        type: environment
      - name: LINK_NAME
        type: environment
      - name: SCOPE_ID
        type: environment
      - name: SCOPE_NRN
        type: environment
      - name: LINK_ACCESS_LEVEL
        type: environment
      - name: SERVER_HOSTNAME
        type: environment
      - name: SERVER_PORT
        type: environment
      - name: SERVER_MASTER_SECRET_ARN
        type: environment
      - name: DB_NAME
        type: environment
      - name: DB_USERNAME
        type: environment
      - name: LINK_NEVER_CREATED
        type: environment

  - name: build permissions context
    type: script
    file: $SERVICE_PATH/scripts/aws/build_permissions_context
    output:
      - name: OUTPUT_DIR
        type: environment
      - name: TOFU_MODULE_DIR
        type: environment
      - name: TOFU_INIT_VARIABLES
        type: environment
      - name: TOFU_VARIABLES
        type: environment

  - name: tofu
    type: script
    file: $SERVICE_PATH/scripts/aws/do_tofu
    configuration:
      TOFU_ACTION: destroy
      # Destroy only grant resources. The database and user are preserved at
      # service level — data survives unlink and access can be re-granted later.
      TOFU_TARGETS: "postgresql_default_privileges.sequences,postgresql_grant.sequences,postgresql_default_privileges.tables,postgresql_grant.tables,postgresql_grant.schema_usage,postgresql_grant.connect"
```

- [ ] **Step 10: Validate all 5 modified YAML files parse correctly**

```bash
for f in create update delete link unlink; do
  python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" \
    "databases/rds-postgres-db/workflows/aws/${f}.yaml" \
    && echo "OK: ${f}.yaml"
done
```
Expected: `OK: create.yaml`, `OK: update.yaml`, `OK: delete.yaml`, `OK: link.yaml`, `OK: unlink.yaml` — no YAML errors.

- [ ] **Step 11: Add `provider_categories` to `values.yaml`**

Current file:
```yaml
# RDS PostgreSQL Service — Static Configuration
# These values are not exposed in the NP UI. They configure the execution
# environment for the agent running this service.
#
# NOTE: In scripts, $VALUES is a FILE PATH (set by np service workflow exec --values).
#       It is NOT JSON content. Read values with yaml_value() from build_context.

# AWS region where RDS instances are created
region: us-east-1

# VPC ID where RDS instances will be deployed
vpc_id: "vpc-0a5dfe8e463dee15d"

# Named AWS profile for local testing (e.g. SSO profile with RDS access)
# If set and AWS_PROFILE is not already in the environment, build_context
# will export it so Terraform and AWS CLI use the correct credentials.
# Run "aws sso login --profile <name>" before starting np-agent locally.
aws_profile: ""
```

Append at the end:
```yaml

# Provider categories the platform must resolve into CONTEXT.providers before
# running workflow steps. identity-access-control is required by
# scripts/aws/assume_role_step to look up the AssumeRole target ARN.
provider_categories:
  - identity-access-control
```

- [ ] **Step 12: Validate the updated `values.yaml` parses correctly**

```bash
python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" \
  databases/rds-postgres-db/values.yaml && echo "OK: values.yaml"
```
Expected: `OK: values.yaml`, no errors.

- [ ] **Step 13: Confirm `AWS_PROFILE` (local-testing override) doesn't fight the assumed role**

`build_context`, `build_permissions_context`, and `build_db_setup_context`
reference `AWS_PROFILE` (an existing, unrelated mechanism for local testing —
see `values.yaml`'s `aws_profile` key). Confirm this is harmless now that
`assume_role` also exports
`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`/`AWS_SESSION_TOKEN`:

```bash
grep -n "AWS_PROFILE" databases/rds-postgres-db/scripts/aws/build_context \
  databases/rds-postgres-db/scripts/aws/build_permissions_context \
  databases/rds-postgres-db/scripts/aws/build_db_setup_context
```

Read the matched lines. Expected: `AWS_PROFILE` is only exported when
`aws_profile` is set in `values.yaml` (a local-dev-only opt-in, empty by
default) — it does not unset or override `AWS_ACCESS_KEY_ID` etc. The AWS
CLI/SDK credential chain prefers explicit access-key env vars over
`AWS_PROFILE` when both are present, so an assumed role always wins if one
was resolved. No code change needed; this step is a documented confirmation,
not a fix. If the grep shows any of these scripts unsetting or overriding
`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`/`AWS_SESSION_TOKEN`, stop and
report back instead of proceeding.

- [ ] **Step 14: Commit**

```bash
git add databases/rds-postgres-db/scripts/aws/assume_role_lib \
        databases/rds-postgres-db/scripts/aws/assume_role \
        databases/rds-postgres-db/scripts/aws/assume_role_step \
        databases/rds-postgres-db/workflows/aws/create.yaml \
        databases/rds-postgres-db/workflows/aws/update.yaml \
        databases/rds-postgres-db/workflows/aws/delete.yaml \
        databases/rds-postgres-db/workflows/aws/link.yaml \
        databases/rds-postgres-db/workflows/aws/unlink.yaml \
        databases/rds-postgres-db/values.yaml
git commit -m "feat(rds-postgres-db): assume the AssumeRole IAM role at runtime"
```

---

### Task 3: Register the AssumeRole ARNs as an `identity-access-control` provider (testing only)

**Files:**
- Modify: `/Users/sebastian.correa/Documents/code/nullplatform/PAE/services-testing/main.tf` (outside the `services` repo — the sandbox testing stack)

**Interfaces:**
- Consumes: `module.service_requirements_rds_postgres_server.permissions_role_arn` and `module.service_requirements_rds_postgres_db.permissions_role_arn`, both already defined and applied in this same file (see prior plan, Task on `services-testing`).
- Produces: a `nullplatform_provider_config` resource resolvable by `scripts/aws/assume_role_step` in both services once a real workflow reads `CONTEXT.providers["identity-access-control"]` for this account/namespace.

- [ ] **Step 1: Add the `identity_access_control` module to `main.tf`**

Append at the end of `/Users/sebastian.correa/Documents/code/nullplatform/PAE/services-testing/main.tf`:

```hcl
# =============================================================================
# AWS IAM provider — registers the two AssumeRole target ARNs under their
# selectors so scripts/aws/assume_role_step (in the services repo, branch
# feat/rds-postgres-server-assume-role) can resolve them at runtime.
# =============================================================================

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

- [ ] **Step 2: Initialize and validate**

```bash
cd /Users/sebastian.correa/Documents/code/nullplatform/PAE/services-testing
tofu init -input=false -upgrade -no-color
tofu validate
```
Expected: module downloads successfully, `Success! The configuration is valid.`

- [ ] **Step 3: Plan (no apply)**

```bash
AWS_PROFILE=providers-test tofu plan -input=false -no-color
```
Expected: `Plan: 1 to add, 0 to change, 0 to destroy` — only the new `nullplatform_provider_config.identity_access_control` resource, nothing else touched. If the plan shows changes to any pre-existing resource, stop and report back rather than proceeding — do not apply.

No commit for this step — `services-testing` has no version control (confirmed in the prior session).
