{
  "assignable_to": "dimension",
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": [
        "publicDomain"
      ],
      "uiSchema": {
        "type": "VerticalLayout",
        "elements": [
          {
            "type": "Categorization",
            "options": {
              "collapsable": {
                "label": "Documentation",
                "collapsed": true
              }
            },
            "elements": [
              {
                "type": "Category",
                "label": "Domains",
                "elements": [
                  {
                    "text": "### Public Domain\nBase domain for routes exposed to external traffic. Requests matching routes with `visibility: public` will be served through this domain.\n\n### Private Domain\nBase domain for routes accessible only within the internal network. Use this for service-to-service communication.",
                    "type": "Label",
                    "options": {
                      "format": "markdown"
                    }
                  }
                ]
              },
              {
                "type": "Category",
                "label": "Routes",
                "elements": [
                  {
                    "text": "### Route Configuration\nDefine how incoming requests are matched and forwarded to backend services.\n\n| Field | Description |\n|-------|-------------|\n| **Verb** | HTTP method to match (GET, POST, PUT, etc.) |\n| **Path** | URL path pattern (e.g., `/api/v1/users`) |\n| **Scope** | Target service that will handle the request |\n| **Visibility** | `public` (external) or `private` (internal network only) |\n| **Groups** | Security groups allowed to access this route. Leave empty for unrestricted access |",
                    "type": "Label",
                    "options": {
                      "format": "markdown"
                    }
                  }
                ]
              },
              {
                "type": "Category",
                "label": "Examples",
                "elements": [
                  {
                    "text": "### Public API Route\n```json\n{\n  \"method\": \"GET\",\n  \"path\": \"/api/v1/wells\",\n  \"scope\": \"wells-service\",\n  \"visibility\": \"public\",\n  \"groups\": []\n}\n```\n\n### Protected Internal Route\n```json\n{\n  \"method\": \"POST\",\n  \"path\": \"/internal/sync\",\n  \"scope\": \"sync-service\",\n  \"visibility\": \"private\",\n  \"groups\": [\"AWS_PlataformaUpstream_Administrador_Desa\"]\n}\n```",
                    "type": "Label",
                    "options": {
                      "format": "markdown"
                    }
                  }
                ]
              }
            ]
          },
          {
            "type": "Group",
            "label": "Domains",
            "elements": [
              {
                "type": "Control",
                "scope": "#/properties/publicDomain"
              },
              {
                "type": "Control",
                "scope": "#/properties/privateDomain"
              }
            ]
          },
          {
            "type": "Group",
            "label": "Authorization",
            "elements": [
              {
                "type": "Control",
                "scope": "#/properties/authorization/properties/enabled"
              },
              {
                "type": "Control",
                "scope": "#/properties/authorization/properties/headerName",
                "rule": {
                  "effect": "SHOW",
                  "condition": {
                    "scope": "#/properties/authorization/properties/enabled",
                    "schema": { "const": true }
                  }
                }
              },
              {
                "type": "Control",
                "scope": "#/properties/authorization/properties/allowedValues",
                "rule": {
                  "effect": "SHOW",
                  "condition": {
                    "scope": "#/properties/authorization/properties/enabled",
                    "schema": { "const": true }
                  }
                }
              }
            ]
          },
          {
            "type": "Group",
            "label": "Routes",
            "elements": [
              {
                "type": "Control",
                "scope": "#/properties/routes",
                "options": {
                  "detail": {
                    "type": "VerticalLayout",
                    "elements": [
                      {
                        "type": "Control",
                        "label": "Verb",
                        "scope": "#/properties/method"
                      },
                      {
                        "type": "HorizontalLayout",
                        "elements": [
                          {
                            "type": "Control",
                            "label": "Path",
                            "scope": "#/properties/path"
                          },
                          {
                            "type": "Control",
                            "label": "Scope",
                            "scope": "#/properties/scope"
                          },
                          {
                            "type": "Control",
                            "label": "Visibility",
                            "scope": "#/properties/visibility"
                          }
                        ]
                      },
                      {
                        "type": "Control",
                        "label": "Groups",
                        "scope": "#/properties/groups"
                      }
                    ]
                  },
                  "showSortButtons": true
                }
              }
            ]
          }
        ]
      },
      "properties": {
        "routes": {
          "type": "array",
          "title": "Routes",
          "items": {
            "type": "object",
            "required": [
              "method",
              "path",
              "scope",
              "visibility"
            ],
            "properties": {
              "path": {
                "type": "string",
                "title": "Path"
              },
              "scope": {
                "type": "string",
                "title": "Scope",
                "additionalKeywords": {
                  "enum": "[.scopes[]?.slug]"
                }
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
              },
              "method": {
                "type": "string",
                "title": "Verb",
                "enum": [
                  "GET",
                  "POST",
                  "PUT",
                  "PATCH",
                  "DELETE",
                  "HEAD",
                  "OPTIONS"
                ]
              },
              "visibility": {
                "type": "string",
                "title": "Visibility",
                "default": "public",
                "enum": [
                  "public",
                  "private"
                ]
              }
            }
          }
        },
        "publicDomain": {
          "type": "string",
          "title": "Public Domain",
          "editableOn": [
            "create",
            "update"
          ],
          "enum": [
            "idp.poc.nullapps.io"
          ]
        },
        "privateDomain": {
          "type": "string",
          "title": "Private Domain",
          "editableOn": [
            "create",
            "update"
          ],
          "enum": [
            "idp.poc.nullapps.io"
          ]
        }
      }
    },
    "values": {}
  },
  "dimensions": {},
  "scopes": {},
  "name": "Endpoint exposer",
  "selectors": {
    "category": "any",
    "imported": false,
    "provider": "any",
    "sub_category": "any"
  },
  "slug": "endpoint-exposer",
  "type": "dependency",
  "use_default_actions": true,
  "available_actions": [
    "read"
  ],
  "available_links": [
  ],
  "visible_to": [
    "{{ env.Getenv "NRN" }}"
  ]
}
