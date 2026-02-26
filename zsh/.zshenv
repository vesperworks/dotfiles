# Homebrew (must be in .zshenv for non-login shells)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Locale
export LC_CTYPE="ja_JP.UTF-8"
export LANG="ja_JP.UTF-8"
export LC_ALL="ja_JP.UTF-8"
export LANGUAGE="ja"

# Cargo
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
