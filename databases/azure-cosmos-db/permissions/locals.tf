locals {
  # Role Definition IDs (built-in)
  role_ids = {
    read  = "00000000-0000-0000-0000-000000000001" # Cosmos DB Built-in Data Reader
    write = "00000000-0000-0000-0000-000000000002" # Cosmos DB Built-in Data Contributor
  }

  role_id = local.role_ids[var.access_level]

  # The script will populate target_containers with all container names
  # when all_containers is true, so we just use target_containers directly
  containers_to_assign = var.target_containers
}
