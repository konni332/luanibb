local config = require("luanibb.config")

local M = {}

function M.setup(user_opts)
    user_opts = user_opts or {}

    if user_opts.nibb_lib_path then
        config.set_nibb_lib_path(user_opts.nibb_lib_path)
    end
    if user_opts.languess_lib_path then
        config.set_languess_lib_path(user_opts.languess_lib_path)
    end

    M.auto_start_languess = user_opts.auto_start_languess ~= false
    
    -- Auto language detection using a languess server.
    -- set auto_start_languess = true / false, to activate / deactivate.
    -- When deactivated, the server can still be activated with ":Nibb languess start" as normal.
    -- The server can always be killed using: ":Nibb languess kill"
    -- The server status can be fetched using ":Nibb languess?"
    if M.auto_start_languess then
        local languess = require("luanibb.languess_server")
        vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
                languess.start_server()
            end,
        })
    end

    if user_opts.enable_default_keymaps ~= false then
        vim.keymap.set("n", "<leader>fz", function()
            require("luanibb.telescope").snippet_picker()
        end, { desc = "Fuzzy search snippets" })
    end

    require("luanibb.nibb_cmd")
end

return M



