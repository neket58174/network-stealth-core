#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
shopt -s nullglob globstar
FAST_MODE=false
LINT_BASE_REF="${LINT_BASE_REF:-origin/main}"

while (($# > 0)); do
    case "$1" in
        --fast)
            FAST_MODE=true
            ;;
        *)
            echo "usage: tests/lint.sh [--fast]" >&2
            exit 1
            ;;
    esac
    shift
done

DEFAULT_SHELL_FILES=(
    "$SCRIPT_DIR/xray-reality.sh"
    "$SCRIPT_DIR/lib.sh"
    "$SCRIPT_DIR/install.sh"
    "$SCRIPT_DIR/config.sh"
    "$SCRIPT_DIR/service.sh"
    "$SCRIPT_DIR/health.sh"
    "$SCRIPT_DIR/export.sh"
    "$SCRIPT_DIR/scripts/release.sh"
    "$SCRIPT_DIR/scripts/check-release-consistency.sh"
    "$SCRIPT_DIR/scripts/release-policy-gate.sh"
    "$SCRIPT_DIR/scripts/check-dead-functions.sh"
    "$SCRIPT_DIR/scripts/check-workflow-pinning.sh"
    "$SCRIPT_DIR/scripts/check-security-baseline.sh"
    "$SCRIPT_DIR/scripts/check-docs-commands.sh"
    "$SCRIPT_DIR/scripts/check-shell-complexity.sh"
    "$SCRIPT_DIR/scripts/check-shellcheck-advisory.sh"
    "$SCRIPT_DIR"/modules/**/*.sh
    "$SCRIPT_DIR"/tests/e2e/*.sh
    "$SCRIPT_DIR/tests/lint.sh"
)
DEFAULT_MD_FILES=(
    "$SCRIPT_DIR/README.md"
    "$SCRIPT_DIR/README.ru.md"
    "$SCRIPT_DIR/CONTRIBUTING.md"
    "$SCRIPT_DIR/ARCHITECTURE.md"
    "$SCRIPT_DIR/OPERATIONS.md"
    "$SCRIPT_DIR/CHANGELOG.md"
    "$SCRIPT_DIR/SECURITY.md"
)

FILES=("${DEFAULT_SHELL_FILES[@]}")
MD_FILES=("${DEFAULT_MD_FILES[@]}")
WORKFLOW_FILES=("$SCRIPT_DIR"/.github/workflows/*.yml)

if [[ "$FAST_MODE" == "true" ]]; then
    merge_base="$(git -C "$SCRIPT_DIR" merge-base HEAD "$LINT_BASE_REF" 2> /dev/null || true)"
    if [[ -z "$merge_base" ]]; then
        merge_base="$(git -C "$SCRIPT_DIR" rev-parse HEAD~1 2> /dev/null || true)"
    fi

    mapfile -t changed_files < <(git -C "$SCRIPT_DIR" diff --name-only "${merge_base:-HEAD}"...HEAD 2> /dev/null || true)
    if ((${#changed_files[@]} == 0)); then
        mapfile -t changed_files < <(git -C "$SCRIPT_DIR" diff --name-only HEAD~1..HEAD 2> /dev/null || true)
    fi

    declare -A seen_shell=()
    declare -A seen_md=()
    declare -A seen_workflows=()
    FILES=()
    MD_FILES=()
    WORKFLOW_FILES=()

    for rel in "${changed_files[@]}"; do
        abs="$SCRIPT_DIR/$rel"
        [[ -f "$abs" ]] || continue
        case "$rel" in
            *.sh | *.bash)
                if [[ -z "${seen_shell[$abs]:-}" ]]; then
                    seen_shell["$abs"]=1
                    FILES+=("$abs")
                fi
                ;;
            *.md)
                if [[ -z "${seen_md[$abs]:-}" ]]; then
                    seen_md["$abs"]=1
                    MD_FILES+=("$abs")
                fi
                ;;
            .github/workflows/*.yml)
                if [[ -z "${seen_workflows[$abs]:-}" ]]; then
                    seen_workflows["$abs"]=1
                    WORKFLOW_FILES+=("$abs")
                fi
                ;;
            *) ;;
        esac
    done

    if ((${#FILES[@]} == 0 && ${#MD_FILES[@]} == 0 && ${#WORKFLOW_FILES[@]} == 0)); then
        echo "lint --fast: нет измененных lint-целей"
        exit 0
    fi
fi

missing_tools=0
for tool in shellcheck bashate shfmt actionlint; do
    if ! command -v "$tool" > /dev/null 2>&1; then
        echo "required tool not found: $tool" >&2
        missing_tools=1
    fi
done
if ! command -v markdownlint > /dev/null 2>&1 && ! command -v npx > /dev/null 2>&1; then
    echo "required tool not found: markdownlint (or npx fallback)" >&2
    missing_tools=1
fi
if ((missing_tools != 0)); then
    exit 1
fi

if ((${#FILES[@]} > 0)); then
    shellcheck -x -e SC1091 "${FILES[@]}"
    bashate -i E003,E006,E042,E043 "${FILES[@]}"
    shfmt -d -i 4 -ci -sr "${FILES[@]}"
fi

if ((${#WORKFLOW_FILES[@]} > 0)); then
    actionlint -oneline "${WORKFLOW_FILES[@]}"
fi

if ((${#MD_FILES[@]} > 0)); then
    if command -v markdownlint > /dev/null 2>&1; then
        NODE_OPTIONS=--no-deprecation markdownlint --config "$SCRIPT_DIR/.markdownlint.json" \
            "${MD_FILES[@]}"
    else
        NODE_OPTIONS=--no-deprecation npx --yes markdownlint-cli@0.41.0 --config "$SCRIPT_DIR/.markdownlint.json" \
            "${MD_FILES[@]}"
    fi
fi

if [[ "$FAST_MODE" != "true" ]]; then
    bash "$SCRIPT_DIR/scripts/check-dead-functions.sh"
    bash "$SCRIPT_DIR/scripts/check-shell-complexity.sh"
    bash "$SCRIPT_DIR/scripts/check-workflow-pinning.sh"
    bash "$SCRIPT_DIR/scripts/check-security-baseline.sh"
    bash "$SCRIPT_DIR/scripts/check-docs-commands.sh"
fi
