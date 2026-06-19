{
  "id": "e3a1f7c2-9b4d-4e8f-a2c6-3d5e6f7a8b9c",
  "name": "Azure Service Bus",
  "slug": "azure-service-bus",
  "type": "dependency",
  "visible_to": [],
  "dimensions": {},
  "scopes": {},
  "assignable_to": "any",
  "use_default_actions": true,
  "available_actions": [],
  "available_links": ["connect"],
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
      "required": [],
      "properties": {
        "queues": {
          "type": "array",
          "title": "Queues",
          "description": "List of queues to create in the Service Bus namespace",
          "editableOn": ["create", "update"],
          "items": {
            "type": "object",
            "required": ["name"],
            "properties": {
              "name": {
                "type": "string",
                "order": 1,
                "title": "Queue Name",
                "description": "Name of the queue",
                "editableOn": ["create"]
              }
            }
          }
        },
        "topics": {
          "type": "array",
          "title": "Topics",
          "description": "List of topics to create in the Service Bus namespace",
          "editableOn": ["create", "update"],
          "items": {
            "type": "object",
            "required": ["name"],
            "properties": {
              "name": {
                "type": "string",
                "order": 1,
                "title": "Topic Name",
                "description": "Name of the topic",
                "editableOn": ["create"]
              },
              "subscriptions": {
                "type": "array",
                "order": 2,
                "title": "Subscriptions",
                "description": "List of subscriptions for this topic",
                "editableOn": ["create", "update"],
                "items": {
                  "type": "object",
                  "required": ["name"],
                  "properties": {
                    "name": {
                      "type": "string",
                      "title": "Subscription Name",
                      "description": "Name of the subscription",
                      "editableOn": ["create"]
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    "values": {}
  }
}
