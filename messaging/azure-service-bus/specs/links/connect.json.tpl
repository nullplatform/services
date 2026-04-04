{
  "id": "f4b2e8d3-0c5a-4f9e-b3d7-4e5f6a7b8c9d",
  "name": "Connect",
  "slug": "connect",
  "visible_to": [],
  "dimensions": {},
  "scopes": {},
  "assignable_to": "any",
  "use_default_actions": true,
  "selectors": {
    "category": "Messaging",
    "imported": false,
    "provider": "Azure",
    "sub_category": "Message Bus"
  },
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": ["access_level"],
      "properties": {
        "access_level": {
          "type": "string",
          "title": "Access Level",
          "description": "Permission level granted to the application on this Service Bus namespace",
          "enum": ["sender", "receiver", "owner"],
          "default": "receiver",
          "editableOn": ["create", "update"]
        }
      }
    },
    "values": {}
  }
}
