#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat << 'EOF'
Usage: scripts/check-release-consistency.sh [--tag vMAJOR.MINOR.PATCH]

Checks release metadata consistency across:
  - lib.sh SCRIPT_VERSION
  - lib.sh header version
  - xray-reality.sh wrapper header version
  - README.md / README.ru.md release badges
  - CHANGELOG.md version section

Optional:
  --tag TAG   additionally requires TAG == vSCRIPT_VERSION
EOF
}

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TAG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tag)
            TAG="${2:-}"
            shift 2
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ -n "$TAG" && ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Tag must match vMAJOR.MINOR.PATCH, got: $TAG" >&2
    exit 1
fi

LIB_FILE="$ROOT_DIR/lib.sh"
WRAPPER_FILE="$ROOT_DIR/xray-reality.sh"
README_EN="$ROOT_DIR/README.md"
README_RU="$ROOT_DIR/README.ru.md"
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"

for file in "$LIB_FILE" "$WRAPPER_FILE" "$README_EN" "$README_RU" "$CHANGELOG_FILE"; do
    [[ -f "$file" ]] || {
        echo "Missing required file: $file" >&2
        exit 1
    }
done

require_pattern() {
    local file="$1"
    local pattern="$2"
    local label="$3"
    if ! grep -q "$pattern" "$file"; then
        echo "Missing or mismatched ${label} in ${file#"$ROOT_DIR"/}" >&2
        exit 1
    fi
}

script_version=$(awk -F'"' '/^readonly SCRIPT_VERSION=/{print $2; exit}' "$LIB_FILE")
if [[ -z "$script_version" ]]; then
    echo "Failed to detect SCRIPT_VERSION from lib.sh" >&2
    exit 1
fi
if [[ ! "$script_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "SCRIPT_VERSION must match MAJOR.MINOR.PATCH, got: $script_version" >&2
    exit 1
fi

require_pattern "$LIB_FILE" "^# Xray Reality Ultimate ${script_version} - " "lib.sh header version"
require_pattern "$WRAPPER_FILE" "^# Xray Reality Ultimate ${script_version} - Wrapper" "wrapper header version"
require_pattern "$README_EN" "release-v${script_version}" "README.md release badge version"
require_pattern "$README_RU" "release-v${script_version}" "README.ru.md release badge version"
require_pattern "$CHANGELOG_FILE" "^## \\[${script_version}\\]" "CHANGELOG.md section"

if [[ -n "$TAG" && "v${script_version}" != "$TAG" ]]; then
    echo "Tag ${TAG} does not match SCRIPT_VERSION v${script_version}" >&2
    exit 1
fi

echo "release-consistency-ok:${script_version}"
if [[ -n "$TAG" ]]; then
    echo "tag-match-ok:${TAG}"
fi
