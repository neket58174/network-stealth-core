#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
shopt -s nullglob

FILES=(
    "$ROOT_DIR/xray-reality.sh"
    "$ROOT_DIR/lib.sh"
    "$ROOT_DIR/install.sh"
    "$ROOT_DIR/config.sh"
    "$ROOT_DIR/service.sh"
    "$ROOT_DIR/health.sh"
    "$ROOT_DIR/export.sh"
    "$ROOT_DIR"/scripts/*.sh
    "$ROOT_DIR"/modules/lib/*.sh
    "$ROOT_DIR"/modules/config/*.sh
    "$ROOT_DIR"/modules/install/*.sh
)

declare -a DEFS=()
declare -a DEAD=()

for file in "${FILES[@]}"; do
    while IFS=: read -r line fn; do
        [[ -n "$line" && -n "$fn" ]] || continue
        DEFS+=("${file}|${line}|${fn}")
    done < <(rg -n -o --pcre2 '^[A-Za-z_][A-Za-z0-9_]*(?=\(\)\s*\{)' "$file" || true)
done

for def in "${DEFS[@]}"; do
    IFS='|' read -r file line fn <<< "$def"
    pattern="(^|[^A-Za-z0-9_])${fn}([^A-Za-z0-9_]|$)"
    matches="$(rg -n --pcre2 "$pattern" "${FILES[@]}" || true)"

    calls="$(printf '%s\n' "$matches" | awk -F: -v fn="$fn" '
        NF < 3 { next }
        {
            text=$0
            sub(/^[^:]+:[0-9]+:/, "", text)
            if (text ~ "^[[:space:]]*" fn "\\(\\)[[:space:]]*\\{") {
                next
            }
            print
        }
    ')"

    if [[ -z "$calls" ]]; then
        DEAD+=("${fn} (${file}:${line})")
    fi
done

if ((${#DEAD[@]} > 0)); then
    echo "dead-function-check: found functions without call sites" >&2
    printf '  - %s\n' "${DEAD[@]}" >&2
    exit 1
fi

echo "dead-function-check: ok"
