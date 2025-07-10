local engine = require("nibb.engine")

-- Utils

function parse_snippet_buffer(lines)
    local meta = {
        name = nil,
        tags = {},
        language = nil,
        created = nil
    }
    local description_lines, content_lines = {}, {}
    local state = "head"

    local found = {
        name = false,
        tags = false,
        language = false,
        created = false,
    }

    for _, line in ipairs(lines) do
        if state == "head" then
            if line:match("^Name:%s*(.*)") then
                meta.name = line:match("^Name:%s*(.*)")
                found.name = true
            elseif line:match("^Tags:%s*(.*)") then
                local tags = line:match("^Tags:%s*(.*)")
                meta.tags = vim.split(tags, ",%s*")
                found.tags = true
            elseif line:match("^Language:%s*(.*)") then
                meta.language = line:match("^Language:%s*(.*)")
                found.language = true
            elseif line:match("^Created:%s*(.*)") then
                meta.created = line:match("^Created:%s*(.*)")
                found.created = true
            elseif line == "Description:" then
                state = "desc"
            end
        elseif state == "desc" then
            if line == "Content:" then
                state = "content"
            else
                table.insert(description_lines, line)
            end
        elseif state == "content" then
            table.insert(content_lines, line)
        end
    end

    for key, was_found in pairs(found) do
        if not was_found then
            return false, string.format("Fehlendes Feld: %s", key:sub(1,1):upper() .. key:sub(2))
        end
    end

    if not meta.tags then
        meta.tags = {}
    end

    return true, {
        meta = {
            name = meta.name,
            tags = meta.tags,
            language = meta.language,
            created = meta.created,
            description = table.concat(description_lines, "\n"),
        },
        content = table.concat(content_lines, "\n"),
    }
end


-- Core functions

local M = {}

function M.get_all_snippets()
    local snippets = engine.load_all()
    if not snippets then return {} end
    return snippets
end

function M.edit_snippet(name)
    local snippet = engine.load_snippet(name)
    if not snippet then
        vim.notify("Snippet not found", vim.log.levels.ERROR)
        return
    end

    local meta = snippet.meta
    local lines = {
        "Name: " .. (meta.name or ""),
        "Tags: " .. table.concat(meta.tags or {}, ", "),
        "Language: " .. (meta.language or ""),
        "Created: " .. (meta.created or os.date("!%Y-%m-%dT%H:%M:%SZ")),
        "Modified: " .. (meta.modified or os.date("!%Y-%m-%dT%H:%M:%SZ")),
        "",
        "Description:",
    }
    vim.list_extend(lines, vim.split(meta.description or "", "\n"))
    table.insert(lines, "")
    table.insert(lines, "Content:")
    vim.list_extend(lines, vim.split(snippet.content or "", "\n"))

    local buf = vim.api.nvim_create_buf(false, true) 
    vim.api.nvim_buf_set_name(buf, "snippet:" .. (meta.name or "unnamed"))
    vim.api.nvim_buf_set_option(buf, "buftype", "acwrite") 
    vim.api.nvim_buf_set_option(buf, "swapfile", false)
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_option(buf, "filetype", "nibedit")
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.cmd("tabnew")
    vim.api.nvim_win_set_buf(0, buf)

    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>q!<CR>', { noremap = true, silent = true })

    -- Save logic
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function()
            local new_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local ok, updated = parse_snippet_buffer(new_lines)
            if not ok then
                vim.notify("Failed to parse snippet", vim.log.levels.ERROR)
                return
            end

            updated.meta.modified = os.date("!%Y-%m-%dT%H:%M:%SZ")
            local ok2, err = pcall(function()
                engine.save_snippet(updated)
            end)
            if not ok2 then
                vim.notify("Error saving snippet: " .. err, vim.log.levels.ERROR)
                return
            end

            vim.notify("Snippet saved", vim.log.levels.INFO)

            vim.schedule(function()
                vim.api.nvim_buf_set_option(buf, "modified", false)

                local tabpages = vim.api.nvim_list_tabpages()
                local cur_tab = vim.api.nvim_get_current_tabpage()

                if #tabpages > 1 then
                    vim.cmd("tabclose")
                else
                    local wins = vim.api.nvim_list_wins()
                    for _, win in ipairs(wins) do
                        if vim.api.nvim_win_get_buf(win) == buf then
                            pcall(vim.api.nvim_win_close, win, true)
                            break
                        end
                    end
                end
            end)
        end,
    })
end


function M.new_snippet()
    local now = os.date("!%Y-%m-%dT%H:%M:%SZ") -- UTC ISO 8601

    local snippet = {
        meta = {
            name = "",
            tags = {},
            description = "",
            language = "",
            created = now,
            modified = now,
            visibility = "private", -- default
        },
        content = "Empty",
    }

    local function input_tags(tags_str)
        for tag in string.gmatch(tags_str, "[^,%s]+") do
            table.insert(snippet.meta.tags, tag)
        end
    end

    vim.ui.input({ prompt = "Snippet name: " }, function(name)
        if not name or name == "" then
            vim.notify("Aborted: No name given", vim.log.levels.ERROR)
            return
        end
        snippet.meta.name = name

        vim.ui.input({ prompt = "Tags (comma-separated): " }, function(tags)
            if tags then input_tags(tags) end

            vim.ui.input({ prompt = "Description: " }, function(desc)
                snippet.meta.description = desc or ""

                vim.ui.input({ prompt = "Language: " }, function(lang)
                    snippet.meta.language = lang or ""

                    vim.ui.select({ "private", "public" }, { prompt = "Visibility:" }, function(vis)
                        snippet.meta.visibility = vis or "private"

                        -- Save
                        local success = engine.save_snippet(snippet)
                        if not success then
                            vim.notify("Error saving snippet", vim.log.levels.ERROR)
                            return
                        end

                        -- Edit content
                        M.edit_snippet(snippet.meta.name)
                    end)
                end)
            end)
        end)
    end)
end

function M.delete_snippet(name)
    local confirm = vim.fn.input("Are you sure you want to delete '" .. name .. "'? (y/n): ")
    if confirm:lower() == "y" then
        engine.delete_snippet(name)
        vim.notify("Deleted snippet: " .. name, vim.log.levels.INFO)
    else
        vim.notify("Aborted deletion.", vim.log.levels.WARN)
    end
end

function M.insert_snippet(name)
    local snippet = engine.load_snippet(name)
    if not snippet or not snippet.content then
        vim.notify("Error fetching snippet for insert", vim.log.levels.ERROR)
        return
    end
    local content = snippet.content

    local lines = {}
        for line in content:gmatch("([^\n]*)\n?") do
            table.insert(lines, line)
        end
        if lines[#lines] == "" then
            table.remove(lines, #lines)
        end

        -- Arguments: lines, type (true=after cursor), follow_cursor, put_register
        vim.api.nvim_put(lines, 'l', true, true)
end


return M
