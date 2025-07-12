# luanibb.nvim

A fast and minimal snippet manager for NeoVim - with built-in fuzzy finder, Git integration, and auto language detection (optional).

---

## Features

- Create, edit, delete and insert code snippets
- Fuzzy finder integration via [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- Snippets saved in files (no cloud, no bulls***)
- Optional automatic language detection using an ML model, run on a *Language server* like python server
- Configurable keymaps and settings
- Designed for developers who want *fast*, minimal tools

---

## 📦 Installation

Using [Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "konni332/luanibb", -- or local dir = "...",
    config = function()
        require("luanibb").setup({
            nibb_lib_path = "~/.nibb/lib/nibb_core.dll", -- Required: path to nibb native library
            languess_lib_path = "~/.nibb/lib/languess_core.dll", -- Optional: path to language detection native library (Languess).
            auto_start_languess = true, -- Optional: auto start languess server
            enable_default_keymaps = true, -- Optional(strongly recommended!): adds <leader>fz for snippet fuzzy finder
        })
    end,
},
```

*if <leader>fz is enabled you can use it to open luanibbs fuzzy finder*  
**The snippets are almost exclusively managet in this fuzzy finder**

---

## Fuzzy finder

**Image**

---

### Configuration

It is strongly advised to enable default keymaps. 
At this time using a shortcut is the only way to open the fuzzy finder.
The shortcut can be edited in [init.lua](./lua/luanibb/init.lua).
```lua
    if user_opts.enable_default_keymaps ~= false then
        vim.keymap.set("n", "<leader>fz", function() -- Edit <leader>fz to change the default shortcut
            require("luanibb.telescope").snippet_picker()
        end, { desc = "Fuzzy search snippets" })
    end
```

---

To configure Nibb, have a look at its **[documentation](https://github.com/konni332/nibb/blob/master/docs/config.md)**

---

### Shortcuts

- **`<CR>` (Enter)** Insert the selected snippet at your cursor (behaves like `p` key)
- **`<C-e>` (Ctrl + e)** Edit a snippet inside NeoVim. Even tho you can, you should not edit the field names!
- **`<C-d>` (Ctrl + d)** Delete the selected snippet. You will be asked for confirmation
- **`<C-n>` (Ctrl + n)** Create a new snippet.

---

## :Nibb

- **git [ARGS]** Executes any valid git command for the local luanibb repository
- **languess?** Fetches status of languess server
- **languess start** Starts languess server
- **languess kill** Kills languess server (terminates child-process)
- **languess** Predicts the language of your systems clipboards contents. Works for "+" and "*" registers

---


## 🤝 Contributing

Suggestions and PRs welcome. For larger contributions, open an issue first.

---

## License

This project is licensed under either of

- MIT license ([LICENSE-MIT](./LICENSE-MIT) or https://opensource.org/license/MIT)
- Apache license, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE.md) or https://www.apache.org/license/LICENSE-2.0)

---
