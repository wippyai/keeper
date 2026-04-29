local consts = {
    PROCESS_NAMES = {
        ORCHESTRATOR = "keeper.state.service.orchestrator",
    },

    PROCESS_HOST = "keeper.gov:processes",

    TOPICS = {
        COMMANDS = "state.commands",
        RESPONSE = "state.response",
        REGISTRY_CHANGE = "state.registry.change",
    },

    OPERATIONS = {
        SYNC_BRANCH = "sync_branch",
        GET_STATE = "get_state",
    },

    DATABASE = {
        RESOURCE_ID = "keeper.state:db",
    },

    BRANCH = {
        MAIN = "main",
        DEFAULT = "main",
    },

    CHUNK_TYPE = {
        CONTENT = "content",
        DEFINITION = "definition",
    },

    EDGE_TYPE = {
        IMPORTS = "imports",
        CALLS = "calls",
        INHERITS = "inherits",
        REFERENCES = "references",
        USES = "uses",
        DEFINES = "defines",
        EXPORTS = "exports",
    },

    ERRORS = {
        OPERATION_IN_PROGRESS = "Operation already in progress",
        WORKER_SPAWN_FAILED = "Failed to spawn worker process",
        UNKNOWN_OPERATION = "Unknown operation",
        DATABASE_ERROR = "Database error",
        SYNC_FAILED = "State synchronization failed",
        TRANSACTION_REQUIRED = "Transaction required",
        COMMANDS_REQUIRED = "Commands required",
        COMMANDS_EMPTY = "Commands empty",
        UNKNOWN_COMMAND_TYPE = "Unknown command type",
        DB_CONNECTION_FAILED = "Database connection failed",
        DB_OPERATION_FAILED = "Database operation failed",
        MISSING_REQUIRED_FIELD = "Missing required field",
    },

    RFS = {
        PATH = {
            FILE_PROTOCOL = "file://",
            PATH_SEPARATOR = "/",
            NAMESPACE_SEPARATOR = ".",
            INDEX_FILENAME = "_index.yaml",
        },
        EXTENSIONS = {
            ["function.lua"] = {
                extension = ".lua",
                source_field = "source"
            },
            ["library.lua"] = {
                extension = ".lua",
                source_field = "source"
            },
            ["process.lua"] = {
                extension = ".lua",
                source_field = "source"
            },
            ["template.jet"] = {
                extension = ".jet",
                source_field = "source"
            },
            ["registry.entry"] = {
                ["agent.gen1"] = {
                    extension = ".md",
                    source_field = "prompt"
                },
                ["tool"] = {
                    extension = ".lua",
                    source_field = "source"
                },
                ["view.page"] = {
                    extension = ".html",
                    source_field = "source"
                },
                ["module.spec"] = {
                    extension = ".md",
                    source_field = "source"
                }
            },
        },
        RFS_ERROR = {
            INVALID_PATH_FORMAT = "Invalid path format",
            FILE_NOT_FOUND = "File not found",
            NAMESPACE_NOT_FOUND = "Namespace not found",
        },
        FILE_STATUS = {
            CLEAN = "clean",
            MODIFIED = "modified",
            NEW = "new",
            DELETED = "deleted",
        },
    },

    FIELD_ORDER = {
        "version",
        "namespace",
        "name",
        "kind",
        "contract",
        "meta",
        "type",
        "title",
        "comment",
        "group",
        "tags",
        "icon",
        "description",
        "order",
        "content_type",
        "prompt",
        "model",
        "temperature",
        "max_tokens",
        "tools",
        "memory",
        "delegate",
        "source",
        "modules",
        "imports",
        "method",
        "depends_on",
        "router",
        "set",
        "resources",
        "entries",
    },

    DEPENDENCY_PATHS = {
        imports = {
            "data.imports.*",
        },
        uses = {
            "data.middleware",
            "data.post_middleware",
            "data.modules",
            "data.tools",
            "data.groups",
            "meta.groups",
            "data.lifecycle.security.policies",
            "data.lifecycle.security.groups",
            "data.security.policies",
            "data.security.groups",
        },
        references = {
            "meta.server",
            "meta.router",
            "meta.parent",
            "meta.host",
            "meta.default_host",
            "data.server",
            "data.router",
            "data.fs",
            "data.store",
            "data.token_store",
            "data.set",
            "data.host",
            "data.process",
            "data.bucket",
            "data.config",
            "data.func",
            "data.security.token_store",
            "meta.depends_on",
            "data.lifecycle.depends_on",
        },
    },
}

return table.freeze(consts)