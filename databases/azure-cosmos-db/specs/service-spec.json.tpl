{
  "id": "d2f57fb3-8664-43c6-bdd4-3f8f06309084",
  "name": "Azure Cosmos DB",
  "slug": "azure-cosmos-db",
  "type": "dependency",
  "visible_to": [
    "organization=1698562351:account=2097086864"
  ],
  "unique": false,
  "dimensions": {},
  "scopes": {},
  "assignable_to": "any",
  "use_default_actions": true,
  "selectors": {
    "category": "Database",
    "imported": false,
    "provider": "Azure",
    "sub_category": "NoSQL Database"
  },
  "attributes": {
    "values": {}
  },
  "specification_schema": {
    "type": "object",
    "$schema": "http://json-schema.org/draft-07/schema#",
    "required": [
      "containers"
    ],
    "properties": {
      "containers": {
        "type": "array",
        "items": {
          "type": "object",
          "required": [
            "containerName",
            "partitionKey"
          ],
          "properties": {
            "partitionKey": {
              "type": "string",
              "order": 2,
              "title": "Partition Key",
              "editableOn": [
                "create"
              ],
              "description": "Partition key path (e.g., /customerId, /tenantId)"
            },
            "containerName": {
              "type": "string",
              "order": 1,
              "title": "Container Name",
              "editableOn": [
                "create"
              ],
              "description": "Name of the container to store documents"
            }
          }
        },
        "title": "Containers",
        "minItems": 1,
        "editableOn": [
          "create",
          "update"
        ],
        "description": "List of containers in this database"
      }
    }
  }
}