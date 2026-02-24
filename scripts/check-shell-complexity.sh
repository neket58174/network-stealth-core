#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

COMPLEXITY_STAGE="${COMPLEXITY_STAGE:-2}"
MAX_FUNC_LINES="${MAX_FUNC_LINES:-}"
MAX_FILE_LINES="${MAX_FILE_LINES:-}"

if [[ -z "$MAX_FUNC_LINES" || -z "$MAX_FILE_LINES" ]]; then
    case "$COMPLEXITY_STAGE" in
        1)
            MAX_FUNC_LINES=420
            MAX_FILE_LINES=3200
            ;;
        2)
            MAX_FUNC_LINES=360
            MAX_FILE_LINES=3000
            ;;
        3)
            MAX_FUNC_LINES=320
            MAX_FILE_LINES=2800
            ;;
        4)
            MAX_FUNC_LINES=280
            MAX_FILE_LINES=2600
            ;;
        *)
            echo "complexity check fail: unsupported COMPLEXITY_STAGE=${COMPLEXITY_STAGE}" >&2
            exit 1
            ;;
    esac
fi

fail=0
FILES=()

if command -v rg > /dev/null 2>&1; then
    while IFS= read -r file; do
        file="${file//\\//}"
        FILES+=("$file")
    done < <(rg --files \
        -g '*.sh' \
        xray-reality.sh lib.sh install.sh config.sh service.sh health.sh export.sh \
        scripts modules)
else
    FILES=(
        xray-reality.sh
        lib.sh
        install.sh
        config.sh
        service.sh
        health.sh
        export.sh
    )
    while IFS= read -r file; do
        FILES+=("${file#./}")
    done < <(find scripts modules -type f -name '*.sh' -print)
fi

if ((${#FILES[@]} == 0)); then
    echo "complexity check fail: no shell files discovered" >&2
    exit 1
fi

check_file_lines() {
    local file="$1"
    local lines
    lines="$(wc -l < "$file")"
    if [[ "$lines" =~ ^[0-9]+$ ]] && ((lines > MAX_FILE_LINES)); then
        echo "complexity check fail: ${file} has ${lines} lines (limit ${MAX_FILE_LINES})" >&2
        fail=1
    fi
}

check_function_lines() {
    local file="$1"
    awk -v file="$file" -v max_lines="$MAX_FUNC_LINES" '
        function count_open(line, tmp) {
            tmp = line
            return gsub(/\{/, "{", tmp)
        }
        function count_close(line, tmp) {
            tmp = line
            return gsub(/\}/, "}", tmp)
        }
        BEGIN {
            in_fn = 0
            depth = 0
            bad = 0
            fn = ""
            start = 0
        }
        {
            if (!in_fn && match($0, /^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{/, m)) {
                in_fn = 1
                fn = m[1]
                start = NR
                depth = 0
            }
            if (in_fn) {
                depth += count_open($0)
                depth -= count_close($0)
                if (depth == 0) {
                    fn_lines = NR - start + 1
                    if (fn_lines > max_lines) {
                        printf "complexity check fail: %s:%d function %s has %d lines (limit %d)\n", file, start, fn, fn_lines, max_lines > "/dev/stderr"
                        bad = 1
                    }
                    in_fn = 0
                    fn = ""
                    start = 0
                }
            }
        }
        END {
            if (bad) {
                exit 3
            }
        }
    ' "$file" || fail=1
}

for file in "${FILES[@]}"; do
    [[ -f "$file" ]] || continue
    check_file_lines "$file"
    check_function_lines "$file"
done

if ((fail != 0)); then
    exit 1
fi

echo "shell complexity check: ok"
