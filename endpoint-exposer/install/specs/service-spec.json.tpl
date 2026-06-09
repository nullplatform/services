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
                "routes"
            ],
            "uiSchema": {
                "type": "VerticalLayout",
                "elements": [
                    {
                        "type": "Control",
                        "scope": "#/properties/environment"
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
                                                "label": "Verbs",
                                                "scope": "#/properties/methods"
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
                            "methods",
                            "path",
                            "scope"
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
                            "methods": {
                                "type": "array",
                                "title": "Verbs",
                                "items": {
                                    "type": "string",
                                    "enum": [
                                        "GET",
                                        "POST",
                                        "PUT",
                                        "PATCH",
                                        "DELETE",
                                        "HEAD",
                                        "OPTIONS"
                                    ]
                                },
                                "uniqueItems": true,
                                "minItems": 1
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
                }
            }
        },
        "values": {}
    },
    "selectors": {
        "category": "Security",
        "imported": false,
        "provider": "Istio",
        "sub_category": "Access Control"
    }
}