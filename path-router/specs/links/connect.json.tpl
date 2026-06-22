{
    "name": "Connect",
    "slug": "connect",
    "unique": false,
    "assignable_to": "any",
    "use_default_actions": false,
    "attributes": {
        "schema": {
            "type": "object",
            "$schema": "http://json-schema.org/draft-07/schema#",
            "required": ["path_prefix", "scope"],
            "uiSchema": {
                "type": "VerticalLayout",
                "elements": [
                    {
                        "type": "Control",
                        "label": "Path Prefix",
                        "scope": "#/properties/path_prefix"
                    },
                    {
                        "type": "Control",
                        "label": "Scope",
                        "scope": "#/properties/scope"
                    }
                ]
            },
            "properties": {
                "path_prefix": {
                    "type": "string",
                    "title": "Path Prefix",
                    "pattern": "^/[a-zA-Z0-9_\\-]+$",
                    "description": "Path prefix to route to this application. Example: /APP1, /api-gateway, /bff-checkout"
                },
                "scope": {
                    "type": "string",
                    "title": "Scope",
                    "description": "Target scope of this application to route traffic to.",
                    "additionalKeywords": {
                        "enum": "[.scopes[]? | select(.status == \"active\")] | if length == 0 then [\"No scopes available\"] else [.[].slug] end"
                    }
                }
            }
        },
        "values": {}
    }
}
