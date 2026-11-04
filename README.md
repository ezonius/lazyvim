# 💤 LazyVim (personal setup)

A [LazyVim](https://github.com/LazyVim/LazyVim) setup with my own rebinds:

- `vim/vimrc.global.vim` is sourced on `VeryLazy` (prefers `~/vim/vimrc.global.vim`,
  falls back to the copy in this repo) and wins over LazyVim's defaults.
- Displaced LazyVim defaults are re-bound: `<leader>K` (LSP hover), `<A-i/j/k/l>`
  (window navigation), `<A-u/d>` (move line), `<leader>w+ - > <` (resize).
- `svart.nvim` on `f`/`F` (flash's `char` mode is disabled so it cannot steal them).

## Install

Windows (PowerShell 5.1+, works on Windows Server too — uses winget, or portable
GitHub builds when winget is missing):

```powershell
irm https://raw.githubusercontent.com/ezonius/lazyvim/master/install.ps1 | iex
```

With options (e.g. a C compiler for tree-sitter parsers):

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/ezonius/lazyvim/master/install.ps1))) -BuildTools
```

Linux (Debian/Ubuntu, apt):

```bash
curl -fsSL https://raw.githubusercontent.com/ezonius/lazyvim/master/install.sh | bash
```

Both scripts install Neovim 0.11+, git, ripgrep, fd and build tools, back up an
existing `nvim` config directory, clone this repo into the right place and run
`:Lazy sync`. Re-running them updates the checkout (`git pull --ff-only`).

Useful flags / environment variables:

| Windows | Linux | Meaning |
| --- | --- | --- |
| `-DryRun` | `DRY_RUN=1` | print the steps, change nothing |
| `-NoPlugins` | `SKIP_PLUGINS=1` | don't install plugins |
| `-Destination <dir>` | `NVIM_CONFIG=<dir>` | install somewhere else |
| `-Repo`, `-Branch` | `LAZYVIM_REPO`, `LAZYVIM_BRANCH` | install another remote/branch |
| `-BuildTools` | (build-essential, always) | install LLVM for tree-sitter parsers |
| `-FontFamily <name>` | `LAZYVIM_FONT=<name>` | Nerd Font family (default `FiraCode`) |
| `-NoFont` | `NO_FONT=1` | skip the Nerd Font |

Manual install: clone this repo into `%LOCALAPPDATA%\nvim` (Windows) or
`~/.config/nvim` (Linux) and start Neovim.

## Requirements

- Neovim 0.11+ (the Linux script installs the official tarball, since apt's
  version is too old)
- git, ripgrep, fd (`fdfind` on Debian, symlinked to `fd` by the script)
- a Nerd Font for icons: `FiraCode Nerd Font` is installed by default
  (`LAZYVIM_FONT`/`-FontFamily` picks another family, `NO_FONT`/`-NoFont` skips it;
  then select it in your terminal, e.g. Windows Terminal > Profiles > Defaults >
  Appearance > Font face)
- optional: `lazygit` for `<leader>gg*`, `node`/`python` for some LSP servers
  installed through `:Mason`
