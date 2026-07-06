-- Treesitter: syntax highlighting + indentation, plus smart text objects
-- (select/move by function, class, parameter).
--
-- Uses nvim-treesitter's `main` branch. Unlike the old `master` branch, `main`
-- does NOT wrap everything in a `setup{ highlight=..., indent=... }` module system.
-- Instead: you install parsers with `require('nvim-treesitter').install{...}` and
-- enable Neovim's built-in treesitter features per-buffer (`vim.treesitter.start()`,
-- `indentexpr`). `master` is frozen and crashes on Neovim 0.12's injection handling.

local parsers = {
  "lua",
  "vim",
  "vimdoc",
  "python",
  "javascript",
  "typescript",
  "tsx",
  "html",
  "css",
  "json",
  "yaml",
  "markdown",
  "markdown_inline", -- needed for fenced-code-block injections in markdown
  "bash",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
  },
  config = function()
    -- Install/keep the listed parsers up to date (async; skips already-installed).
    require("nvim-treesitter").install(parsers)

    -- Enable highlighting + indentation for a buffer, auto-installing the parser
    -- if it isn't present yet (replaces the old `auto_install = true`).
    local function enable(buf)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
      if not lang then
        return
      end
      if #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0 then
        -- parser missing: install it in the background; it'll highlight next time.
        pcall(function()
          require("nvim-treesitter").install({ lang })
        end)
        return
      end
      pcall(vim.treesitter.start, buf) -- highlighting (provided by Neovim)
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" -- experimental
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_enable", { clear = true }),
      callback = function(ev)
        enable(ev.buf)
      end,
    })

    -- The BufReadPost/BufNewFile that lazy-loaded us already fired FileType, so
    -- enable treesitter for any buffers that are already open.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
        enable(buf)
      end
    end

    -- Text objects (select + move), main-branch API.
    require("nvim-treesitter-textobjects").setup({
      select = { lookahead = true }, -- jump forward to the next object if not on one
      move = { set_jumps = true }, -- record jumps for <C-o>/<C-i>
    })

    local select = require("nvim-treesitter-textobjects.select").select_textobject
    local move = require("nvim-treesitter-textobjects.move")
    local map = vim.keymap.set

    -- select: e.g. `vif` visual-inside-function, `daf` delete-around-function
    -- stylua: ignore start
    map({ "x", "o" }, "af", function() select("@function.outer", "textobjects") end, { desc = "a function" })
    map({ "x", "o" }, "if", function() select("@function.inner", "textobjects") end, { desc = "inner function" })
    map({ "x", "o" }, "ac", function() select("@class.outer", "textobjects") end, { desc = "a class" })
    map({ "x", "o" }, "ic", function() select("@class.inner", "textobjects") end, { desc = "inner class" })
    map({ "x", "o" }, "aa", function() select("@parameter.outer", "textobjects") end, { desc = "a parameter" })
    map({ "x", "o" }, "ia", function() select("@parameter.inner", "textobjects") end, { desc = "inner parameter" })

    -- move: jump between functions/classes with ]f [f ]c [c
    map({ "n", "x", "o" }, "]f", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "next function start" })
    map({ "n", "x", "o" }, "]c", function() move.goto_next_start("@class.outer", "textobjects") end, { desc = "next class start" })
    map({ "n", "x", "o" }, "[f", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "prev function start" })
    map({ "n", "x", "o" }, "[c", function() move.goto_previous_start("@class.outer", "textobjects") end, { desc = "prev class start" })
    -- stylua: ignore end
  end,
}
