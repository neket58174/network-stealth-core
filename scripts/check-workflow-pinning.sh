#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_DIR="${ROOT_DIR}/.github/workflows"

trim() {
    local v="$1"
    v="${v#"${v%%[![:space:]]*}"}"
    v="${v%"${v##*[![:space:]]}"}"
    printf '%s' "$v"
}

fail=0

while IFS=: read -r file line raw; do
    value="${raw#*uses:}"
    value="${value%%#*}"
    value="$(trim "$value")"
    [[ -n "$value" ]] || continue

    case "$value" in
        ./*)
            continue
            ;;
        docker://*)
            # docker:// references are immutable when digest is used.
            if [[ ! "$value" =~ @sha256:[0-9a-f]{64}$ ]]; then
                echo "un-pinned docker action reference: ${file}:${line}: ${value}" >&2
                fail=1
            fi
            continue
            ;;
        *) ;;
    esac

    if [[ ! "$value" =~ @[0-9a-f]{40}$ ]]; then
        echo "action is not sha-pinned: ${file}:${line}: ${value}" >&2
        fail=1
    fi
done < <(awk '/^[[:space:]]*uses:[[:space:]]*/ {print FILENAME ":" NR ":" $0}' "${WORKFLOW_DIR}"/*.yml)

if ((fail != 0)); then
    exit 1
fi

echo "workflow pinning check: ok"
