{
  "id": "41a7659d-7b3b-480c-a7d3-a30c8ccaa1cc",
  "name": "Connect",
  "slug": "connect",
  "visible_to": [],
  "unique": false,
  "dimensions": {},
  "scopes": {},
  "assignable_to": "any",
  "use_default_actions": true,
  "selectors": {
    "category": "any",
    "imported": false,
    "provider": "any",
    "sub_category": "any"
  },
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": [
        "linkName",
        "accessLevel"
      ],
      "uiSchema": {
        "type": "VerticalLayout",
        "elements": [
          {
            "type": "Control",
            "scope": "#/properties/linkName"
          },
          {
            "type": "Control",
            "scope": "#/properties/accessLevel"
          },
          {
            "rule": {
              "effect": "HIDE",
              "condition": {
                "scope": "#/properties/allContainers",
                "schema": {
                  "const": true
                }
              }
            },
            "type": "Control",
            "scope": "#/properties/target"
          },
          {
            "type": "Control",
            "scope": "#/properties/allContainers"
          }
        ]
      },
      "properties": {
        "linkName": {
          "type": "string",
          "title": "Link Name",
          "description": "Name for this link",
          "editableOn": [
            "create"
          ]
        },
        "accessLevel": {
          "type": "string",
          "title": "Access Level",
          "description": "Permission level for this link",
          "enum": [
            "read",
            "write"
          ],
          "default": "read",
          "editableOn": [
            "create"
          ]
        },
        "target": {
          "type": "array",
          "title": "Target",
          "description": "Select containers to apply this link",
          "items": {
            "type": "string",
            "enum": [
              "Users",
              "Orders",
              "Products",
              "Inventory",
              "Sessions"
            ]
          },
          "uniqueItems": true,
          "editableOn": [
            "create",
            "update"
          ]
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