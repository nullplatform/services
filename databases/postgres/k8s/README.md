# PostgreSQL Database Service

A production-ready PostgreSQL database service for Kubernetes environments using the Bitnami Helm chart. This service provides a managed PostgreSQL instance with configurable security, persistence, and user management capabilities.

## Overview

- **Service Name**: Postgres DB
- **Service Slug**: `postgres-db`
- **Type**: Dependency Service
- **Provider**: Kubernetes (K8S)
- **Category**: Database → Relational Database

## Features

- 🔒 **Security**: PII compliance with configurable security contexts
- 💾 **Persistence**: Configurable persistent storage (default: 10Gi)
- ⚡ **Performance**: Resource limits and requests configuration
- 👥 **User Management**: Create database users with granular permissions
- 🔧 **Query Execution**: Built-in DDL and DML query execution
- 🏷️ **Usage Types**: Support for transactions, cache, and configurations

## Installation

### Using Terraform

```hcl
module "postgres_db_service_definition" {
  source = "git@github.com:nullplatform/main-terraform-modules.git//modules/nullplatform/scope-definition?ref=alpha"
  nrn        = var.np_account_nrn
  np_api_key = var.np_api_key

  git_repo = "nullplatform/services"
  git_ref      = "main"
  git_service_path = "databases/postgres/k8s"
  service_name        = "Postgres DB"
  service_description = "Postgres Database for production workloads"
}

module "postgres_db_service_agent_association" {
  source = "git@github.com:nullplatform/main-terraform-modules.git//modules/nullplatform/service-definition-agent-association?ref=alpha"
  agent_api_key = var.np_api_key
  service_definition = module.postgres_db_service_definition
  agent_tags = var.agent_tags
}
```

## Configuration

### Required Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `usage_type` | enum | Purpose of the database: `transactions`, `cache`, or `configurations` |
| `pii` | boolean | Whether the database will store personally identifiable information |

### Optional Attributes

| Attribute | Type | Exported | Description |
|-----------|------|----------|-------------|
| `hostname` | string | ✅ | Database hostname (read-only after creation) |
| `port` | number | ✅ | Database port (read-only after creation) |
| `dbname` | string | ✅ | Database name (read-only after creation) |

## Available Actions

### Run DDL Query (`run-ddl-query`)

Execute Data Definition Language queries for schema management.

**Parameters:**
- `query` (string, required): The DDL query to execute

**Use Cases:**
- Create/alter/drop tables
- Create/drop indexes
- Modify database schema
- Create/drop views and functions

**Example:**
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Run DML Query (`run-dml-query`)

Execute Data Manipulation Language queries for data operations.

**Parameters:**
- `query` (string, required): The DML query to execute

**Use Cases:**
- Insert/update/delete data
- Select queries for data retrieval
- Data migration scripts
- Bulk data operations

**Example:**
```sql
INSERT INTO users (username, email)
VALUES ('john_doe', 'john@example.com');
```

## Available Links

### Database User (`database-user`)

Create and manage database users with configurable permissions.

**Attributes:**
- `username` (string, exported): Database username
- `password` (string, secret, exported): Database password
- `permissions` (object, required): User permissions configuration

**Permission Options:**
- `read` (boolean, default: true): Read permissions on database
- `write` (boolean, default: false): Write permissions on database
- `admin` (boolean, default: false): DDL/administrative permissions

**Usage Example:**
```json
{
  "permissions": {
    "read": true,
    "write": true,
    "admin": false
  }
}
```

## Helm Configuration

The service uses the Bitnami PostgreSQL Helm chart with the following default configuration:

```yaml
# Resource Configuration
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 256Mi

# Persistence
persistence:
  enabled: true
  size: 10Gi

# Service
service:
  type: ClusterIP
  ports:
    postgresql: 5432
```

### PII-Enabled Security Context

When `pii: true` is configured, additional security measures are applied:

```yaml
securityContext:
  enabled: true
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 1001
```

## Directory Structure

```
k8s/
├── README.md                          # This documentation
├── specs/                            # Service specifications
│   ├── service-spec.json             # Main service definition
│   ├── actions/
│   │   ├── run-ddl-query.json        # DDL query action spec
│   │   └── run-dml-query.json        # DML query action spec
│   └── links/
│       └── database-user.json        # Database user link spec
├── postgres-db/                      # Implementation
│   ├── service/                      # Service management scripts
│   │   ├── create-postgres-db        # Create database instance
│   │   ├── delete-postgres-db        # Delete database instance
│   │   ├── update-postgres-db        # Update database instance
│   │   ├── run-ddl-query            # Execute DDL queries
│   │   ├── run-dml-query            # Execute DML queries
│   │   ├── handle-helm.sh           # Helm operations handler
│   │   ├── project.sh               # Project configuration
│   │   └── values.yaml.tpl          # Helm values template
│   ├── link/                        # Link management scripts
│   │   ├── create-database-user     # Create database user
│   │   ├── update-database-user     # Update database user
│   │   └── delete-database-user     # Delete database user
│   ├── ensure_psql.sh               # PostgreSQL client setup
│   └── run_query_in_pod.sh          # Query execution helper
└── handle-service-agent              # Main service agent handler
```

## Best Practices

### Security
- Always set `pii: true` when storing personal information
- Use least-privilege principle for database users
- Regularly rotate database passwords
- Enable security contexts for production workloads

### Performance
- Choose appropriate `usage_type` for workload optimization
- Monitor resource usage and adjust limits as needed
- Consider connection pooling for high-traffic applications
- Use read replicas for read-heavy workloads (if available)

### Operations
- Regular backups (configure backup retention policies)
- Monitor disk usage and scale storage as needed
- Use DDL actions for schema migrations
- Test queries in development before production execution

## Troubleshooting

### Common Issues

1. **Connection Refused**: Check service status and network policies
2. **Permission Denied**: Verify user permissions and authentication
3. **Disk Full**: Monitor storage usage and scale as needed
4. **Query Timeout**: Optimize queries and check resource limits

### Support

For issues and support:
- Check service logs: `kubectl logs -n <namespace> <pod-name>`
- Verify service configuration in nullplatform dashboard
- Review Helm release status: `helm status <release-name>`

## License

This service definition is part of the nullplatform services repository.