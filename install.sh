#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# LazyVim setup installer (Debian / Ubuntu, apt based)
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/ezonius/lazyvim/master/install.sh | bash
#
# Environment variables:
#   LAZYVIM_REPO=https://github.com/ezonius/lazyvim.git   git remote to install
#   LAZYVIM_BRANCH=<default>                              branch or tag (default: remote HEAD)
#   NVIM_CONFIG=~/.config/nvim                            target config directory
#   DRY_RUN=1                                             show what would happen only
#   SKIP_PLUGINS=1                                        skip `Lazy! sync` at the end
# ---------------------------------------------------------------------------
set -euo pipefail

REPO="${LAZYVIM_REPO:-https://github.com/ezonius/lazyvim.git}"
BRANCH="${LAZYVIM_BRANCH:-}"
MIN_NVIM="${LAZYVIM_MIN_NVIM:-0.11.0}"
DRY_RUN="${DRY_RUN:-0}"
SKIP_PLUGINS="${SKIP_PLUGINS:-0}"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
  exit 1
}
# run COMMAND... : execute, or just print when DRY_RUN=1
run() {
  if [ "$DRY_RUN" = 1 ]; then note "[dry-run] $*"; else "$@"; fi
}

version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }

# --- who are we installing for? --------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
  if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
  else
    TARGET_USER=""
    TARGET_HOME="$HOME"
  fi
else
  command -v sudo >/dev/null 2>&1 || die "sudo is required (or run as root)"
  SUDO="sudo"
  TARGET_USER=""
  TARGET_HOME="$HOME"
fi

CONFIG_DIR="${NVIM_CONFIG:-${XDG_CONFIG_HOME:-$TARGET_HOME/.config}/nvim}"

# --- prerequisites ----------------------------------------------------------
command -v apt-get >/dev/null 2>&1 || die "this installer targets apt (Debian/Ubuntu); install git/neovim/rg/fd manually"

missing=()
for pkg in git curl ca-certificates unzip ripgrep fd-find build-essential; do
  if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
    missing+=("$pkg")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  log "apt: installing ${missing[*]}"
  run $SUDO apt-get update -qq
  run $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends "${missing[@]}"
else
  log "apt: prerequisites already installed"
fi

# Debian ships fd as `fdfind`; LazyVim looks for `fd`
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  log "linking fdfind -> fd"
  run $SUDO ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

# --- neovim (apt's build is usually too old for LazyVim) -------------------
have_nvim=0
if command -v nvim >/dev/null 2>&1; then
  current="$(nvim --version | head -n1 | sed -E 's/^NVIM v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
  if version_ge "$current" "$MIN_NVIM"; then
    have_nvim=1
    log "neovim $current (ok)"
  else
    warn "neovim $current is older than $MIN_NVIM; installing the official tarball"
  fi
fi

if [ "$have_nvim" -eq 0 ]; then
  case "$(uname -m)" in
    x86_64 | amd64) asset="nvim-linux-x86_64" ;;
    aarch64 | arm64) asset="nvim-linux-arm64" ;;
    *) die "unsupported architecture: $(uname -m)" ;;
  esac

  log "installing neovim from ${asset}.tar.gz into /opt/nvim"
  tmp="$(mktemp -d)"
  run curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${asset}.tar.gz" -o "$tmp/nvim.tar.gz"
  if [ "$DRY_RUN" = 1 ]; then
    note "[dry-run] extract to /opt/nvim, link /usr/local/bin/nvim"
  else
    $SUDO rm -rf /opt/nvim
    $SUDO mkdir -p /opt
    $SUDO tar -xzf "$tmp/nvim.tar.gz" -C /opt
    $SUDO mv "/opt/${asset}" /opt/nvim
    $SUDO ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
  fi
  rm -rf "$tmp"
fi

# --- configuration ---------------------------------------------------------
if [ -z "$BRANCH" ]; then
  log "detecting the default branch of $REPO"
  BRANCH="$(git ls-remote --symref "$REPO" HEAD 2>/dev/null | sed -n 's|^ref: refs/heads/\([^[:space:]]*\).*|\1|p' | head -n1)"
  [ -n "$BRANCH" ] || BRANCH="master"
fi
log "branch: $BRANCH"

if [ -d "$CONFIG_DIR/.git" ]; then
  log "updating existing clone in $CONFIG_DIR"
  if [ "$DRY_RUN" = 1 ]; then
    note "[dry-run] git pull --ff-only origin $BRANCH"
  else
    if ! git -C "$CONFIG_DIR" pull --ff-only --quiet origin "$BRANCH"; then
      warn "could not fast-forward $CONFIG_DIR - leaving it untouched"
    fi
  fi
else
  if [ -e "$CONFIG_DIR" ]; then
    backup="${CONFIG_DIR}.bak.$(date +%Y%m%d-%H%M%S)"
    log "backing up existing config -> $backup"
    run mv "$CONFIG_DIR" "$backup"
  fi

  log "cloning $REPO ($BRANCH) -> $CONFIG_DIR"
  run mkdir -p "$(dirname "$CONFIG_DIR")"
  run git clone --quiet --depth 1 --branch "$BRANCH" "$REPO" "$CONFIG_DIR"

  if [ -n "$TARGET_USER" ]; then
    run chown -R "$TARGET_USER:$TARGET_USER" "$CONFIG_DIR"
  fi
fi

# --- plugins ---------------------------------------------------------------
if [ "$SKIP_PLUGINS" = 1 ]; then
  note "skipping plugin install (SKIP_PLUGINS=1)"
elif [ "$DRY_RUN" = 1 ]; then
  note "[dry-run] nvim --headless '+Lazy! sync' +qa"
else
  log "installing plugins (this takes a few minutes)"
  # </dev/null: never eat the script's own stdin when piped into bash
  if ! nvim --headless "+Lazy! sync" +qa </dev/null; then
    warn "plugin install did not finish; run ':Lazy sync' inside Neovim"
  fi
fi

log "done"
note "config:  $CONFIG_DIR"
note "start:   nvim"
note "first start also installs any remaining plugins; ':Mason' shows missing LSPs"
