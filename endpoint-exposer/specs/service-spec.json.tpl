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
                        },
                        {
                          "type": "Control",
                          "label": "Visibility",
                          "scope": "#/items/properties/visibility"
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
          "title": "Public Domain",
          "description": "Domain for public routes",
          "enum": [
            "birds.edenred.nullimplementation.com",
            "api.edenred.nullimplementation.com"
          ],
          "editableOn": ["create", "update"]
        },
        "privateDomain": {
          "type": "string",
          "title": "Private Domain",
          "description": "Domain for private routes",
          "enum": [
            "birds-private.edenred.nullimplementation.com",
            "api-private.edenred.nullimplementation.com"
          ],
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
              },
              "visibility": {
                "type": "string",
                "title": "Visibility",
                "description": "Route visibility level",
                "enum": ["public", "private"],
                "default": "public"
              }
            },
            "required": [
              "method",
              "path",
              "scope",
              "visibility"
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
