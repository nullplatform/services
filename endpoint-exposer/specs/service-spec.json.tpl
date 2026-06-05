{
  "assignable_to": "dimension",
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": ["auth_type"],
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
