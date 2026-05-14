{
  "name": "Azure MySQL",
  "slug": "azure-mysql",
  "type": "dependency",
  "unique": false,
  "assignable_to": "any",
  "use_default_actions": true,
  "available_links": ["connect"],
  "selectors": {
    "category": "Database",
    "imported": false,
    "provider": "Azure",
    "sub_category": "Relational Database"
  },
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": ["sku_name"],
      "properties": {
        "sku_name": {
          "type": "string",
          "title": "SKU / Instance Size",
          "default": "B_Standard_B1ms",
          "enum": [
            "B_Standard_B1ms",
            "B_Standard_B2ms",
            "B_Standard_B4ms",
            "GP_Standard_D2ds_v4",
            "GP_Standard_D4ds_v4",
            "MO_Standard_E2ds_v4"
          ],
          "description": "Compute tier and size. B_ = Burstable (dev/test), GP_ = General Purpose, MO_ = Memory Optimized.",
          "editableOn": ["create", "update"],
          "order": 1
        },
        "mysql_version": {
          "type": "string",
          "title": "MySQL Version",
          "default": "8.0.21",
          "enum": ["8.0.21"],
          "description": "MySQL engine version (cannot be changed after creation)",
          "editableOn": ["create"],
          "order": 2
        },
        "storage_size_gb": {
          "type": "number",
          "title": "Storage (GB)",
          "default": 20,
          "minimum": 20,
          "maximum": 16384,
          "description": "Allocated storage size in GB",
          "editableOn": ["create", "update"],
          "order": 3
        },
        "backup_retention_days": {
          "type": "number",
          "title": "Backup Retention (days)",
          "default": 7,
          "minimum": 7,
          "maximum": 35,
          "description": "Number of days to retain automated backups",
          "editableOn": ["create", "update"],
          "order": 4
        },
        "hostname": {
          "type": "string",
          "title": "Hostname",
          "export": true,
          "visibleOn": ["read"],
          "editableOn": [],
          "description": "MySQL Flexible Server FQDN (auto-populated after creation)",
          "order": 5
        },
        "port": {
          "type": "number",
          "title": "Port",
          "export": true,
          "visibleOn": ["read"],
          "editableOn": [],
          "description": "MySQL port (always 3306, auto-populated after creation)",
          "order": 6
        },
        "administrator_login": {
          "type": "string",
          "export": false,
          "visibleOn": [],
          "editableOn": [],
          "description": "Internal: admin username used by workflow scripts to create per-link users"
        },
        "admin_password_secret_id": {
          "type": "string",
          "export": false,
          "visibleOn": [],
          "editableOn": [],
          "description": "Internal: Azure Key Vault secret ID holding the admin password"
        }
      }
    },
    "values": {}
  }
}
