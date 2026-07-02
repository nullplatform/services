# RDS Postgres AssumeRole IAM Scaffolding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give `rds-postgres-server` and `rds-postgres-db` each a dedicated IAM role, created by their `requirements/` Terraform modules, that the nullplatform agent can assume via `sts:AssumeRole` — replacing `rds-postgres-server`'s current pattern of attaching managed policies directly to an externally supplied role.

**Architecture:** Both modules follow the `nullplatform/scopes-static-files` (`static-files/requirements/aws`) reference exactly: a `cluster_name`-keyed IAM role with a trust policy naming the agent role (`agent_role_arn`, defaulted by convention) as the sole principal allowed to assume it. Each service's already-documented minimal permissions (existing 4 policies for `rds-postgres-server`; one new Secrets Manager policy for `rds-postgres-db`) attach to that role. Neither module touches the agent's own role/permissions — granting the agent permission to assume these roles is out of scope, handled centrally elsewhere.

**Tech Stack:** OpenTofu/Terraform (`hashicorp/aws` provider `>= 5.0`), no test harness or CI in this repo.

**Design spec:** `docs/superpowers/specs/2026-07-02-rds-postgres-assume-role-design.md`

## Global Constraints

- Provider requirement: `hashicorp/aws >= 5.0` (matches the `scopes-static-files` reference).
- AWS-side resource `name` values (IAM role/policy names) use hyphens uniformly — e.g. `nullplatform-<cluster_name>-rds-postgres-server-role`. Terraform resource **labels** (the `resource "aws_iam_policy" "label"` identifier) use underscores, per normal HCL convention — only the AWS-facing `name` attribute changes.
- `<service>` in naming is always the full service name (`rds-postgres-server` or `rds-postgres-db`), never abbreviated.
- No changes to `build_context`, any entrypoint script, or the `agent` module/role. Granting the agent permission to assume these new roles is explicitly out of scope.
- No new infrastructure-permission content beyond what's already documented: `rds-postgres-server` keeps its existing 4 policies' `Statement` blocks byte-for-byte identical (only their `name` changes); `rds-postgres-db` gets exactly the one Secrets Manager policy specified below, no more.
- Validate every module with `tofu init -backend=false && tofu validate` (no live AWS account/backend available in this environment) — there is no other test harness for these modules.

---

### Task 1: Rewrite `rds-postgres-server/requirements/` to create its own permissions role

**Files:**
- Modify: `databases/rds-postgres-server/requirements/variables.tf`
- Modify: `databases/rds-postgres-server/requirements/main.tf`
- Modify: `databases/rds-postgres-server/requirements/output.tf`
- Create: `databases/rds-postgres-server/requirements/data.tf`
- Create: `databases/rds-postgres-server/requirements/locals.tf`
- Create: `databases/rds-postgres-server/requirements/versions.tf`
- Modify: `databases/rds-postgres-server/README.md`

**Interfaces:**
- Produces: `aws_iam_role.nullplatform_rds_postgres_server` (a `count`-based resource, index `[0]` when created), with outputs `permissions_role_arn`, `permissions_role_name`, `permissions_role_id`. Task 2 does not depend on this — the two modules are independent — but keep this shape in mind since it's the pattern Task 2 replicates.

- [ ] **Step 1: Replace `variables.tf`**

Current content renames `name` → `cluster_name` and drops the old external-role `role_name` semantics in favor of the reference's override variable. Replace the entire file:

