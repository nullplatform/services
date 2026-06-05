{
  "assignable_to": "dimension",
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": ["auth_type", "deny_public_traffic", "deny_private_traffic"],
      "anyOf": [
        {"properties": {"deny_public_traffic": {"const": true}}},
        {"properties": {"deny_private_traffic": {"const": true}}}
      ],
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
            "label": "Deny Public Traffic",
            "scope": "#/properties/deny_public_traffic"
          },
          {
            "type": "Control",
            "label": "Deny Private Traffic",
            "scope": "#/properties/deny_private_traffic"
          }
        ]
      },
      "properties": {
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
        "deny_public_traffic": {
          "type": "boolean",
          "title": "Deny Public Traffic",
          "description": "Block all unauthenticated traffic on the public gateway. At least one gateway must be protected.",
          "default": true,
          "editableOn": ["create", "update"]
        },
        "deny_private_traffic": {
          "type": "boolean",
          "title": "Deny Private Traffic",
          "description": "Block all unauthenticated traffic on the private gateway. At least one gateway must be protected.",
          "default": true,
          "editableOn": ["create", "update"]
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
  "available_links": [
    "route"
  ],
  "visible_to": [
    "{{ env.Getenv `NRN` }}"
  ]
}
