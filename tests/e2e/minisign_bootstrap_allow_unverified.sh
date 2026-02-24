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
mkdir -p "$TMPDIR" "$WORK_ROOT/assets/bin" "$WORK_ROOT/bin"

source ./lib.sh
trap - EXIT
trap cleanup EXIT
source ./install.sh

if command -v minisign > /dev/null 2>&1; then
    echo "Host already has minisign in PATH; skipping bootstrap-path e2e." >&2
    exit 0
fi

ALLOW_UNVERIFIED_MINISIGN_BOOTSTRAP=true
SKIP_MINISIGN=true
MINISIGN_MIRRORS="https://fixture.test/minisign/{version}"
DOWNLOAD_HOST_ALLOWLIST="fixture.test,github.com,ghproxy.com"
MINISIGN_BIN="$WORK_ROOT/bin/minisign"

cat > "$WORK_ROOT/assets/bin/minisign" << 'EOF'
echo "stub-minisign"
EOF
chmod +x "$WORK_ROOT/assets/bin/minisign"
tar -czf "$WORK_ROOT/minisign-linux-amd64.tar.gz" -C "$WORK_ROOT/assets" .

apt-get() { return 1; }
apt-cache() { return 1; }

download_file_allowlist() {
    local url="$1"
    local out_file="$2"
    case "$url" in
        *minisign-linux-amd64.tar.gz)
            cp "$WORK_ROOT/minisign-linux-amd64.tar.gz" "$out_file"
            ;;
        *)
            return 1
            ;;
    esac
}

set +e
install_minisign > "$WORK_ROOT/install.log" 2>&1
rc=$?
set -e

if ((rc != 0)); then
    echo "install_minisign failed in allow-unverified bootstrap scenario" >&2
    cat "$WORK_ROOT/install.log" >&2 || true
    exit 1
fi

if [[ "$SKIP_MINISIGN" != "false" ]]; then
    echo "Expected SKIP_MINISIGN=false after bootstrap install, got: $SKIP_MINISIGN" >&2
    cat "$WORK_ROOT/install.log" >&2 || true
    exit 1
fi

if [[ ! -x "$MINISIGN_BIN" ]]; then
    echo "Expected bootstrap minisign binary at $MINISIGN_BIN" >&2
    cat "$WORK_ROOT/install.log" >&2 || true
    exit 1
fi

if ! grep -q "Пробуем источник minisign" "$WORK_ROOT/install.log"; then
    echo "Expected bootstrap mirror attempt in install log" >&2
    cat "$WORK_ROOT/install.log" >&2 || true
    exit 1
fi

echo "e2e minisign bootstrap allow-unverified check passed."
