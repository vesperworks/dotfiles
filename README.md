# dotfiles

macOS development environment managed with [GNU Stow](https://www.gnu.org/software/stow/) and [Jujutsu (jj)](https://martinvonz.github.io/jj/).

## Setup

```bash
git clone https://github.com/vesperworks/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` installs Homebrew (if needed), applies all stow packages, and runs `brew bundle`.

## Packages

| Package | Target | Description |
|---------|--------|-------------|
| `bin` | `~/.local/bin/` | Personal scripts |
| `zsh` | `~/.zshrc` etc. | Shell config (atuin, zoxide, fzf) |
| `sheldon` | `~/.config/sheldon/` | Zsh plugin manager |
| `git` | `~/.gitconfig` | Git config (delta, lfs) |
| `brew` | `~/.Brewfile` | Homebrew bundle |
| `claude` | `~/.claude/` | [Claude Code](https://docs.anthropic.com/en/docs/claude-code) customizations |
| `codex` | `~/.codex/` | OpenAI Codex CLI — **template-only**, see [policy](#codex-template-only) |
| `ghostty` | `~/.config/ghostty/` | Terminal |
| `alacritty` | `~/.config/alacritty/` | Terminal |
| `tmux` | `~/.config/tmux/` | Terminal multiplexer |
| `herdr` | `~/.config/herdr/` | [herdr](https://github.com/ogulcancelik/herdr) session manager (config + scripts) |
| `nvim` | `~/.config/nvim/` | Neovim (vw.* plugin series) |
| `aerospace` | `~/.config/aerospace/` | Tiling window manager |
| `sketchybar` | `~/.config/sketchybar/` | Status bar |
| `borders` | `~/.config/borders/` | Window borders |
| `yazi` | `~/.config/yazi/` | File manager |
| `raycast` | `~/.config/raycast/` | Raycast script commands |
| `karabiner` | `~/.config/karabiner/` | Keyboard remapping |

## Codex (template-only)

The `codex` package ships only templates (`config.toml.example`, `rules/default.rules.example`); the live `~/.codex/config.toml` and `~/.codex/rules/default.rules` are **not tracked** because Codex CLI auto-appends machine-specific entries (project paths, allow rules with private URLs, marketplace sources) and has no `include` mechanism. `install.sh` copies the templates on first setup; after that they're machine-local. For team-shared settings use `<project_repo>/.codex/config.toml` ([official two-layer design](https://developers.openai.com/codex/config-reference)).

## Stow Usage

```bash
# Apply a single package
stow -t ~ --no-folding <package>

# Remove a package
stow -t ~ -D <package>

# Apply all packages
./install.sh
```

## License

[MIT](LICENSE)
