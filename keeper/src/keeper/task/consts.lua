local PHASES = {
    SPEC      = "spec",
    RESEARCH  = "research",
    DESIGN    = "design",
    PLAN      = "plan",
    REVIEW    = "review",
    IMPLEMENT = "implement",
    TEST      = "test",
    INTEGRATE = "integrate",
    DONE      = "done",
    BLOCKED   = "blocked",
}

local consts = {
    DATABASE = {
        RESOURCE_ID = "keeper.state:db",
    },

    -- CQRS event publishing
    CENTRAL = "wippy.central",
    TOPIC   = "keeper.task",

    PROCESS_NAMES = {
        SERVICE = "keeper.task.service.phase_spawner",
    },

    TOPICS = {
        COMMANDS = "task.commands",
    },

    EVENTS = {
        TASK_CREATED    = "task.created",
        TASK_UPDATED    = "task.updated",
        TASK_DELETED    = "task.deleted",
        NODE_CREATED      = "node.created",
        NODE_UPDATED      = "node.updated",
        NODE_DELETED       = "node.deleted",
        NODE_EMBEDDED     = "node.embedded",
        PHASE_SPAWN_REQUESTED = "phase.spawn.requested",
    },

    -- Design lifecycle statuses
    STATUSES = {
        ACTIVE    = "active",
        COMPLETED = "completed",
        ABANDONED = "abandoned",
    },

    -- Kanban phases. A design moves through these columns.
    -- Any phase can transition to "blocked" (agent raises a question).
    -- Backward movement is allowed (e.g., integrate failure → back to implement).
    PHASES = PHASES,

    -- Ordered list for Kanban column rendering
    PHASE_ORDER = {
        PHASES.SPEC, PHASES.RESEARCH, PHASES.DESIGN, PHASES.REVIEW,
        PHASES.IMPLEMENT, PHASES.TEST, PHASES.INTEGRATE, PHASES.DONE,
    },

    -- Well-known node types. The schema is open — callers can use ANY string
    -- as node_type. These constants exist for discoverability, not enforcement.
    -- New types can be added without schema changes.
    NODE_TYPES = {
        SPEC              = "spec",
        SPEC_VERSION      = "spec_version",
        ACCEPTANCE        = "acceptance",
        RESEARCH_TASK     = "research_task",
        RESEARCH_RESULT   = "research_result",
        CONTEXT           = "context",
        REASONING         = "reasoning",
        PLAN              = "plan",
        IMPLEMENTATION    = "implementation",
        TEST_PLAN         = "test_plan",
        TEST_RESULT       = "test_result",
        DEBUG             = "debug",
        REVIEW_REQUEST    = "review_request",
        REVIEW_VERDICT    = "review_verdict",
        FEEDBACK          = "feedback",
        CRITIQUE          = "critique",
        SUGGESTION        = "suggestion",
        REVISION_REQUEST  = "revision_request",
        ANSWER            = "answer",
        QUESTION          = "question",
        INTEGRATION_REQUEST = "integration_request",
        INTEGRATION_RESULT  = "integration_result",
        NOTE              = "note",
        ERROR             = "error",
    },

    -- Content types for log node content field
    CONTENT_TYPES = {
        PLAIN    = "text/plain",
        MARKDOWN = "text/markdown",
        JSON     = "application/json",
        YAML     = "application/yaml",
        LUA      = "text/x-lua",
    },

    -- Log node statuses (workflow state within a single node)
    NODE_STATUSES = {
        PENDING    = "pending",
        ACTIVE     = "active",
        COMPLETED  = "completed",
        FAILED     = "failed",
        SUPERSEDED = "superseded",
        BLOCKED    = "blocked",
    },

    -- Embedding dimensions (matches keeper.knowledge and autocoder memory)
    EMBEDDING_DIMS = 512,

    ERRORS = {
        NOT_FOUND        = "task not found",
        NODE_NOT_FOUND   = "task log node not found",
        INVALID_STATUS   = "invalid task status",
        MISSING_REQUIRED = "missing required field",
        DB_ERROR         = "database error",
        SEARCH_ERROR     = "search error",
    },

    LIMITS = {
        MAX_TITLE_LENGTH       = 500,
        MAX_SEARCH_RESULTS     = 100,
        DEFAULT_SEARCH_LIMIT   = 20,
    },
}

return table.freeze(consts)
