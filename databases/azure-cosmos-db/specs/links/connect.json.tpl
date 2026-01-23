{
  "id": "8383cb49-d027-4030-84d1-5f5c387ace8e",
  "name": "Connect",
  "slug": "connect",
  "visible_to": [],
  "unique": false,
  "dimensions": {},
  "scopes": {},
  "assignable_to": "any",
  "use_default_actions": true,
  "selectors": {
    "category": "Database",
    "imported": false,
    "provider": "Azure",
    "sub_category": "NoSQL Database"
  },
  "attributes": {
    "values": {}
  },
  "specification_schema": {
    "type": "object",
    "$schema": "http://json-schema.org/draft-07/schema#",
    "required": [
      "linkName",
      "accessLevel"
    ],
    "properties": {
      "target": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "container": {
              "type": "string",
              "additionalKeywords": {
                "enum": "if (.service.attributes.containers | type == \"array\" and length > 0) then [.service.attributes.containers[].container_name] else [\"No containers available\"] end"
              }
            },
            "accessLevel": {
              "enum": [
                "read/write",
                "read",
                "write"
              ],
              "type": "string",
              "title": "Access Level",
              "default": "read/write",
              "editableOn": [
                "create"
              ],
              "description": "Permission level for this link"
            }
          }
        },
        "title": "Containers",
        "editableOn": [
          "create",
          "update"
        ],
        "description": "Select containers to apply this link",
        "uniqueItems": true
      },
      "allContainers": {
        "type": "boolean",
        "title": "All Containers",
        "default": false,
        "editableOn": [
          "create",
          "update"
        ],
        "description": "Apply this link to all containers"
      }
    }
  }
}