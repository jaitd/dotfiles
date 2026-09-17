-- Formatting via conform.nvim. Installs nothing itself: it drives whatever
-- formatters are on PATH (mason can install prettier/stylua/etc.).
return {
  "stevearc/conform.nvim",
  dependencies = { "mason-org/mason.nvim" },
  event = { "BufWritePre" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_format" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      json = { "prettier" },
      yaml = { "yamlfmt" },
      markdown = { "prettier" },
      toml = { "taplo" },
    },
    format_on_save = {
      timeout_ms = 1000,
      lsp_format = "fallback",
    },
  },
  config = function(_, opts)
    require("conform").setup(opts)

    -- Taplo is a formatter, not an LSP server; install it through Mason.
    local ok, registry = pcall(require, "mason-registry")
    if ok then
      local package = registry.get_package("taplo")
      if not package:is_installed() then
        package:install()
      end
    end
  end,
}
