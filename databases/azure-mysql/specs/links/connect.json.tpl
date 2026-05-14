{
  "name": "Connect",
  "slug": "connect",
  "unique": false,
  "assignable_to": "any",
  "use_default_actions": true,
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
      "required": ["db_name", "access_level"],
      "properties": {
        "db_name": {
          "type": "string",
          "title": "Database Name",
          "description": "Name of the MySQL database to create inside the server",
          "editableOn": ["create"],
          "order": 1
        },
        "access_level": {
          "type": "string",
          "title": "Access Level",
          "default": "read-write",
          "enum": ["read", "write", "read-write"],
          "description": "Permission level: read (SELECT), write (INSERT/UPDATE/DELETE), read-write (full DML + DDL)",
          "editableOn": ["create", "update"],
          "order": 2
        },
        "username": {
          "type": "string",
          "title": "DB Username",
          "export": true,
          "visibleOn": ["read"],
          "editableOn": [],
          "description": "Per-link MySQL username (auto-populated after link creation)",
          "order": 3
        },
        "password": {
          "type": "string",
          "title": "DB Password",
          "export": {"type": "environment_variable", "secret": true},
          "visibleOn": ["read"],
          "editableOn": [],
          "description": "Per-link MySQL password (auto-populated, delivered as secret env var)",
          "order": 4
        },
        "database_name": {
          "type": "string",
          "title": "Database",
          "export": true,
          "visibleOn": ["read"],
          "editableOn": [],
          "description": "Database name (auto-populated after link creation)",
          "order": 5
        }
      }
    },
    "values": {}
  }
}
