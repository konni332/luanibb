local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local core = require("nibb.core")

-- Utils
local previewers = require("telescope.previewers")
local entry_display = require("telescope.pickers.entry_display")


local displayer = entry_display.create({
    separator = " | ",
    items = {
        { width = 30 },
        { width = 20 },
        { remaining = true },
    },
})


local function make_display(entry)
    return displayer({
        entry.value.meta.name or "",
        entry.value.meta.language or "",
        table.concat(entry.value.meta.tags or {}, ", "),
    })
end

local function snippet_previewer()
    return previewers.new_buffer_previewer({
        define_preview = function(self, entry, _)
            local snippet = entry.value
            local description = snippet.meta.description or ""
            local content = snippet.content or ""

            local lines = {}
            vim.list_extend(lines, vim.split(description, "\n", { trimempty = true }))
            table.insert(lines, "") 
            vim.list_extend(lines, vim.split(content, "\n", { trimempty = true }))

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

            local ft = type(snippet.meta.language) == "string" and snippet.meta.language:lower() or "txt"
            vim.bo[self.state.bufnr].filetype = ft
        end,
    })
end

-- Core functions

local M = {}


function M.snippet_picker(opts)
    opts = opts or {}

    local snippets = core.get_all_snippets()
    local entries = {}

    for _, snippet in ipairs(snippets) do
        table.insert(entries, {
            value = snippet,
            ordinal = table.concat({
                snippet.meta.name or "",
                snippet.meta.description or "",
                table.concat(snippet.meta.tags or {}, " "),
                snippet.meta.language or "",
                snippet.content or "",
            }, " "),
        })
    end
    
    table.sort(entries, function(a, b)
        local lang_a = a.value.meta.language or ""
        local lang_b = b.value.meta.language or ""
        return lang_a:lower() < lang_b:lower()
    end)

    pickers.new(opts, {
        prompt_title = "Snippets",
        finder = finders.new_table({
            results = entries,
            entry_maker = function(entry)
                return {
                    value = entry.value,
                    display = function()
                        return make_display(entry)
                    end,
                    ordinal = entry.ordinal or "",
                }
            end,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = snippet_previewer(),
        attach_mappings = function(prompt_bufnr, map)
            local function get_entry()
                return action_state.get_selected_entry()
            end

            map("i", "<CR>", function()
                local entry = get_entry()
                actions.close(prompt_bufnr)
                core.insert_snippet(entry.value.meta.name)
            end)

            map("i", "<C-d>", function()
                local entry = get_entry()
                actions.close(prompt_bufnr)
                vim.notify("Delete snippet: " .. (entry.value.meta.name or ""), vim.log.levels.WARN)
                core.delete_snippet(entry.value.meta.name) 
            end)

            map("i", "<C-e>", function()
                local entry = get_entry()
                actions.close(prompt_bufnr)
                vim.notify("Edit snippet: " .. (entry.value.meta.name or ""), vim.log.levels.INFO)
                core.edit_snippet(entry.value.meta.name) 
            end)

            map("i", "<C-n>", function()
                actions.close(prompt_bufnr)
                core.new_snippet() 
            end)

            return true
        end,
    }):find()
end




return M
