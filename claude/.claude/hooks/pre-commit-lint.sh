#!/bin/bash
set -euo pipefail

# pre-commit-lint.sh - コミット前にlint/型チェックを実行するゲートフック
# PreToolUse (Bash) で stdin から JSON を受け取り、commit コマンドを検出する
# lint 失敗時は exit 2 でコミットをブロック

DEBUG="${CLAUDE_HOOKS_DEBUG:-false}"
DEBUG_LOG="$HOME/.claude/hooks/debug.log"

debug_log() {
  [[ "$DEBUG" == "true" ]] && echo "[pre-commit-lint] $1" >> "$DEBUG_LOG"
}

# stdin から JSON を読み取り、コマンドを抽出
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

debug_log "Command: $COMMAND"

# commit コマンド以外はスキップ
if ! echo "$COMMAND" | grep -qE '(jj (commit|split|describe)|git commit)'; then
  exit 0
fi

debug_log "Commit detected, running pre-commit lint"

# CWD を取得（JSON から）
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
if [[ -n "$CWD" ]]; then
  cd "$CWD" || exit 0
fi

# 変更ファイル一覧を取得
changed_files=()
if command -v jj &>/dev/null && jj root &>/dev/null 2>&1; then
  # jj: ワーキングコピーの変更ファイル
  while IFS= read -r file; do
    [[ -n "$file" ]] && changed_files+=("$file")
  done < <(jj diff --name-only 2>/dev/null)
else
  # git: 変更ファイル（staged + unstaged）
  while IFS= read -r file; do
    [[ -n "$file" ]] && changed_files+=("$file")
  done < <(git diff --name-only HEAD 2>/dev/null)
fi

if [[ ${#changed_files[@]} -eq 0 ]]; then
  debug_log "No changed files"
  exit 0
fi

# ファイルを拡張子別に分類
ts_files=()
sh_files=()
py_files=()

for file in "${changed_files[@]}"; do
  [[ ! -f "$file" ]] && continue
  case "${file##*.}" in
    ts|tsx|js|jsx|mjs|cjs) ts_files+=("$file") ;;
    sh) sh_files+=("$file") ;;
    py) py_files+=("$file") ;;
  esac
done

errors=()

# --- TypeScript/JavaScript: biome ---
if [[ ${#ts_files[@]} -gt 0 ]]; then
  debug_log "TS/JS files: ${ts_files[*]}"

  # プロジェクトルートを探す（biome.json または package.json）
  ts_dir=$(dirname "${ts_files[0]}")
  project_root="$ts_dir"
  while [[ "$project_root" != "/" ]]; do
    if [[ -f "$project_root/biome.json" ]] || [[ -f "$project_root/biome.jsonc" ]] || [[ -f "$project_root/package.json" ]]; then
      break
    fi
    project_root=$(dirname "$project_root")
  done

  if [[ -f "$project_root/biome.json" ]] || [[ -f "$project_root/biome.jsonc" ]]; then
    # biome check（lint + format check）
    if ! (cd "$project_root" && npx biome check "${ts_files[@]}" 2>&1); then
      errors+=("biome check failed")
    fi
  elif [[ -f "$project_root/package.json" ]]; then
    # biome.json がない場合は package.json の scripts を確認
    if jq -e '.scripts.check' "$project_root/package.json" &>/dev/null; then
      if ! (cd "$project_root" && nr check 2>&1); then
        errors+=("nr check failed")
      fi
    fi
  fi

  # tsc（tsconfig.json がある場合のみ）
  if [[ -f "$project_root/tsconfig.json" ]]; then
    if ! (cd "$project_root" && npx tsc --noEmit 2>&1); then
      errors+=("tsc --noEmit failed")
    fi
  fi
fi

# --- Shell: shellcheck ---
if [[ ${#sh_files[@]} -gt 0 ]]; then
  debug_log "SH files: ${sh_files[*]}"

  if command -v shellcheck &>/dev/null; then
    if ! shellcheck "${sh_files[@]}" 2>&1; then
      errors+=("shellcheck failed")
    fi
  else
    debug_log "shellcheck not found, skipping"
  fi
fi

# --- Python: ruff ---
if [[ ${#py_files[@]} -gt 0 ]]; then
  debug_log "PY files: ${py_files[*]}"

  if command -v ruff &>/dev/null; then
    if ! ruff check "${py_files[@]}" 2>&1; then
      errors+=("ruff check failed")
    fi
  elif command -v uv &>/dev/null; then
    if ! uv run ruff check "${py_files[@]}" 2>&1; then
      errors+=("ruff check failed")
    fi
  else
    debug_log "ruff not found, skipping"
  fi
fi

# --- 結果判定 ---
if [[ ${#errors[@]} -gt 0 ]]; then
  echo "Pre-commit lint failed:" >&2
  for err in "${errors[@]}"; do
    echo "  - $err" >&2
  done
  echo "Fix the errors before committing." >&2
  exit 2  # ブロック
fi

debug_log "All checks passed"
exit 0
