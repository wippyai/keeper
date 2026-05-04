-- Changeset-backed scan for the Keeper Git review surface.
--
-- git_scan.lua reads the host working tree and is intentionally review-only:
-- those rows are not tied to a Keeper workspace branch, so pushing them would
-- bypass governance. This scanner reads live Keeper changesets and their
-- pending journal rows. Those rows carry changeset_id, so clusters built from
-- them can be reviewed, approved, and pushed through keeper.state.tools:push.

local cs_consts = require("cs_consts")
local cs_repo = require("cs_repo")
local git_config = require("git_config")

local M = {}

local DEFAULT_STATES = {
    cs_consts.STATES.OPEN,
    cs_consts.STATES.EDITING,
    cs_consts.STATES.REVIEW,
    cs_consts.STATES.ACCEPTED,
}

local function namespace_from_entry_id(target)
    if type(target) ~= "string" then return nil end
    return target:match("^([^:]+):")
end

local function namespace_root(namespace)
    if type(namespace) ~= "string" or namespace == "" then return nil end
    return namespace:match("^([^.]+)") or namespace
end

local function is_managed_namespace(namespace, cfg)
    if type(namespace) ~= "string" or namespace == "" then return false end
    for _, managed in ipairs((cfg and cfg.managed_namespaces) or {}) do
        if namespace == managed or namespace:sub(1, #managed + 1) == managed .. "." then
            return true
        end
    end
    return false
end

local function change_from_journal(row, cfg)
    local namespace
    local ns_root
    local managed

    if row.category == cs_consts.CATEGORIES.REGISTRY then
        namespace = namespace_from_entry_id(row.target)
        ns_root = namespace_root(namespace)
        managed = is_managed_namespace(namespace, cfg)
    end

    return {
        change_id         = row.change_id,
        changeset_id      = row.changeset_id,
        category          = row.category,
        op                = row.op,
        target            = row.target,
        ns_root           = ns_root,
        namespace         = namespace,
        managed_namespace = managed,
        source            = "changeset",
        status            = row.status,
        added             = 0,
        removed           = 0,
    }
end

local function list_changesets(opts)
    opts = opts or {}
    if opts.changeset_id and opts.changeset_id ~= "" then
        local cs, err = cs_repo.get_changeset(opts.changeset_id)
        if err then return nil, err end
        return { cs }, nil
    end

    local states = opts.states or DEFAULT_STATES
    local seen = {}
    local out = {}
    for _, state in ipairs(states) do
        local rows, err = cs_repo.list_changesets({
            state = state,
            kind = opts.kind,
            actor_id = opts.actor_id,
            session_id = opts.session_id,
            limit = opts.limit or 100,
        })
        if err then return nil, err end
        for _, cs in ipairs(rows or {}) do
            if cs.changeset_id and not seen[cs.changeset_id] then
                seen[cs.changeset_id] = true
                table.insert(out, cs)
            end
        end
    end
    table.sort(out, function(a, b)
        return tostring(a.created_at or "") < tostring(b.created_at or "")
    end)
    return out, nil
end

-- Public: list_changes(opts) -> change_rows, resolved_git_config
--
-- opts may filter to a single changeset_id or live workspace attributes
-- (kind/actor_id/session_id). Unmanaged registry namespaces are included with
-- managed_namespace=false so push_policy can block them explicitly instead of
-- hiding unsafe work from review.
function M.list_changes(opts)
    opts = opts or {}
    local cfg = git_config.resolve(opts)
    local changesets, cs_err = list_changesets(opts)
    if cs_err then return nil, "changesets: " .. tostring(cs_err) end

    local out = {}
    for _, cs in ipairs(changesets or {}) do
        local journal, jerr = cs_repo.list_changes_for_changeset(cs.changeset_id, {
            status = cs_consts.CHANGE_STATUSES.PENDING,
            limit = opts.per_changeset_limit or 2000,
        })
        if jerr then
            return nil, "changeset " .. tostring(cs.changeset_id) .. ": " .. tostring(jerr)
        end
        for _, row in ipairs(journal or {}) do
            table.insert(out, change_from_journal(row, cfg))
        end
    end
    return out, cfg
end

M._namespace_from_entry_id = namespace_from_entry_id
M._namespace_root = namespace_root
M._is_managed_namespace = is_managed_namespace
M._change_from_journal = change_from_journal
M._default_states = DEFAULT_STATES

return M