```hcl
variable "cluster_name" {
  description = "Name of the cluster this bootstrap run is for. Used to derive the permissions role name, the policy names, and the default agent role ARN. Must be unique per AWS account (IAM policy names are account-global). Example: \"prod-us-east-1\"."
  type        = string
}

variable "agent_role_arn" {
  description = "ARN of the primary nullplatform agent IAM role allowed to assume this permissions role via sts:AssumeRole, and always a trusted principal of the role's trust policy. Defaults (when empty) to the conventional agent role for the cluster: arn:aws:iam::<account>:role/nullplatform-<cluster_name>-agent-role."
  type        = string
  default     = ""

  validation {
    condition     = var.agent_role_arn == "" || can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.agent_role_arn))
    error_message = "agent_role_arn must be empty (to use the derived default) or match arn:aws:iam::<account-id>:role/<role-name>"
  }
}

variable "additional_agent_role_arns" {
  description = "Extra IAM role ARNs allowed to assume this permissions role, appended to agent_role_arn in the trust policy. Defaults to none."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.additional_agent_role_arns : can(regex("^arn:aws:iam::[0-9]{12}:role/.+", arn))])
    error_message = "each additional_agent_role_arns entry must match arn:aws:iam::<account-id>:role/<role-name>"
  }
}

variable "role_name" {
  description = "Override for the permissions IAM role name. Defaults to nullplatform-{cluster_name}-rds-postgres-server-role."
  type        = string
  default     = ""
}

variable "iam_create_role" {
  description = "Whether to create the permissions role and its policies. When false, the module produces no resources."
  type        = bool
  default     = true
}

variable "iam_resource_tags_json" {
  description = "Tags to apply to IAM resources created by this module."
  type        = map(string)
  default     = {}
}
```

- [ ] **Step 2: Create `data.tf`**

```hcl
data "aws_caller_identity" "current" {}
```

- [ ] **Step 3: Create `locals.tf`**

```hcl
locals {
  iam_module_name = "requirements-rds-postgres-server"
  iam_create      = var.iam_create_role

  role_name      = var.role_name != "" ? var.role_name : "nullplatform-${var.cluster_name}-rds-postgres-server-role"
  agent_role_arn = var.agent_role_arn != "" ? var.agent_role_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nullplatform-${var.cluster_name}-agent-role"

  iam_default_tags = merge(var.iam_resource_tags_json, {
    ManagedBy = "rds-postgres-server"
    Module    = local.iam_module_name
  })
}
```

- [ ] **Step 4: Create `versions.tf`**

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

- [ ] **Step 5: Replace `main.tf`**

Adds the permissions role and its trust policy; renames the 4 existing policies to the hyphenated, `cluster_name`-keyed convention (content of each `Statement` block is untouched — only `name` changes); repoints the 4 attachments at the new role. Replace the entire file:

```hcl
################################################################################
# Permissions role — assumed by the nullplatform agent role (sts:AssumeRole)
################################################################################

resource "aws_iam_role" "nullplatform_rds_postgres_server" {
  count = local.iam_create ? 1 : 0

  name        = local.role_name
  description = "Permissions role assumed by the nullplatform agent role for rds-postgres-server in cluster ${var.cluster_name}"

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

################################################################################
# Policy attachments
################################################################################

resource "aws_iam_role_policy_attachment" "rds" {
  count      = local.iam_create ? 1 : 0
  role       = aws_iam_role.nullplatform_rds_postgres_server[0].name
  policy_arn = aws_iam_policy.nullplatform_rds_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "rds_sg" {
  count      = local.iam_create ? 1 : 0
  role       = aws_iam_role.nullplatform_rds_postgres_server[0].name
  policy_arn = aws_iam_policy.nullplatform_rds_sg_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "rds_secretsmanager" {
  count      = local.iam_create ? 1 : 0
  role       = aws_iam_role.nullplatform_rds_postgres_server[0].name
  policy_arn = aws_iam_policy.nullplatform_rds_secretsmanager_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "rds_s3" {
  count      = local.iam_create ? 1 : 0
  role       = aws_iam_role.nullplatform_rds_postgres_server[0].name
  policy_arn = aws_iam_policy.nullplatform_rds_s3_policy[0].arn
}

################################################################################
# RDS IAM policy
################################################################################

# Grant permissions to manage RDS instances and subnet groups
resource "aws_iam_policy" "nullplatform_rds_policy" {
  count = local.iam_create ? 1 : 0

  name        = "nullplatform-${var.cluster_name}-rds-policy"
  description = "Policy for managing RDS instances and subnet groups"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:ModifyDBInstance",
          "rds:DescribeDBInstances",
          "rds:CreateDBSubnetGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:DescribeDBSubnetGroups",
          "rds:ModifyDBSubnetGroup",
          "rds:AddTagsToResource",
          "rds:ListTagsForResource",
          "rds:RemoveTagsFromResource",
          "rds:DescribeDBParameterGroups",
          "rds:DescribeDBParameters",
          "rds:DescribeDBEngineVersions",
          "rds:DescribeOrderableDBInstanceOptions",
          "rds:DescribeOptionGroups",
          "iam:CreateServiceLinkedRole"
        ],
        "Resource" : "*"
      }
    ]
  })
}

################################################################################
# EC2 Security Group IAM policy
################################################################################

# Grant permissions to manage EC2 security groups for RDS
resource "aws_iam_policy" "nullplatform_rds_sg_policy" {
  count = local.iam_create ? 1 : 0

  name        = "nullplatform-${var.cluster_name}-rds-sg-policy"
  description = "Policy for managing EC2 security groups for RDS"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeSubnets",
          "ec2:CreateTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSecurityGroupRules"
        ],
        "Resource" : "*"
      }
    ]
  })
}

################################################################################
# S3 IAM policy (per-service tfstate buckets: np-service-<id>)
################################################################################

# Grant permissions to manage the per-link S3 bucket used to store tofu state
resource "aws_iam_policy" "nullplatform_rds_s3_policy" {
  count = local.iam_create ? 1 : 0

  name        = "nullplatform-${var.cluster_name}-rds-s3-policy"
  description = "Policy for managing per-service S3 tfstate buckets (np-service-*)"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:CreateBucket",
          "s3:HeadBucket",
          "s3:PutBucketVersioning",
          "s3:ListBucket",
          "s3:ListBucketVersions",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:DeleteBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::np-service-*",
          "arn:aws:s3:::np-service-*/*"
        ]
      }
    ]
  })
}

################################################################################
# Secrets Manager IAM policy
################################################################################

# Grant permissions to manage Secrets Manager secrets for RDS master password
resource "aws_iam_policy" "nullplatform_rds_secretsmanager_policy" {
  count = local.iam_create ? 1 : 0

  name        = "nullplatform-${var.cluster_name}-rds-secretsmanager-policy"
  description = "Policy for managing Secrets Manager secrets for RDS master password"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:TagResource",
          "secretsmanager:UntagResource",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:ListSecretVersionIds"
        ],
        "Resource" : "*"
      }
    ]
  })
}
```

