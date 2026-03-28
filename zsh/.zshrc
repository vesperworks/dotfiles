# Powerlevel10k Instant Prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Completions (must be before sheldon to avoid compdef errors)
if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi
# Remove non-existent /usr/local paths from FPATH (Apple Silicon)
FPATH="${FPATH/\/usr\/local\/share\/zsh\/site-functions:/}"
autoload -Uz compinit
if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24)" ]]; then
  compinit -u
else
  compinit -C -u
fi

# sheldon (plugin manager)
eval "$(sheldon source 2>/dev/null)"

# Powerlevel10k config
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# PATH
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.nodebrew/current/bin:$PATH"
export PATH="/opt/homebrew/bin/dotnet:$PATH"
export PATH="$HOME/.vw:$PATH"
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# 1Password
[[ -f ~/.secrets.env ]] && source ~/.secrets.env
command -v op >/dev/null 2>&1 && eval "$(op completion zsh)"

# Environment
export EDITOR="nvim"
export VISUAL="nvim"
export OBSIDIAN_VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/MainVault"
export CCMANAGER_MULTI_PROJECT_ROOT="$HOME/Works"

# Tools
eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(atuin init zsh --disable-up-arrow)"
export ATUIN_FZF_OPTS='--preview "echo {}" --preview-window=down:3:wrap'
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Bun
export BUN_INSTALL="$HOME/.bun"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# UV completion
if command -v uv >/dev/null 2>&1; then
  eval "$(uv generate-shell-completion zsh)"
fi

# Shell options
setopt auto_pushd pushd_ignore_dups
setopt print_eight_bit no_flow_control
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
bindkey -e

# Aliases
alias -g L='| less'
alias -g G='| grep'
alias ls='eza --color=always --icons'
alias ll='eza -la --color=always --icons'
alias la='eza -a --color=always --icons'
alias lt='eza --tree --color=always --icons --level=2'
alias ccm='ccmanager --multi-project'

# Git aliases (migrated from Oh My Zsh git plugin)
alias g='git'
alias ga='git add'
alias gc='git commit -v'
alias gco='git checkout'
alias gd='git diff'
alias gl='git pull'
alias gp='git push'
alias gst='git status'
alias glog='git log --oneline --decorate --graph'

# nv: Obsidian notes
function nv() {
  cd "$OBSIDIAN_VAULT" || return

  if [[ "$1" == "-F" && -n "$2" ]]; then
    local query="$2"
    rg --no-heading --line-number --color=always --glob "*.md" "$query" . |
    fzf --ansi \
        --query "$query" \
        --delimiter : \
        --nth 3.. \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
        --bind 'enter:execute(nvim {1} +{2})'

  elif [[ "$1" == "-f" ]]; then
    local query="$2"
    gfind . -type f -name "*.md" -printf "%T@ %p\n" 2>/dev/null |
      sort -nr |
      cut -d' ' -f2- |
      sed 's|^\./||' |
      fzf --query="${query:-}" \
          --layout=reverse \
          --height=40% \
          --preview 'bat --style=plain --color=always {} | head -20' \
          --bind 'enter:execute(nvim {})'

  elif [[ -n "$1" ]]; then
    local file="Inbox/${1// /_}.md"
    mkdir -p "$(dirname "$file")"
    nvim "$file"

  else
    local date=$(date +%Y%m%d)
    local filename="Capture/c${date}.md"
    mkdir -p "$(dirname "$filename")"
    nvim "$filename"
  fi
}

# vw: vesperworks tools
vw() {
    local command="$1"
    shift
    case "$command" in
        ("git-templ" | "template")
            if [ -x "$HOME/.vw/git-templ" ]; then
                "$HOME/.vw/git-templ" "$@"
            else
                echo "❌ エラー: $HOME/.vw/git-templ が見つからないか実行権限がありません"
                echo "スクリプトが正しく配置されているか確認してください"
                return 1
            fi ;;
        ("git-commit-gen" | "commit-gen" | "commit")
            if [ -x "$HOME/.vw/git-commit-gen" ]; then
                "$HOME/.vw/git-commit-gen" "$@"
            else
                echo "❌ エラー: $HOME/.vw/git-commit-gen が見つからないか実行権限がありません"
                echo "スクリプトが正しく配置されているか確認してください"
                return 1
            fi ;;
        ("ccc" | "claude-code-command")
            if [ -x "$HOME/.vw/ccc" ]; then
                "$HOME/.vw/ccc" "$@"
            else
                echo "❌ エラー: $HOME/.vw/ccc が見つからないか実行権限がありません"
                echo "スクリプトが正しく配置されているか確認してください"
                return 1
            fi ;;
        ("photos_monitor" | "photos")
            if [ -x "$HOME/.vw/photos_monitor" ]; then
                "$HOME/.vw/photos_monitor" "$@"
            else
                echo "❌ エラー: $HOME/.vw/photos_monitor が見つからないか実行権限がありません"
                echo "スクリプトが正しく配置されているか確認してください"
                return 1
            fi ;;
        ("help" | "--help" | "-h" | "")
            echo "🛠️  vesperworks ツールセット"
            echo ""
            echo "使用方法:"
            echo "  vw <command> [options]"
            echo ""
            echo "利用可能なコマンド:"
            echo "  git-templ, template        GitHubプライベートテンプレート作成"
            echo "  git-commit-gen, commit     Git変更分析＆コミットコマンド生成"
            echo "  ccc, claude-code-command   Claude Code文脈コマンド生成"
            echo "  photos_monitor, photos     Photos/iCloud同期モニタリング"
            echo "  help                       このヘルプを表示"
            echo ""
            echo "例:"
            echo "  vw git-templ my-template \"My awesome template\""
            echo "  vw template tsx-renderer \"React + TypeScript boilerplate\""
            echo "  vw git-commit-gen"
            echo "  vw commit"
            echo "  vw ccc \"ghでpr作るコマンド考えて\""
            echo "  vw photos_monitor --volume /Volumes/MyBook4TB --library \"/path/to/Library.photoslibrary\""
            ;;
        (*)
            echo "❌ エラー: 不明なコマンド '$command'"
            echo "利用可能なコマンドを確認するには: vw help"
            return 1 ;;
    esac
}

# ag: agent-deck shortcut
ag() {
    if [[ "$1" == "." ]]; then
      local existing
      existing=$(agent-deck list --json 2>/dev/null | jq -r --arg path "$(pwd)" '.[] | select(.path == $path) | .id' | head -1)
      if [[ -z "$existing" ]]; then
        local session_name
        session_name="$(basename "$(pwd)")-$(date +%m%d-%H%M)"
        agent-deck add . -t "$session_name"
      fi
      agent-deck
    else
      agent-deck "$@"
    fi
}

# tmux auto-start
tmux_auto_start() {
    [[ -n "$TMUX" ]] && return
    [[ ! -t 0 ]] && return
    [[ ! -o interactive ]] && return
    [[ -n "$INSIDE_EMACS" ]] && return
    [[ -n "$VSCODE_RESOLVING_ENVIRONMENT" ]] && return
    [[ -n "$SSH_CONNECTION" && -z "$SSH_TTY" ]] && return
    command -v tmux &>/dev/null || return
    tmux new-session -A -s "zsh" && exit
}
tmux_auto_start
