-- LSP setup using the native Neovim 0.11 API (vim.lsp.config / vim.lsp.enable).
-- mason installs the servers; mason-lspconfig auto-enables the installed ones.
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- diagnostics look & feel
      vim.diagnostic.config({
        virtual_text = true,
        severity_sort = true,
        float = { border = "rounded" },
      })

      -- LSP keymaps, set once per attached buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
        callback = function(ev)
          -- let pyright own hover; ruff stays the linter/formatter (Astral's advice)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end

          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gr", "<cmd>Telescope lsp_references<cr>", "References")
          map("gi", vim.lsp.buf.implementation, "Implementation")
          map("K", vim.lsp.buf.hover, "Hover docs")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("[d", vim.diagnostic.goto_prev, "Prev diagnostic")
          map("]d", vim.diagnostic.goto_next, "Next diagnostic")
          map("<leader>e", vim.diagnostic.open_float, "Line diagnostics")
        end,
      })

      -- default config applied to every server: completion capabilities from blink
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- per-server settings (merged on top of nvim-lspconfig's shipped defaults)
      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })

      -- Resolve the Python interpreter for a project, uv-aware:
      --   1. an already-activated venv ($VIRTUAL_ENV, e.g. after `source .venv/bin/activate`)
      --   2. uv's default project venv at <root>/.venv (no activation needed)
      --   3. whatever python3 is on PATH
      local function python_path(root)
        if vim.env.VIRTUAL_ENV then
          return vim.fs.joinpath(vim.env.VIRTUAL_ENV, "bin", "python")
        end
        if root then
          local venv = vim.fs.joinpath(root, ".venv", "bin", "python")
          if vim.uv.fs_stat(venv) then
            return venv
          end
        end
        return vim.fn.exepath("python3")
      end

      vim.lsp.config("pyright", {
        settings = { python = { analysis = { typeCheckingMode = "basic" } } },
        before_init = function(_, config)
          config.settings = config.settings or {}
          config.settings.python = config.settings.python or {}
          -- point pyright at the uv venv so imports of installed deps resolve
          config.settings.python.pythonPath = python_path(config.root_dir or vim.fn.getcwd())
        end,
      })

      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "pyright", -- python types / completion
          "ruff", -- python linting + formatting
          "ts_ls", -- typescript / javascript
          "eslint", -- js/ts linting (replaces neomake eslint)
          "html",
          "cssls",
          "jsonls",
        },
        -- automatic_enable is on by default: it calls vim.lsp.enable() for each
        -- installed server, so nothing else is needed here.
      })
    end,
  },
}
