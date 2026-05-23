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
              "detail": {
                "type": "VerticalLayout",
                "elements": [
                  {
                    "type": "HorizontalLayout",
                    "elements": [
                      {"type": "Control", "label": "HTTP Method", "scope": "#/properties/method"},
                      {"type": "Control", "label": "Visibility", "scope": "#/properties/visibility"}
                    ]
                  },
                  {"type": "Control", "label": "Path", "scope": "#/properties/path"},
                  {
                    "type": "Control",
                    "label": "Authorized Groups",
                    "scope": "#/properties/groups",
                    "options": {"orientation": "vertical"}
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
            "required": ["method", "path"],
            "properties": {
              "method": {
                "type": "string",
                "title": "HTTP Method",
                "enum": ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
              },
              "path": {
                "type": "string",
                "title": "Path"
              },
              "visibility": {
                "type": "string",
                "title": "Visibility",
                "default": "public",
                "enum": ["public", "private"]
              },
              "groups": {
                "type": "array",
                "title": "Authorized Groups",
                "uniqueItems": true,
                "items": {
                  "type": "string",
                  "enum": [
                    "AWS_PlataformaUpstream_Gestor_Desa",
                    "AWS_PlataformaUpstream_Programador_Desa",
                    "AWS_PlataformaUpstream_Pulling_Desa",
                    "AWS_PlataformaUpstream_Workover_Desa",
                    "AWS_PlataformaUpstream_Visita_Desa",
                    "AWS_PlataformaUpstream_Administrador_Desa"
                  ]
                }
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
