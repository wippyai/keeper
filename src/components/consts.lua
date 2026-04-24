-- keeper.components:consts
--
-- Shared constants for the FE components subsystem: filesystem volume ids,
-- scan roots, preview storage paths, session statuses, and default limits.

local consts = {
    -- Filesystem volume IDs (see _index.yaml)
    FS = {
        -- Writable scoped to ./frontend (used for session apply)
        FE_FS_ID = "keeper.components:fe_fs",
        -- Writable scoped to ./static/public/previews (thumbnails)
        PREVIEWS_FS_ID = "keeper.components:previews_fs",
        -- Read-only project root (used by the scanner)
        PROJECT_FS_ID = "keeper.components:project_fs",
        -- Writable scoped to ./.wippy/fe-sessions (docker build staging, M3)
        STAGING_FS_ID = "keeper.components:staging_fs",
        -- Read-only sibling repos (..) used to resolve linked origin sources
        SIBLINGS_FS_ID = "keeper.components:siblings_fs",
    },

    -- Paths (all relative to the project root / project_fs)
    PATHS = {
        APP_ROOT = "frontend/applications",
        WC_ROOT = "frontend/web-components",
        DOCS_ROOT = "frontend/docs",
        VENDORED_APP_ROOT = "static/app",
        VENDORED_WC_ROOT = "static/wc",
        PREVIEWS_REL = "static/public/previews",
        STAGING_REL = ".wippy/fe-sessions",
    },

    -- URL prefixes (served by the main keeper http.static handler which
    -- serves ./static at /app)
    URLS = {
        PREVIEWS_PUBLIC = "/app/public/previews",
    },

    -- Wippy component spec marker (package.json.specification)
    COMPONENT_SPEC = "wippy-component-1.0",

    -- Origin manifest file dropped next to a prebuilt bundle to link it
    -- back to its source (see describe_vendored in scanner.lua).
    ORIGIN_MANIFEST = ".wippy-origin.json",

    -- Default toolchain for new components
    DEFAULT_TOOLCHAIN = "fe_node",

    -- Directories that the scanner ignores when computing source stats.
    SOURCE_SKIP_DIRS = {
        ["node_modules"] = true,
        ["dist"] = true,
        [".cache"] = true,
        [".vite"] = true,
        [".turbo"] = true,
    },

    -- Preview retention (auto-cleanup in M4 when screenshots start flowing).
    PREVIEW_TTL_SECONDS = 24 * 60 * 60,

    -- App database id (shared with the rest of keeper)
    DB_ID = "app:db",

    -- Host shell executor id (exec.native)
    HOST_SHELL_ID = "keeper.components:host_shell",

    -- Env variable id that resolves to the absolute project root on the host
    PROJECT_ROOT_ENV = "keeper.components:project_root",

    -- Build runner process id
    BUILD_RUNNER_ID = "keeper.components.build:build_runner",

    -- Build toolchain defaults
    BUILD_IMAGE = "node:20-alpine",
    CONTAINER_WORKSPACE = "/workspace",
    NPM_CACHE_VOLUME = "keeper-fe-npm-cache",
    -- 6 GB headroom — vite + Monaco can spike well above 1.5 GB during
    -- minify. Hard-cap protects against runaway builds.
    CONTAINER_MEMORY = "6g",
    -- Pass to node so vite can use the full container memory.
    NODE_OPTIONS = "--max-old-space-size=4096",

    -- Retention: keep last N builds per component (oldest pruned on insert)
    BUILD_RETENTION_PER_COMPONENT = 30,

    -- Build statuses
    BUILD_STATUS = {
        QUEUED = "queued",
        RUNNING = "running",
        SUCCESS = "success",
        FAILED = "failed",
        CANCELLED = "cancelled",
    },

    -- Screenshot pipeline
    PLAYWRIGHT_IMAGE = "mcr.microsoft.com/playwright:v1.59.1-noble",
    SCREENSHOT_VIEWPORT_W = 1280,
    SCREENSHOT_VIEWPORT_H = 800,
    SCREENSHOT_TIMEOUT_S = 30,
    -- After this many seconds with no captures, the supervisor exits and
    -- the next request will spawn a fresh one. Playwright itself is
    -- transient — it lives only for the duration of one capture.
    SCREENSHOT_IDLE_S = 300,
    -- The screenshot container needs a URL that:
    --   1. Resolves to the running wippy host
    --   2. Matches whatever PUBLIC_API_URL is set to (so the facade
    --      config's hardcoded API URL also resolves from the container)
    --
    -- We read PUBLIC_API_URL straight from env. If the user has set it
    -- to a real public URL the container can hit it via plain bridge
    -- networking on any platform. If they've left it at localhost
    -- (the dev default) we use --network host so the container shares
    -- the host's loopback. Linux-only for that fallback, but it's the
    -- same constraint as the rest of dev mode.
    PUBLIC_HOST_ENV = "PUBLIC_API_URL",
    DEFAULT_HOST_URL = "http://localhost:8067",

    -- Build triggers
    BUILD_TRIGGER = {
        USER = "user",
        AGENT = "agent",
        SESSION = "session",
    },

    -- Build log streams
    BUILD_STREAM = {
        STDOUT = "stdout",
        STDERR = "stderr",
        SYSTEM = "system",
    },

    -- Edit session statuses
    SESSION_STATUS = {
        DRAFT = "draft",
        BUILDING = "building",
        BUILT = "built",
        VERIFYING = "verifying",
        VERIFIED = "verified",
        APPLIED = "applied",
        ABANDONED = "abandoned",
        FAILED = "failed",
    },

    -- File operation kinds inside a session
    FILE_OP = {
        CREATE = "create",
        UPDATE = "update",
        DELETE = "delete",
    },
}

return consts
