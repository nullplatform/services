{
    "name": "Postgres DB",
    "slug": "postgres-db",
    "type": "dependency",
    "use_default_actions": true,
    "available_actions": [
        "run-ddl-query",
        "run-dml-query"
    ],
    "available_links": [
        "database-user"
    ],
    "agent_command":{
        "data": {
        "cmdline": "nullplatform/services/databases/postgres/k8s/handle-service-agent",
        "environment": {
            "NP_ACTION_CONTEXT": "${NOTIFICATION_CONTEXT}"
        }
        },
        "type": "exec"
    },
    "attributes": {
        "schema": {
            "type": "object",
            "required": [
                "usage_type",
                "pii"
            ],
            "properties": {
                "pii": {
                    "type": "boolean",
                    "default": false,
                    "description": "Will you store personal user information (email, name, id, etc)?"
                },
                "port": {
                    "type": "number",
                    "export": true,
                    "visibleOn": [
                        "read"
                    ],
                    "editableOn": []
                },
                "dbname": {
                    "type": "string",
                    "export": true,
                    "visibleOn": [
                        "read"
                    ],
                    "editableOn": []
                },
                "hostname": {
                    "type": "string",
                    "export": true,
                    "visibleOn": [
                        "read"
                    ],
                    "editableOn": []
                },
                "usage_type": {
                    "enum": [
                        "transactions",
                        "cache",
                        "configurations"
                    ],
                    "type": "string",
                    "description": "What this database is used for?"
                },
                "k8s_secret_name": {
                    "type": "string",
                    "export": false,
                    "visibleOn": [],
                    "editableOn": []
                },
                "helm_release_name": {
                    "type": "string",
                    "export": false,
                    "visibleOn": [],
                    "editableOn": []
                }
            }
        },
        "values": {}
    },
    "selectors": {
        "category": "Database",
        "imported": false,
        "provider": "K8S",
        "sub_category": "Relational Database"
    }
}
