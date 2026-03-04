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

    calls="$(printf '%s\n' "$matches" | awk -v fn="$fn" '
        function strip_shell_literals(s,    out, i, ch, state, sq, cmd_depth) {
            out = ""
            state = "code"
            sq = sprintf("%c", 39)
            cmd_depth = 0
            for (i = 1; i <= length(s); i++) {
                ch = substr(s, i, 1)
                if (state == "code") {
                    if (ch == "#") {
                        break
                    }
                    if (ch == "\"") {
                        state = "dquote"
                        continue
                    }
                    if (ch == sq) {
                        state = "squote"
                        continue
                    }
                    out = out ch
                    continue
                }
                if (state == "dquote") {
                    if (ch == "$" && substr(s, i + 1, 1) == "(") {
                        out = out "$("
                        i++
                        cmd_depth = 1
                        state = "dquote_cmd"
                        continue
                    }
                    if (ch == "\\") {
                        i++
                        continue
                    }
                    if (ch == "\"") {
                        state = "code"
                    }
                    continue
                }
                if (state == "dquote_cmd") {
                    if (ch == "\\") {
                        out = out ch
                        i++
                        if (i <= length(s)) {
                            out = out substr(s, i, 1)
                        }
                        continue
                    }
                    if (ch == "$" && substr(s, i + 1, 1) == "(") {
                        out = out "$("
                        i++
                        cmd_depth++
                        continue
                    }
                    out = out ch
                    if (ch == ")") {
                        cmd_depth--
                        if (cmd_depth <= 0) {
                            state = "dquote"
                            cmd_depth = 0
                        }
                    }
                    continue
                }
                if (state == "squote") {
                    if (ch == "\\") {
                        i++
                        continue
                    }
                    if (ch == sq) {
                        state = "code"
                    }
                    continue
                }
            }
            return out
        }
        {
            text=$0
            if (match(text, /:[0-9]+:/)) {
                text=substr(text, RSTART + RLENGTH)
            } else {
                next
            }
            clean=strip_shell_literals(text)
            if (clean ~ "^[[:space:]]*$") {
                next
            }
            if (clean ~ "^[[:space:]]*" fn "\\(\\)[[:space:]]*\\{") {
                next
            }
            pattern="(^|[^A-Za-z0-9_])" fn "([^A-Za-z0-9_]|$)"
            if (clean ~ pattern) {
                print
            }
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
