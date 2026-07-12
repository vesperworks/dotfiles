#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR"

STOW_PACKAGES=(bin zsh git brew claude codex ghostty alacritty aerospace borders sketchybar tmux nvim yazi sheldon raycast karabiner herdr)

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
			# --restow keeps re-runs idempotent; per-package fallback so one
			# conflicting package doesn't abort the rest under set -e
			stow -t "$HOME" -d "$DOTFILES_DIR" --no-folding --restow "$pkg" ||
				warn "stow failed for $pkg (conflicting real file in \$HOME?). Continuing."
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

# --- sheldon ---
install_sheldon() {
	if command -v sheldon >/dev/null 2>&1; then
		return 0
	fi
	if command -v brew >/dev/null 2>&1; then
		log "Installing sheldon..."
		brew install sheldon
	else
		err "brew not found. Install sheldon manually: https://sheldon.cli.rs/"
		return 1
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

# --- yazi plugins ---
install_yazi_plugins() {
	if command -v ya >/dev/null 2>&1; then
		log "Installing yazi plugins..."
		ya pack -i
	else
		warn "ya not found. Skipping yazi plugin install."
	fi
}

# --- tmux plugins (TPM) ---
install_tmux_plugins() {
	local tpm_dir="$HOME/.config/tmux/plugins/tpm"
	if [[ ! -d "$tpm_dir" ]]; then
		log "Installing TPM (Tmux Plugin Manager)..."
		git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
	fi
	if [[ -x "$tpm_dir/bin/install_plugins" ]]; then
		log "Installing tmux plugins..."
		"$tpm_dir/bin/install_plugins"
	fi
}

# --- aerospace watchdog (launchd) ---
# Continuously monitors AeroSpace health and known-bad processes. Generates
# the launchd plist with absolute paths derived from $HOME so the public
# dotfiles repo stays free of user-specific paths.
bootstrap_aerospace_watchdog() {
	local script="$HOME/.local/bin/aerospace-process-watchdog"
	local plist="$HOME/Library/LaunchAgents/com.user.aerospace-watchdog.plist"
	local log_dir="$HOME/Library/Logs/aerospace-watchdog"

	if [[ ! -x "$script" ]]; then
		warn "aerospace-process-watchdog not found ($script). Skipping launchd setup."
		return 0
	fi

	mkdir -p "$(dirname "$plist")" "$log_dir"

	cat >"$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.user.aerospace-watchdog</string>
  <key>ProgramArguments</key>
  <array>
    <string>${script}</string>
    <string>--quiet</string>
  </array>
  <key>StartInterval</key>
  <integer>60</integer>
  <key>ThrottleInterval</key>
  <integer>30</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${log_dir}/stdout.log</string>
  <key>StandardErrorPath</key>
  <string>${log_dir}/stderr.log</string>
</dict>
</plist>
EOF

	launchctl unload "$plist" 2>/dev/null || true
	if launchctl load "$plist"; then
		log "Loaded launchd agent: com.user.aerospace-watchdog (60s interval)"
	else
		warn "Failed to load launchd agent: $plist"
	fi
}

# --- codex user-level config bootstrap ---
# user 層 config (~/.codex/config.toml, ~/.codex/rules/default.rules) は
# 個人マシン固有（codex CLI が案件パス込みの allow ルール等を自動追記する）のため
# git 管理外。新マシン初回セットアップ時に *.example を実ファイルとしてコピーする。
# 既存マシン（既にターゲットがある場合）は何もしない。
bootstrap_codex_config() {
	local target example
	for target in "$HOME/.codex/config.toml" "$HOME/.codex/rules/default.rules"; do
		example="${target}.example"
		if [[ -f "$target" ]]; then
			continue
		fi
		if [[ ! -f "$example" ]]; then
			warn "codex example not found ($example). Skipping bootstrap."
			continue
		fi
		mkdir -p "$(dirname "$target")"
		log "Bootstrapping ~/${target#"$HOME"/} from example..."
		cp "$example" "$target"
	done
}

# --- Main ---
log "dotfiles setup starting..."

install_homebrew
setup_brew_env
install_sheldon
stow_packages
brew_bundle
install_uv
install_yazi_plugins
install_tmux_plugins
bootstrap_codex_config
bootstrap_aerospace_watchdog

log "Done! Restart your shell or run: source ~/.zshrc"
