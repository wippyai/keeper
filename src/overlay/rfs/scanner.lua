-- Text Search Engine over RFS with Memory Optimizations
local consts = require("consts")

local scanner = {}

-- ============================================================================
-- SCANNER CLASS
-- ============================================================================

local scanner_methods = {}
local scanner_mt = { __index = scanner_methods }

-- Create new scanner instance
function scanner.new(rfs_reader)
    if not rfs_reader then
        return nil, "RFS reader is required"
    end

    local instance = {
        _rfs_reader = rfs_reader,
        _index = nil,
        _built = false
    }

    return setmetatable(instance, scanner_mt), nil
end

-- ============================================================================
-- INDEX BUILDING
-- ============================================================================

-- Build searchable index from RFS reader
function scanner_methods:build_index()
    if self._built then
        return self, nil -- already built
    end

    -- Get all accessible namespaces and files first to count total files
    local tree, err = self._rfs_reader:get_tree()
    if err then
        return nil, "Failed to get RFS tree: " .. tostring(err)
    end

    if not tree or not tree.namespaces then
        return nil, "Invalid tree structure returned from RFS reader"
    end

    -- Count total files for pre-allocation
    local total_files = 0
    for _, namespace_info in ipairs(tree.namespaces) do
        if namespace_info.files then
            total_files = total_files + #namespace_info.files
        end
    end

    local index = {
        files = table.create(0, total_files),  -- Pre-allocate hash table
        total_files = 0,
        total_lines = 0
    }

    -- Index all files from all namespaces
    for namespace_idx, namespace_info in ipairs(tree.namespaces) do
        if type(namespace_info) ~= "table" then
            return nil, "Invalid namespace_info at index " .. namespace_idx .. ": expected table, got " .. type(namespace_info)
        end

        local namespace = namespace_info.namespace

        if type(namespace) ~= "string" then
            return nil, "Invalid namespace type at index " .. namespace_idx .. ": expected string, got " .. type(namespace)
        end

        if not namespace_info.files then
            return nil, "No files array in namespace info for " .. namespace
        end

        if type(namespace_info.files) ~= "table" then
            return nil, "Files must be a table for namespace " .. namespace
        end

        for file_idx, filename in ipairs(namespace_info.files) do
            if type(filename) ~= "string" then
                return nil, "Invalid filename type at namespace " .. namespace .. ", file index " .. file_idx .. ": expected string, got " .. type(filename)
            end

            -- Build file path carefully
            local namespace_path = namespace:gsub("%.", "/")
            if type(namespace_path) ~= "string" then
                return nil, "Namespace path conversion failed for " .. namespace
            end

            local file_path = namespace_path .. "/" .. filename
            if type(file_path) ~= "string" then
                return nil, "File path construction failed: " .. type(file_path)
            end

            local file_result = self._rfs_reader:read_file(file_path)

            if file_result and file_result.content and not file_result.error then
                local file_index, index_err = self:_index_file_content(file_path, file_result.content)
                if index_err then
                    return nil, "Failed to index file " .. file_path .. ": " .. index_err
                end

                index.files[file_path] = file_index
                index.total_files = index.total_files + 1
                index.total_lines = index.total_lines + #file_index.lines
            end
        end
    end

    self._index = index
    self._built = true
    return self, nil
end

