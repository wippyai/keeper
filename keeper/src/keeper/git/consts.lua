local consts = {
    PROCESS_NAMES = {
        SERVICE = "keeper.git.service.central",
    },

    TOPICS = {
        COMMANDS = "git.commands",
    },

    RELAY_TARGET = "wippy.central",
    RELAY_TOPIC  = "keeper.git",

    EVENTS = {
        REBUILD_STARTED       = "git.rebuild.started",
        REBUILD_FINISHED      = "git.rebuild.finished",
        REBUILD_FAILED        = "git.rebuild.failed",
        SUGGEST_SPLIT_STARTED  = "git.suggest_split.started",
        SUGGEST_SPLIT_FINISHED = "git.suggest_split.finished",
        SUGGEST_SPLIT_FAILED   = "git.suggest_split.failed",
        EXPLAIN_STARTED        = "git.explain.started",
        EXPLAIN_FINISHED       = "git.explain.finished",
        EXPLAIN_FAILED         = "git.explain.failed",
        DECISION_CHANGED      = "git.cluster.decision_changed",
        STALE                 = "git.index.stale",
        PUSHED                = "git.cluster.pushed",
    },

    OPERATIONS = {
        REBUILD                = "rebuild",
        LIST_CLUSTERS          = "list_clusters",
        GET_CLUSTER            = "get_cluster",
        SET_DECISION           = "set_decision",
        UPDATE_RECOMMENDATION  = "update_recommendation",
        EXPLAIN_RECOMMENDATION = "explain_recommendation",
        SUGGEST_SPLIT          = "suggest_split",
        SPLIT_CLUSTER          = "split_cluster",
        PUSH                   = "push",
    },

    -- Cluster decision (user intent)
    DECISIONS = {
        PENDING  = "pending",
        APPROVED = "approved",
        SKIPPED  = "skipped",
        PUSHED   = "pushed",
    },

    -- Importance buckets
    IMPORTANCE = {
        CRITICAL = "critical",
        HIGH     = "high",
        NORMAL   = "normal",
        CLEANUP  = "cleanup",
        SUSPECT  = "suspect",
    },

    -- AI verdict
    VERDICTS = {
        READY        = "ready",
        CLOSER_LOOK  = "closer_look",
        DO_NOT_PUSH  = "do_not_push",
    },

    -- Recommendation severity
    SEVERITY = {
        INFO  = "info",
        WARN  = "warn",
        BLOCK = "block",
    },

    -- Recommendation lifecycle
    REC_STATES = {
        OPEN         = "open",
        ACKNOWLEDGED = "acknowledged",
        FIXED        = "fixed",
        SPLIT        = "split",
    },

    -- Index run status
    RUN_STATUS = {
        RUNNING  = "running",
        FINISHED = "finished",
        FAILED   = "failed",
    },

    -- Snapshot is marked stale after this many new journal rows accumulate.
    STALE_AFTER_CHANGES = 5,

    -- Default tracked dirs — only files under these prefixes are surfaced.
    -- An empty list means "track everything git reports".
    DEFAULT_TRACKED_DIRS = ({
        "src/",
        "frontend/applications/",
        "plugins/",
    } :: string[]),

    -- Patterns to ALWAYS exclude (even within tracked dirs).
    EXCLUDE_PATTERNS = ({
        "%.bak$",
        "%.DS_Store$",
        "node_modules/",
        "%.wippy/vendor/",
        "static/keeper/",
        "static/public/previews/",
        "%.git/",
    } :: string[]),

    -- Host shell identifier (registered in keeper.components:host_shell).
    HOST_SHELL_ID = "keeper.components:host_shell",

    -- Diff base — what we compare working tree against.
    DEFAULT_DIFF_BASE = "HEAD",

    -- Run history retention — drop runs beyond this many
    RUN_HISTORY_KEEP = 10,

    -- Guardrail for AI rebuilds over very large dirty trees.
    DEFAULT_MAX_CHANGES = 2000,

    ERRORS = {
        MAILBOX_SEND_FAILED = "git mailbox send failed",
        MAILBOX_TIMEOUT     = "git mailbox timeout",
        UNKNOWN_OP          = "unknown git operation",
        MISSING_REQUIRED    = "missing required argument",
        UNKNOWN_CLUSTER     = "unknown cluster_id",
    },
}

local VALID_DECISIONS = {
    [consts.DECISIONS.PENDING] = true,
    [consts.DECISIONS.APPROVED] = true,
    [consts.DECISIONS.SKIPPED] = true,
    [consts.DECISIONS.PUSHED] = true,
}

local VALID_REC_STATES = {
    [consts.REC_STATES.OPEN] = true,
    [consts.REC_STATES.ACKNOWLEDGED] = true,
    [consts.REC_STATES.FIXED] = true,
    [consts.REC_STATES.SPLIT] = true,
}

function consts.is_decision(value)
    return VALID_DECISIONS[value] == true
end

function consts.is_rec_state(value)
    return VALID_REC_STATES[value] == true
end

return consts
