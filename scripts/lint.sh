#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

if ! command -v rg >/dev/null 2>&1; then
  echo "rg (ripgrep) is required for linting." >&2
  exit 1
fi

lua_files="$(rg --files -g "*.lua" src || true)"
if [ -z "$lua_files" ]; then
  echo "No .lua files found under src/."
  exit 0
fi

if rg -n $'\t' src; then
  echo "Tab characters found. Use spaces." >&2
  exit 1
fi

if rg -n $'\r' src; then
  echo "CRLF line endings found. Use LF." >&2
  exit 1
fi

if rg -n "[ \t]+$" src; then
  echo "Trailing whitespace found." >&2
  exit 1
fi

echo "Lint OK"
