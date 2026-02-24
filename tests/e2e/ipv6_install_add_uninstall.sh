#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="$ROOT_DIR/xray-reality.sh"
# shellcheck source=tests/e2e/lib.sh
source "$ROOT_DIR/tests/e2e/lib.sh"

START_PORT="${START_PORT:-25140}"
INITIAL_CONFIGS="${INITIAL_CONFIGS:-1}"
ADD_CONFIGS="${ADD_CONFIGS:-1}"

cleanup() {
    cleanup_installation "$SCRIPT_PATH"
}

ipv6_available() {
    if ! run_root test -r /proc/net/if_inet6; then
        return 1
    fi
    if ! run_root grep -q . /proc/net/if_inet6; then
        return 1
    fi
    local disable_flag
    disable_flag="$(run_root bash -lc 'cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null || echo 1' | tr -d '[:space:]')"
    [[ "$disable_flag" == "0" ]]
}

systemd_usable() {
    run_root test -d /run/systemd/system || return 1
    run_root systemctl list-unit-files > /dev/null 2>&1
}

trap cleanup EXIT

if ! ipv6_available; then
    echo "ipv6 is unavailable in this runner; skipping ipv6 lifecycle smoke."
    exit 0
fi

if ! systemd_usable; then
    echo "systemd is unavailable in this runner; skipping ipv6 lifecycle smoke."
    exit 0
fi

echo "==> pre-clean"
cleanup

echo "==> install (ipv4 + ipv6)"
run_root env \
    NON_INTERACTIVE=true \
    ASSUME_YES=true \
    XRAY_NUM_CONFIGS="$INITIAL_CONFIGS" \
    START_PORT="$START_PORT" \
    SERVER_IP=127.0.0.1 \
    SERVER_IP6=::1 \
    DOMAIN_CHECK=false \
    SKIP_REALITY_CHECK=true \
    ALLOW_INSECURE_SHA256=true \
    bash "$SCRIPT_PATH" install
assert_service_active xray

echo "==> validate ipv6 client links after install"
run_root test -f /etc/xray/private/keys/clients.txt
if ! run_root grep -q '@\[::1\]' /etc/xray/private/keys/clients.txt; then
    echo "expected ipv6 links in clients.txt after install" >&2
    exit 1
fi

echo "==> add-clients (ipv6 path)"
run_root env \
    NON_INTERACTIVE=true \
    ASSUME_YES=true \
    SERVER_IP=127.0.0.1 \
    SERVER_IP6=::1 \
    DOMAIN_CHECK=false \
    SKIP_REALITY_CHECK=true \
    ALLOW_INSECURE_SHA256=true \
    bash "$SCRIPT_PATH" add-clients "$ADD_CONFIGS"
assert_service_active xray

if ! run_root grep -q '@\[::1\]' /etc/xray/private/keys/clients.txt; then
    echo "expected ipv6 links in clients.txt after add-clients" >&2
    exit 1
fi

echo "==> uninstall"
run_root bash "$SCRIPT_PATH" uninstall --yes --non-interactive

echo "==> post-checks"
assert_path_absent /etc/xray
assert_path_absent /etc/xray-reality
assert_path_absent /usr/local/bin/xray
assert_path_absent /usr/local/bin/xray-reality.sh
assert_user_absent xray

trap - EXIT
echo "ipv6 lifecycle smoke passed."
