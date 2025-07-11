
-- Keymaps

vim.g.mapleader = "\\"

vim.keymap.set("n", "<leader>fz", function()
    require("nibb.telescope").snippet_picker()
end, { desc = "Fuzzy search snippets" })


-- Auto language detection using a languess server.
-- set auto_start_languess = true / false, to activate / deactivate.
-- When deactivated, the server can still be activated with ":Nibb languess start" as normal.
-- The server can always be killed using: ":Nibb languess kill"
local auto_start_languess = true
local languess = require("nibb.languess_server")
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if auto_start_languess then languess.start_server() end
    end,
})


-- Require :Nibb command
require("nibb.nibb_cmd")
