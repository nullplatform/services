locals {
  # Role Definition IDs (built-in)
  role_ids = {
    read  = "00000000-0000-0000-0000-000000000001" # Cosmos DB Built-in Data Reader
    write = "00000000-0000-0000-0000-000000000002" # Cosmos DB Built-in Data Contributor
  }

  role_id = local.role_ids[var.access_level]

  containers_to_assign = var.containers_to_apply_permissions
}
