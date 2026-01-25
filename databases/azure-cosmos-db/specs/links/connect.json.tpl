{
  "id": "8383cb49-d027-4030-84d1-5f5c387ace8e",
  "name": "Connect",
  "slug": "connect",
  "visible_to": [],
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
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": [],
      "properties": {
        "target": {
          "type": "array",
          "title": "Containers",
          "description": "Select containers to apply this link",
          "uniqueItems": true,
          "editableOn": [
            "create"
          ],
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
                "type": "string",
                "title": "Access Level",
                "description": "Permission level for this link",
                "enum": [
                  "read/write",
                  "read",
                  "write"
                ],
                "default": "read/write",
                "editableOn": [
                  "create",
                  "update"
                ]
              }
            }
          }
        },
        "allContainers": {
          "type": "boolean",
          "title": "All Containers",
          "description": "Apply this link to all containers",
          "default": false,
          "editableOn": [
            "create",
            "update"
          ]
        }
      }
    },
    "values": {}
  }
}