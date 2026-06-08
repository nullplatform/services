{
  "assignable_to": "dimension",
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": ["environment", "auth_type", "routes"],
      "if": {
        "properties": { "auth_type": { "const": "aws-avp" } }
      },
      "then": {
        "required": ["avp_policy_store_arn"]
      },
      "else": {
        "if": {
          "properties": { "auth_type": { "const": "aws-cognito" } }
        },
        "then": {
          "required": ["cognito_user_pool_arn"]
        }
      },
      "uiSchema": {
        "type": "VerticalLayout",
        "elements": [
          {
            "type": "Control",
            "label": "Environment",
            "scope": "#/properties/environment"
          },
          {
            "type": "Control",
            "label": "Authorization Scheme",
            "scope": "#/properties/auth_type"
          },
          {
            "type": "Control",
            "label": "AVP Policy Store ARN",
            "scope": "#/properties/avp_policy_store_arn",
            "rule": {
              "effect": "HIDE",
              "condition": {
                "scope": "#/properties/auth_type",
                "schema": { "not": { "const": "aws-avp" } }
              }
            }
          },
          {
            "type": "Control",
            "label": "Cognito User Pool ARN",
            "scope": "#/properties/cognito_user_pool_arn",
            "rule": {
              "effect": "HIDE",
              "condition": {
                "scope": "#/properties/auth_type",
                "schema": { "not": { "const": "aws-cognito" } }
              }
            }
          },
          {
            "type": "Control",
            "label": "Routes",
            "scope": "#/properties/routes",
            "options": {
              "showSortButtons": true,
              "detail": {
                "type": "VerticalLayout",
                "elements": [
                  {"type": "Control", "label": "Verbs", "scope": "#/properties/methods"},
                  {"type": "Control", "label": "Path", "scope": "#/properties/path"},
                  {"type": "Control", "label": "Scope", "scope": "#/properties/scope"},
                  {"type": "Control", "label": "Authorized Groups", "scope": "#/properties/groups"}
                ]
              }
            }
          }
        ]
      },
      "properties": {
        "environment": {
          "type": "string",
          "title": "Environment",
          "description": "Select the environment this service applies to.",
          "editableOn": ["create"],
          "enum": ["dev", "test", "prod"]
        },
        "auth_type": {
          "type": "string",
          "title": "Authorization Scheme",
          "description": "Authorization scheme to use for endpoint protection.",
          "enum": ["aws-avp", "aws-cognito"],
          "editableOn": ["create"]
        },
        "avp_policy_store_arn": {
          "type": "string",
          "title": "AVP Policy Store ARN",
          "description": "ARN of the Amazon Verified Permissions Policy Store (arn:aws:verifiedpermissions::account-id:policy-store/id).",
          "editableOn": ["create"]
        },
        "cognito_user_pool_arn": {
          "type": "string",
          "title": "Cognito User Pool ARN",
          "description": "ARN of the Cognito User Pool for JWT validation (arn:aws:cognito-idp:region:account-id:userpool/pool-id).",
          "editableOn": ["create", "update"]
        },
        "routes": {
          "type": "array",
          "title": "Routes",
          "description": "HTTP routes to protect. Each rule defines a path, method, scope and authorized groups.",
          "editableOn": ["create", "update"],
          "items": {
            "type": "object",
            "required": ["methods", "path", "scope"],
            "properties": {
              "methods": {
                "type": "array",
                "title": "Verbs",
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
              "scope": {
                "type": "string",
                "title": "Scope",
                "description": "The scope this rule applies to (filtered by selected dimension).",
                "additionalKeywords": {
                  "enum": "[.scopes[] | select(.dimensions == (.dimensions // {})) | .slug]"
                }
              },
              "groups": {
                "type": "string",
                "title": "Authorized Groups",
                "description": "Comma-separated list of groups allowed to access this route. Leave empty to allow any authenticated user.",
                "editableOn": ["create", "update"]
              }
            }
          }
        }
      }
    },
    "values": {}
  },
  "dimensions": {},
  "scopes": {},
  "name": "HTTP Route Access Control",
  "selectors": {
    "category": "Security",
    "imported": false,
    "provider": "Istio",
    "sub_category": "Access Control"
  },
  "slug": "http-route-access-control",
  "type": "dependency",
  "use_default_actions": true,
  "available_actions": [],
  "available_links": [],
  "visible_to": [
    "{{ env.Getenv `NRN` }}"
  ]
}
