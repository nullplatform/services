{
    "name": "Path Router",
    "slug": "path-router",
    "type": "dependency",
    "visible_to": ["{{ env.Getenv `NRN` }}"],
    "dimensions": {},
    "scopes": {},
    "assignable_to": "any",
    "use_default_actions": true,
    "attributes": {
        "schema": {
            "type": "object",
            "$schema": "http://json-schema.org/draft-07/schema#",
            "required": ["base_domain"],
            "uiSchema": {
                "type": "VerticalLayout",
                "elements": [
                    {
                        "type": "Control",
                        "label": "Base Domain",
                        "scope": "#/properties/base_domain"
                    },
                    {
                        "type": "Control",
                        "label": "Gateway",
                        "scope": "#/properties/gateway",
                        "options": { "format": "radio" }
                    },
                    {
                        "type": "Control",
                        "label": "Strip path prefix before forwarding",
                        "scope": "#/properties/strip_prefix"
                    }
                ]
            },
            "properties": {
                "base_domain": {
                    "type": "string",
                    "title": "Base Domain",
                    "description": "Shared domain for all path-based routes. Example: svc.dev.galiciaseguro.com.ar"
                },
                "gateway": {
                    "type": "string",
                    "title": "Gateway",
                    "oneOf": [
                        {"const": "public", "title": "Public (internet-facing)"},
                        {"const": "private", "title": "Private (internal)"}
                    ],
                    "default": "public"
                },
                "strip_prefix": {
                    "type": "boolean",
                    "title": "Strip path prefix",
                    "description": "Remove the path prefix before forwarding to the backend. When enabled, /APP1/health is forwarded as /health.",
                    "default": true
                }
            }
        },
        "values": {}
    },
    "selectors": {
        "category": "Networking",
        "imported": false,
        "provider": "Istio",
        "sub_category": "Path Routing"
    }
}
