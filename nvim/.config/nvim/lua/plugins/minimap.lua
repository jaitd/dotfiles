-- mini.map: lightweight code minimap, toggled on demand.
return {
  "echasnovski/mini.map",
  version = false,
  keys = {
    { "<leader>mm", function() require("mini.map").toggle() end, desc = "Minimap: toggle" },
    { "<leader>mf", function() require("mini.map").toggle_focus() end, desc = "Minimap: focus" },
    { "<leader>ms", function() require("mini.map").toggle_side() end, desc = "Minimap: switch side" },
  },
  config = function()
    local map = require("mini.map")
    map.setup({
      -- show search hits, diagnostics, and git changes as marks in the map
      integrations = {
        map.gen_integration.builtin_search(),
        map.gen_integration.diagnostic(),
        map.gen_integration.gitsigns(),
      },
      -- braille-style downscaling for fine detail (needs a font with braille glyphs)
      symbols = {
        encode = map.gen_encode_symbols.dot("4x2"),
      },
      window = {
        width = 12,
        winblend = 25,
        show_integration_count = true,
      },
    })
  end,
}
