-- Fuzzy finder (replaces fzf + fzf.vim). Your old fzf maps are preserved.
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- native fzf sorter for speed (needs `make`)
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  cmd = "Telescope",
  keys = {
    -- <leader>ff  Files   -> find_files
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
    -- <leader>gf  GFiles  -> git_files (all tracked files)
    { "<leader>gf", "<cmd>Telescope git_files<cr>", desc = "Git files" },
    -- <leader>gs  dirty + staged files only, with diff preview
    { "<leader>gs", "<cmd>Telescope git_status<cr>", desc = "Git status (changed files)" },
    -- <leader>b   Buffers -> buffers
    { "<leader>b", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    -- <leader>t   BTags   -> document symbols (buffer)
    { "<leader>t", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
    -- <leader>gt  Tags    -> workspace symbols
    { "<leader>gt", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace symbols" },
    -- <leader><leader>  Ag -> live grep
    { "<leader><leader>", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local builtin = require("telescope.builtin")

    -- toggle hidden (dotfiles) + gitignored files inside find_files, keeping
    -- the current query. bound to <C-h>. state lives in a global flag.
    vim.g.telescope_find_hidden = false
    local function toggle_find_hidden(prompt_bufnr)
      vim.g.telescope_find_hidden = not vim.g.telescope_find_hidden
      local query = action_state.get_current_line()
      actions.close(prompt_bufnr)
      builtin.find_files({
        default_text = query,
        hidden = vim.g.telescope_find_hidden, -- show dotfiles
        no_ignore = vim.g.telescope_find_hidden, -- also show gitignored files
      })
    end

    telescope.setup({
      pickers = {
        find_files = {
          mappings = {
            i = { ["<C-h>"] = toggle_find_hidden },
            n = { ["<C-h>"] = toggle_find_hidden },
          },
        },
      },
    })
    pcall(telescope.load_extension, "fzf")
  end,
}
