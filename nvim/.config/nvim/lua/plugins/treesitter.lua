-- Treesitter: syntax highlighting, indentation, folding (replaces vim-polyglot),
-- plus smart text objects (select/move by function, class, parameter).
return {
  "nvim-treesitter/nvim-treesitter",
  -- pin the stable branch; the repo's new default (`main`) is a still-maturing
  -- rewrite with a different, unfinished API.
  branch = "master",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    -- pin to master for the same reason as the core plugin (main is the rewrite)
    { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
  },
  main = "nvim-treesitter.configs",
  opts = {
    ensure_installed = {
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
      "bash",
    },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
    textobjects = {
      -- select: e.g. `vif` visual-inside-function, `daf` delete-around-function
      select = {
        enable = true,
        lookahead = true, -- jump forward to the next object if not already on one
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["aa"] = "@parameter.outer",
          ["ia"] = "@parameter.inner",
        },
      },
      -- move: jump between functions/classes with ]f [f ]c [c
      move = {
        enable = true,
        set_jumps = true, -- record in the jumplist for <C-o>/<C-i>
        goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
        goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
      },
    },
  },
}
