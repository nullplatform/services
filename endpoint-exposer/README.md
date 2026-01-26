# Endpoint Exposer Service

## Overview

The **endpoint-exposer** service is a critical infrastructure component of Nullplatform that manages dynamic exposure of application endpoints through public and private domains. It functions as a route orchestrator that translates high-level specifications into native Kubernetes configurations using Istio Service Mesh.

## Core Responsibilities

### 1. Dynamic Endpoint Management
- Expose application endpoints declaratively
- Configure separate public and private domains for different access levels
- Update route configurations with zero downtime
- Maintain configuration synchronized with desired state

### 2. Route Configuration
- Define route patterns (exact, regex, wildcards)
- Specify allowed HTTP methods (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS)
- Associate routes with Nullplatform scopes for access control
- Control route visibility (public vs. private)

### 3. Kubernetes and Istio Integration
- Generate HTTPRoute resources (Kubernetes Gateway API v1)
- Create Istio AuthorizationPolicies for access control
- Configure RequestAuthentication for JWT validation
- Apply routing policies in the service mesh

### 4. Scope-Based Access Control
- Map endpoints to specific Nullplatform scopes
- Integrate with Open Policy Agent (OPA) for external authorization
- Implement granular authorization policies per route
- Validate JWT tokens according to scope configuration

## Key Features

### Route Management
```yaml
routes:
  - method: GET
    path: /api/users
    scope: user-management
    visible_on: public
    enable_authorization: true
```

- **Path Types**:
  - Exact: `/api/users`
  - Regex with parameters: `/api/users/{id}`
  - Wildcard: `/api/users/*`

- **HTTP Methods**: Supports all standard HTTP methods
- **Visibility**: Public or private routes on separate domains
- **Authorization**: Optional per-route with JWT and OPA validation

### Domain Separation

**Public Domain:**
- Endpoints accessible from the internet
- Typically for public APIs and unauthenticated resources
- Connected to `gateway-public` gateway

**Private Domain:**
- Internal organization endpoints
- Requires private network access
- Connected to `gateway-private` gateway

### Authorization and Security

- **JWT Validation**: Verifies authentication tokens on each request
- **Authorization Policies**: Istio AuthorizationPolicies per route
- **OPA Integration**: Authorization decisions delegated to Open Policy Agent
- **Scope Control**: Route-to-scope mapping for granular permissions

## Architecture

### Workflow

1. **Build Context**
   - Extracts service action parameters
   - Retrieves Kubernetes namespace information
   - Classifies routes by visibility (public/private)

2. **Build HTTPRoutes**
   - Generates base HTTPRoute templates per domain
   - Queries scopes associated with each route
   - Constructs Istio routing rules

3. **Process Routes**
   - Sorts routes by specificity (exact > regex > prefix)
   - Generates AuthorizationPolicies if authorization is enabled
   - Maps scope IDs to backend services

4. **Apply Configuration**
   - Applies generated YAML manifests to the cluster
   - Manages cleanup of obsolete resources
   - Maintains tracking of applied resources

### Technologies

- **Kubernetes**: Orchestration platform (Gateway API v1)
- **Istio**: Service mesh for traffic management and security
- **Bash**: Workflow scripting and automation
- **jq**: JSON processing and manipulation
- **gomplate**: Resource template generation
- **kubectl**: Kubernetes resource management
- **OPA**: Open Policy Agent for external authorization

### Nullplatform Integration

- **Scopes Service**: Scope queries for authorization (`np scope list/read`)
- **Notification Channel**: Receives events to trigger actions
- **Service Specification**: Service specification registration
- **Deployment Service**: Coordination with deployment workflows

## File Structure

```
/endpoint-exposer
├── configure                      # Service configuration script
├── entrypoint/                   # Entry points for actions
│   ├── service-action            # Service action handler
│   └── link-action               # Dependency handler
├── specs/                        # Service specifications
│   ├── service-specification.json
│   └── link-specification.json
├── workflows/istio/              # Workflow definitions
│   ├── service-action.json
│   └── link-action.json
├── scripts/istio/                # Core routing logic
│   ├── build_context
│   ├── build_httproute
│   ├── process_routes
│   ├── build_rule
│   └── build_ingress_with_rule
├── scripts/common/               # Shared utilities
│   ├── apply
│   └── delete
├── templates/istio/              # K8s resource templates
│   ├── httproute.yaml.tmpl
│   ├── authz-policy.yaml.tmpl
│   └── request-authn.yaml.tmpl
├── test/                         # BATS test suite
├── examples/                     # Example configurations
└── container-scope-override/     # Custom deployment support
```

## Configuration

### Environment Variables

- `K8S_NAMESPACE`: Kubernetes namespace for resources (default: `nullplatform`)
- `PUBLIC_GATEWAY_NAME`: Public gateway name (default: `gateway-public`)
- `PRIVATE_GATEWAY_NAME`: Private gateway name (default: `gateway-private`)
- `GATEWAY_NAMESPACE`: Gateway namespace (default: `gateways`)
- `OPA_PROVIDER_NAME`: OPA authorization provider (default: `opa-ext-authz`)

### Route Configuration Example

```json
{
  "routes": [
    {
      "method": "GET",
      "path": "/api/v1/resource/{id}",
      "scope": "resource-read",
      "visible_on": "public",
      "enable_authorization": true
    },
    {
      "method": "POST",
      "path": "/api/v1/resource",
      "scope": "resource-write",
      "visible_on": "private",
      "enable_authorization": true
    }
  ],
  "public_domain": "api.example.com",
  "private_domain": "internal-api.example.com"
}
```

## Testing

The service uses BATS (Bash Automated Testing System) for testing:

```bash
# Run all tests
./test/run-tests.sh

# Run specific tests
bats test/istio/
```

Tests cover:
- Simple routes
- Public and private routes
- Authorization scenarios
- JWT configurations
- Manifest generation

## Operations

### Create/Update Endpoints

The service responds to Nullplatform actions:
- `create`: Generates and applies initial configuration
- `update`: Modifies existing configuration
- `delete`: Cleans up Kubernetes resources

### Monitoring

Generated resources can be monitored with:

```bash
# View HTTPRoutes
kubectl get httproutes -n <namespace>

# View AuthorizationPolicies
kubectl get authorizationpolicies -n <namespace>

# View gateway status
kubectl get gateway -n gateways
```

## Use Cases

1. **Public API**: Expose public REST endpoints with rate limiting and optional authentication
2. **Admin API**: Private endpoints with JWT authentication and scope-based authorization
3. **Internal Microservices**: Private routes between services with authorization policies
4. **Multi-Version APIs**: Path-based routing for API versioning

## Contributing

See [test/README.md](test/README.md) for information about testing and development.