-- Index individual file content
function scanner_methods:_index_file_content(file_path, content)
    if type(content) ~= "string" then
        return nil, "Content must be a string"
    end

    -- Estimate line count for pre-allocation (average ~60 chars per line)
    local estimated_lines = math.max(10, math.floor(#content / 60))
    local lines = table.create(estimated_lines, 0)
    local line_number = 1

    -- Split content into lines while preserving line endings
    for line in content:gmatch("([^\r\n]*)\r?\n?") do
        if line_number == 1 or line ~= "" or content:sub(-1) == "\n" then
            table.insert(lines, {
                number = line_number,
                content = line,
                length = #line
            })
            line_number = line_number + 1
        end
    end

    -- Handle edge case of content without final newline
    if content ~= "" and not content:match("\n$") and #lines == 0 then
        table.insert(lines, {
            number = 1,
            content = content,
            length = #content
        })
    end

    return {
        file_path = file_path,
        lines = lines,
        total_lines = #lines
    }, nil
end

-- ============================================================================
-- SEARCH OPERATIONS
-- ============================================================================

-- Execute multiple search queries
function scanner_methods:search(queries)
    if not self._built then
        return nil, "Index must be built before searching. Call :build_index() first."
    end

    if not queries or type(queries) ~= "table" then
        return nil, "Queries must be a table of {query_name = pattern}"
    end

    -- Count queries for pre-allocation
    local query_count = 0
    for _ in pairs(queries) do
        query_count = query_count + 1
    end
    local results = table.create(0, query_count)

    -- Process each query
    for query_name, query_pattern in pairs(queries) do
        local query_results, err = self:_execute_single_query(query_pattern)
        if err then
            return nil, "Failed to execute query '" .. query_name .. "': " .. err
        end
        results[query_name] = query_results
    end

    return results, nil
end

-- Execute single search query
function scanner_methods:_execute_single_query(query_pattern)
    local pattern_type, search_pattern, err = self:_parse_query_pattern(query_pattern)
    if err then
        return nil, err
    end

    -- Estimate total matches for pre-allocation (conservative estimate)
    local estimated_matches = math.min(1000, self._index.total_files * 5)
    local matches = table.create(estimated_matches, 0)

    -- Search across all indexed files
    for file_path, file_index in pairs(self._index.files) do
        local file_matches = self:_search_in_file(file_index, pattern_type, search_pattern)

        for _, match in ipairs(file_matches) do
            table.insert(matches, match)
        end
    end

    -- Sort matches by file path, then line number
    table.sort(matches, function(a, b)
        if a.file_path ~= b.file_path then
            return a.file_path < b.file_path
        end
        return a.line < b.line
    end)

    return matches, nil
end

-- Parse query pattern (string literal vs regex)
function scanner_methods:_parse_query_pattern(query_pattern)
    if type(query_pattern) == "string" then
        return "literal", query_pattern, nil
    elseif type(query_pattern) == "table" and query_pattern.regex then
        return "regex", query_pattern.regex, nil
    else
        return nil, nil, "Invalid query pattern. Use string for literal or {regex = 'pattern'} for regex"
    end
end

-- Search within a single file
function scanner_methods:_search_in_file(file_index, pattern_type, search_pattern)
    -- Estimate matches per file (conservative: ~1 match per 20 lines)
    local estimated_file_matches = math.min(50, math.floor(#file_index.lines / 20))
    local matches = table.create(estimated_file_matches, 0)

    for _, line_info in ipairs(file_index.lines) do
        local line_matches = self:_search_in_line(file_index, line_info, pattern_type, search_pattern)

        for _, match in ipairs(line_matches) do
            table.insert(matches, match)
        end
    end

    return matches
end

-- Search within a single line
function scanner_methods:_search_in_line(file_index, line_info, pattern_type, search_pattern)
    local matches = table.create(5, 0)  -- Most lines have few matches
    local line_content = line_info.content

    if pattern_type == "literal" then
        -- String literal search
        local start_pos = 1
        while true do
            local match_start, match_end = line_content:find(search_pattern, start_pos, true) -- plain text search
            if not match_start then
                break
            end

            local match_text = line_content:sub(match_start, match_end)

            -- Store context info for lazy generation
            table.insert(matches, {
                file_path = file_index.file_path,
                line = line_info.number,
                match_text = match_text,
                _context_info = {
                    file_index = file_index,
                    line_number = line_info.number,
                    match_start = match_start,
                    match_end = match_end
                }
            })

            start_pos = match_end + 1
        end

    elseif pattern_type == "regex" then
        -- Regex pattern search
        local start_pos = 1
        while start_pos <= #line_content do
            local match_start, match_end = line_content:find(search_pattern, start_pos)
            if not match_start then
                break
            end

            local match_text = line_content:sub(match_start, match_end)

            -- Store context info for lazy generation
            table.insert(matches, {
                file_path = file_index.file_path,
                line = line_info.number,
                match_text = match_text,
                _context_info = {
                    file_index = file_index,
                    line_number = line_info.number,
                    match_start = match_start,
                    match_end = match_end
                }
            })

            start_pos = match_end + 1
        end
    end

    -- Add metatable for lazy context generation
    for _, match in ipairs(matches) do
        setmetatable(match, {
            __index = function(t, k)
                if k == "context" then
                    -- Generate context on first access
                    local ctx_info = rawget(t, "_context_info")
                    if ctx_info then
                        local context = self:_extract_context(
                            ctx_info.file_index,
                            ctx_info.line_number,
                            ctx_info.match_start,
                            ctx_info.match_end
                        )
                        rawset(t, "context", context)  -- Cache it
                        rawset(t, "_context_info", nil)  -- Remove context info
                        return context
                    end
                end
                return rawget(t, k)
            end
        })
    end

    return matches
end

-- Extract context around match (previous line + current line + next line)
function scanner_methods:_extract_context(file_index, line_number, match_start, match_end)
    local context_lines = table.create(3, 0)  -- Max 3 lines: prev + current + next

    -- Get previous line
    if line_number > 1 then
        local prev_line = file_index.lines[line_number - 1]
        if prev_line then
            table.insert(context_lines, prev_line.content)
        end
    end

    -- Get current line
    local current_line = file_index.lines[line_number]
    if current_line then
        table.insert(context_lines, current_line.content)
    end

    -- Get next line
    if line_number < #file_index.lines then
        local next_line = file_index.lines[line_number + 1]
        if next_line then
            table.insert(context_lines, next_line.content)
        end
    end

    return table.concat(context_lines, "\n")
end

-- ============================================================================
-- UTILITY METHODS
-- ============================================================================

-- Get index statistics
function scanner_methods:get_stats()
    if not self._built then
        return {
            built = false,
            total_files = 0,
            total_lines = 0
        }
    end

    return {
        built = true,
        total_files = self._index.total_files,
        total_lines = self._index.total_lines
    }
end

-- Check if index is built
function scanner_methods:is_built()
    return self._built
end

-- Rebuild index (clears existing and rebuilds)
function scanner_methods:rebuild_index()
    self._index = nil
    self._built = false
    return self:build_index()
end

return scanner