locals {
  privileges = {
    "read"       = ["SELECT"]
    "write"      = ["SELECT", "INSERT", "UPDATE", "DELETE"]
    "read-write" = ["SELECT", "INSERT", "UPDATE", "DELETE", "CREATE", "DROP", "ALTER", "INDEX", "REFERENCES"]
  }
}

resource "random_password" "user" {
  length  = 20
  special = false
}

resource "mysql_database" "db" {
  name = var.db_name
}

resource "mysql_user" "app" {
  user               = var.link_username
  host               = "%"
  plaintext_password = random_password.user.result
}

resource "mysql_grant" "app" {
  user       = mysql_user.app.user
  host       = mysql_user.app.host
  database   = mysql_database.db.name
  privileges = local.privileges[var.access_level]
}
