-- keeper.git.flows:file_diff — function-callable wrapper around git_scan.file_diff
-- that ALSO parses unified diff text into structured hunks for nice rendering.
--
-- Returns:
--   { path, diff_text, hunks = { { header, lines = [{kind, text, old_no, new_no}] } }, exit_code }

local git_scan = require("git_scan")

local M = {}

local function parse_diff(text)
    if not text or text == "" then return {} end
    local hunks = {}
    local current = nil
    local old_no, new_no = 0, 0
    for line in text:gmatch("([^\n]*)\n?") do
        if line == "" and not current then
            -- skip preamble blank
        elseif line:sub(1, 4) == "@@ " or line:match("^@@.*@@") then
            -- @@ -old_start,old_count +new_start,new_count @@
            local os_, oc, ns_, nc = line:match("@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
            old_no = tonumber(os_) or 0
            new_no = tonumber(ns_) or 0
            current = { header = line, lines = {} }
            table.insert(hunks, current)
        elseif current then
            local prefix = line:sub(1, 1)
            if prefix == "+" and line:sub(1, 3) ~= "+++" then
                table.insert(current.lines, {
                    kind = "+", text = line:sub(2), old_no = nil, new_no = new_no,
                })
                new_no = new_no + 1
            elseif prefix == "-" and line:sub(1, 3) ~= "---" then
                table.insert(current.lines, {
                    kind = "-", text = line:sub(2), old_no = old_no, new_no = nil,
                })
                old_no = old_no + 1
            elseif prefix == " " then
                table.insert(current.lines, {
                    kind = " ", text = line:sub(2), old_no = old_no, new_no = new_no,
                })
                old_no = old_no + 1
                new_no = new_no + 1
            elseif prefix == "\\" then
                -- "\ No newline at end of file" — skip silently
            end
        end
    end
    return hunks
end

function M.handler(params)
    params = params or {}
    local res, err = git_scan.file_diff(params.path, { diff_base = params.diff_base })
    if err then return nil, err end
    local hunks = parse_diff(res.diff or "")
    return {
        path      = res.path,
        diff_text = res.diff or "",
        hunks     = hunks,
        exit_code = res.exit_code,
    }
end

M._parse_diff = parse_diff

return M
