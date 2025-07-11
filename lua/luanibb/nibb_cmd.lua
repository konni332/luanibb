local languess = require("luanibb.languess_server")
local engine = require("luanibb.engine")
local function handle_languess_status()
    local ok, running = pcall(languess.is_running)

    if not ok then
        vim.notify("Error checking languess server", vim.log.levels.ERROR)
    elseif running then
        vim.notify("Languess server is running ✅", vim.log.levels.INFO)
    else
        vim.notify("Languess server is NOT running ❌", vim.log.levels.WARN)
    end
end


local function show_output_popup(args, stdout, stderr)
  local lines = {}
  table.insert(lines, "Args: " .. args)
  table.insert(lines, "")
  table.insert(lines, "STDOUT:")
  vim.list_extend(lines, vim.split(stdout or "", "\n", { trimempty = true }))
  table.insert(lines, "")
  table.insert(lines, "STDERR:")
  vim.list_extend(lines, vim.split(stderr or "", "\n", { trimempty = true }))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = math.max(60, vim.o.columns - 20)
  local height = math.min(#lines + 2, vim.o.lines - 6)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "nibboutput")

  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
end

local function handle_nibb_git(args)
    local cmd = args:sub(5)
        vim.notify("" .. cmd, vim.log.levels.WARN)
    local out = engine.nibb_git_generic(cmd)
    if not out or not out.stdout or not out.stderr then
        vim.notify("No git output", vim.log.levels.WARN)
        return
    end
    show_output_popup(args, out.stdout, out.stderr)
end

local function handle_languess_start()
    languess.start_server()
end

local function handle_languess_kill()
    languess.kill_server()
end

local function handle_languess()
    -- try "+"
    local content = vim.fn.getreg("+")
    -- try "*"
    if not content or content == "*" then
        content = vim.fn.getreg("*")
    end

    if not content or content == "" then
        vim.notify("Nothing in clipboard", vim.log.levels.WARN)
        return 
    end

    local prediction = languess.predict(content)
    if not prediction or prediction == "" then
        vim.notify("Error predicting clipboard filetype", vim.log.levels.ERROR)
        return
    end

    vim.notify("Predicted: '" .. prediction .. "' for the clipboard content!", vim.log.levels.INFO)
end

-- Commands

local nibb_commands = {}

nibb_commands = {
  help = {
    description = "Shows this help message",
    handler = function()
      local lines = { "Nibb help - for subcommands", "" }
      for cmd, def in pairs(nibb_commands) do
        table.insert(lines, string.format("  %-16s %s", cmd, def.description or ""))
      end
      vim.api.nvim_echo({ { table.concat(lines, "\n"), "normal" } }, false, {})
    end,
  },
  ["git"] = {
    description = "Executes git command via ffi (e.g. `git status`).",
    handler = function(args)
      handle_nibb_git(args)
    end,
  },
  ["languess"] = {
    description = "Guesses language of the systems clipboards' content.",
    handler = function()
      handle_languess()
    end,
  },
  ["languess?"] = {
    description = "Show languess server status.",
    handler = function()
      handle_languess_status()
    end,
  },
  ["languess start"] = {
    description = "Starts languess server",
    handler = function()
      handle_languess_start()
    end,
  },
  ["languess kill"] = {
    description = "Kills languess server",
    handler = function()
      handle_languess_kill()
    end,
  },
}


vim.api.nvim_create_user_command("Nibb", function(opts)
  local args = opts.args

  if args:match("^git%s") then
    nibb_commands["git"].handler(args)
    return
  end

  local cmd = nibb_commands[args]
  if cmd then
    cmd.handler()
  else
    vim.notify("Unknown :Nibb subcommand: " .. args, vim.log.levels.ERROR)
  end
end, {
  nargs = 1,
  complete = function(_, _, _)
    local keys = vim.tbl_keys(nibb_commands)
    table.sort(keys)
    return keys
  end,
})
