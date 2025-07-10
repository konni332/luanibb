
-- Keymaps

vim.g.mapleader = "\\"

vim.keymap.set("n", "<leader>fz", function()
    require("nibb.telescope").snippet_picker()
end, { desc = "Fuzzy search snippets" })
