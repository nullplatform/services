{
  "assignable_to": "dimension",
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "uiSchema": {
        "type": "VerticalLayout",
        "elements": [
          {
            "type": "Group",
            "label": "Domain",
            "elements": [
              {
                "type": "Control",
                "scope": "#/properties/publicDomain"
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
                      "type": "GridLayout",
                      "columns": 4,
                      "elements": [
                        {
                          "type": "Control",
                          "label": "Verb",
                          "scope": "#/items/properties/method"
                        },
                        {
                          "type": "Control",
                          "label": "Path",
                          "scope": "#/items/properties/path"
                        },
                        {
                          "type": "Control",
                          "label": "Scope",
                          "scope": "#/items/properties/scope"
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
        "publicDomain": {
          "type": "string",
          "editableOn": ["create", "update"]
        },
        "routes": {
          "items": {
            "properties": {
              "method": {
                "type": "string",
                "title": "Verb",
                "enum": ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
              },
              "path": {
                "type": "string",
                "title": "Path"
              },
              "scope": {
                "type": "string",
                "title": "Scope",
                "description": "The scope slug",
                "additionalKeywords": {
                  "enum": "[.scopes[]?.slug]"
                }
              }
            },
            "required": [
              "method",
              "path",
              "scope"
            ],
            "type": "object"
          },
          "type": "array"
        }
      },
      "required": [
        "publicDomain"
      ],
      "type": "object"
    },
    "values": {}
  },
  "dimensions": {},
  "name": "Service exposer V2",
  "selectors": {
    "category": "any",
    "imported": false,
    "provider": "any",
    "sub_category": "any"
  },
  "slug": "service-exposer",
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
