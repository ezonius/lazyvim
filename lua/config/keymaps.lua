-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Shared "global" Vimscript keymap file, used by plain Vim, Neovim and this LazyVim setup.
--
-- Lookup order (first hit wins):
--   1. ~/vim/vimrc.global.vim     (user override outside the config repo)
--   2. <config>/vim/vimrc.global.vim  (i.e. ./vim/vimrc.global.vim, versioned with this config)
--
-- config.keymaps is loaded *after* lazyvim.config.keymaps on VeryLazy
-- (see LazyVim.config.load), so the sourced mappings win over every LazyVim
-- default that uses the same lhs.
local candidates = {
  vim.fn.expand("~/vim/vimrc.global.vim"),
  vim.fs.joinpath(vim.fn.stdpath("config"), "vim", "vimrc.global.vim"),
}

local sourced
for _, path in ipairs(candidates) do
  if vim.uv.fs_stat(path) then
    sourced = path
    break
  end
end

if sourced then
  local ok, err = pcall(vim.cmd, "source " .. vim.fn.fnameescape(sourced))
  if not ok then
    vim.notify("Failed to source " .. sourced .. ":\n" .. tostring(err), vim.log.levels.ERROR)
  end
  -- handy for `:lua print(vim.g.vimrc_global)`
  vim.g.vimrc_global = sourced
else
  vim.notify(
    "No vimrc.global.vim found (looked in ~/vim and " .. vim.fn.stdpath("config") .. "/vim)",
    vim.log.levels.WARN
  )
end

----------------------------------------------------------------------------
-- LazyVim defaults displaced by vimrc.global.vim, put back somewhere else.
-- Everything below runs after the source above, so it wins.
----------------------------------------------------------------------------

-- The file maps K -> J, so LazyVim's `K` (LSP hover) is gone.
-- Make LazyVim's <leader>K context aware instead: hover for LSP buffers,
-- 'keywordprg' (vim.cmd.normal, bypasses mappings) everywhere else.
vim.keymap.set("n", "<leader>K", function()
  if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
    vim.lsp.buf.hover()
  else
    vim.cmd("normal! K")
  end
end, { desc = "Hover (LSP) / Keywordprg" })

-- Window navigation: <C-hjkl> are taken by the shared file, so use <A-...>
-- with the same spatial keys it uses (i = up, k = down, j = left, l = right).
vim.keymap.set("n", "<A-i>", "<C-w>k", { desc = "Go to Upper Window" })
vim.keymap.set("n", "<A-k>", "<C-w>j", { desc = "Go to Lower Window" })
vim.keymap.set("n", "<A-j>", "<C-w>h", { desc = "Go to Left Window" })
vim.keymap.set("n", "<A-l>", "<C-w>l", { desc = "Go to Right Window" })

-- ...which displaces LazyVim's <A-j>/<A-k> line moving; moved to <A-u>/<A-d>.
vim.keymap.set("n", "<A-u>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Line Up" })
vim.keymap.set("n", "<A-d>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Line Down" })
vim.keymap.set("i", "<A-u>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Line Up" })
vim.keymap.set("i", "<A-d>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Line Down" })
vim.keymap.set("x", "<A-u>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Line Up" })
vim.keymap.set("x", "<A-d>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Line Down" })

-- Window resizing: <C-Up>/<C-Down> are taken, so the whole set lives in the
-- which-key <leader>w group (<leader>w already proxies <C-w>).
vim.keymap.set("n", "<leader>w+", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<leader>w-", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<leader>w>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })
vim.keymap.set("n", "<leader>w<", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
