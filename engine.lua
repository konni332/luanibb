local ffi = require("ffi")

ffi.cdef[[
    char *load_snippet_ffi(const char *name);
    bool save_snippet_ffi(const char *snippet_json);
    char *load_all_ffi(void);
    bool save_all_ffi(const char *snippet_json);
    bool delete_snippet_ffi(const char *name);
    void free_string_ffi(char *s);
    char *nibb_git_generic_ffi(const char *args);
]]

--- Expands a tilde-prefixed path to an absolute Windows path.
-- @param path (string) The path containing `~` as the home directory.
-- @return (string) The expanded path.
local function expand_home(path)
    return path:gsub("^~", os.getenv("USERPROFILE") or "~")
end

local lib_path = expand_home(require("luanibb.config").get_nibb_lib_path())
local ok, engine = pcall(ffi.load, lib_path)
if not ok then
        error("Failed to load nibb_core library backend: " .. tostring(engine))
end

local M = {}


-- Utils

--- Safely converts a C string to a Lua string and frees the original.
-- @param c_str (cdata*) The raw C string returned from FFI.
-- @return (string) The resulting Lua string.
local function safe_string(c_str)
    local lua_str = ffi.string(c_str)
    engine.free_string_ffi(c_str)
    return lua_str
end

--- Checks if a JSON string represents a known error object.
-- @param json_str (string) The JSON string to inspect.
-- @return (table|false) The decoded error object or false if it's not an error.
local function is_error_json(json_str)
    local ok, obj = pcall(vim.fn.json_decode, json_str)
    if not ok or type(obj) ~= "table" or type(obj.type) ~= "string" then
        return false
    end
    local known_errors = {
        Io = true, Toml = true, TomlSer = true, UnsupportedLanguage = true,
        MissingField = true, NotFound = true, InvalidSlug = true,
        FFIError = true, Other = true
    }
    return known_errors[obj.type] and obj or false
end

--- Displays a user-facing load error notification.
-- @param err (table) The error object with `type` and `message` fields.
-- @return nil
local function load_error(err)
    vim.notify("Load error [" .. err.type .. "]: " .. err.message, vim.log.levels.ERROR)
    return nil
end

--- Decodes a JSON string into a Lua table safely.
-- @param json_str (string) The JSON string to decode.
-- @return (table|nil) The decoded table or nil on error.
local function safe_json_decode(json_str)
    local ok, result = pcall(vim.fn.json_decode, json_str)
    return ok and result or nil
end

--- Encodes a Lua table into a JSON string safely.
-- @param table (table) The table to encode.
-- @return (string|nil) The JSON string or nil on error.
local function safe_json_encode(table)
    local ok, result = pcall(vim.fn.json_encode, table)
    return ok and result or nil
end

-- Core functions

--- Loads a single snippet from the backend by name.
-- @param name (string) The name of the snippet.
-- @return (table|nil) The snippet table or nil on failure.
function M.load_snippet(name)
    local snippet_json = safe_string(engine.load_snippet_ffi(name))
    local err = is_error_json(snippet_json)
    if err then 
        return load_error(err)
    end

    local snippet = safe_json_decode(snippet_json)
    if not snippet then
        vim.notify("Error decoding snippet from JSON", vim.log.levels.ERROR)
        return nil
    end
    return snippet
end

--- Saves a single snippet to the backend.
-- @param snippet (table) The snippet to save.
-- @return (boolean) True on success, false on failure.
function M.save_snippet(snippet)
    local snippet_json = safe_json_encode(snippet)
    if not snippet_json then
        vim.notify("Error encoding snippet to JSON", vim.log.levels.ERROR)
        return false
    end
    
    local rc = engine.save_snippet_ffi(snippet_json)
    if rc == false then
        vim.notify("Error saving the snippet in backend\n" .. snippet_json, vim.log.levels.ERROR)
        return false
    end
    vim.notify("Saved snippet!", vim.log.levels.INFO)
    return true
end

--- Loads all snippets from the backend.
-- @return (table|nil) A list of snippet tables, or nil on failure.
function M.load_all()
    local snippets_json = safe_string(engine.load_all_ffi())
    local err = is_error_json(snippets_json)
    if err then
        return load_error(err)
    end

    local snippets = safe_json_decode(snippets_json)
    if not snippets then
        vim.notify("Error decoding snippets from JSON", vim.log.levels.ERROR)
        return nil
    end
    return snippets
end

--- Saves all snippets to the backend in bulk.
-- @param snippets (table) A list of snippets to save.
-- @return (boolean) True on success, false on failure.
function M.save_all(snippets)
    local snippet_json = safe_json_encode(snippets)
    if not snippet_json then
        vim.notify("Error encoding snippet to JSON", vim.log.levels.ERROR)
        return false
    end
    
    local rc = engine.save_all_ffi(snippet_json)
    if rc == 0 then
        vim.notify("Error saving the snippet in backend", vim.log.levels.ERROR)
        return false
    end
    vim.notify("Saved snippets!", vim.log.levels.INFO)
    return true
end

function M.delete_snippet(name)
    if not name or name == "" then
        vim.notify("Error: no valid snippet name", vim.log.levels.ERROR)
        return
    end
    local rc = engine.delete_snippet_ffi(name)
    if rc ~= true then
        vim.notify("Error occurred when trying to delete snippet " .. name, vim.log.levels.ERROR)
    end
end

function M.nibb_git_generic(args)
    if not args or args == "" then
        return
    end

    local result = safe_string(engine.nibb_git_generic_ffi(args))

    local err = is_error_json(result)
    if err then
        return load_error(err)
    end
    local out = safe_json_decode(result)
    return out
end

return M
