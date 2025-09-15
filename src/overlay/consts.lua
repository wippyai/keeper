local env = require("env")

local consts = {
    -- Environment variable IDs
    ENV_IDS = {
        DATABASE_RESOURCE = "keeper.overlay.env:database_resource",
        MAX_WORKSPACES_PER_USER = "keeper.overlay.env:max_workspaces_per_user",
        MAX_ENTRIES_PER_WORKSPACE = "keeper.overlay.env:max_entries_per_workspace"
    },

    -- Workspace Status Constants
    WORKSPACE_STATUS = {
        DRAFT = "draft",
        ACTIVE = "active",
        REVIEWED = "reviewed",
        APPROVED = "approved",
        COMMITTED = "committed",
        INTEGRATED = "integrated",
        FAILED = "failed",
        ARCHIVED = "archived"
    },

    -- Operation Types (CQRS Commands)
    OPERATION_TYPE = {
        -- Workspace operations
        CREATE_WORKSPACE = "CREATE_WORKSPACE",
        UPDATE_WORKSPACE = "UPDATE_WORKSPACE",
        DELETE_WORKSPACE = "DELETE_WORKSPACE",
        COMMIT_WORKSPACE = "COMMIT_WORKSPACE",

        -- Workspace permission operations
        CREATE_WORKSPACE_PERMISSION = "CREATE_WORKSPACE_PERMISSION",
        DELETE_WORKSPACE_PERMISSION = "DELETE_WORKSPACE_PERMISSION",

        -- Workspace entry operations
        CREATE_WORKSPACE_ENTRY = "CREATE_WORKSPACE_ENTRY",
        UPDATE_WORKSPACE_ENTRY = "UPDATE_WORKSPACE_ENTRY",
        DELETE_WORKSPACE_ENTRY = "DELETE_WORKSPACE_ENTRY",

        -- Workspace review operations
        CREATE_WORKSPACE_REVIEW = "CREATE_WORKSPACE_REVIEW",
        UPDATE_WORKSPACE_REVIEW = "UPDATE_WORKSPACE_REVIEW",
        DELETE_WORKSPACE_REVIEW = "DELETE_WORKSPACE_REVIEW",

        -- Workspace context operations
        CREATE_WORKSPACE_CONTEXT = "CREATE_WORKSPACE_CONTEXT",
        UPDATE_WORKSPACE_CONTEXT = "UPDATE_WORKSPACE_CONTEXT",
        DELETE_WORKSPACE_CONTEXT = "DELETE_WORKSPACE_CONTEXT",
    },

    -- Workspace Entry Operation Types (stored in DB)
    ENTRY_OPERATION_TYPE = {
        CREATE = "create",
        UPDATE = "update",
        DELETE = "delete"
    },

    -- Permission Types (updated for new schema)
    PERMISSION_TYPE = {
        READ = "read",
        WRITE = "write" -- also makes it readable
    },

    -- Review Status Constants
    REVIEW_STATUS = {
        OPEN = "open",
        RESOLVED = "resolved",
        ARCHIVED = "archived"
    },

    -- Content Types
    CONTENT_TYPE = {
        TEXT_PLAIN = "text/plain",
        TEXT_MARKDOWN = "text/markdown",
        APPLICATION_JSON = "application/json",
        APPLICATION_YAML = "application/yaml"
    },

    -- Topic Patterns for Real-time Updates
    TOPIC_PATTERNS = {
        WORKSPACE_PREFIX = "workspace:"
        -- Full pattern: "workspace:{workspace_id}"
    },

    -- Update Types for Real-time Publishing
    UPDATE_TYPES = {
        WORKSPACE_CREATED = "workspace_created",
        WORKSPACE_UPDATED = "workspace_updated",
        WORKSPACE_DELETED = "workspace_deleted",
        WORKSPACE_COMMITTED = "workspace_committed",
        PERMISSION_CREATED = "permission_created",
        PERMISSION_DELETED = "permission_deleted",
        ENTRY_CREATED = "entry_created",
        ENTRY_UPDATED = "entry_updated",
        ENTRY_DELETED = "entry_deleted",
        REVIEW_CREATED = "review_created",
        REVIEW_UPDATED = "review_updated",
        REVIEW_DELETED = "review_deleted",
        CONTEXT_CREATED = "context_created",
        CONTEXT_UPDATED = "context_updated",
        CONTEXT_DELETED = "context_deleted",
        OP_AUDIT_CREATED = "op_audit_created"
    },

    -- Error Messages
    ERROR = {
        -- General errors
        MISSING_REQUIRED_FIELD = "Missing required field: ",
        INVALID_FIELD_VALUE = "Invalid value for field: ",
        UNKNOWN_COMMAND_TYPE = "Unknown command type: ",

        -- Workspace errors
        WORKSPACE_NOT_FOUND = "Workspace not found",
        WORKSPACE_ACCESS_DENIED = "Access denied to workspace",
        WORKSPACE_LIMIT_EXCEEDED = "Workspace limit exceeded for user",
        WORKSPACE_ALREADY_COMMITTED = "Workspace is already committed",
        WORKSPACE_ENTRY_LIMIT_EXCEEDED = "Entry limit exceeded for workspace",

        -- Entry errors
        WORKSPACE_ENTRY_NOT_FOUND = "Workspace entry not found",
        ENTRY_ID_REQUIRED = "Entry ID is required",
        INVALID_NAMESPACE_PATTERN = "Invalid namespace pattern",

        -- Permission errors
        INSUFFICIENT_PERMISSIONS = "Insufficient permissions for operation",
        INVALID_PERMISSION_TYPE = "Invalid permission type",

        -- Review errors
        REVIEW_NOT_FOUND = "Review not found",
        INVALID_CONTENT_TYPE = "Invalid content type",
        INVALID_STATUS = "Invalid status",

        -- Operation errors
        NO_FIELDS_TO_UPDATE = "No fields provided for update",
        TRANSACTION_REQUIRED = "Transaction is required",
        COMMANDS_REQUIRED = "Commands must be provided",
        COMMANDS_EMPTY = "Commands array cannot be empty",

        -- Database errors
        DB_CONNECTION_FAILED = "Failed to connect to database",
        DB_OPERATION_FAILED = "Database operation failed",
        JSON_ENCODE_FAILED = "Failed to encode JSON",
        JSON_DECODE_FAILED = "Failed to decode JSON",

        -- Commit errors
        COMMIT_CONFLICT_DETECTED = "Commit conflict detected",
        COMMIT_FAILED = "Failed to commit workspace changes"
    },

    -- Validation Sets
    VALID_VALUES = {
        WORKSPACE_STATUS = {
            ["draft"] = true,
            ["active"] = true,
            ["reviewed"] = true,
            ["approved"] = true,
            ["committed"] = true,
            ["integrated"] = true,
            ["failed"] = true,
            ["archived"] = true
        },

        ENTRY_OPERATION_TYPE = {
            ["create"] = true,
            ["update"] = true,
            ["delete"] = true
        },

        PERMISSION_TYPE = {
            ["read"] = true,
            ["write"] = true,
            ["admin"] = true
        },

        REVIEW_STATUS = {
            ["draft"] = true,
            ["active"] = true,
            ["archived"] = true
        },

        CONTENT_TYPE = {
            ["text/plain"] = true,
            ["text/markdown"] = true,
            ["application/json"] = true,
            ["application/yaml"] = true
        }
    },

    -- Default Values
    DEFAULTS = {
        WORKSPACE_STATUS = "draft",
        REVIEW_STATUS = "draft",
        CONTENT_TYPE = "text/plain",
        METADATA = "{}",
        MAX_WORKSPACES_PER_USER = 50,
        MAX_ENTRIES_PER_WORKSPACE = 1000
    },

    -- Limits
    LIMITS = {
        MAX_NAMESPACE_PATTERN_LENGTH = 255,
        MAX_WORKSPACE_TITLE_LENGTH = 200,
        MAX_WORKSPACE_DESCRIPTION_LENGTH = 1000,
        MAX_ENTRY_ID_LENGTH = 255,
        MAX_REVIEW_NAME_LENGTH = 100
    },

    -- Add to consts.lua
    RFS = {
        -- File Status Constants (for workspace overlay)
        FILE_STATUS = {
            CLEAN = "clean",       -- Unchanged from registry
            MODIFIED = "modified", -- Modified in workspace
            NEW = "new",           -- Created in workspace
            DELETED = "deleted"    -- Deleted in workspace
        },

        -- File Type Constants
        FILE_TYPE = {
            INDEX = "index",  -- _index.yaml files
            SOURCE = "source" -- Source code files
        },

        -- Path Constants
        PATH = {
            INDEX_FILENAME = "_index.yaml",
            NAMESPACE_SEPARATOR = ".",
            PATH_SEPARATOR = "/",
            FILE_PROTOCOL = "file://"
        },

        -- Entry Kind to Extension Mapping
        EXTENSIONS = {
            ["function.lua"] = ".lua",
            ["library.lua"] = ".lua",
            ["process.lua"] = ".lua",
            ["template.jet"] = ".jet",
            ["registry.entry"] = {
                ["module.spec"] = ".md"
            }
        },

        -- RFS Error Messages
        RFS_ERROR = {
            INVALID_PATH_FORMAT = "Invalid path format, expected: namespace/filename",
            NAMESPACE_NOT_FOUND = "Namespace not found",
            FILE_NOT_FOUND = "File not found",
            PATH_PARSING_FAILED = "Failed to parse path",
            CONTENT_EXTRACTION_FAILED = "Failed to extract file content",
            MULTIPLE_FILES_FAILED = "Failed to read multiple files"
        }
    }
}

-- Get database resource only (lightweight)
function consts.get_db_resource()
    local db_resource, _ = env.get(consts.ENV_IDS.DATABASE_RESOURCE)
    return db_resource
end

-- Load configuration from environment variables
function consts.get_config()
    local database_resource, _ = env.get(consts.ENV_IDS.DATABASE_RESOURCE)
    local max_workspaces_per_user, _ = env.get(consts.ENV_IDS.MAX_WORKSPACES_PER_USER)
    local max_entries_per_workspace, _ = env.get(consts.ENV_IDS.MAX_ENTRIES_PER_WORKSPACE)

    return {
        -- Environment configuration
        database_resource = database_resource,
        max_workspaces_per_user = tonumber(max_workspaces_per_user) or consts.DEFAULTS.MAX_WORKSPACES_PER_USER,
        max_entries_per_workspace = tonumber(max_entries_per_workspace) or consts.DEFAULTS.MAX_ENTRIES_PER_WORKSPACE
    }
end

return consts