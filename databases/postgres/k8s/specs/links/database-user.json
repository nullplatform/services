{
    "name": "database-user",
    "slug": "database-user",
    "visible_to": [],
    "unique": false,
    "dimensions": {},
    "assignable_to": "any",
    "use_default_actions": true,
    "attributes": {
        "schema": {
            "type": "object",
            "required": [
                "permisions"
            ],
            "properties": {
                "password": {
                    "type": "string",
                    "export": {
                        "type": "environment_variable",
                        "secret": true
                    },
                    "secret": true,
                    "visibleOn": [
                        "read"
                    ],
                    "editableOn": []
                },
                "username": {
                    "type": "string",
                    "export": true,
                    "visibleOn": [
                        "read"
                    ],
                    "editableOn": []
                },
                "permisions": {
                    "type": "object",
                    "properties": {
                        "read": {
                            "type": "boolean",
                            "default": true,
                            "description": "User will have read permisions"
                        },
                        "admin": {
                            "type": "boolean",
                            "default": false,
                            "description": "User will have DDL permisions"
                        },
                        "write": {
                            "type": "boolean",
                            "default": false,
                            "description": "User will have write permisions"
                        }
                    }
                }
            }
        },
        "values": {}
    },
    "selectors": {
        "category": "any",
        "imported": false,
        "provider": "any",
        "sub_category": "any"
    }
}