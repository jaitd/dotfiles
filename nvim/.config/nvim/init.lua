-- Entry point for the Neovim (Lua) config.
-- Leader must be set before lazy.nvim and any plugin lazy-keys load.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
