-- fieldguide.nvim — an agent that answers from the plugins you actually have,
-- at the revisions you actually pinned.
--
-- The local development checkout when there is one: `dir` points lazy.nvim
-- straight at the working tree, so edits there are live on the next restart
-- with nothing to sync. Without it, lazy.nvim installs from GitHub. The
-- checkout lives *outside* this config tree on purpose — that is the read/write
-- zone the agent is confined to, and the plugin should not be inside it.
--
-- Repo: https://github.com/jaitd/fieldguide.nvim
local checkout = vim.fn.expand("~/dev/fieldguide.nvim")

return {
  {
    "jaitd/fieldguide.nvim",
    name = "fieldguide.nvim",
    dir = vim.fn.isdirectory(checkout) == 1 and checkout or nil,
    -- No lazy-load trigger: the commands and keymaps below are the entry
    -- points, and setup() is cheap (it registers commands, nothing else).
    lazy = false,
    opts = {
      -- Credentials come from the environment or from `pi auth`, never from
      -- here: this file is committed, and Neovim configs get published.
      --
      -- `openai-codex` is the ChatGPT subscription, and it serves only the ids
      -- listed under that provider by `pi --list-models`. A prefixed id belongs
      -- to another provider's namespace: pi passes it through as a custom model
      -- and the refusal comes back from the provider mid-reply.
      provider = "openai-codex",
      model = "gpt-5.6-luna",

      window = { side = "right", width = 80 },

      -- auto        — edits and reload both automatic
      -- verify-only — edits automatic, reload prompts
      -- manual      — both prompt
      --
      -- `reload` executes agent-authored code in this process. Nothing gates it
      -- at "auto". Start at verify-only; `:FieldguideLevel auto` when you are
      -- watching. See "Read this before enabling `reload`" in the README.
      reload = { level = "verify-only" },

      -- The plugin binds nothing by default; this is the only global key it
      -- gets. <leader>fg sits with the other <leader>f pickers: ff files,
      -- ft tree. Focus is one keystroke from the toggle, and reload covers only
      -- the fraction of a config that is not plugin specs — :FieldguideFocus
      -- and :FieldguideReload are the right weight for both.
      keys = { toggle = "<leader>fg" },
    },
    config = function(_, opts)
      require("fieldguide").setup(opts)
    end,
  },
}
