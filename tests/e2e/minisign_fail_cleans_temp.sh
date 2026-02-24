#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

WORK_ROOT="$(mktemp -d)"
cleanup() {
    rm -rf "$WORK_ROOT"
}
trap cleanup EXIT

export TMPDIR="$WORK_ROOT/tmp"
mkdir -p "$TMPDIR" "$WORK_ROOT/assets" "$WORK_ROOT/bin"

source ./lib.sh
trap - EXIT
trap cleanup EXIT
source ./install.sh

XRAY_VERSION="1.2.3"
XRAY_BIN="$WORK_ROOT/bin/xray"
MINISIGN_KEY="$WORK_ROOT/minisign.pub"
SKIP_MINISIGN=false
ALLOW_INSECURE_SHA256=false
XRAY_MIRRORS="https://example.test/releases/download/v{version}"
MINISIGN_MIRRORS=""
DOWNLOAD_HOST_ALLOWLIST="example.test,github.com"

ZIP_ASSET="$WORK_ROOT/Xray-linux-64.zip"
DGST_ASSET="$WORK_ROOT/Xray-linux-64.zip.dgst"
SIG_ASSET="$WORK_ROOT/Xray-linux-64.zip.minisig"

cat > "$WORK_ROOT/assets/xray" << 'EOF'
if [[ "${1:-}" == "version" ]]; then
    echo "Xray 1.2.3"
    exit 0
fi
echo "stub xray"
EOF
chmod +x "$WORK_ROOT/assets/xray"
echo "geoip" > "$WORK_ROOT/assets/geoip.dat"
echo "geosite" > "$WORK_ROOT/assets/geosite.dat"

(
    cd "$WORK_ROOT/assets"
    ZIP_ASSET="$ZIP_ASSET" python3 - << 'PY'
import os
import zipfile
from pathlib import Path

root = Path(".")
zip_path = Path(os.environ["ZIP_ASSET"])
with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for name in ("xray", "geoip.dat", "geosite.dat"):
        zf.write(root / name, arcname=name)
PY
)

sha256="$(sha256sum "$ZIP_ASSET" | awk '{print $1}')"
printf 'SHA256 = %s\n' "$sha256" > "$DGST_ASSET"
printf 'untrusted comment: test minisign\nR%040d\n' 0 > "$SIG_ASSET"

download_file_allowlist() {
    local url="$1"
    local out_file="$2"
    case "$url" in
        *Xray-linux-64.zip.minisig)
            cp "$SIG_ASSET" "$out_file"
            ;;
        *Xray-linux-64.zip.dgst)
            cp "$DGST_ASSET" "$out_file"
            ;;
        *Xray-linux-64.zip)
            cp "$ZIP_ASSET" "$out_file"
            ;;
        *)
            return 1
            ;;
    esac
}

minisign() {
    return 1
}

set +e
install_xray > "$WORK_ROOT/install.log" 2>&1
rc=$?
set -e

if ((rc == 0)); then
    echo "Expected install_xray to fail when minisign fails" >&2
    cat "$WORK_ROOT/install.log" >&2 || true
    exit 1
fi

if ! grep -q "Ошибка проверки minisign подписи" "$WORK_ROOT/install.log"; then
    echo "Expected minisign failure message in install log" >&2
    cat "$WORK_ROOT/install.log" >&2 || true
    exit 1
fi

if find "$TMPDIR" -maxdepth 1 -type d \( -name "xray-${XRAY_VERSION}.*" -o -name "xray-install.*" \) | grep -q .; then
    echo "Temporary directories were not cleaned after install_xray failure" >&2
    find "$TMPDIR" -maxdepth 2 -print >&2 || true
    exit 1
fi

if find "$TMPDIR" -maxdepth 1 -type f -name "*.minisig" | grep -q .; then
    echo "Temporary minisign files were not cleaned" >&2
    find "$TMPDIR" -maxdepth 2 -print >&2 || true
    exit 1
fi

echo "e2e minisign cleanup check passed."
