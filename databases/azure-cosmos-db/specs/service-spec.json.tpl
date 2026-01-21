{
  "id": "b9f5f4d2-b489-4473-8d9a-d6122d0b3878",
  "name": "Azure Cosmos DB",
  "slug": "azure-cosmos-db",
  "type": "dependency",
  "visible_to": [
    "organization=1698562351"
  ],
  "dimensions": {},
  "scopes": {},
  "assignable_to": "any",
  "use_default_actions": true,
  "available_actions": [],
  "available_links": [],
  "selectors": {
    "category": "Database",
    "imported": false,
    "provider": "Azure",
    "sub_category": "NoSQL Database"
  },
  "attributes": {
    "schema": {
      "type": "object",
      "$schema": "http://json-schema.org/draft-07/schema#",
      "required": [
        "accountName",
        "databaseName",
        "containers"
      ],
      "uiSchema": {
        "type": "VerticalLayout",
        "elements": [
          {
            "type": "Group",
            "label": "Connection Info",
            "elements": [
              {
                "type": "HorizontalLayout",
                "elements": [
                  {
                    "type": "Control",
                    "scope": "#/properties/accountName"
                  },
                  {
                    "type": "Control",
                    "scope": "#/properties/endpoint",
                    "options": {
                      "readonly": true
                    }
                  }
                ]
              }
            ]
          },
          {
            "type": "Group",
            "label": "Database Configuration",
            "elements": [
              {
                "type": "Control",
                "scope": "#/properties/databaseName"
              },
              {
                "type": "Control",
                "scope": "#/properties/containers",
                "options": {
                  "detail": {
                    "type": "VerticalLayout",
                    "elements": [
                      {
                        "type": "Control",
                        "scope": "#/properties/containerName"
                      },
                      {
                        "type": "Control",
                        "scope": "#/properties/partitionKey"
                      }
                    ]
                  },
                  "showSortButtons": false,
                  "elementLabelProp": "containerName"
                }
              }
            ]
          },
          {
            "type": "Categorization",
            "options": {
              "collapsable": {
                "label": "ADVANCED",
                "collapsed": true
              }
            },
            "elements": [
              {
                "type": "Category",
                "label": "Capacity & Consistency",
                "elements": [
                  {
                    "type": "Control",
                    "scope": "#/properties/capacityMode"
                  },
                  {
                    "type": "Control",
                    "scope": "#/properties/consistencyLevel"
                  }
                ]
              }
            ]
          }
        ]
      },
      "properties": {
        "accountName": {
          "type": "string",
          "title": "Account Name",
          "description": "Cosmos DB account name",
          "editableOn": [
            "create"
          ]
        },
        "endpoint": {
          "type": "string",
          "title": "Endpoint",
          "description": "Cosmos DB account endpoint URL",
          "editableOn": []
        },
        "databaseName": {
          "type": "string",
          "title": "Database Name",
          "description": "Name of the Cosmos DB database",
          "editableOn": [
            "create"
          ]
        },
        "containers": {
          "type": "array",
          "title": "Containers",
          "description": "List of containers in this database",
          "minItems": 1,
          "editableOn": [
            "create",
            "update"
          ],
          "items": {
            "type": "object",
            "required": [
              "containerName",
              "partitionKey"
            ],
            "properties": {
              "containerName": {
                "type": "string",
                "title": "Container Name",
                "description": "Name of the container to store documents",
                "editableOn": [
                  "create"
                ]
              },
              "partitionKey": {
                "type": "string",
                "title": "Partition Key",
                "description": "Partition key path (e.g., /customerId, /tenantId)",
                "editableOn": [
                  "create"
                ]
              },
              "throughput": {
                "type": "number",
                "title": "Throughput (RU/s)",
                "description": "Request Units per second (400 - 1000000)",
                "default": 400,
                "editableOn": [
                  "create",
                  "update"
                ]
              },
              "throughputType": {
                "type": "string",
                "title": "Throughput Type",
                "description": "Manual: fixed RU/s, Autoscale: scales automatically",
                "enum": [
                  "manual",
                  "autoscale"
                ],
                "default": "autoscale",
                "editableOn": [
                  "create"
                ]
              },
              "defaultTtl": {
                "type": "number",
                "title": "Default TTL (seconds)",
                "description": "Time to live for documents (-1 = disabled)",
                "default": -1,
                "editableOn": [
                  "create",
                  "update"
                ]
              }
            }
          }
        },
        "capacityMode": {
          "type": "string",
          "title": "Capacity Mode",
          "description": "Provisioned: fixed RU/s, Serverless: pay per request",
          "enum": [
            "provisioned",
            "serverless"
          ],
          "default": "provisioned",
          "editableOn": [
            "create"
          ]
        },
        "consistencyLevel": {
          "type": "string",
          "title": "Consistency Level",
          "description": "Data consistency guarantee across replicas",
          "enum": [
            "Strong",
            "BoundedStaleness",
            "Session",
            "ConsistentPrefix",
            "Eventual"
          ],
          "default": "Session",
          "editableOn": [
            "create"
          ]
        }
      }
    },
    "values": {}
  }
}