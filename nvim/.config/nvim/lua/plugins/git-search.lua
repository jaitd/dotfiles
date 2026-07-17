-- Grep through git history: advanced-git-search.nvim (telescope extension).
-- Lets you search file contents across all branches/commits, with diff previews.
-- Extension options live in telescope.lua under extensions.advanced_git_search.
return {
  "aaronhallaert/advanced-git-search.nvim",
  cmd = "AdvancedGitSearch",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "sindrets/diffview.nvim",
    "tpope/vim-fugitive",
  },
  keys = {
    -- <leader>ga  pick a search mode (log content, branches, file history, ...)
    { "<leader>ga", "<cmd>AdvancedGitSearch<cr>", desc = "Git search (history/branches)" },
  },
  config = function()
    require("telescope").load_extension("advanced_git_search")
  end,
}
