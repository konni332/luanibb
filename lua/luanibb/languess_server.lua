local ffi = require("ffi")

ffi.cdef[[
    char *predict_ffi(const char *input);
    char *init_predictor_ffi(void);
    bool is_predictor_initialized_ffi(void);
    char *server_predict(const char *input);
    void free_string_ffi(char *s);
    void shutdown_predictor_ffi();
]]
--- Expands a tilde-prefixed path to an absolute Windows path.
-- @param path (string) The path containing `~` as the home directory.
-- @return (string) The expanded path.
local function expand_home(path)
    return path:gsub("^~", os.getenv("USERPROFILE") or "~")
end

local lib_path = expand_home(require("luanibb.config").get_languess_lib_path())
local ok, engine = pcall(ffi.load, lib_path)
if not ok then
        error("Failed to load languess_core library backend: " .. tostring(engine))
end

-- Utils

--- Safely converts a C string to a Lua string and frees the original.
-- @param c_str (cdata*) The raw C string returned from FFI.
-- @return (string) The resulting Lua string.
local function safe_string(c_str)
    local lua_str = ffi.string(c_str)
    engine.free_string_ffi(c_str)
return lua_str
end

local function is_running()
    return engine.is_predictor_initialized_ffi()
end


-- Core functions

local M = {}

function M.start_server()
    if is_running() then return end

    local started = safe_string(engine.init_predictor_ffi())
    
    if started ~= "ok" then
        vim.notify("Error starting languess server: " .. started, vim.log.levels.ERROR)
        return
    end

    vim.notify("Started languess server", vim.log.levels.INFO)
end

function M.is_running()
    return is_running()
end

function M.kill_server()
    engine.shutdown_predictor_ffi()
    vim.notify("Languess server killed", vim.log.levels.WARN)
end

function M.predict(content)
    if not content or content == "" then
        vim.notify("Error: not valid content", vim.log.levels.ERROR)
        return nil
    end
    local prediction = safe_string(engine.predict_ffi(content))
    if not prediction or prediction == "" then
        vim.notify("Error predicting content:\n" .. content, vim.log.levels.ERROR)
        return nil
    end
    return prediction
end

return M
