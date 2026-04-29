-- keeper.components:filenames
--
-- Central filename-stem sanitizer for generated component artifacts. Callers
-- pass stems only; the UI runner appends ".png" and keeps a final guard.

local M = {}
local uuid = require("uuid")

local DEFAULT_FALLBACK = "screenshot"
local DEFAULT_MAX_LENGTH = 96
local MIN_MAX_LENGTH = 16
local DEFAULT_SEED_LENGTH = 16

local RESERVED = {
    con = true,
    prn = true,
    aux = true,
    nul = true,
    com1 = true,
    com2 = true,
    com3 = true,
    com4 = true,
    com5 = true,
    com6 = true,
    com7 = true,
    com8 = true,
    com9 = true,
    lpt1 = true,
    lpt2 = true,
    lpt3 = true,
    lpt4 = true,
    lpt5 = true,
    lpt6 = true,
    lpt7 = true,
    lpt8 = true,
    lpt9 = true,
}

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function clamp_max(n)
    local value = DEFAULT_MAX_LENGTH
    if type(n) == "number" then
        value = n
    elseif type(n) == "string" then
        value = tonumber(n) or DEFAULT_MAX_LENGTH
    end
    if value < MIN_MAX_LENGTH then return MIN_MAX_LENGTH end
    return math.floor(value)
end

local function strip_png_extension(s)
    if s:lower():sub(-4) == ".png" then
        return s:sub(1, -5)
    end
    return s
end

local function clean_once(value, max_length)
    local s = trim(tostring(value or ""))
    s = strip_png_extension(s)
    s = s:gsub("[/\\:]+", "_")
    s = s:gsub("[^A-Za-z0-9_-]+", "_")
    s = s:gsub("_+", "_")
    s = s:gsub("^[_%-]+", "")
    s = s:gsub("[_%-]+$", "")
    if #s > max_length then
        s = s:sub(1, max_length):gsub("[_%-]+$", "")
    end
    return s
end

function M.safe_stem(value, opts)
    opts = opts or {}
    local max_length = clamp_max(opts.max_length)
    local fallback = opts.fallback or DEFAULT_FALLBACK

    local stem = clean_once(value, max_length)
    if stem == "" then
        stem = clean_once(fallback, max_length)
    end
    if stem == "" then
        stem = DEFAULT_FALLBACK
    end

    if RESERVED[stem:lower()] then
        stem = "file_" .. stem
    end
    if #stem > max_length then
        stem = stem:sub(1, max_length):gsub("[_%-]+$", "")
    end
    if stem == "" then
        stem = DEFAULT_FALLBACK
    end
    return stem
end

function M.random_seed(length)
    length = clamp_max(length or DEFAULT_SEED_LENGTH)
    local id = uuid.v4()
    local hex = tostring(id or ""):gsub("[^0-9A-Fa-f]", ""):lower()
    if #hex >= length then
        return hex:sub(1, length)
    end
    -- uuid.v4 should be available in production. Keep a non-empty fallback so
    -- callers never silently write deterministic ad-hoc screenshot names.
    local fallback = tostring(os.time()) .. tostring(math.random(100000, 999999))
    return M.safe_stem(fallback, { max_length = length, fallback = "seed" })
end

function M.with_random_seed(value, opts)
    opts = opts or {}
    local max_length = DEFAULT_MAX_LENGTH
    if type(opts.max_length) == "number" or type(opts.max_length) == "string" then
        max_length = clamp_max(opts.max_length)
    end
    local seed_limit = 32
    if max_length < seed_limit + 2 then seed_limit = max_length - 2 end
    if seed_limit < 1 then seed_limit = 1 end

    local seed = clean_once(opts.seed or M.random_seed(opts.seed_length), seed_limit)
    if seed == "" then seed = clean_once("seed", seed_limit) end
    if #seed >= max_length then
        return seed:sub(1, max_length):gsub("[_%-]+$", "")
    end

    local base_limit = max_length - #seed - 1
    local base = clean_once(value, base_limit)
    if base == "" then
        base = clean_once(opts.fallback or DEFAULT_FALLBACK, base_limit)
    end
    if base == "" then base = "s" end
    if RESERVED[base:lower()] then
        base = clean_once("file_" .. base, base_limit)
    end
    if base == "" then base = "s" end
    return base .. "-" .. seed
end

function M.component_slug(desc, component_id)
    local from_path
    if type(desc) == "table" and type(desc.path) == "string" then
        from_path = desc.path:match("[^/\\]+$")
    end
    return M.safe_stem(from_path or component_id, { fallback = "component" })
end

return M
