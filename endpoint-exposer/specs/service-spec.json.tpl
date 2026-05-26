{
  "assignable_to": "dimension",
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": ["avp_policy_store_id"],
      "uiSchema": {
        "type": "VerticalLayout",
        "elements": [
          {
            "type": "Control",
            "label": "AVP Policy Store ID",
            "scope": "#/properties/avp_policy_store_id"
          }
        ]
      },
      "properties": {
        "avp_policy_store_id": {
          "type": "string",
          "title": "AVP Policy Store ID",
          "description": "Amazon Verified Permissions Policy Store ID associated with the Lambda authorizer for this cluster. Obtained from the 'policy_store_id' output of the security Terraform module.",
          "editableOn": ["create"]
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
    "{{ env.Getenv \"NRN\" }}"
  ]
}
