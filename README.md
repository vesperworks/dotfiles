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
| `zsh` | `~/.zshrc` etc. | Shell config (atuin, zoxide, fzf) |
| `git` | `~/.gitconfig` | Git config (delta, lfs) |
| `brew` | `~/.Brewfile` | Homebrew bundle |
| `claude` | `~/.claude/` | [Claude Code](https://docs.anthropic.com/en/docs/claude-code) customizations |
| `ghostty` | `~/.config/ghostty/` | Terminal |
| `alacritty` | `~/.config/alacritty/` | Terminal |
| `tmux` | `~/.config/tmux/` | Terminal multiplexer |
| `nvim` | `~/.config/nvim/` | Neovim (vw.* plugin series) |
| `aerospace` | `~/.config/aerospace/` | Tiling window manager |
| `sketchybar` | `~/.config/sketchybar/` | Status bar |
| `borders` | `~/.config/borders/` | Window borders |
| `yazi` | `~/.config/yazi/` | File manager |

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
