#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

STOW_PACKAGES=(zsh git brew claude codex ghostty aerospace sketchybar tmux nvim)

log() { printf '\033[0;32m[✓]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[!]\033[0m %s\n' "$*"; }
err() { printf '\033[0;31m[✗]\033[0m %s\n' "$*" >&2; }

# --- Homebrew ---
install_homebrew() {
  if [[ -x "/opt/homebrew/bin/brew" ]] || [[ -x "/usr/local/bin/brew" ]]; then
    return 0
  fi

  if [[ -f "$DOTFILES_DIR/scripts/install-homebrew.sh" ]]; then
    log "Installing Homebrew..."
    bash "$DOTFILES_DIR/scripts/install-homebrew.sh"
  else
    err "Homebrew not found and install script missing"
    return 1
  fi
}

setup_brew_env() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# --- Stow ---
stow_packages() {
  if ! command -v stow >/dev/null 2>&1; then
    err "stow not found. Install with: brew install stow"
    return 1
  fi

  for pkg in "${STOW_PACKAGES[@]}"; do
    if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
      log "Stowing $pkg..."
      stow -t "$HOME" -d "$DOTFILES_DIR" --no-folding "$pkg"
    fi
  done
}

# --- Brew bundle ---
brew_bundle() {
  if command -v brew >/dev/null 2>&1 && [[ -f "$HOME/.Brewfile" ]]; then
    log "Running brew bundle..."
    brew bundle --global
  fi
}

# --- uv ---
install_uv() {
  if command -v uv >/dev/null 2>&1; then
    return 0
  fi

  if [[ -f "$DOTFILES_DIR/scripts/install-uv.sh" ]]; then
    log "Installing uv..."
    bash "$DOTFILES_DIR/scripts/install-uv.sh"
  fi
}

# --- Main ---
log "dotfiles setup starting..."

install_homebrew
setup_brew_env
stow_packages
brew_bundle
install_uv

log "Done! Restart your shell or run: source ~/.zshrc"
