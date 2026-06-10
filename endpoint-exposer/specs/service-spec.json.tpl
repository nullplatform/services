{
    "name": "HTTP Route Access Control",
    "type": "dependency",
    "dimensions": {},
    "scopes": {},
    "assignable_to": "any",
    "use_default_actions": true,
    "attributes": {
        "schema": {
            "type": "object",
            "$schema": "http://json-schema.org/draft-07/schema#",
            "required": [
                "auth_type",
                "environment",
                "routes"
            ],
            "uiSchema": {
                "type": "VerticalLayout",
                "elements": [
                    {
                        "type": "Control",
                        "label": "Authorization Scheme",
                        "scope": "#/properties/auth_type"
                    },
                    {
                        "type": "Control",
                        "label": "AVP Policy Store ARN",
                        "scope": "#/properties/avp_policy_store_arn",
                        "rule": {
                            "effect": "HIDE",
                            "condition": {
                                "scope": "#/properties/auth_type",
                                "schema": {
                                    "not": {
                                        "const": "aws-avp"
                                    }
                                }
                            }
                        }
                    },
                    {
                        "type": "Control",
                        "label": "Cognito User Pool ARN",
                        "scope": "#/properties/cognito_user_pool_arn",
                        "rule": {
                            "effect": "HIDE",
                            "condition": {
                                "scope": "#/properties/auth_type",
                                "schema": {
                                    "not": {
                                        "const": "aws-cognito"
                                    }
                                }
                            }
                        }
                    },
                    {
                        "type": "Control",
                        "label": "Environment",
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
                                            },
                                            {
                                                "type": "Control",
                                                "label": "Authorized Groups",
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
                            },
                            "groups": {
                                "type": "string",
                                "title": "Authorized Groups",
                                "description": "Comma-separated list of groups allowed to access this route. Leave empty to allow any authenticated user.",
                                "editableOn": [
                                    "create",
                                    "update"
                                ]
                            }
                        }
                    },
                    "title": "Routes"
                },
                "auth_type": {
                    "type": "string",
                    "title": "Authorization Scheme",
                    "description": "Authorization scheme to use for endpoint protection.",
                    "enum": [
                        "aws-avp",
                        "aws-cognito"
                    ],
                    "editableOn": [
                        "create"
                    ]
                },
                "avp_policy_store_arn": {
                    "type": "string",
                    "title": "AVP Policy Store ARN",
                    "description": "ARN of the Amazon Verified Permissions Policy Store (arn:aws:verifiedpermissions::account-id:policy-store/id).",
                    "editableOn": [
                        "create"
                    ]
                },
                "cognito_user_pool_arn": {
                    "type": "string",
                    "title": "Cognito User Pool ARN",
                    "description": "ARN of the Cognito User Pool for JWT validation (arn:aws:cognito-idp:region:account-id:userpool/pool-id).",
                    "editableOn": [
                        "create",
                        "update"
                    ]
                },
                "environment": {
                    "type": "string",
                    "title": "Environment",
                    "description": "Target environment for agent routing (e.g. dev, test, prod).",
                    "enum": [
                        "dev",
                        "test",
                        "prod"
                    ],
                    "editableOn": [
                        "create"
                    ]
                }
            },
            "if": {
                "properties": {
                    "auth_type": {
                        "const": "aws-avp"
                    }
                }
            },
            "then": {
                "required": [
                    "avp_policy_store_arn"
                ]
            },
            "else": {
                "if": {
                    "properties": {
                        "auth_type": {
                            "const": "aws-cognito"
                        }
                    }
                },
                "then": {
                    "required": [
                        "cognito_user_pool_arn"
                    ]
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