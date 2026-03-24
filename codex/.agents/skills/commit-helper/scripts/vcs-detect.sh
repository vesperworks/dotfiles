#!/bin/bash
set -euo pipefail

detect_vcs() {
  if jj root >/dev/null 2>&1; then
    printf 'jj\n'
    return 0
  fi

  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    printf 'git\n'
    return 0
  fi

  return 1
}

get_changed_files() {
  local vcs
  vcs=$(detect_vcs)

  case "$vcs" in
    jj)
      jj diff --name-only
      ;;
    git)
      git status --porcelain | awk '{print $2}'
      ;;
  esac
}
