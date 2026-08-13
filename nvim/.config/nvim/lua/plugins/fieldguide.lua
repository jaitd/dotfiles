-- fieldguide.nvim — an agent that answers from the plugins you actually have,
-- at the revisions you actually pinned.
--
-- Local development checkout: `dir` points lazy.nvim straight at the working
-- tree, so edits there are live on the next restart with nothing to sync. The
-- repo lives *outside* this config tree on purpose — that is the read/write
-- zone the agent is confined to, and the plugin should not be inside it.
--
-- Repo: https://github.com/jaitd/fieldguide-poc
return {
  {
    "jaitd/fieldguide-poc",
    name = "fieldguide.nvim",
    dir = vim.fn.expand("~/fieldguide/fieldguide-poc"),
    -- No lazy-load trigger: the commands and keymaps below are the entry
    -- points, and setup() is cheap (it registers commands, nothing else).
    lazy = false,
    opts = {
      -- Key comes from OPENROUTER_API_KEY in the environment, never from here:
      -- this file is committed, and Neovim configs get published.
      --
      -- pi 0.79.10's bundled registry predates this model, so it warns once and
      -- passes the id through to OpenRouter as a custom model. `pi update self`
      -- clears the warning once the registry catches up.
      provider = "openrouter",
      model = "openai/gpt-5.6-luna",

      window = { side = "right", width = 80 },

      -- auto        — edits and reload both automatic
      -- verify-only — edits automatic, reload prompts
      -- manual      — both prompt
      --
      -- `reload` executes agent-authored code in this process. Nothing gates it
      -- at "auto". Start at verify-only; `:FieldguideLevel auto` when you are
      -- watching. See §6 of the design.
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
