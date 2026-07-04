-- Non-plugin keymaps (ported from init.vim). Plugin-specific maps live with
-- each plugin spec under lua/plugins/.
local map = vim.keymap.set

-- clear search highlight
map("n", "<F3>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- move by visual line
map("n", "j", "gj", { silent = true })
map("n", "k", "gk", { silent = true })

-- break the arrow-key habit
map("n", "<Up>", "<Nop>")
map("n", "<Down>", "<Nop>")
map("n", "<Left>", "<Nop>")
map("n", "<Right>", "<Nop>")

-- jump to the alternate (last) buffer
map("n", "<leader><tab>", "<C-^>", { desc = "Alternate buffer" })

-- build
map("n", "<F4>", "<cmd>make!<cr>", { desc = "Run :make!" })

-- diagnostics (lint problems) into a split
-- all buffers -> quickfix, opens the split
map("n", "<leader>xd", function()
  vim.diagnostic.setqflist({ open = true })
end, { desc = "All diagnostics -> quickfix" })
-- current buffer only -> location list, opens the split
map("n", "<leader>xb", function()
  vim.diagnostic.setloclist({ open = true })
end, { desc = "Buffer diagnostics -> loclist" })
