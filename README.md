# ranger.nvim

[Ranger](https://github.com/ranger/ranger) plugin for neovim.

## Install

Install using your favourite package manager. This plugin ships with no keymaps
set by default, you will need to set your own keymaps.

```lua
{
  "kelly-lin/ranger.nvim",
  config = function()
    vim.api.nvim_set_keymap("n", "<leader>ef", "", { noremap = true, callback = require("ranger-nvim").open })
  end,
},
```

## API

### open()

Opens `ranger` in a new tab. When `ranger` exits and if file(s) have been selected
they will be opened in new buffers.
