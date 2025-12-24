---
name: nvim
description: Open nvim in a new tmux pane (vertical split)
---

# Open Neovim in tmux

Execute the following bash command to open nvim in a new vertical tmux pane.

## Pre-check

First check if running inside tmux:

```bash
if [[ -z "$TMUX" ]]; then
  echo "Error: Not running inside tmux. Please start tmux first."
  exit 1
fi
```

## Command

Split current pane and open nvim:

```bash
tmux split-window -h -t "$TMUX_PANE" -c "$(pwd)" "nvim ${ARGUMENTS:-.}"
```

- `-h`: Vertical split (side-by-side panes)
- `-t "$TMUX_PANE"`: Split in current pane (uses current session/window)
- `-c "$(pwd)"`: Set working directory to current directory
- `${ARGUMENTS:-.}`: Path to open (default: current directory)

## Examples

```
/nvim              # Open current directory
/nvim README.md    # Open specific file
/nvim src/         # Open specific directory
```

## Note

This command requires sandbox bypass due to tmux socket access.
Execute with `dangerouslyDisableSandbox: true`.
