local env = require("env")

local consts = {
    -- Environment Variable IDs
    ENV_IDS = {
        MANAGED_NAMESPACES = "keeper.gov.env:managed_namespaces",
        LINTER_LEVEL = "keeper.gov.env:linter_level"
    },

    -- Governance Operations
    OPERATIONS = {
        APPLY_CHANGES = "apply_changes",
        APPLY_VERSION = "apply_version",
        UPLOAD = "upload",
        DOWNLOAD = "download",
        GET_STATE = "get_state"
    },

    -- Registry Operation Types
    REGISTRY_OPERATIONS = {
        CREATE = "entry.create",
        UPDATE = "entry.update",
        DELETE = "entry.delete"
    },

    -- Process and Topic Names
    PROCESS_NAME = "registry.governance",
    PROCESS_HOST = "keeper.gov:processes",
    TOPICS = {
        COMMANDS = "registry.governance.command",
        RESPONSE = "response",
        RELAY = "wippy.central",
        VERSION = "registry:version"
    },

    -- Security Permissions
    PERMISSIONS = {
        WRITE = "registry.request.write",
        VERSION = "registry.request.version",
        SYNC = "registry.request.sync",
        READ = "registry.request.read"
    },

    -- Default Values
    DEFAULTS = {
        TIMEOUT = "10m",
        LINTER_LEVEL = 100,
        MANAGED_NAMESPACES = {"app"},
    },

    -- Error Messages
    ERRORS = {
        -- Authentication/Authorization
        AUTH_REQUIRED = "Authentication required",
        PERMISSION_DENIED = "Permission denied",

        -- Workspace
        NO_WORKSPACE_CONTEXT = "No active changeset context",
        WORKSPACE_ACCESS_FAILED = "Failed to open changeset session",

        -- Changeset Validation
        NO_CHANGESET = "No changeset items provided",
        INVALID_OPERATION = "Invalid operation kind",
        MISSING_ENTRY_ID = "Delete operation missing ID",
        UNMANAGED_NAMESPACE = "Namespace is not managed by governance",

        -- Version Operations
        INVALID_VERSION_ID = "Invalid version_id provided",
        VERSION_NOT_FOUND = "Version not found",
        REGISTRY_HISTORY_UNAVAILABLE = "Failed to access registry history",

        -- Process Operations
        OPERATION_IN_PROGRESS = "Operation already in progress",
        WORKER_SPAWN_FAILED = "Failed to start operation",
        OPERATION_TIMEOUT = "Operation timed out",

        -- General
        INVALID_ARGUMENTS = "Invalid arguments provided",
        UNKNOWN_OPERATION = "Unknown operation",
        INTERNAL_ERROR = "Internal error occurred"
    },

    -- Validation Constants
    VALIDATION = {
        MAX_CHANGESET_SIZE = 1000,
        MIN_LINTER_LEVEL = 1,
        MAX_LINTER_LEVEL = 100,
        NAMESPACE_PATTERN = "^[a-zA-Z][a-zA-Z0-9]*(?:%.[a-zA-Z][a-zA-Z0-9]*)*$"
    },

    -- Filesystem Constants
    FILESYSTEM = {
        SOURCE_FS_ID = "keeper.gov:source_fs",
        INDEX_FILENAME = "_index.yaml"
    }
}

-- Get managed namespaces from environment
function consts.get_managed_namespaces()
    local namespaces_str, err = env.get(consts.ENV_IDS.MANAGED_NAMESPACES)
    if err or not namespaces_str then
        return consts.DEFAULTS.MANAGED_NAMESPACES
    end

    local namespaces = {}
    for ns in string.gmatch(namespaces_str, "([^,]+)") do
        table.insert(namespaces, ns:match("^%s*(.-)%s*$")) -- trim whitespace
    end
    return namespaces
end

-- Get linter level from environment
function consts.get_linter_level()
    local level_str, _ = env.get(consts.ENV_IDS.LINTER_LEVEL)
    return tonumber(level_str) or consts.DEFAULTS.LINTER_LEVEL
end

-- Check if namespace is managed
function consts.is_namespace_managed(namespace)
    local managed_namespaces = consts.get_managed_namespaces()
    for _, managed_ns in ipairs(managed_namespaces) do
        if namespace == managed_ns or namespace:match("^" .. managed_ns:gsub("%.", "%%.") .. "%.") then
            return true
        end
    end
    return false
end

-- Get governance configuration
function consts.get_config()
    return {
        managed_namespaces = consts.get_managed_namespaces(),
        linter_level = consts.get_linter_level(),
        source_fs_id = consts.FILESYSTEM.SOURCE_FS_ID,
        process_host = consts.PROCESS_HOST
    }
end

return table.freeze(consts)
