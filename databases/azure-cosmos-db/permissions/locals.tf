locals {

  # Map access levels to built-in role definition GUIDs
  role_definitions = {
    read      = "00000000-0000-0000-0000-000000000001" # Built-in Data Reader
    readwrite = "00000000-0000-0000-0000-000000000002" # Built-in Data Contributor
  }

  # Create a map for for_each
  permissions_map = {
    for p in var.permissions : p.container => p.access_level
  }

  # Determine access level for database-wide permissions (highest wins)
  database_access_level = "readwrite"
}