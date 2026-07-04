-- Completion (replaces deoplete) + snippets (replaces neosnippet).
-- blink.cmp is the current-generation completion engine; it ships prebuilt
-- binaries so no Rust toolchain is required.
return {
  "saghen/blink.cmp",
  version = "*",
  dependencies = {
    {
      "L3MON4D3/LuaSnip",
      dependencies = { "rafamadriz/friendly-snippets" },
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end,
    },
  },
  event = { "InsertEnter", "CmdlineEnter" },
  opts = {
    snippets = { preset = "luasnip" },
    -- 'default' preset: <C-y> accept, <C-n>/<C-p> or arrows to select,
    -- <C-space> open/docs, <Tab>/<S-Tab> to jump snippet placeholders.
    keymap = {
      preset = "default",
      -- keep your old <C-k> expand-or-jump muscle memory
      ["<C-k>"] = { "snippet_forward", "fallback" },
      ["<C-j>"] = { "snippet_backward", "fallback" },
    },
    appearance = { nerd_font_variant = "mono" },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    completion = {
      documentation = { auto_show = true },
    },
  },
}
