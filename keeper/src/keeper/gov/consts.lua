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
        MANAGED_NAMESPACES = {},
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
        NAMESPACE_SEGMENT_PATTERN = "^[A-Za-z][A-Za-z0-9_]*$"
    },

    -- Filesystem Constants
    FILESYSTEM = {
        SOURCE_FS_ID = "keeper.gov:source_fs",
        INDEX_FILENAME = "_index.yaml"
    }
}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function split_csv(value)
    local out = {}
    for item in string.gmatch(tostring(value or ""), "([^,]+)") do
        table.insert(out, item)
    end
    return out
end

local function is_valid_namespace(namespace)
    namespace = trim(namespace)
    if namespace == "" then return false end
    if namespace:find("..", 1, true) or namespace:sub(1, 1) == "." or namespace:sub(-1) == "." then
        return false
    end
    for segment in namespace:gmatch("[^.]+") do
        if not segment:match(consts.VALIDATION.NAMESPACE_SEGMENT_PATTERN) then
            return false
        end
    end
    return true
end

local function default_managed_namespaces()
    local defaults = {}
    for _, namespace in ipairs(consts.DEFAULTS.MANAGED_NAMESPACES) do
        table.insert(defaults, namespace)
    end
    return defaults
end

function consts.normalize_managed_namespaces(input)
    local raw = input
    if type(input) == "string" then
        raw = split_csv(input)
    end
    if type(raw) ~= "table" then
        return nil, "managed_namespaces must be an array or comma-separated string"
    end

    local out = {}
    local seen = {}
    for _, value in ipairs(raw) do
        local namespace = trim(value)
        if namespace ~= "" then
            if not is_valid_namespace(namespace) then
                return nil, "invalid namespace: " .. namespace
            end
            if not seen[namespace] then
                seen[namespace] = true
                table.insert(out, namespace)
            end
        end
    end
    return out, nil
end

function consts.serialize_managed_namespaces(namespaces)
    local normalized, err = consts.normalize_managed_namespaces(namespaces)
    if not normalized then return nil, err end
    return table.concat(normalized, ","), nil
end

-- Get managed namespaces from environment
function consts.get_managed_namespaces()
    local namespaces_str, err = env.get(tostring(consts.ENV_IDS.MANAGED_NAMESPACES))
    if err or not namespaces_str then
        return default_managed_namespaces()
    end

    local namespaces = consts.normalize_managed_namespaces(namespaces_str)
    return namespaces or default_managed_namespaces()
end

function consts.get_effective_managed_namespaces(options)
    if type(options) == "table" and options.managed_namespaces ~= nil then
        local namespaces, err = consts.normalize_managed_namespaces(options.managed_namespaces)
        if not namespaces then return nil, err end
        return namespaces, nil
    end
    return consts.get_managed_namespaces(), nil
end

function consts.is_namespace_in(namespace, managed_namespaces)
    namespace = trim(namespace)
    if namespace == "" or type(managed_namespaces) ~= "table" then return false end
    for _, managed_ns in ipairs(managed_namespaces) do
        managed_ns = trim(managed_ns)
        if namespace == managed_ns or namespace:sub(1, #managed_ns + 1) == managed_ns .. "." then
            return true
        end
    end
    return false
end

function consts.namespace_filter(options)
    local managed_namespaces, err = consts.get_effective_managed_namespaces(options)
    if not managed_namespaces then return nil, nil, err end
    return function(namespace)
        return consts.is_namespace_in(namespace, managed_namespaces)
    end, managed_namespaces, nil
end

function consts.set_managed_namespaces(namespaces)
    local value, normalize_err = consts.serialize_managed_namespaces(namespaces)
    if not value then return nil, normalize_err end
    local ok, set_err = env.set(tostring(consts.ENV_IDS.MANAGED_NAMESPACES), value)
    if not ok then return nil, set_err or "failed to persist managed namespaces" end
    return consts.normalize_managed_namespaces(value)
end

-- Get linter level from environment
function consts.get_linter_level()
    local level_str, _ = env.get(tostring(consts.ENV_IDS.LINTER_LEVEL))
    return tonumber(level_str) or consts.DEFAULTS.LINTER_LEVEL
end

-- Check if namespace is managed
function consts.is_namespace_managed(namespace)
    return consts.is_namespace_in(namespace, consts.get_managed_namespaces())
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
