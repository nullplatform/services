{
  "assignable_to": "dimension",
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": [],
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
          "description": "ID del Policy Store de Amazon Verified Permissions. Si se deja vacío, se creará un policy store de AVP por defecto.",
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
