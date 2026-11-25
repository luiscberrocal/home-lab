#!/usr/bin/env bash
# Copy ADMIN_TOKEN from .env to the clipboard (macOS or Linux).
# Usage: ./copy_token.sh [--print]
set -euo pipefail

usage="Usage: $0 [--print]"
env_file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.env"

if [[ $# -gt 1 || ( $# -eq 1 && $1 != --print ) ]]; then
  echo "$usage" >&2
  exit 2
fi

if [[ ! -r $env_file ]]; then
  echo "Cannot read $env_file" >&2
  exit 1
fi

# Parse rather than source the file, so the $ signs in the hash stay literal.
# Quotes are stripped from each end independently, including curly quotes and
# any surrounding whitespace, so an unmatched quote is never copied.
token="$(sed -n 's/^[[:space:]]*ADMIN_TOKEN[[:space:]]*=//p' "$env_file" | tail -n 1 |
  LC_ALL=C sed -E $'s/^([[:space:]\'"]|\xe2\x80[\x98\x99\x9c\x9d])+//; s/([[:space:]\'"]|\xe2\x80[\x98\x99\x9c\x9d])+$//')"

if [[ -z $token ]]; then
  echo "ADMIN_TOKEN is missing or empty in $env_file" >&2
  exit 1
fi

if [[ ${1:-} == --print ]]; then
  printf '%s\n' "$token"
  exit 0
fi

if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$token" | pbcopy
elif [[ -n ${WAYLAND_DISPLAY:-} ]] && command -v wl-copy >/dev/null 2>&1; then
  printf '%s' "$token" | wl-copy
elif [[ -n ${DISPLAY:-} ]] && command -v xclip >/dev/null 2>&1; then
  # xclip stays in the background to serve the clipboard. Send its output to a
  # file so it doesn't hold the terminal or SSH session open.
  err_file="$(mktemp)"
  trap 'rm -f "$err_file"' EXIT
  if ! printf '%s' "$token" | xclip -selection clipboard >/dev/null 2>"$err_file"; then
    echo "xclip failed; the token was not copied:" >&2
    cat "$err_file" >&2
    echo "Run '$0 --print' to show the token." >&2
    exit 1
  fi
else
  echo "No clipboard available. Run '$0 --print' to show the token." >&2
  exit 1
fi

echo "ADMIN_TOKEN copied to clipboard."
