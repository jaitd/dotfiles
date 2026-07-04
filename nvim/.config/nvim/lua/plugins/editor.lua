-- Editing helpers: pairs, surround, git, file tree, symbol outline, fugitive.
return {
  -- auto-pairs (replaces jiangmiao/auto-pairs)
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },

  -- flash: jump anywhere on screen in a few keystrokes
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      -- `s` then the label to jump; works as a motion for operators too (e.g. dsxy)
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      -- jump to a Treesitter node (select by structure)
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },

  -- surround (replaces tpope/vim-surround)
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },

  -- git signs + hunk maps (replaces vim-gitgutter)
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        -- hunk navigation (] h / [ h)
        map("n", "]h", gs.next_hunk, "Next git hunk")
        map("n", "[h", gs.prev_hunk, "Prev git hunk")
        -- stage / undo
        map("n", "<leader>ha", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        -- hunk text objects (i h / a h)
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Inner hunk")
        map({ "o", "x" }, "ah", ":<C-U>Gitsigns select_hunk<CR>", "A hunk")
      end,
    },
  },

  -- git commands / blame (kept from your setup)
  { "tpope/vim-fugitive", cmd = { "Git", "G", "Gdiffsplit", "Gblame" } },

  -- file tree (replaces NERDTree) -- <leader>ft
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>ft", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
    },
    opts = {
      filters = { custom = { "^\\.git$" } },
      -- don't open an inotify watcher per file in huge dirs (avoids ENOSPC)
      filesystem_watchers = {
        enable = true,
        debounce_delay = 50,
        ignore_dirs = {
          "node_modules",
          ".git",
          ".venv",
          "venv",
          "__pycache__",
          ".mypy_cache",
          ".ruff_cache",
          ".pytest_cache",
          "dist",
          "build",
          "target",
        },
      },
    },
  },

  -- symbol outline (replaces tagbar) -- F8
  {
    "stevearc/aerial.nvim",
    -- default branch now requires nvim 0.12+; pin the 0.11 compatibility branch
    branch = "nvim-0.11",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<F8>", "<cmd>AerialToggle!<cr>", desc = "Toggle symbol outline" },
    },
    opts = {},
  },
}
