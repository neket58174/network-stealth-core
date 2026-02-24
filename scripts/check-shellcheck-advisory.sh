#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v shellcheck > /dev/null 2>&1; then
    echo "shellcheck advisory: skipped (shellcheck not installed)"
    exit 0
fi

FILES=()
if command -v rg > /dev/null 2>&1; then
    while IFS= read -r file; do
        FILES+=("$file")
    done < <(rg --files -g '*.sh' -g '!tests/bats/**')
else
    while IFS= read -r file; do
        FILES+=("${file#./}")
    done < <(find . -type f -name '*.sh' ! -path './tests/bats/*' -print)
fi

if ((${#FILES[@]} == 0)); then
    echo "shellcheck advisory: no files discovered"
    exit 0
fi

output=""
if output=$(shellcheck -x -o all -e SC1091,SC2250,SC2310,SC2312 "${FILES[@]}" 2>&1); then
    echo "shellcheck advisory: ok"
    exit 0
fi

echo "shellcheck advisory: warnings found (non-blocking)" >&2
printf '%s\n' "$output" >&2
exit 0
