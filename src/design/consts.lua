local env = require("env")

local consts = {
    ENV_IDS = {
        DATABASE_RESOURCE = "keeper.design.env:database_resource"
    },

    WORKSPACE_STATUS = {
        DRAFT = "draft",
        ACTIVE = "active",
        ARCHIVED = "archived"
    },

    OPERATION_TYPE = {
        CREATE_WORKSPACE = "CREATE_WORKSPACE",
        UPDATE_WORKSPACE = "UPDATE_WORKSPACE",
        DELETE_WORKSPACE = "DELETE_WORKSPACE",

        CREATE_WORKSPACE_DATA = "CREATE_WORKSPACE_DATA",
        UPDATE_WORKSPACE_DATA = "UPDATE_WORKSPACE_DATA",
        DELETE_WORKSPACE_DATA = "DELETE_WORKSPACE_DATA",
        MOVE_WORKSPACE_DATA = "MOVE_WORKSPACE_DATA"
    },

    CONTENT_TYPE = {
        TEXT_PLAIN = "text/plain",
        TEXT_MARKDOWN = "text/markdown",
        APPLICATION_JSON = "application/json",
        APPLICATION_YAML = "application/yaml"
    },

    TOPIC_PATTERNS = {
        WORKSPACE_PREFIX = "design:workspace:"
    },

    UPDATE_TYPES = {
        WORKSPACE_CREATED = "workspace_created",
        WORKSPACE_UPDATED = "workspace_updated",
        WORKSPACE_DELETED = "workspace_deleted",
        DATA_CREATED = "data_created",
        DATA_UPDATED = "data_updated",
        DATA_DELETED = "data_deleted",
        DATA_MOVED = "data_moved"
    },

    ERROR = {
        MISSING_REQUIRED_FIELD = "Missing required field: ",
        INVALID_FIELD_VALUE = "Invalid value for field: ",
        UNKNOWN_COMMAND_TYPE = "Unknown command type: ",

        WORKSPACE_NOT_FOUND = "Workspace not found",
        WORKSPACE_ACCESS_DENIED = "Access denied to workspace",

        DATA_NOT_FOUND = "Workspace data not found",
        PARENT_NOT_FOUND = "Parent data not found",
        INVALID_CONTENT_TYPE = "Invalid content type",

        NO_FIELDS_TO_UPDATE = "No fields provided for update",
        TRANSACTION_REQUIRED = "Transaction is required",
        COMMANDS_REQUIRED = "Commands must be provided",
        COMMANDS_EMPTY = "Commands array cannot be empty",

        DB_CONNECTION_FAILED = "Failed to connect to database",
        DB_OPERATION_FAILED = "Database operation failed",
        JSON_ENCODE_FAILED = "Failed to encode JSON",
        JSON_DECODE_FAILED = "Failed to decode JSON"
    },

    VALID_VALUES = {
        WORKSPACE_STATUS = {
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

    DEFAULTS = {
        WORKSPACE_STATUS = "draft",
        CONTENT_TYPE = "text/plain",
        METADATA = "{}"
    },

    LIMITS = {
        MAX_WORKSPACE_TITLE_LENGTH = 200,
        MAX_WORKSPACE_DESCRIPTION_LENGTH = 1000
    }
}

function consts.get_db_resource()
    local db_resource, _ = env.get(consts.ENV_IDS.DATABASE_RESOURCE)
    return db_resource
end

function consts.get_config()
    local database_resource, _ = env.get(consts.ENV_IDS.DATABASE_RESOURCE)

    return {
        database_resource = database_resource
    }
end

return consts