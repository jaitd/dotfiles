-- Tools for discovering keymaps and building Vim-motion muscle memory.
return {
  -- popup of available keybindings after you press <leader> (or any prefix)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer-local keymaps",
      },
    },
  },

  -- live virtual-text hints showing which motions jump where.
  -- starts hidden; toggle with <leader>up when you want the training wheels.
  {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    opts = { startVisible = false },
    keys = {
      {
        "<leader>up",
        function()
          require("precognition").toggle()
        end,
        desc = "Toggle precognition hints",
      },
    },
  },

  -- discourages hjkl/arrow spamming and suggests the efficient motion.
  -- toggle it off any time with :Hardtime toggle.
  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    event = "VeryLazy",
    opts = {
      -- keep the mouse (and scroll wheel) usable for reading specs/plans;
      -- hardtime disables it by default
      disable_mouse = false,
    },
  },
}
