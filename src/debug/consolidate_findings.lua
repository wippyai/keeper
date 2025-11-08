local json = require("json")

local function run(args)
    local query = args.query
    local results = args.results or {}

    local findings = {}

    for _, item in ipairs(results) do
        if item.result then
            table.insert(findings, item.result)
        end
        if item.error then
            table.insert(findings, string.format("Error: %s", item.error.error or "Unknown error"))
        end
    end

    if #findings == 0 then
        return "No findings from investigation"
    end

    return string.format("# Debug Investigation\n\n**Query**: %s\n\n%s", query, table.concat(findings, "\n\n---\n\n"))
end

return { run = run }