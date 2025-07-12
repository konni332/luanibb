# luanibb.nvim

A fast and minimal snippet manager for Neovim — featuring a built-in fuzzy finder, Git integration, and optional automatic language detection.

---

## Features

- Create, edit, delete and insert code snippets
- Fuzzy finder integration via [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- Snippets are saved locally in plain files (no cloud, no bullshit)
- Optional language detection via an ML-based server (Python via native shared library)
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
            enable_default_keymaps = true, -- Optional (strongly recommended!): adds <leader>fz for snippet fuzzy finder
        })
    end,
},
```

*If `<leader>fz` is enabled, you can use it to open luanibb's fuzzy finder.*  
**Snippets are almost exclusively managed through this interface.**

---

## 🔍 Fuzzy finder

[demo](./assets/finder-demo.gif)

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

### 🧷 Keybindings

| Key        | Action                                 |
|------------|----------------------------------------|
| `<CR>`     | Insert selected snippet (like `p`)     |
| `<C-e>`    | Edit selected snippet in Neovim        |
| `<C-d>`    | Delete selected snippet (with confirm) |
| `<C-n>`    | Create a new snippet                   |

---


## `:Nibb` Commands

| Command                | Description                                              |
|------------------------|----------------------------------------------------------|
| `:Nibb git [args]`     | Run git commands in the luanibb snippet repo             |
| `:Nibb languess?`      | Check if the languess server is running                  |
| `:Nibb languess`       | Predict the language of the current clipboard content    |
| `:Nibb languess start` | Start the languess server                                |
| `:Nibb languess kill`  | Kill the languess server                                 |

---


## 🤝 Contributing

Suggestions and PRs welcome. For larger contributions, open an issue first.

---

## License

This project is licensed under either of

- MIT license ([LICENSE-MIT](./LICENSE-MIT) or https://opensource.org/license/MIT)
- Apache license, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE.md) or https://www.apache.org/licenses/LICENSE-2.0)

---
