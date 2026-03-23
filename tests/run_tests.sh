#!/bin/bash
set -euo pipefail

NVIM_CONFIG="$HOME/.config/nvim"
MINIMAL_INIT="$NVIM_CONFIG/tests/minimal_init.lua"

if [ "${1:-}" = "" ]; then
  echo "Running all tests..."
  nvim --headless --noplugin -u "$MINIMAL_INIT" \
    -c "PlenaryBustedDirectory $NVIM_CONFIG/tests/ { minimal_init = '$MINIMAL_INIT', sequential = true }" 2>&1
else
  echo "Running test: $1"
  nvim --headless --noplugin -u "$MINIMAL_INIT" \
    -c "PlenaryBustedFile $NVIM_CONFIG/tests/$1" 2>&1
fi
