{
  "name": "Route",
  "slug": "route",
  "unique": false,
  "assignable_to": "any",
  "use_default_actions": true,
  "attributes": {
    "schema": {
      "type": "object",
      "required": ["method", "path", "scope"],
      "uiSchema": {
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
          {"type": "Control", "label": "Scope", "scope": "#/properties/scope"},
          {"type": "Control", "label": "Authorized Groups", "scope": "#/properties/groups"}
        ]
      },
      "properties": {
        "method": {
          "type": "string",
          "title": "HTTP Method",
          "editableOn": ["create"],
          "visibleOn": ["read"],
          "enum": ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
        },
        "path": {
          "type": "string",
          "title": "Path",
          "editableOn": ["create"],
          "visibleOn": ["read"]
        },
        "scope": {
          "type": "string",
          "title": "Scope",
          "editableOn": ["create"],
          "visibleOn": ["read"]
        },
        "visibility": {
          "type": "string",
          "title": "Visibility",
          "default": "public",
          "editableOn": ["create"],
          "visibleOn": ["read"],
          "enum": ["public", "private"]
        },
        "groups": {
          "type": "array",
          "title": "Authorized Groups",
          "uniqueItems": true,
          "editableOn": ["create"],
          "visibleOn": ["read"],
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
        },
        "httproute_name": {
          "type": "string",
          "title": "HTTPRoute Name",
          "editableOn": [],
          "visibleOn": ["read"]
        },
        "policy_id": {
          "type": "string",
          "title": "AVP Policy ID",
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