- [ ] **Step 6: Replace `output.tf`**

Keeps the 3 existing policy ARN outputs, adds the 3 new role outputs. Replace the entire file:

```hcl
output "rds_policy_arn" {
  description = "ARN of the RDS management policy"
  value       = local.iam_create ? aws_iam_policy.nullplatform_rds_policy[0].arn : ""
}

output "rds_sg_policy_arn" {
  description = "ARN of the EC2 security group policy"
  value       = local.iam_create ? aws_iam_policy.nullplatform_rds_sg_policy[0].arn : ""
}

output "rds_secretsmanager_policy_arn" {
  description = "ARN of the Secrets Manager policy"
  value       = local.iam_create ? aws_iam_policy.nullplatform_rds_secretsmanager_policy[0].arn : ""
}

output "permissions_role_arn" {
  description = "ARN of the rds-postgres-server permissions role assumed by the nullplatform agent role. Pass to the agent (assume_role_arns)."
  value       = local.iam_create ? aws_iam_role.nullplatform_rds_postgres_server[0].arn : ""
}

output "permissions_role_name" {
  description = "Name of the rds-postgres-server permissions role"
  value       = local.iam_create ? aws_iam_role.nullplatform_rds_postgres_server[0].name : ""
}

output "permissions_role_id" {
  description = "ID of the rds-postgres-server permissions role"
  value       = local.iam_create ? aws_iam_role.nullplatform_rds_postgres_server[0].id : ""
}
```

- [ ] **Step 7: Validate the module**

