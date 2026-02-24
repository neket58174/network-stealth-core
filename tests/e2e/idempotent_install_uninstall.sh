#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="$ROOT_DIR/xray-reality.sh"
# shellcheck source=tests/e2e/lib.sh
source "$ROOT_DIR/tests/e2e/lib.sh"

START_PORT="${START_PORT:-24220}"
INITIAL_CONFIGS="${INITIAL_CONFIGS:-2}"

cleanup() {
    cleanup_installation "$SCRIPT_PATH"
}

trap cleanup EXIT

echo "==> pre-clean"
cleanup

echo "==> first install"
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
assert_service_active xray

count_first="$(run_root jq '[.inbounds[] | select(.listen == "0.0.0.0" or .listen == null)] | length' /etc/xray/config.json)"
if ((count_first < 1)); then
    echo "Expected at least one inbound after first install, got ${count_first}" >&2
    exit 1
fi
config_sha_first="$(hash_as_root /etc/xray/config.json)"

echo "==> second install (idempotency)"
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
assert_service_active xray

count_second="$(run_root jq '[.inbounds[] | select(.listen == "0.0.0.0" or .listen == null)] | length' /etc/xray/config.json)"
if ((count_second != count_first)); then
    echo "Install is not idempotent: first=${count_first}, second=${count_second}" >&2
    exit 1
fi
config_sha_second="$(hash_as_root /etc/xray/config.json)"
if [[ "$config_sha_second" != "$config_sha_first" ]]; then
    echo "Config changed after idempotent install run" >&2
    exit 1
fi

run_root bash "$SCRIPT_PATH" status --verbose | tee /tmp/xru-status-idempotent.txt > /dev/null
grep -q "Inbounds:" /tmp/xru-status-idempotent.txt

mapfile -t ports_before_uninstall < <(collect_ports_from_config /etc/xray/config.json)
if [[ ${#ports_before_uninstall[@]} -eq 0 ]]; then
    echo "No ports detected before uninstall" >&2
    exit 1
fi

echo "==> first uninstall"
run_root bash "$SCRIPT_PATH" uninstall --yes --non-interactive

echo "==> second uninstall (idempotency)"
run_root bash "$SCRIPT_PATH" uninstall --yes --non-interactive

echo "==> post-checks"
for path in \
    /etc/xray \
    /etc/xray-reality \
    /usr/local/bin/xray \
    /usr/local/bin/xray-reality.sh; do
    assert_path_absent "$path"
done

for port in "${ports_before_uninstall[@]}"; do
    assert_port_not_listening "$port"
done

assert_user_absent xray

trap - EXIT
echo "E2E idempotency check passed."
