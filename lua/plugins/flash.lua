-- flash.nvim's "char" mode remaps f/F/t/T/;/, on VeryLazy, which silently
-- steals the f/F bindings from svart.nvim (see plugins/svart.lua).
-- Disable it so f/F stay with svart; flash keeps its own s/S/r/R bindings.
return {
  {
    "folke/flash.nvim",
    opts = {
      modes = {
        char = { enabled = false },
      },
    },
  },
}
