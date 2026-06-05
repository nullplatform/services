{
  "name": "Route",
  "slug": "route",
  "unique": false,
  "assignable_to": "any",
  "use_default_actions": true,
  "attributes": {
    "schema": {
      "type": "object",
      "required": ["routes"],
      "uiSchema": {
        "type": "VerticalLayout",
        "elements": [
          {
            "type": "Control",
            "scope": "#/properties/routes",
            "options": {
              "showSortButtons": true,
              "elementLabelProp": "summary",
              "detail": {
                "type": "VerticalLayout",
                "elements": [
                  {
                    "type": "HorizontalLayout",
                    "elements": [
                      {"type": "Control", "label": "HTTP Methods", "scope": "#/properties/methods"}
                    ]
                  },
                  {"type": "Control", "label": "Path", "scope": "#/properties/path"},
                  {
                    "type": "Control",
                    "label": "Authorized Groups",
                    "scope": "#/properties/groups"
                  }
                ]
              }
            }
          }
        ]
      },
      "properties": {
        "routes": {
          "type": "array",
          "title": "Routes",
          "description": "HTTP routes to expose",
          "editableOn": ["create", "update"],
          "items": {
            "type": "object",
            "required": ["methods", "path"],
            "properties": {
              "methods": {
                "type": "array",
                "title": "HTTP Methods",
                "items": {
                  "type": "string",
                  "enum": ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
                },
                "uniqueItems": true,
                "minItems": 1
              },
              "path": {
                "type": "string",
                "title": "Path"
              },
              "groups": {
                "type": "string",
                "title": "Authorized Groups",
                "description": "Comma-separated list of groups allowed to access this route (e.g. pae-test-admins, pae-test-users). Leave empty to allow any authenticated user.",
                "editableOn": ["create", "update"]
              },
              "summary": {
                "type": "string",
                "title": "Summary",
                "editableOn": [],
                "visibleOn": ["read"]
              }
            }
          }
        },
        "scope": {
          "type": "string",
          "title": "Scope",
          "editableOn": [],
          "visibleOn": ["read"]
        },
        "httproute_name": {
          "type": "string",
          "title": "HTTPRoute Name",
          "editableOn": [],
          "visibleOn": ["read"]
        },
        "policy_ids": {
          "type": "string",
          "title": "AVP Policy IDs",
          "editableOn": [],
          "visibleOn": ["read"]
        }
      }
    },
    "values": {}
  },
  "selectors": {
    "category": "any",
    "imported": false,
    "provider": "any",
    "sub_category": "any"
  }
}
