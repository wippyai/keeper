-- keeper.gov.service:sync
--
-- Source-file mapping helpers for the explicit registry -> filesystem download
-- (keeper.gov.tools:sync_to_fs). The registry is the store: registry changes,
-- installs, updates and rollbacks never write source files.

local M = {}

M.KIND_CONFIG = {
    ["function.lua"]   = { source_field = "source", extension = ".lua" },
    ["library.lua"]    = { source_field = "source", extension = ".lua" },
    ["process.lua"]    = { source_field = "source", extension = ".lua" },
    ["workflow.lua"]   = { source_field = "source", extension = ".lua" },
    ["template.jet"]   = { source_field = "source", extension = ".jet" },
    ["registry.entry"] = {
        types = {
            ["view.page"]   = { source_field = "source", extension = ".html" },
            ["module.spec"] = { source_field = "source", extension = ".md" },
            ["agent.gen1"]  = { source_field = "source", extension = ".yml" },
        }
    }
}

-- Pure: resolve the effective { source_field, extension } config for a given
-- kind + optional meta.type. Returns nil when no mapping exists.
function M.pick_kind_config(kind, meta_type)
    local kind_config = M.KIND_CONFIG[kind]
    if not kind_config then return nil end
    if kind_config.types and meta_type and kind_config.types[meta_type] then
        return kind_config.types[meta_type]
    end
    if kind_config.source_field and kind_config.extension then
        return kind_config
    end
    return nil
end

-- Pure: append the extension if the filename doesn't already end with it.
function M.append_extension(filename, extension)
    if not filename or not extension then return filename end
    if filename:sub(-#extension) == extension then return filename end
    return filename .. extension
end

-- Pure: pull the path out of a "file://..." URL. Returns nil for non-matching input.
function M.extract_filename(file_url)
    if not file_url or type(file_url) ~= "string" then return nil end
    return file_url:match("^file://(.+)$")
end

return M
