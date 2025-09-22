# Services

This repository contains a collection of service definitions for the null platform. It provides pre-configured services that can be deployed and managed within Kubernetes environments.

⚠️ **Development Status**: This repository is currently under development. It's not recommended to use any service in production environments.

## Table of Contents

- [Service Catalog](#service-catalog)
  - [Databases](#databases)
    - [PostgreSQL Database](#postgresql-database-postgres-db)
- [Installation](#installation)
- [Directory Structure](#directory-structure)
- [Usage](#usage)
- [Contributing](#contributing)

## Usage

Each service is defined by its specification files and includes:

1. **Service Specification** (`service-spec.json`): Defines the service metadata, attributes, and capabilities
2. **Action Definitions**: JSON files describing custom actions the service can perform
3. **Link Definitions**: JSON files describing how the service can be linked to other resources
4. **Implementation Scripts**: Shell scripts that handle the actual service operations

## Contributing

When adding new services:

1. Follow the existing directory structure pattern
2. Include proper service specifications with required attributes
3. Document all available actions and links
4. Ensure proper security configurations for production readiness

