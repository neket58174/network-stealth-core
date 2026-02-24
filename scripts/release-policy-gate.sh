#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat << 'EOF'
Usage: scripts/release-policy-gate.sh \
  --tag vMAJOR.MINOR.PATCH \
  --archive <release.tar.gz> \
  --checksum <release.sha256> \
  --matrix <matrix-result.json> \
  --sbom <release.spdx.json>

Verifies release policy before publish:
  - checksum file matches archive
  - matrix-result contains only successful jobs
  - sbom is valid SPDX JSON metadata
EOF
}

die() {
    echo "$*" >&2
    exit 1
}

TAG=""
ARCHIVE=""
CHECKSUM=""
MATRIX=""
SBOM=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tag)
            TAG="${2:-}"
            shift 2
            ;;
        --archive)
            ARCHIVE="${2:-}"
            shift 2
            ;;
        --checksum)
            CHECKSUM="${2:-}"
            shift 2
            ;;
        --matrix)
            MATRIX="${2:-}"
            shift 2
            ;;
        --sbom)
            SBOM="${2:-}"
            shift 2
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

[[ -n "$TAG" ]] || die "Missing --tag"
[[ -n "$ARCHIVE" ]] || die "Missing --archive"
[[ -n "$CHECKSUM" ]] || die "Missing --checksum"
[[ -n "$MATRIX" ]] || die "Missing --matrix"
[[ -n "$SBOM" ]] || die "Missing --sbom"

[[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Tag must match vMAJOR.MINOR.PATCH, got: $TAG"

for file in "$ARCHIVE" "$CHECKSUM" "$MATRIX" "$SBOM"; do
    [[ -f "$file" ]] || die "Missing required artifact: $file"
    [[ -s "$file" ]] || die "Artifact is empty: $file"
done

archive_name="$(basename "$ARCHIVE")"
if ! grep -Eq "[[:space:]]\\*?${archive_name}\$" "$CHECKSUM"; then
    die "Checksum file $CHECKSUM does not reference $archive_name"
fi
sha256sum -c "$CHECKSUM" > /dev/null

jq -e 'type == "array" and length > 0' "$MATRIX" > /dev/null
jq -e 'all(.[]; (.name | type == "string" and length > 0) and (.status == "success"))' "$MATRIX" > /dev/null || {
    echo "Matrix policy gate failed:" >&2
    cat "$MATRIX" >&2
    exit 1
}

jq -e '
  type == "object" and
  (.spdxVersion | type == "string") and
  (.SPDXID | type == "string") and
  (.creationInfo.created | type == "string") and
  ((.packages? // []) | type == "array") and
  ((.files? // []) | type == "array")
' "$SBOM" > /dev/null

echo "release-policy-gate:ok:${TAG}"
