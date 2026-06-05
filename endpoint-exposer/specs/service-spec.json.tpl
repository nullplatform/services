{
  "assignable_to": "dimension",
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": ["auth_type"],
      "if": {
        "properties": { "auth_type": { "const": "avp" } }
      },
      "then": {
        "required": ["avp_policy_store_id"]
      },
      "else": {
        "if": {
          "properties": { "auth_type": { "const": "istio-jwt" } }
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
            "label": "Authorization Scheme",
            "scope": "#/properties/auth_type"
          },
          {
            "type": "Control",
            "label": "AVP Policy Store ID",
            "scope": "#/properties/avp_policy_store_id",
            "rule": {
              "effect": "HIDE",
              "condition": {
                "scope": "#/properties/auth_type",
                "schema": { "not": { "const": "avp" } }
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
                "schema": { "not": { "const": "istio-jwt" } }
              }
            }
          }
        ]
      },
      "properties": {
        "auth_type": {
          "type": "string",
          "title": "Authorization Scheme",
          "description": "Authorization scheme to use for endpoint protection.",
          "enum": ["avp", "istio-jwt"],
          "default": "avp",
          "editableOn": ["create"]
        },
        "avp_policy_store_id": {
          "type": "string",
          "title": "AVP Policy Store ID",
          "description": "Amazon Verified Permissions Policy Store ID. Obtained from the 'policy_store_id' output of the security Terraform module.",
          "editableOn": ["create"]
        },
        "cognito_user_pool_arn": {
          "type": "string",
          "title": "Cognito User Pool ARN",
          "description": "ARN of the Cognito User Pool for JWT validation (arn:aws:cognito-idp:region:account-id:userpool/pool-id).",
          "editableOn": ["create", "update"]
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
  "available_actions": [],
  "available_links": [
    "route"
  ],
  "visible_to": [
    "{{ env.Getenv `NRN` }}"
  ]
}
