{
    "name":  "{{ env.Getenv \"SERVICE_NAME\" | default \"Endpoint Exposer\" }}",
    "type": "dependency",
    "visible_to": [
        "{{ env.Getenv \"NRN\" }}"
    ],
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
                                        "text": "### Route Configuration\nDefine how incoming requests are matched and forwarded to backend services.\n\n| Field | Description |\n|-------|-------------|\n| **Verb** | HTTP method to match (GET, POST, PUT, etc.) |\n| **Path** | URL path pattern. See *Path Types* below |\n| **Scope** | Target service that will handle the request |\n| **Visibility** | `public` (external) or `private` (internal network only) |\n| **Groups** | Security groups allowed to access this route. Leave empty for unrestricted access |\n\n### Path Types\n| Type | Example | Description |\n|------|---------|-------------|\n| **Exact** | `/api/users` | Matches the exact path only |\n| **Parameterized** | `/api/users/{id}` | Matches path with dynamic segments |\n| **Wildcard** | `/api/users/*` | Matches any path starting with the prefix |",
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
                                        "text": "### Public API Route\n```json\n{\n  \"method\": \"GET\",\n  \"path\": \"/api/v1/wells\",\n  \"scope\": \"wells-service\",\n  \"visibility\": \"public\",\n  \"groups\": []\n}\n```\n\n### Protected Internal Route\n```json\n{\n  \"method\": \"POST\",\n  \"path\": \"/internal/sync\",\n  \"scope\": \"sync-service\",\n  \"visibility\": \"private\",\n  \"groups\": [\"AWS_PlataformaUpstream_Administrador_Desa\"]\n}\n```",
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
                                            },
                                            {
                                                "type": "Control",
                                                "label": "Groups",
                                                "scope": "#/properties/groups"
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
                            "visibility",
                            "environment"
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
                            "groups": {
                                "type": "array",
                                "items": {
                                    "enum": [
                                        "AWS_PlataformaUpstream_Gestor_Desa",
                                        "AWS_PlataformaUpstream_Programador_Desa",
                                        "AWS_PlataformaUpstream_Pulling_Desa",
                                        "AWS_PlataformaUpstream_Workover_Desa",
                                        "AWS_PlataformaUpstream_Visita_Desa",
                                        "AWS_PlataformaUpstream_Administrador_Desa"
                                    ],
                                    "type": "string"
                                },
                                "title": "Authorized Groups",
                                "uniqueItems": true
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
                    "enum": [
                        "hello.idp.poc.nullapps.io"
                    ],
                    "type": "string",
                    "title": "Public Domain",
                    "editableOn": [
                        "create",
                        "update"
                    ]
                },
                "privateDomain": {
                    "enum": [
                        "hello.idp.poc.nullapps.io"
                    ],
                    "type": "string",
                    "title": "Private Domain",
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
    },
    "action_specifications": [
        {
            "name": "Read",
            "slug": "read",
            "type": "custom",
            "parameters": {
                "schema": {
                    "type": "object",
                    "required": [],
                    "properties": {}
                },
                "values": {}
            },
            "results": {
                "schema": {
                    "type": "object",
                    "required": [],
                    "properties": {}
                },
                "values": {}
            },
            "icon": "",
            "annotations": {},
            "enabled_when": ""
        },
        {
            "name": "delete Endpoint Exposer",
            "slug": "delete-endpoint-exposer",
            "type": "delete",
            "parameters": {
                "schema": {
                    "type": "object",
                    "$schema": "http://json-schema.org/draft-07/schema#",
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
                                                "text": "### Route Configuration\nDefine how incoming requests are matched and forwarded to backend services.\n\n| Field | Description |\n|-------|-------------|\n| **Verb** | HTTP method to match (GET, POST, PUT, etc.) |\n| **Path** | URL path pattern. See *Path Types* below |\n| **Scope** | Target service that will handle the request |\n| **Visibility** | `public` (external) or `private` (internal network only) |\n| **Groups** | Security groups allowed to access this route. Leave empty for unrestricted access |\n\n### Path Types\n| Type | Example | Description |\n|------|---------|-------------|\n| **Exact** | `/api/users` | Matches the exact path only |\n| **Parameterized** | `/api/users/{id}` | Matches path with dynamic segments |\n| **Wildcard** | `/api/users/*` | Matches any path starting with the prefix |",
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
                                                "text": "### Public API Route\n```json\n{\n  \"method\": \"GET\",\n  \"path\": \"/api/v1/wells\",\n  \"scope\": \"wells-service\",\n  \"visibility\": \"public\",\n  \"groups\": []\n}\n```\n\n### Protected Internal Route\n```json\n{\n  \"method\": \"POST\",\n  \"path\": \"/internal/sync\",\n  \"scope\": \"sync-service\",\n  \"visibility\": \"private\",\n  \"groups\": [\"AWS_PlataformaUpstream_Administrador_Desa\"]\n}\n```",
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
                                                    },
                                                    {
                                                        "type": "Control",
                                                        "label": "Groups",
                                                        "scope": "#/properties/groups"
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
                                    "groups": {
                                        "type": "array",
                                        "items": {
                                            "enum": [
                                                "AWS_PlataformaUpstream_Gestor_Desa",
                                                "AWS_PlataformaUpstream_Programador_Desa",
                                                "AWS_PlataformaUpstream_Pulling_Desa",
                                                "AWS_PlataformaUpstream_Workover_Desa",
                                                "AWS_PlataformaUpstream_Visita_Desa",
                                                "AWS_PlataformaUpstream_Administrador_Desa"
                                            ],
                                            "type": "string"
                                        },
                                        "title": "Authorized Groups",
                                        "uniqueItems": true
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
                            "title": "Routes",
                            "target": "routes"
                        },
                        "environment": {
                            "type": "string",
                            "title": "Environment",
                            "target": "environment",
                            "additionalKeywords": {
                                "enum": "[.scopes[]?.dimensions?.environment] | unique | if length == 0 then [\"No environments available\"] else . end"
                            }
                        },
                        "publicDomain": {
                            "enum": [
                                "hello.idp.poc.nullapps.io"
                            ],
                            "type": "string",
                            "title": "Public Domain",
                            "target": "publicDomain",
                            "editableOn": [
                                "create",
                                "update"
                            ]
                        },
                        "privateDomain": {
                            "enum": [
                                "hello.idp.poc.nullapps.io"
                            ],
                            "type": "string",
                            "title": "Private Domain",
                            "target": "privateDomain",
                            "editableOn": [
                                "create",
                                "update"
                            ]
                        }
                    }
                },
                "values": {}
            },
            "results": {
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
                                                "text": "### Route Configuration\nDefine how incoming requests are matched and forwarded to backend services.\n\n| Field | Description |\n|-------|-------------|\n| **Verb** | HTTP method to match (GET, POST, PUT, etc.) |\n| **Path** | URL path pattern. See *Path Types* below |\n| **Scope** | Target service that will handle the request |\n| **Visibility** | `public` (external) or `private` (internal network only) |\n| **Groups** | Security groups allowed to access this route. Leave empty for unrestricted access |\n\n### Path Types\n| Type | Example | Description |\n|------|---------|-------------|\n| **Exact** | `/api/users` | Matches the exact path only |\n| **Parameterized** | `/api/users/{id}` | Matches path with dynamic segments |\n| **Wildcard** | `/api/users/*` | Matches any path starting with the prefix |",
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
                                                "text": "### Public API Route\n```json\n{\n  \"method\": \"GET\",\n  \"path\": \"/api/v1/wells\",\n  \"scope\": \"wells-service\",\n  \"visibility\": \"public\",\n  \"groups\": []\n}\n```\n\n### Protected Internal Route\n```json\n{\n  \"method\": \"POST\",\n  \"path\": \"/internal/sync\",\n  \"scope\": \"sync-service\",\n  \"visibility\": \"private\",\n  \"groups\": [\"AWS_PlataformaUpstream_Administrador_Desa\"]\n}\n```",
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
                                                    },
                                                    {
                                                        "type": "Control",
                                                        "label": "Groups",
                                                        "scope": "#/properties/groups"
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
                                    "visibility",
                                    "environment"
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
                                    "groups": {
                                        "type": "array",
                                        "items": {
                                            "enum": [
                                                "AWS_PlataformaUpstream_Gestor_Desa",
                                                "AWS_PlataformaUpstream_Programador_Desa",
                                                "AWS_PlataformaUpstream_Pulling_Desa",
                                                "AWS_PlataformaUpstream_Workover_Desa",
                                                "AWS_PlataformaUpstream_Visita_Desa",
                                                "AWS_PlataformaUpstream_Administrador_Desa"
                                            ],
                                            "type": "string"
                                        },
                                        "title": "Authorized Groups",
                                        "uniqueItems": true
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
                            "title": "Routes",
                            "target": "routes"
                        },
                        "environment": {
                            "type": "string",
                            "title": "Environment",
                            "target": "environment",
                            "additionalKeywords": {
                                "enum": "[.scopes[]?.dimensions?.environment] | unique | if length == 0 then [\"No environments available\"] else . end"
                            }
                        },
                        "publicDomain": {
                            "enum": [
                                "hello.idp.poc.nullapps.io"
                            ],
                            "type": "string",
                            "title": "Public Domain",
                            "target": "publicDomain",
                            "editableOn": [
                                "create",
                                "update"
                            ]
                        },
                        "privateDomain": {
                            "enum": [
                                "hello.idp.poc.nullapps.io"
                            ],
                            "type": "string",
                            "title": "Private Domain",
                            "target": "privateDomain",
                            "editableOn": [
                                "create",
                                "update"
                            ]
                        }
                    }
                },
                "values": {}
            },
            "icon": "",
            "annotations": {},
            "enabled_when": null
        },
        {
            "name": "create Endpoint Exposer",
            "slug": "create-endpoint-exposer",
            "type": "create",
            "parameters": {
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
                                                "text": "### Route Configuration\nDefine how incoming requests are matched and forwarded to backend services.\n\n| Field | Description |\n|-------|-------------|\n| **Verb** | HTTP method to match (GET, POST, PUT, etc.) |\n| **Path** | URL path pattern. See *Path Types* below |\n| **Scope** | Target service that will handle the request |\n| **Visibility** | `public` (external) or `private` (internal network only) |\n| **Groups** | Security groups allowed to access this route. Leave empty for unrestricted access |\n\n### Path Types\n| Type | Example | Description |\n|------|---------|-------------|\n| **Exact** | `/api/users` | Matches the exact path only |\n| **Parameterized** | `/api/users/{id}` | Matches path with dynamic segments |\n| **Wildcard** | `/api/users/*` | Matches any path starting with the prefix |",
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
                                                "text": "### Public API Route\n```json\n{\n  \"method\": \"GET\",\n  \"path\": \"/api/v1/wells\",\n  \"scope\": \"wells-service\",\n  \"visibility\": \"public\",\n  \"groups\": []\n}\n```\n\n### Protected Internal Route\n```json\n{\n  \"method\": \"POST\",\n  \"path\": \"/internal/sync\",\n  \"scope\": \"sync-service\",\n  \"visibility\": \"private\",\n  \"groups\": [\"AWS_PlataformaUpstream_Administrador_Desa\"]\n}\n```",
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
                                                    },
                                                    {
                                                        "type": "Control",
                                                        "label": "Groups",
                                                        "scope": "#/properties/groups"
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
                                    "visibility",
                                    "environment"
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
                                    "groups": {
                                        "type": "array",
                                        "items": {
                                            "enum": [
                                                "AWS_PlataformaUpstream_Gestor_Desa",
                                                "AWS_PlataformaUpstream_Programador_Desa",
                                                "AWS_PlataformaUpstream_Pulling_Desa",
                                                "AWS_PlataformaUpstream_Workover_Desa",
                                                "AWS_PlataformaUpstream_Visita_Desa",
                                                "AWS_PlataformaUpstream_Administrador_Desa"
                                            ],
                                            "type": "string"
                                        },
                                        "title": "Authorized Groups",
                                        "uniqueItems": true
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
                            "enum": [
                                "hello.idp.poc.nullapps.io"
                            ],
                            "type": "string",
                            "title": "Public Domain",
                            "editableOn": [
                                "create",
                                "update"
                            ]
                        },
                        "privateDomain": {
                            "enum": [
                                "hello.idp.poc.nullapps.io"
                            ],
                            "type": "string",
                            "title": "Private Domain",
                            "editableOn": [
                                "create",
                                "update"
                            ]
                        }
                    }
                },
                "values": {}
            },
            "results": {
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
                                                "text": "### Route Configuration\nDefine how incoming requests are matched and forwarded to backend services.\n\n| Field | Description |\n|-------|-------------|\n| **Verb** | HTTP method to match (GET, POST, PUT, etc.) |\n| **Path** | URL path pattern. See *Path Types* below |\n| **Scope** | Target service that will handle the request |\n| **Visibility** | `public` (external) or `private` (internal network only) |\n| **Groups** | Security groups allowed to access this route. Leave empty for unrestricted access |\n\n### Path Types\n| Type | Example | Description |\n|------|---------|-------------|\n| **Exact** | `/api/users` | Matches the exact path only |\n| **Parameterized** | `/api/users/{id}` | Matches path with dynamic segments |\n| **Wildcard** | `/api/users/*` | Matches any path starting with the prefix |",
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
                                                "text": "### Public API Route\n```json\n{\n  \"method\": \"GET\",\n  \"path\": \"/api/v1/wells\",\n  \"scope\": \"wells-service\",\n  \"visibility\": \"public\",\n  \"groups\": []\n}\n```\n\n### Protected Internal Route\n```json\n{\n  \"method\": \"POST\",\n  \"path\": \"/internal/sync\",\n  \"scope\": \"sync-service\",\n  \"visibility\": \"private\",\n  \"groups\": [\"AWS_PlataformaUpstream_Administrador_Desa\"]\n}\n```",
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
                                                    },
                                                    {
                                                        "type": "Control",
                                                        "label": "Groups",
                                                        "scope": "#/properties/groups"
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
                                    "visibility",
                                    "environment"
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
                                    "groups": {
                                        "type": "array",
                                        "items": {
                                            "enum": [
                                                "AWS_PlataformaUpstream_Gestor_Desa",
                                                "AWS_PlataformaUpstream_Programador_Desa",
                                                "AWS_PlataformaUpstream_Pulling_Desa",
                                                "AWS_PlataformaUpstream_Workover_Desa",
                                                "AWS_PlataformaUpstream_Visita_Desa",
                                                "AWS_PlataformaUpstream_Administrador_Desa"
                                            ],
                                            "type": "string"
                                        },
                                        "title": "Authorized Groups",
                                        "uniqueItems": true
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
                            "enum": [
                                "hello.idp.poc.nullapps.io"
                            ],
                            "type": "string",
                            "title": "Public Domain",
                            "editableOn": [
                                "create",
                                "update"
                            ]
                        },
                        "privateDomain": {
                            "enum": [
                                "hello.idp.poc.nullapps.io"
                            ],
                            "type": "string",
                            "title": "Private Domain",
                            "editableOn": [
                                "create",
                                "update"
                            ]
                        }
                    }
                },
                "values": {}
            },
            "icon": "",
            "annotations": {},
            "enabled_when": null
        }
    ]
}
