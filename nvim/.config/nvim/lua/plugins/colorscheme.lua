-- Kanagawa: muted, painterly dark theme (wave/dragon/lotus variants).
return {
  "rebelot/kanagawa.nvim",
  lazy = false,
  priority = 1000, -- load before other plugins so highlights are set early
  config = function()
    require("kanagawa").setup({
      -- Kanagawa's default separator is very close to the background.
      -- Use a brighter palette color so split boundaries remain visible.
      overrides = function(colors)
        return {
          WinSeparator = { fg = colors.palette.sumiInk6, bg = "NONE" },
          VertSplit = { link = "WinSeparator" },
        }
      end,
    })
    vim.o.background = "dark"
    -- Theme options: "kanagawa"/"kanagawa-wave" (default),
    -- "kanagawa-dragon" (darker), or "kanagawa-lotus" (light).
    vim.cmd.colorscheme("kanagawa")
  end,
}
