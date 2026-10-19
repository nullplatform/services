# Services

This repository used to hold nullplatform's services and later served as their index. Each service now lives in its
own repository, and the list of what's available is in the documentation:

- **[Sample services](https://docs.nullplatform.com/docs/services/sample-services)** — every sample service, with its
  repository, the directory that holds its specs, and how to adopt it. It is kept in sync with the repositories
  automatically.
- **[Agent-backed scopes](https://docs.nullplatform.com/docs/public-repos-reference#agent-backed-scopes)** — the base
  scopes.

There is no code on `main`, and nothing new is added here.

## Coming from an older setup

Setups that read services from this repository keep working while they are pinned to a branch or commit that still
has the code, such as the `1.0.0` branch. Nothing is deleted from its history. `main` has no code, so anything that
points at `main` here — a `?ref=main` module source, or an agent cloning this repository at `main` — finds no service.

Where each service moved:

| Was in this repository | Now |
| --- | --- |
| `databases/rds-postgres-server` | [services-postgresql-rds](https://github.com/nullplatform/services-postgresql-rds), `rds-postgres-server/` |
| `databases/rds-postgres-db` | [services-postgresql-rds](https://github.com/nullplatform/services-postgresql-rds), `rds-postgres-db/` |
| `databases/postgres/k8s` (Postgres DB) | [services-postgresql-k-8-s](https://github.com/nullplatform/services-postgresql-k-8-s), `postgres-db/` |
| `databases/azure-cosmos-db` | [services-azure-cosmos-db](https://github.com/nullplatform/services-azure-cosmos-db), `azure-cosmos-db/` |
| `endpoint-exposer` | [services-endpoint-exposer](https://github.com/nullplatform/services-endpoint-exposer), repository root |

To move a setup, point its module sources and agent repositories at the new repository, pinned to its latest release,
and use the new directory as the service path. The service's README has the exact steps and values.
