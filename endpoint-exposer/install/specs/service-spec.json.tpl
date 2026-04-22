{
    "name": "Endpoint Exposer",
    "type": "dependency",
    "visible_to": [],
    "dimensions": {},
    "scopes": {},
    "assignable_to": "any",
    "use_default_actions": true,
    "attributes": {
        "schema": {
            "type": "object",
            "$schema": "http://json-schema.org/draft-07/schema#",
            "required": [
                "publicDomain"
            ],
            "uiSchema": {
                "type": "VerticalLayout",
                "elements": [
                    {
                        "type": "Categorization",
                        "options": {
                            "collapsable": {
                                "label": "Documentation",
                                "collapsed": true
                            }
                        },
                        "elements": [
                            {
                                "type": "Category",
                                "label": "Domains",
                                "elements": [
                                    {
                                        "text": "### Public Domain\nBase domain for routes exposed to external traffic. Requests matching routes with `visibility: public` will be served through this domain.\n\n### Private Domain\nBase domain for routes accessible only within the internal network. Use this for service-to-service communication.",
                                        "type": "Label",
                                        "options": {
                                            "format": "markdown"
                                        }
                                    }
                                ]
                            },
                            {
                                "type": "Category",
                                "label": "Routes",
                                "elements": [
                                    {
                                        "text": "### Route Configuration\nDefine how incoming requests are matched and forwarded to backend services.\n\n| Field | Description |\n|-------|-------------|\n| **Verb** | HTTP method to match (GET, POST, PUT, etc.) |\n| **Path** | URL path pattern. See *Path Types* below |\n| **Scope** | Target service that will handle the request |\n| **Visibility** | `public` (external) or `private` (internal network only) |\n\n### Path Types\n| Type | Example | Description |\n|------|---------|-------------|\n| **Exact** | `/api/users` | Matches the exact path only |\n| **Parameterized** | `/api/users/{id}` | Matches path with dynamic segments |\n| **Wildcard** | `/api/users/*` | Matches any path starting with the prefix |",
                                        "type": "Label",
                                        "options": {
                                            "format": "markdown"
                                        }
                                    }
                                ]
                            },
                            {
                                "type": "Category",
                                "label": "Examples",
                                "elements": [
                                    {
                                        "text": "### Public API Route\n```json\n{\n  \"method\": \"GET\",\n  \"path\": \"/api/v1/wells\",\n  \"scope\": \"wells-service\",\n  \"visibility\": \"public\"\n}\n```\n\n### Private Internal Route\n```json\n{\n  \"method\": \"POST\",\n  \"path\": \"/internal/sync\",\n  \"scope\": \"sync-service\",\n  \"visibility\": \"private\"\n}\n```",
                                        "type": "Label",
                                        "options": {
                                            "format": "markdown"
                                        }
                                    }
                                ]
                            }
                        ]
                    },
                    {
                        "type": "Control",
                        "scope": "#/properties/environment"
                    },
                    {
                        "type": "Group",
                        "label": "Domains",
                        "elements": [
                            {
                                "type": "Control",
                                "scope": "#/properties/publicDomain"
                            },
                            {
                                "type": "Control",
                                "scope": "#/properties/privateDomain"
                            }
                        ]
                    },
                    {
                        "type": "Group",
                        "label": "Routes",
                        "elements": [
                            {
                                "type": "Control",
                                "scope": "#/properties/routes",
                                "options": {
                                    "detail": {
                                        "type": "VerticalLayout",
                                        "elements": [
                                            {
                                                "type": "Control",
                                                "label": "Verb",
                                                "scope": "#/properties/method"
                                            },
                                            {
                                                "type": "HorizontalLayout",
                                                "elements": [
                                                    {
                                                        "type": "Control",
                                                        "label": "Path",
                                                        "scope": "#/properties/path"
                                                    },
                                                    {
                                                        "type": "Control",
                                                        "label": "Scope",
                                                        "scope": "#/properties/scope"
                                                    },
                                                    {
                                                        "type": "Control",
                                                        "label": "Visibility",
                                                        "scope": "#/properties/visibility"
                                                    }
                                                ]
                                            }
                                        ]
                                    },
                                    "showSortButtons": true
                                }
                            }
                        ]
                    }
                ]
            },
            "properties": {
                "routes": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "required": [
                            "method",
                            "path",
                            "scope",
                            "visibility"
                        ],
                        "properties": {
                            "path": {
                                "type": "string",
                                "title": "Path"
                            },
                            "scope": {
                                "type": "string",
                                "title": "Scope",
                                "additionalKeywords": {
                                    "enum": "[.scopes[]?.slug] | if length == 0 then [\"No scopes available for selected environment\"] else . end"
                                }
                            },
                            "method": {
                                "enum": [
                                    "GET",
                                    "POST",
                                    "PUT",
                                    "PATCH",
                                    "DELETE",
                                    "HEAD",
                                    "OPTIONS"
                                ],
                                "type": "string",
                                "title": "Verb"
                            },
                            "visibility": {
                                "enum": [
                                    "public",
                                    "private"
                                ],
                                "type": "string",
                                "title": "Visibility",
                                "default": "public"
                            }
                        }
                    },
                    "title": "Routes"
                },
                "environment": {
                    "type": "string",
                    "title": "Environment",
                    "additionalKeywords": {
                        "enum": "[.scopes[]?.dimensions?.environment] | unique | if length == 0 then [\"No environments available\"] else . end"
                    }
                },
                "publicDomain": {
                    "type": "string",
                    "title": "Public Domain",
                    "description": "Base domain for routes with visibility=public. Tenant-specific — provide the FQDN that resolves to the public Istio gateway of the target cluster.",
                    "editableOn": [
                        "create",
                        "update"
                    ]
                },
                "privateDomain": {
                    "type": "string",
                    "title": "Private Domain",
                    "description": "Base domain for routes with visibility=private. Tenant-specific — provide the FQDN that resolves to the private (internal) Istio gateway of the target cluster.",
                    "editableOn": [
                        "create",
                        "update"
                    ]
                }
            }
        },
        "values": {}
    },
    "selectors": {
        "category": "Networking",
        "imported": false,
        "provider": "K8S",
        "sub_category": "HTTP Routing"
    }
}
