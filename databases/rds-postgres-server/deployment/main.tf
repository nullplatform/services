# ---------------------------------------------------------------------------
# Customer Managed KMS Key for RDS storage and Secrets Manager encryption
# ---------------------------------------------------------------------------

resource "aws_kms_key" "rds" {
  description             = "CMK for RDS instance ${var.instance_name} storage and secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RootFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "RDSServiceAccess"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecretsManagerServiceAccess"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    "managed-by" = "nullplatform"
    "service-id" = var.service_id
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/nullplatform/rds/${var.instance_name}"
  target_key_id = aws_kms_key.rds.key_id
}

# ---------------------------------------------------------------------------
# Security group for RDS (allows PostgreSQL traffic from within the VPC)
# ---------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "np-rds-${var.instance_name}"
  description = "Allow PostgreSQL access from within the VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "managed-by" = "nullplatform"
    "service-id" = var.service_id
  }
}

# ---------------------------------------------------------------------------
# Master password (stored in Secrets Manager, used by link permissions)
# ---------------------------------------------------------------------------

resource "random_password" "master" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "master" {
  name                    = "nullplatform/rds/${var.instance_name}/master"
  recovery_window_in_days = 0
  kms_key_id              = aws_kms_key.rds.arn

  tags = {
    "managed-by"   = "nullplatform"
    "rds-instance" = var.instance_name
    "service-id"   = var.service_id
  }
}

resource "aws_secretsmanager_secret_version" "master" {
  secret_id = aws_secretsmanager_secret.master.id
  secret_string = jsonencode({
    username = "master"
    password = random_password.master.result
  })
}

# ---------------------------------------------------------------------------
# RDS instance
# ---------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = var.instance_name
  subnet_ids = data.aws_subnets.private.ids

  tags = {
    "managed-by" = "nullplatform"
    "service-id" = var.service_id
  }
}

resource "aws_db_instance" "main" {
  identifier        = var.instance_name
  engine            = "postgres"
  engine_version    = var.postgres_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  db_name  = "postgres"
  username = "master"
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = var.multi_az
  publicly_accessible = false
  skip_final_snapshot = true
  deletion_protection = false

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  tags = {
    "managed-by" = "nullplatform"
    "service-id" = var.service_id
  }

  depends_on = [aws_secretsmanager_secret_version.master]
}
