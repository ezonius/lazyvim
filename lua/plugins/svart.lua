-- Label-based jump navigation, carried over from the old NvChad setup:
--   map({"n","x","o","v"}, "f", "<cmd>Svart<CR>", { remap = true })
--   map({"n","x","o","v"}, "F", "<cmd>SvartRegex<CR>", { remap = true })
--   svart.configure({ label_location = -2 })
--
-- `f`/`F` are free in LazyVim (flash.nvim owns `s`/`S`, and leap - which also
-- uses f/F - is only an extra), so the two can coexist.
return {
  {
    "m6vrm/svart.nvim",
    lazy = false,
    config = function()
      require("svart").configure({ label_location = -2 })
    end,
    keys = {
      { "f", "<Cmd>Svart<CR>", mode = { "n", "v", "o" }, desc = "Jump (label)" },
      { "F", "<Cmd>SvartRegex<CR>", mode = { "n", "v", "o" }, desc = "Jump (regex labels)" },
    },
  },
}
