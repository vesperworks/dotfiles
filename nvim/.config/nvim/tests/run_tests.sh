#!/bin/bash
set -euo pipefail

# symlink (stow) 経由で呼ばれても実体パスに解決する。
# plenary の PlenaryBustedDirectory は symlink の spec ファイルを列挙しない
# （~/.config/nvim/tests/ を渡すと 0 件で「全部 green」に見える）ため、
# 実体ディレクトリを渡すこと、また tests.helpers の require が
# cwd 相対（./tests/helpers.lua）なので config 直下に cd することが必須。
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
NVIM_CONFIG="$(cd "$(dirname "$SELF")/.." && pwd -P)"
MINIMAL_INIT="$NVIM_CONFIG/tests/minimal_init.lua"
cd "$NVIM_CONFIG"

if [ "${1:-}" = "" ]; then
	echo "Running all tests..."
	nvim --headless --noplugin -u "$MINIMAL_INIT" \
		-c "PlenaryBustedDirectory $NVIM_CONFIG/tests/ { minimal_init = '$MINIMAL_INIT', sequential = true }" 2>&1
else
	echo "Running test: $1"
	nvim --headless --noplugin -u "$MINIMAL_INIT" \
		-c "PlenaryBustedFile $NVIM_CONFIG/tests/$1" 2>&1
fi
