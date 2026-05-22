{
  "assignable_to": "dimension",
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": [],
      "uiSchema": {
        "type": "VerticalLayout",
        "elements": []
      },
      "properties": {}
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
