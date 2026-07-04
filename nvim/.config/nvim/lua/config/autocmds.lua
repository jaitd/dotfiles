-- Autocommands (ported / modernised from init.vim).
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- per-filetype indentation
local indent = augroup("UserIndent", { clear = true })
local function set_indent(filetypes, width)
  autocmd("FileType", {
    group = indent,
    pattern = filetypes,
    callback = function()
      vim.bo.shiftwidth = width
      vim.bo.softtabstop = width
      vim.bo.tabstop = width
    end,
  })
end
set_indent({ "vim", "lua" }, 2)
set_indent({ "tex" }, 4)
set_indent({ "python" }, 4)
-- 2-space is idiomatic for the web stack
set_indent(
  { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "html", "css", "scss", "yaml" },
  2
)

-- briefly highlight yanked text
autocmd("TextYankPost", {
  group = augroup("UserYankHighlight", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
