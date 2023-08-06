# ranger.nvim

[Ranger](https://github.com/ranger/ranger) integration plugin for neovim with
no dependencies besides `ranger`.

[](https://user-images.githubusercontent.com/19686599/235407677-04066885-cb8a-43e1-9cee-479c8d4187e7.mov)

## Dependencies

- [Ranger](https://github.com/ranger/ranger)

## Install

Install using your package manager. This plugin *does not set* Neovim keymaps by
default, you will need to set your own keymaps using the exposed [api](#api).
See below [Lazy](https://github.com/folke/lazy.nvim)
configuration for example.

```lua
{
  "kelly-lin/ranger.nvim",
  config = function()
    require("ranger-nvim").setup({ replace_netrw = true })
    vim.api.nvim_set_keymap("n", "<leader>ef", "", {
      noremap = true,
      callback = function()
        require("ranger-nvim").open(true)
      end,
    })
  end,
}
```

## Configuration

You can configure `ranger.nvim` by invoking `ranger_nvim.setup()` with an
options `table` described below. Note: `ranger_nvim.setup()` is *optional*, if you
do not invoke `ranger_nvim.setup()` `ranger.nvim` will use the default values.

| Key | Type | Default | Description |
| --- | ---- | ------- | ----------- |
| `enable_cmds` | `boolean` | `false` | Set vim commands, see [commands](#commands). |
| `keybinds` | `Keybind = table<string, OPEN_MODE>` | See [ranger keybindings](#ranger-keybindings). | Key bindings set in `ranger` to control how files are opened in neovim. See [ranger keybindings](#ranger-keybindings). |
| `replace_netrw` | `boolean` | `false` | Replace `netrw` with `ranger` when neovim is launched with a directory argument. |
| `ui` | `UI` | See [UI Configuration](#configuration---ui). | Settings for ranger window. |

See below code snippet for example configuring `ranger.nvim` with the default
values.

```lua
local ranger_nvim = require("ranger-nvim")
ranger_nvim.setup({
  enable_cmds = false,
  replace_netrw = false,
  keybinds = {
    ["ov"] = ranger_nvim.OPEN_MODE.vsplit,
    ["oh"] = ranger_nvim.OPEN_MODE.split,
    ["ot"] = ranger_nvim.OPEN_MODE.tabedit,
    ["or"] = ranger_nvim.OPEN_MODE.rifle,
  },
  ui = {
    border = "none",
    height = 1,
    width = 1,
    x = 0.5,
    y = 0.5,
  }
})
```

### Configuration - UI

| Key | Type | Default | Value |
| --- | ---- | ------- | ----- |
| `border` | `string` | `"none"` | See `:h nvim_open_win`. |
| `height` | `number` | `1` | From 0 to 1 (0 = 0% of screen and 1 = 100% of screen). |
| `width` | `number` | `1` | From 0 to 1 (0 = 0% of screen and 1 = 100% of screen). |
| `x` | `number` | `0.5` | From 0 to 1 (0 = left most of screen and 1 = right most of screen). |
| `y` | `number` | `0.5` | From 0 to 1 (0 = top most of screen and 1 = bottom most of screen). |

## API

### `open(select_current_file: boolean)`

Opens `ranger` in a fullscreen floating window.

When `select_current_file` is set to `true`, `ranger` will focus on the file in
the current buffer on load.

You can control how to open these files in Neovim by using the [ranger keybindings](#ranger-keybindings)
that `ranger.nvim` sets.

### `enum OPEN_MODE`

Enum to configure keybindings for open modes.

| Variant | Action |
| ------- | ------ |
| `vsplit` | Open files in vertical split |
| `split` | Open files in horizontal split |
| `tabedit` | Open files in tab |
| `rifle` | Open files with rifle |

## Ranger Keybindings

`ranger.nvim` sets `ranger` keybindings in order to control how selected files
are opened in neovim. You can override the keybindings using `ranger_nvim.setup()`.

See below table for default keybindings.

**Note: the keybinding string is in ranger keybinding syntax and not vim syntax
(they are bindings for ranger)**

| Keybinding  | Action |
| ----------- | ------ |
| `<CR>`, `l` (when selected on file) | Open files in current window |
| `ov` | Open files in vertical split |
| `oh` | Open files in horizontal split |
| `ot` | Open files in tab |
| `or` | Open files with rifle |

### Overriding Keybindings

The `ranger-nvim` module provides an `OPEN_MODE` enum which is used to control
the open modes. To override keybinds, create an entry in the `keybinds` table
with a `string` key in **ranger** keybinding syntax (the same syntax you would
use in your `rc.conf`) and assign it a value of an `OPEN_MODE` variant.

```lua
local ranger_nvim = require("ranger-nvim")
ranger_nvim.setup({
  keybinds = {
    ["ov"] = ranger_nvim.OPEN_MODE.vsplit,
    ["oh"] = ranger_nvim.OPEN_MODE.split,
    ["ot"] = ranger_nvim.OPEN_MODE.tabedit,
    ["or"] = ranger_nvim.OPEN_MODE.rifle,
  },
})
```

## Commands

Commands are disabled by default, they can be enabled by setting `enable_cmds =
true` in `ranger_nvim.setup()`.

| Command | Lua |
|---------|-----|
| `Ranger` | `ranger_nvim.open(true)` |

## Contributing

All feature/pull requests are welcome!
