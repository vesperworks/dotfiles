#!/bin/bash

# Status line with token usage display
# Reads JSON from stdin and displays: user, branch, model, token usage%, AWS profile, directory

input=$(cat)

# Extract basic information
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // ""')
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')

# Display username
printf '\e[90m⚡mur41\e[0m'

# Display git branch if in a git repo
if git rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null || echo 'detached')
  printf ' \e[90m±\e[0m \e[90m%s\e[0m' "$branch"
fi

# Display model name
printf ' \e[90m%s\e[0m' "$model"

# Calculate and display token usage
if [ -f "$transcript_path" ]; then
  # Extract CUMULATIVE token usage across all messages
  tokens=$(cat "$transcript_path" | jq -s '
    map(select(.message.usage != null) | .message.usage) |
    if length > 0 then
      map({input: (.input_tokens // 0), output: (.output_tokens // 0)}) |
      {
        input: (map(.input) | add // 0),
        output: (map(.output) | add // 0)
      } |
      .total = (.input + .output) |
      .usage_pct = ((.total / 200000) * 100)
    else
      {total: 0, usage_pct: 0}
    end
  ' 2>/dev/null)

  if [ -n "$tokens" ]; then
    total_tokens=$(echo "$tokens" | jq -r '.total // 0')
    usage_pct=$(echo "$tokens" | jq -r '.usage_pct // 0')

    # Format token count (k for thousands)
    if [ "$total_tokens" -gt 999 ]; then
      token_display=$(echo "scale=1; $total_tokens / 1000" | bc 2>/dev/null || echo "0")k
    else
      token_display="$total_tokens"
    fi

    # Color code based on usage percentage
    if [ "$(echo "$usage_pct >= 80" | bc 2>/dev/null)" = "1" ]; then
      color='\e[91m'  # Red for 80%+
    elif [ "$(echo "$usage_pct >= 60" | bc 2>/dev/null)" = "1" ]; then
      color='\e[93m'  # Yellow for 60-80%
    else
      color='\e[92m'  # Green for <60%
    fi

    # Display percentage with 1 decimal place
    usage_pct_formatted=$(printf "%.1f" "$usage_pct" 2>/dev/null || echo "0.0")
    printf " ${color}[%s%% %s]\e[0m" "$usage_pct_formatted" "$token_display"
  fi
fi

# Display AWS profile if set
if [ -n "$AWS_PROFILE" ] && [ "$AWS_PROFILE" != "aiss-ClaudeCode-murai" ]; then
  printf ' \e[90mAWS:%s\e[0m' "$AWS_PROFILE"
elif [ "$AWS_PROFILE" = "aiss-ClaudeCode-murai" ]; then
  printf ' \e[42m\e[30m ✓ \e[0m'
fi

# Display current directory basename
if [ -n "$cwd" ]; then
  printf ' \e[90m%s\e[0m' "$(basename "$cwd")"
fi
