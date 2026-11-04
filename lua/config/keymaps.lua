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
