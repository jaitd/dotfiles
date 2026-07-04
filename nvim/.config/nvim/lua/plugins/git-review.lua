-- PR / diff review: diffview.nvim (diff UX) + octo.nvim (GitHub via gh).
return {
  -- rich diff viewer for reviewing branch diffs and file history
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
    },
    keys = {
      -- review the whole working tree diff
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview: open" },
      -- review a PR branch against its base, e.g. :DiffviewOpen main...HEAD
      { "<leader>gm", "<cmd>DiffviewOpen main...HEAD<cr>", desc = "Diffview: PR vs main" },
      -- git history of the current file
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: file history" },
      { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
    },
    opts = {},
  },

  -- GitHub PR / issue review inside nvim (requires the `gh` CLI, authenticated)
  {
    "pwntester/octo.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    cmd = "Octo",
    keys = {
      { "<leader>op", "<cmd>Octo pr list<cr>", desc = "Octo: list PRs" },
      { "<leader>or", "<cmd>Octo review start<cr>", desc = "Octo: start review" },
      { "<leader>oo", "<cmd>Octo actions<cr>", desc = "Octo: actions menu" },
    },
    opts = {
      picker = "telescope", -- use your existing telescope for PR/issue pickers
    },
  },
}