Run:
```bash
cd databases/rds-postgres-server/requirements && tofu init -backend=false && tofu validate
```
Expected: `Success! The configuration is valid.` (init must succeed first — it downloads the `hashicorp/aws` provider; no backend or AWS credentials are needed since `-backend=false` skips backend init and `validate` doesn't call AWS APIs.)

If it fails, read the error carefully — a `Reference to undeclared resource`/`variable` error means a rename in one file wasn't propagated to another; fix and re-run before moving on.

- [ ] **Step 8: Update `databases/rds-postgres-server/README.md`**

Find this block (the `### AWS IAM Permissions` subsection under `## Requirements`):

```markdown
The `requirements/` Terraform module can be used to create and attach the necessary IAM policies to an existing role.
```

Replace it with:

```markdown
The `requirements/` Terraform module creates a dedicated IAM role
(`nullplatform-<cluster_name>-rds-postgres-server-role`) holding these
policies, with a trust policy allowing the nullplatform agent role to
`sts:AssumeRole` on it. Pass `cluster_name` (required) and optionally
`agent_role_arn` (defaults to `nullplatform-<cluster_name>-agent-role`) when
applying it. Granting the agent itself permission to assume this role is
handled separately, outside this module.
```

- [ ] **Step 9: Commit**

```bash
git add databases/rds-postgres-server/requirements databases/rds-postgres-server/README.md
git commit -m "feat(rds-postgres-server): create dedicated AssumeRole IAM role in requirements/"
```

---

### Task 2: Create `rds-postgres-db/requirements/` with its own permissions role

**Files:**
- Create: `databases/rds-postgres-db/requirements/variables.tf`
- Create: `databases/rds-postgres-db/requirements/data.tf`
- Create: `databases/rds-postgres-db/requirements/locals.tf`
- Create: `databases/rds-postgres-db/requirements/versions.tf`
- Create: `databases/rds-postgres-db/requirements/main.tf`
- Create: `databases/rds-postgres-db/requirements/output.tf`
- Modify: `databases/rds-postgres-db/README.md`

**Interfaces:**
- Consumes: nothing from Task 1 — independent module, same pattern replicated with `rds-postgres-db` naming instead of `rds-postgres-server`.
- Produces: `aws_iam_role.nullplatform_rds_postgres_db` (count-based, index `[0]`), `aws_iam_policy.nullplatform_rds_postgres_db_secretsmanager_policy` (count-based, index `[0]`), outputs `permissions_role_arn`, `permissions_role_name`, `permissions_role_id`, `secretsmanager_policy_arn`.

- [ ] **Step 1: Create `variables.tf`**

```hcl
variable "cluster_name" {
  description = "Name of the cluster this bootstrap run is for. Used to derive the permissions role name, the policy name, and the default agent role ARN."
  type        = string
}

variable "agent_role_arn" {
  description = "ARN of the primary nullplatform agent IAM role allowed to assume this permissions role via sts:AssumeRole, and always a trusted principal of the role's trust policy. Defaults (when empty) to the conventional agent role for the cluster: arn:aws:iam::<account>:role/nullplatform-<cluster_name>-agent-role."
  type        = string
  default     = ""

  validation {
    condition     = var.agent_role_arn == "" || can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.agent_role_arn))
    error_message = "agent_role_arn must be empty (to use the derived default) or match arn:aws:iam::<account-id>:role/<role-name>"
  }
}

variable "additional_agent_role_arns" {
  description = "Extra IAM role ARNs allowed to assume this permissions role, appended to agent_role_arn in the trust policy. Defaults to none."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for arn in var.additional_agent_role_arns : can(regex("^arn:aws:iam::[0-9]{12}:role/.+", arn))])
    error_message = "each additional_agent_role_arns entry must match arn:aws:iam::<account-id>:role/<role-name>"
  }
}

variable "role_name" {
  description = "Override for the permissions IAM role name. Defaults to nullplatform-{cluster_name}-rds-postgres-db-role."
  type        = string
  default     = ""
}

variable "iam_create_role" {
  description = "Whether to create the permissions role and its policy. When false, the module produces no resources."
  type        = bool
  default     = true
}

variable "iam_resource_tags_json" {
  description = "Tags to apply to IAM resources created by this module."
  type        = map(string)
  default     = {}
}
```

- [ ] **Step 2: Create `data.tf`**

```hcl
data "aws_caller_identity" "current" {}
```

- [ ] **Step 3: Create `locals.tf`**

```hcl
locals {
  iam_module_name = "requirements-rds-postgres-db"
  iam_create      = var.iam_create_role

  role_name      = var.role_name != "" ? var.role_name : "nullplatform-${var.cluster_name}-rds-postgres-db-role"
  agent_role_arn = var.agent_role_arn != "" ? var.agent_role_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nullplatform-${var.cluster_name}-agent-role"

  iam_default_tags = merge(var.iam_resource_tags_json, {
    ManagedBy = "rds-postgres-db"
    Module    = local.iam_module_name
  })
}
```

- [ ] **Step 4: Create `versions.tf`**

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

- [ ] **Step 5: Create `main.tf`**

The permissions role and trust policy, plus the one Secrets Manager policy this service's README already documents as required (`secretsmanager:GetSecretValue`), scoped to the `nullplatform/rds/*` secret-name prefix that `rds-postgres-server`'s `deployment/main.tf` actually uses (`name = "nullplatform/rds/${var.instance_name}/master"`) rather than `*`:

```hcl
################################################################################
# Permissions role — assumed by the nullplatform agent role (sts:AssumeRole)
################################################################################

resource "aws_iam_role" "nullplatform_rds_postgres_db" {
  count = local.iam_create ? 1 : 0

  name        = local.role_name
  description = "Permissions role assumed by the nullplatform agent role for rds-postgres-db in cluster ${var.cluster_name}"

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

################################################################################
# Secrets Manager IAM policy — read-only access to the RDS master password
################################################################################

resource "aws_iam_policy" "nullplatform_rds_postgres_db_secretsmanager_policy" {
  count = local.iam_create ? 1 : 0

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

- [ ] **Step 6: Create `output.tf`**

```hcl
output "permissions_role_arn" {
  description = "ARN of the rds-postgres-db permissions role assumed by the nullplatform agent role. Pass to the agent (assume_role_arns)."
  value       = local.iam_create ? aws_iam_role.nullplatform_rds_postgres_db[0].arn : ""
}

output "permissions_role_name" {
  description = "Name of the rds-postgres-db permissions role"
  value       = local.iam_create ? aws_iam_role.nullplatform_rds_postgres_db[0].name : ""
}

output "permissions_role_id" {
  description = "ID of the rds-postgres-db permissions role"
  value       = local.iam_create ? aws_iam_role.nullplatform_rds_postgres_db[0].id : ""
}

output "secretsmanager_policy_arn" {
  description = "ARN of the Secrets Manager read policy"
  value       = local.iam_create ? aws_iam_policy.nullplatform_rds_postgres_db_secretsmanager_policy[0].arn : ""
}
```

- [ ] **Step 7: Validate the module**

Run:
```bash
cd databases/rds-postgres-db/requirements && tofu init -backend=false && tofu validate
```
Expected: `Success! The configuration is valid.`

- [ ] **Step 8: Update `databases/rds-postgres-db/README.md`**

Find this block (the `### AWS IAM Permissions` subsection under `## Requirements`):

```markdown
### AWS IAM Permissions

This service requires minimal AWS permissions compared to `rds-postgres-server`. The agent only needs:

- **Secrets Manager**: `GetSecretValue` — to retrieve the master PostgreSQL password from the ARN stored in service attributes

No RDS, EC2, or S3 permissions are needed.
```

Replace it with:

```markdown
### AWS IAM Permissions

This service requires minimal AWS permissions compared to `rds-postgres-server`. The agent only needs:

- **Secrets Manager**: `GetSecretValue` — to retrieve the master PostgreSQL password from the ARN stored in service attributes

No RDS, EC2, or S3 permissions are needed.

The `requirements/` Terraform module creates a dedicated IAM role
(`nullplatform-<cluster_name>-rds-postgres-db-role`) holding this policy,
with a trust policy allowing the nullplatform agent role to `sts:AssumeRole`
on it. Pass `cluster_name` (required) and optionally `agent_role_arn`
(defaults to `nullplatform-<cluster_name>-agent-role`) when applying it.
Granting the agent itself permission to assume this role is handled
separately, outside this module.
```

- [ ] **Step 9: Commit**

```bash
git add databases/rds-postgres-db/requirements databases/rds-postgres-db/README.md
git commit -m "feat(rds-postgres-db): add requirements/ module with AssumeRole IAM role"
```

---

## Out of scope (do not implement as part of this plan)

- Wiring `build_context` (or any entrypoint script) to call `sts assume-role` and export temporary credentials.
- Granting the agent permission to assume these new roles (`assume_role_arns` or equivalent on the agent's own module).
- Any change to the `agent` module/role itself.
