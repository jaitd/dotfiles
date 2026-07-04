-- Statusline, buffer tabline, indent guides, start screen.
return {
  -- statusline (replaces vim-airline)
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        theme = "auto", -- derives from the active colorscheme; no hard coupling
        globalstatus = true,
        section_separators = "",
        component_separators = "",
      },
    },
  },

  -- buffer tabline with numbers (replaces airline's tabline buffer_idx_mode)
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        numbers = "ordinal",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)
      -- <leader>1..9 jump to buffer by ordinal, matching your old airline habit
      for i = 1, 9 do
        vim.keymap.set("n", "<leader>" .. i, function()
          require("bufferline").go_to(i, true)
        end, { desc = "Go to buffer " .. i })
      end
    end,
  },

  -- indent guides (replaces indentLine)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },

  -- start screen with sessions (kept from your setup)
  {
    "mhinz/vim-startify",
    lazy = false,
    init = function()
      vim.g.startify_session_dir = "~/.vim/session"
      vim.g.startify_lists = {
        { type = "sessions", header = { "   Sessions" } },
        { type = "files", header = { "   Files" } },
        { type = "dir", header = { "   Current Directory" } },
      }
    end,
  },
}
