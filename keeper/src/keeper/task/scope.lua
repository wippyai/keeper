-- keeper.task:scope
--
-- Single source of truth for the task-scope payload that travels with a
-- dataflow. Every dataflow that keeper spawns for a task declares this
-- exact shape via :with_input(...) AND arena.context = ... so the runtime
-- always sees task_id + phase + the active changeset regardless of how
-- the dataflow was spawned.
--
-- Construct via scope.for_phase(task_id, phase, opts). Do not assemble
-- the table inline at call sites.

local changeset_repo = require("changeset_repo")

local M = {}

-- for_phase(task_id, phase, opts?) → { task_id, phase, changeset_id,
--                                      overlay_branch, actor_id? }
--
--   task_id  string (required)
--   phase    string (required)
--   opts     {
--              changeset_id?  string,   -- override repo lookup (used by
--                                          spawn_function before the cs
--                                          is resolved on disk)
--              actor_id?      string,   -- attached when relevant
--            }
function M.for_phase(task_id, phase, opts)
    opts = opts or {}
    local cs = changeset_repo.active_for_task(task_id)
    return {
        task_id        = task_id,
        phase          = phase,
        changeset_id   = (cs and cs.changeset_id) or opts.changeset_id,
        overlay_branch = cs and cs.state_branch or nil,
        actor_id       = opts.actor_id,
    }
end

return M
