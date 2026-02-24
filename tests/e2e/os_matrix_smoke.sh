#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="$ROOT_DIR/xray-reality.sh"
# shellcheck source=tests/e2e/lib.sh
source "$ROOT_DIR/tests/e2e/lib.sh"

START_PORT="${START_PORT:-25040}"
INITIAL_CONFIGS="${INITIAL_CONFIGS:-1}"
ADD_CONFIGS="${ADD_CONFIGS:-1}"

latest_backup_dir() {
    run_root find /var/backups/xray -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' 2> /dev/null |
        sort -nr |
        head -n 1 |
        awk '{print $2}'
}

systemd_is_usable() {
    if ! run_root test -d /run/systemd/system; then
        return 1
    fi
    run_root systemctl list-unit-files > /dev/null 2>&1
}

cleanup() {
    cleanup_installation "$SCRIPT_PATH"
}

trap cleanup EXIT

echo "==> pre-clean"
cleanup

echo "==> install"
run_root env \
    NON_INTERACTIVE=true \
    ASSUME_YES=true \
    XRAY_NUM_CONFIGS="$INITIAL_CONFIGS" \
    START_PORT="$START_PORT" \
    SERVER_IP=127.0.0.1 \
    DOMAIN_CHECK=false \
    SKIP_REALITY_CHECK=true \
    ALLOW_INSECURE_SHA256=true \
    bash "$SCRIPT_PATH" install

echo "==> status"
run_root bash "$SCRIPT_PATH" status --verbose | run_root tee /tmp/xru-status.txt > /dev/null
grep -q "Inbounds:" /tmp/xru-status.txt

before_count="$(run_root jq '.inbounds | length' /etc/xray/config.json)"
if ((before_count < INITIAL_CONFIGS)); then
    echo "expected at least ${INITIAL_CONFIGS} inbounds, got ${before_count}" >&2
    exit 1
fi

if systemd_is_usable; then
    echo "==> add-clients"
    run_root env \
        NON_INTERACTIVE=true \
        ASSUME_YES=true \
        ALLOW_INSECURE_SHA256=true \
        bash "$SCRIPT_PATH" add-clients "$ADD_CONFIGS"

    after_count="$(run_root jq '.inbounds | length' /etc/xray/config.json)"
    expected_after=$((before_count + ADD_CONFIGS))
    if ((after_count != expected_after)); then
        echo "expected ${expected_after} inbounds after add-clients, got ${after_count}" >&2
        exit 1
    fi
else
    echo "==> add-clients skipped: systemd runtime unavailable in this OS-matrix target"
fi

echo "==> update"
run_root env \
    NON_INTERACTIVE=true \
    ASSUME_YES=true \
    ALLOW_INSECURE_SHA256=true \
    bash "$SCRIPT_PATH" update

backup_dir="$(latest_backup_dir)"
if [[ -n "${backup_dir:-}" ]] && run_root test -f "${backup_dir}/etc/xray/config.json"; then
    echo "==> rollback smoke"
    backup_cfg_sha="$(hash_as_root "${backup_dir}/etc/xray/config.json")"
    run_root bash -c "printf '%s\n' '{\"broken\":true}' > /etc/xray/config.json"
    run_root env \
        NON_INTERACTIVE=true \
        ASSUME_YES=true \
        bash "$SCRIPT_PATH" rollback "$backup_dir"
    current_cfg_sha="$(hash_as_root /etc/xray/config.json)"
    if [[ "$current_cfg_sha" != "$backup_cfg_sha" ]]; then
        echo "rollback hash mismatch for /etc/xray/config.json" >&2
        exit 1
    fi
else
    echo "==> rollback smoke skipped: no backup snapshot found after update"
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
echo "os matrix smoke passed."
