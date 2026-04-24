local test = require("test")
local json = require("json")
local detectors = require("detectors")

local function node(fields)
    return {
        node_id         = fields.node_id or "n1",
        parent_node_id  = fields.parent_node_id,
        type            = fields.type,
        status          = fields.status,
        metadata        = fields.metadata or {},
    }
end

local function action_row(node_id, tool_calls)
    return {
        node_id      = node_id,
        type         = "agent.action",
        content_type = "application/json",
        content      = json.encode({ tool_calls = tool_calls }),
    }
end

local function observation_row(node_id, value)
    return {
        node_id      = node_id,
        type         = "agent.observation",
        content_type = "application/json",
        content      = json.encode(value),
    }
end

local function define_tests()
    describe("Flow detectors", function()

        describe("detect_iteration_exhaustion", function()
            it("flags agent node with MAX_ITERATIONS error code", function()
                local findings = {}
                detectors.detect_iteration_exhaustion({
                    node(
                        { node_id = "a1",
                          type    = "userspace.dataflow.node.agent:node",
                          status  = "failed",
                          metadata = { error = { code = "MAX_ITERATIONS" } } })
                }, findings)
                test.eq(#findings, 1)
                test.eq(findings[1].type, "iteration_exhaustion")
                test.eq(findings[1].severity, "high")
                test.eq(findings[1].node_id, "a1")
            end)

            it("flags agent node by status_message substring", function()
                local findings = {}
                detectors.detect_iteration_exhaustion({
                    node(
                        { node_id = "a2",
                          type    = "userspace.dataflow.node.agent:node",
                          status  = "failed",
                          metadata = { status_message = "Maximum iterations reached" } })
                }, findings)
                test.eq(#findings, 1)
                test.is_true(findings[1].evidence:find("Maximum iterations") ~= nil)
            end)

            it("ignores non-agent or non-failed nodes", function()
                local findings = {}
                detectors.detect_iteration_exhaustion({
                    node({ type = "tool.call", status = "failed",
                           metadata = { error = { code = "MAX_ITERATIONS" } } }),
                    node({ type = "userspace.dataflow.node.agent:node", status = "completed",
                           metadata = { error = { code = "MAX_ITERATIONS" } } }),
                }, findings)
                test.eq(#findings, 0)
            end)
        end)

        describe("detect_cycle_exhaustion", function()
            it("flags cycle node with MAX_ITERATIONS_EXCEEDED", function()
                local findings = {}
                detectors.detect_cycle_exhaustion({
                    node({ node_id = "c1",
                           type    = "userspace.dataflow.node.cycle:cycle",
                           status  = "failed",
                           metadata = { error = { code = "MAX_ITERATIONS_EXCEEDED" } } })
                }, findings)
                test.eq(#findings, 1)
                test.eq(findings[1].type, "cycle_exhaustion")
                test.eq(findings[1].node_id, "c1")
            end)

            it("ignores non-cycle nodes", function()
                local findings = {}
                detectors.detect_cycle_exhaustion({
                    node({ type = "tool.call", status = "failed",
                           metadata = { error = { code = "MAX_ITERATIONS_EXCEEDED" } } }),
                }, findings)
                test.eq(#findings, 0)
            end)
        end)

        describe("detect_tool_failures", function()
            it("flags each failed tool.call node", function()
                local findings = {}
                detectors.detect_tool_failures({
                    node({ node_id = "t1", parent_node_id = "a1",
                           type = "tool.call", status = "failed",
                           metadata = { title = "my_tool", error_message = "boom" } }),
                    node({ node_id = "t2", parent_node_id = "a1",
                           type = "tool.call", status = "completed" }),
                }, findings)
                test.eq(#findings, 1)
                test.eq(findings[1].type, "tool_failure")
                test.eq(findings[1].severity, "medium")
                test.eq(findings[1].node_id, "t1")
                test.eq(findings[1].parent_id, "a1")
                test.is_true(findings[1].title:find("boom") ~= nil)
            end)

            it("falls back to metadata.error.message when error_message is absent", function()
                local findings = {}
                detectors.detect_tool_failures({
                    node({ node_id = "t3", type = "tool.call", status = "failed",
                           metadata = { error = { message = "nested" } } }),
                }, findings)
                test.eq(#findings, 1)
                test.is_true(findings[1].evidence:find("nested") ~= nil)
            end)
        end)

        describe("detect_retry_loops", function()
            it("flags a tool called 3+ times with identical args", function()
                local findings = {}
                local tc = { name = "search", arguments = { q = "foo" } }
                detectors.detect_retry_loops({
                    action_row("a1", { tc }),
                    action_row("a1", { tc }),
                    action_row("a1", { tc }),
                }, findings)
                test.eq(#findings, 1)
                test.eq(findings[1].type, "retry_loop")
                test.eq(findings[1].node_id, "a1")
                test.is_true(findings[1].title:find("search called 3x") ~= nil)
            end)

            it("does not flag when count is below threshold", function()
                local findings = {}
                local tc = { name = "search", arguments = { q = "foo" } }
                detectors.detect_retry_loops({
                    action_row("a1", { tc }),
                    action_row("a1", { tc }),
                }, findings)
                test.eq(#findings, 0)
            end)

            it("treats different args as distinct calls", function()
                local findings = {}
                detectors.detect_retry_loops({
                    action_row("a1", { { name = "search", arguments = { q = "a" } } }),
                    action_row("a1", { { name = "search", arguments = { q = "b" } } }),
                    action_row("a1", { { name = "search", arguments = { q = "c" } } }),
                }, findings)
                test.eq(#findings, 0)
            end)

            it("scopes retry detection per node_id", function()
                local findings = {}
                local tc = { name = "search", arguments = { q = "same" } }
                detectors.detect_retry_loops({
                    action_row("a1", { tc }),
                    action_row("a1", { tc }),
                    action_row("a2", { tc }),
                }, findings)
                test.eq(#findings, 0, "retries must be within one agent node")
            end)
        end)

        describe("detect_sequence_violations", function()
            it("flags observations carrying known precondition errors", function()
                local findings = {}
                detectors.detect_sequence_violations({
                    observation_row("a1", "Error: Cannot modify main branch directly"),
                }, findings)
                test.eq(#findings, 1)
                test.eq(findings[1].type, "sequence_violation")
                test.is_true(findings[1].title:find("Cannot modify main branch") ~= nil)
                test.is_true(findings[1].suggested:find("set_branch") ~= nil)
            end)

            it("emits at most one finding per observation row", function()
                local findings = {}
                detectors.detect_sequence_violations({
                    observation_row("a1",
                        "Cannot modify main branch. Invalid entry ID format."),
                }, findings)
                test.eq(#findings, 1, "break after first match")
            end)

            it("ignores non-observation rows", function()
                local findings = {}
                detectors.detect_sequence_violations({
                    {
                        node_id      = "a1",
                        type         = "agent.action",
                        content_type = "application/json",
                        content      = "Cannot modify main branch",
                    },
                }, findings)
                test.eq(#findings, 0)
            end)

            it("searches encoded JSON body when value is a table", function()
                local findings = {}
                detectors.detect_sequence_violations({
                    observation_row("a1", { error = "not found: foo" }),
                }, findings)
                test.eq(#findings, 1)
                test.is_true(findings[1].title:find("not found") ~= nil)
            end)
        end)

        describe("analyze", function()
            it("returns empty list when inputs are nil", function()
                local out = detectors.analyze(nil, nil)
                test.eq(#out, 0)
            end)

            it("sorts high severity before medium, then by type", function()
                local nodes = {
                    node({ node_id = "t1", type = "tool.call", status = "failed",
                           metadata = { error_message = "x" } }),
                    node({ node_id = "a1",
                           type = "userspace.dataflow.node.agent:node",
                           status = "failed",
                           metadata = { error = { code = "MAX_ITERATIONS" } } }),
                    node({ node_id = "c1",
                           type = "userspace.dataflow.node.cycle:cycle",
                           status = "failed",
                           metadata = { error = { code = "MAX_ITERATIONS_EXCEEDED" } } }),
                }
                local out = detectors.analyze(nodes, {})
                test.eq(#out, 3)
                test.eq(out[1].severity, "high")
                test.eq(out[2].severity, "high")
                test.eq(out[3].severity, "medium")
                test.eq(out[1].type, "cycle_exhaustion",
                    "ties within high severity sort by type ascending")
                test.eq(out[2].type, "iteration_exhaustion")
            end)
        end)
    end)
end

local run = test.run_cases(define_tests)
return { define_tests = run }
