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
              "elementLabelProp": "summary",
              "showSortButtons": true,
              "detail": {
                "type": "VerticalLayout",
                "elements": [
                  {"type": "Control", "label": "Scope", "scope": "#/properties/target_scope"},
                  {"type": "Control", "label": "HTTP Methods", "scope": "#/properties/methods"},
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
          "title": "Expose Rules",
          "description": "Configure which HTTP paths and methods are exposed, and who can access them.",
          "editableOn": ["create", "update"],
          "items": {
            "type": "object",
            "required": ["target_scope", "methods", "path", "groups"],
            "properties": {
              "target_scope": {
                "type": "string",
                "title": "Scope",
                "description": "Scope this rule applies to (e.g. develop, staging). Add multiple rules for multiple scopes.",
                "editableOn": ["create", "update"]
              },
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
                "title": "Rule Summary",
                "default": "New Rule",
                "editableOn": ["create", "update"],
                "visibleOn": []
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
