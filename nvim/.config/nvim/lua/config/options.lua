-- Vim options (ported from the old init.vim, modernised for Neovim 0.11).
local o = vim.opt

-- whitespace / editing
o.backspace = { "indent", "eol", "start" }
o.listchars = { tab = ">·", trail = "~", extends = "❯", precedes = "❮", space = "␣" }
o.shiftround = true
o.showbreak = "↪"

-- buffers
o.hidden = true

-- appearance
o.number = true
o.relativenumber = true
o.cursorline = true
o.colorcolumn = "80"
o.showcmd = true
o.wildmenu = true
o.termguicolors = true -- required for truecolour themes
o.signcolumn = "yes" -- stable gutter width for gitsigns / diagnostics

-- search
o.incsearch = true
o.hlsearch = true

-- folds (Treesitter-based, native in 0.11 via vim.treesitter.foldexpr)
o.foldenable = true
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevelstart = 99 -- start with everything open
o.foldnestmax = 10

-- indent
o.autoindent = true
o.smartindent = true
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4

-- mouse (default in nvim, kept explicit)
o.mouse = "a"

-- trusted local config files (.nvim.lua / .exrc in the cwd; nvim prompts to trust)
o.exrc = true

-- Python 3 provider: only needed if a remote plugin requires it. None of the
-- plugins in this config do, so it is left unset. If you want it back, point it
-- at a venv that has `pynvim` installed:
-- vim.g.python3_host_prog = vim.fn.expand("~/.virtualenvs/neovim3/bin/python")
