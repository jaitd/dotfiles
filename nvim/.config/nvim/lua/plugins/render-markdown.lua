-- In-buffer markdown rendering: concealed emphasis markers, styled headings,
-- drawn tables and code blocks.
--
-- Treesitter already highlights markdown; this is the layer above that, which
-- hides the syntax characters and draws the structure. It applies to every
-- markdown buffer, so design notes and READMEs get it as well as the
-- fieldguide.nvim transcript.
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown" },
    opts = {
      -- The agent transcript is a scratch buffer that is never in insert mode,
      -- and rendering only what the cursor is not on avoids the text shifting
      -- under you while reading.
      render_modes = { "n", "c", "t" },
      anti_conceal = { enabled = true },
      code = {
        style = "normal",
        width = "block",
        right_pad = 2,
      },
      heading = {
        sign = false,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
    },
  },
}
