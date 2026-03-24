#!/bin/bash
set -euo pipefail

detect_sensitive_info() {
  local files=("$@")
  local username
  local found=0

  username=$(whoami)

  for file in "${files[@]}"; do
    [[ -f "$file" ]] || continue

    if grep -n "$username" "$file" 2>/dev/null | head -5; then
      echo "TYPE:username:FILE:$file"
      found=1
    fi

    if grep -nE "(/Users/|/home/)[^/]+" "$file" 2>/dev/null | head -5; then
      echo "TYPE:absolute_path:FILE:$file"
      found=1
    fi

    if grep -nE "(token|secret|api[_-]?key|auth)[[:space:]=:]+[^[:space:]]+" "$file" 2>/dev/null | head -5; then
      echo "TYPE:credential_like:FILE:$file"
      found=1
    fi
  done

  return $found
}

get_commit_target_files() {
  if jj root >/dev/null 2>&1; then
    jj diff --name-only 2>/dev/null
  else
    git diff --cached --name-only 2>/dev/null
  fi
}

check_commit_sensitive() {
  local target_files
  target_files=$(get_commit_target_files)

  [[ -n "$target_files" ]] || return 0

  local files_array=()
  while IFS= read -r file; do
    [[ -n "$file" ]] && files_array+=("$file")
  done <<< "$target_files"

  detect_sensitive_info "${files_array[@]}"
}
