local M = {
    nibb_lib_path = "~/.nibb/lib/nibb_core.dll",
    languess_lib_path = "~/.nibb/lib/languess_core.dll"
}

function M.get_nibb_lib_path()
    return M.nibb_lib_path
end

function M.get_languess_lib_path()
    return M.languess_lib_path
end

function M.set_nibb_lib_path(path)
    if not path or path == "" then
        vim.notify("Invalid library path:" .. path or "", vim.log.levels.ERROR)
        return
    end
    M.nibb_lib_path = path
end

function M.set_languess_lib_path(path)
if not path or path == "" then
        vim.notify("Invalid library path:" .. path or "", vim.log.levels.ERROR)
        return
    end
    M.languess_lib_path = path
end

return M
