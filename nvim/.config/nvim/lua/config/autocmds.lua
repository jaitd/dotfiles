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

-- copy-on-select: put the visual selection on the system clipboard when leaving
-- visual mode, mirroring Ghostty's `copy-on-select = clipboard`.
-- Swap "+" for "*" below if you'd rather it go to the primary selection
-- (middle-click paste) and leave the system clipboard untouched.
local copy_on_select = augroup("UserCopyOnSelect", { clear = true })
local tick_on_enter

autocmd("ModeChanged", {
  group = copy_on_select,
  pattern = "*:[vV\22]*", -- entering visual / visual-line / visual-block
  callback = function()
    tick_on_enter = vim.b.changedtick
  end,
})

autocmd("ModeChanged", {
  group = copy_on_select,
  pattern = "[vV\22]*:[^vV\22]*", -- leaving visual for a non-visual mode
  callback = function()
    -- If an operator changed the buffer (d/c/x), the selection no longer exists
    -- and '< '> would read whatever text moved into its place. Skip those.
    if tick_on_enter and vim.b.changedtick ~= tick_on_enter then
      return
    end
    local mode = vim.fn.visualmode()
    if mode == "" then
      return
    end
    local ok, lines = pcall(vim.fn.getregion, vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = mode })
    if ok and type(lines) == "table" and #lines > 0 then
      vim.fn.setreg("+", lines, mode)
    end
  end,
})
