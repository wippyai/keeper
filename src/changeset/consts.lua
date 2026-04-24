local consts = {
    -- Process identity
    PROCESS_NAMES = {
        CENTRAL = "keeper.changeset.service.central",
    },

    PROCESS_HOST = "keeper.gov:processes",

    -- Mailbox topics for process.send(target, topic, message)
    TOPICS = {
        COMMANDS = "workspace.commands",
        RESPONSE = "workspace.response",
    },

    -- CQRS: real-time event publishing via wippy relay
    RELAY_TARGET = "wippy.central",
    RELAY_TOPIC  = "keeper.changeset",

    EVENTS = {
        CREATED    = "workspace.created",
        UPDATED    = "workspace.updated",
        EDITED     = "workspace.edited",
        DROPPED    = "workspace.dropped",
        TRANSITIONED = "workspace.transitioned",
        LOCKED       = "workspace.locked",
        UNLOCKED     = "workspace.unlocked",
    },

    -- Operations dispatched via the central supervisor
    OPERATIONS = {
        CREATE          = "create",
        OPEN_OR_RESUME  = "open_or_resume",
        EDIT            = "edit",
        DROP            = "drop",
        TRANSITION      = "transition",
        LIST_CHANGES    = "list_changes",
        SCAN_DRIFT      = "scan_drift",
        MERGE_DRIFT     = "merge_drift",
        PUSH            = "push",
        LOCK            = "lock",
        UNLOCK          = "unlock",
    },

    -- Changeset kinds
    KINDS = {
        SESSION = "session",
        WILD    = "wild",
        MANUAL  = "manual",
        IMPORT  = "import",
    },

    -- Edit op kinds — what kind of mutation an edit performs inside a changeset.
    -- Used by keeper.changeset.service:edit dispatch and sys_cs op validation.
    EDIT_KINDS = {
        REGISTRY_SET    = "registry_set",
        REGISTRY_DELETE = "registry_delete",
        FS_WRITE        = "fs_write",
        FS_DELETE       = "fs_delete",
    },

    -- Changeset lifecycle states
    STATES = {
        OPEN     = "open",
        EDITING  = "editing",
        REVIEW   = "review",
        ACCEPTED = "accepted",
        REJECTED = "rejected",
        MERGED   = "merged",
        DROPPED  = "dropped",
    },

    -- Change row categories
    CATEGORIES = {
        REGISTRY   = "registry",
        FILESYSTEM = "filesystem",
    },

    -- Change row ops
    OPS = {
        CREATE = "create",
        UPDATE = "update",
        DELETE = "delete",
    },

    -- Registry entry parts. A registry entry is stored as two overlay chunks:
    -- the YAML definition (metadata) and the source body (optional). The diff
    -- layer emits one row per changed part so the UI can render them as
    -- distinct items — mirroring the registry view's meta/data tabs.
    CHUNKS = {
        DEFINITION = "definition",
        CONTENT    = "content",
    },

    -- Change row source — why the row exists
    SOURCES = {
        DETECTED_DRIFT  = "detected_drift",
        MATERIALIZED    = "materialized",
        PUSHED          = "pushed",
        REJECTED        = "rejected",
        SYNCED_FROM_FS  = "synced_from_fs",
        SYNCED_TO_FS    = "synced_to_fs",
        FS_FLUSHED      = "fs_flushed",
        VERSION_REVERT  = "version_revert",
    },

    -- Change row status
    CHANGE_STATUSES = {
        PENDING    = "pending",
        APPLIED    = "applied",
        SUPERSEDED = "superseded",
        REJECTED   = "rejected",
        REVERTED   = "reverted",
    },

    -- Baseline capture reasons
    BASELINE_REASONS = {
        OPEN        = "open",
        PHASE_SPAWN = "phase_spawn",
    },

    -- Merge event resolutions
    MERGE_RESOLUTIONS = {
        AUTO     = "auto",
        MANUAL   = "manual",
        REJECTED = "rejected",
    },

    -- FS volume for baseline reads (fe_fs fallthrough on workspace read).
    -- Changeset FS content is stored in keeper_changeset_fs_content DB table,
    -- NOT on disk. The staging_fs volume is no longer used by workspaces.
    FS = {
        FE_VOLUME = "keeper.components:fe_fs",
    },

    -- Build output / dependency directories that should never be part of a
    -- workspace baseline or a diff. Mirrors keeper.components:consts.SOURCE_SKIP_DIRS
    -- but declared here so the workspace domain doesn't depend on components.
    FE_SKIP_DIRS = {
        "node_modules",
        "dist",
        "build",
        ".cache",
        ".vite",
        ".turbo",
        ".next",
        ".nuxt",
        ".svelte-kit",
    },

    -- State DB resource
    DATABASE = {
        RESOURCE_ID = "keeper.state:db",
    },

    -- Branch naming — overlay branch per workspace. MAIN_BRANCH is the
    -- reserved published-state branch; workspace branches must never equal it.
    MAIN_BRANCH   = "main",
    BRANCH_PREFIX = "ws/",

    -- Janitor: stale-changeset sweep cadence + TTL.
    -- Live states older than STALE_TTL with no updates get dropped with a
    -- stale-expired reason so they stop accumulating in list views and
    -- baselines don't grow unbounded.
    JANITOR = {
        SWEEP_INTERVAL        = "30m",  -- tight cadence so EMPTY_OPEN_TTL drops fire promptly
        STALE_TTL             = "168h", -- 7d; drops live states that sat without updates
        STALE_REASON          = "stale-expired: no activity within TTL",
        EMPTY_OPEN_TTL        = "2h",   -- empty 'open' workspaces that were never edited
        EMPTY_OPEN_REASON     = "empty-open: no edits within TTL",
        ABANDONED_OPEN_TTL    = "48h",  -- 'open' workspaces past TTL; catches abandoned-but-nonempty shells
        ABANDONED_OPEN_REASON = "abandoned-open: open state never progressed within TTL",
        BATCH_LIMIT           = 50,
    },

    -- Sensitive namespaces require HIL approval on push (v1 default; extend via env var)
    SENSITIVE_NAMESPACES = {
        "app.security",
        "keeper.gov.service.security",
        "keeper.mcp",
    },

    -- Errors
    ERRORS = {
        NOT_FOUND             = "workspace not found",
        INVALID_STATE         = "invalid workspace state for operation",
        INVALID_TRANSITION    = "invalid state transition",
        INVALID_PATH          = "invalid path",
        CONFLICT              = "change conflicts with existing pending change",
        DB_ERROR              = "database error",
        FS_ERROR              = "filesystem error",
        HASH_ERROR            = "hash error",
        MAILBOX_TIMEOUT       = "central supervisor did not respond in time",
        MAILBOX_SEND_FAILED   = "central supervisor unreachable",
        MISSING_REQUIRED      = "missing required field",
        PUSH_BLOCKED_BY_DRIFT = "push blocked by drift",
        BASELINE_DIVERGED     = "baseline has diverged",
        LOCKED_BY_OTHER       = "changeset is locked by another agent",
        NOT_LOCKED            = "changeset is not locked",
        NOT_LOCK_HOLDER       = "caller is not the lock holder",
        ACTIVE_SESSION_EXISTS = "cannot fork session changeset: active changeset already exists for task",
    },
}

-- helper: full branch name for a workspace
function consts.branch_for(changeset_id)
    return consts.BRANCH_PREFIX .. changeset_id
end

-- helper: is this namespace sensitive (v1 list only; phase 5 will make this env-driven)
function consts.is_sensitive_namespace(ns)
    if not ns then return false end
    for _, sensitive in ipairs(consts.SENSITIVE_NAMESPACES) do
        if ns == sensitive or ns:sub(1, #sensitive + 1) == sensitive .. "." then
            return true
        end
    end
    return false
end

return table.freeze(consts)
