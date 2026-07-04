-- Kanagawa: muted, painterly dark theme (wave/dragon/lotus variants).
return {
  "rebelot/kanagawa.nvim",
  lazy = false,
  priority = 1000, -- load before other plugins so highlights are set early
  config = function()
    require("kanagawa").setup({})
    vim.o.background = "dark"
    -- `kanagawa` uses the default (wave). Swap for `kanagawa-dragon` (darker)
    -- or `kanagawa-lotus` (light) if you want a different variant.
    vim.cmd.colorscheme("kanagawa")
  end,
}
