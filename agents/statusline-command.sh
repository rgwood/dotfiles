#!/usr/bin/env bash
input=$(cat)

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cwd=$(echo "$input" | jq -r '.cwd')

branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

parts=()

if [ -n "$branch" ]; then
  parts+=("$branch")
fi

if [ -n "$used" ]; then
  printf -v used_rounded "%.0f" "$used"
  parts+=("ctx: ${used_rounded}%")
fi

IFS=" | "
echo "${parts[*]}"
