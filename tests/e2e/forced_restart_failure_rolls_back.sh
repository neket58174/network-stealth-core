#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="$ROOT_DIR/xray-reality.sh"
# shellcheck source=tests/e2e/lib.sh
source "$ROOT_DIR/tests/e2e/lib.sh"

START_PORT="${START_PORT:-24340}"
INITIAL_CONFIGS="${INITIAL_CONFIGS:-2}"
ADD_CONFIGS="${ADD_CONFIGS:-1}"

cleanup() {
    cleanup_installation "$SCRIPT_PATH"
}

trap cleanup EXIT

echo "==> pre-clean"
cleanup

echo "==> install baseline"
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

before_count="$(run_root jq '.inbounds | length' /etc/xray/config.json)"
if ((before_count < INITIAL_CONFIGS)); then
    echo "Expected at least ${INITIAL_CONFIGS} inbounds after install, got ${before_count}" >&2
    exit 1
fi

config_sha_before="$(hash_as_root /etc/xray/config.json)"
keys_sha_before="$(hash_as_root /etc/xray/private/keys/keys.txt)"
clients_sha_before="$(hash_as_root /etc/xray/private/keys/clients.txt)"
json_sha_before="$(hash_as_root /etc/xray/private/keys/clients.json)"

mapfile -t baseline_ports < <(collect_ports_from_config /etc/xray/config.json)
if [[ ${#baseline_ports[@]} -eq 0 ]]; then
    echo "No baseline ports detected in /etc/xray/config.json" >&2
    exit 1
fi

echo "==> force add-clients failure after restart"
log_file="/tmp/xru-forced-restart-failure.log"
set +e
# shellcheck disable=SC2016 # variables expand in nested shell after sourcing modules
run_root env \
    SCRIPT_DIR="$ROOT_DIR" \
    XRAY_DATA_DIR="$ROOT_DIR" \
    NON_INTERACTIVE=true \
    ASSUME_YES=true \
    ADD_COUNT="$ADD_CONFIGS" \
    bash -c '
set -Eeuo pipefail
source "$SCRIPT_DIR/lib.sh"
source "$MODULE_DIR/install.sh"
source "$MODULE_DIR/config.sh"
source "$MODULE_DIR/service.sh"
source "$MODULE_DIR/health.sh"
if [[ -f "$MODULE_DIR/export.sh" ]]; then
    source "$MODULE_DIR/export.sh"
fi
ADD_CLIENTS_COUNT="$ADD_COUNT"
port_is_listening() { return 1; }
add_clients_flow
' | tee "$log_file" > /dev/null
rc=${PIPESTATUS[0]}
set -e

if ((rc == 0)); then
    echo "Expected add-clients forced failure, got success" >&2
    cat "$log_file" >&2 || true
    exit 1
fi
if ! grep -q "После перезапуска" "$log_file"; then
    echo "Expected post-restart failure message in forced failure log" >&2
    cat "$log_file" >&2 || true
    exit 1
fi

echo "==> verify transactional rollback"
config_sha_after="$(hash_as_root /etc/xray/config.json)"
keys_sha_after="$(hash_as_root /etc/xray/private/keys/keys.txt)"
clients_sha_after="$(hash_as_root /etc/xray/private/keys/clients.txt)"
json_sha_after="$(hash_as_root /etc/xray/private/keys/clients.json)"

if [[ "$config_sha_before" != "$config_sha_after" ]]; then
    echo "config.json changed after rollback failure path" >&2
    exit 1
fi
if [[ "$keys_sha_before" != "$keys_sha_after" ]]; then
    echo "keys.txt changed after rollback failure path" >&2
    exit 1
fi
if [[ "$clients_sha_before" != "$clients_sha_after" ]]; then
    echo "clients.txt changed after rollback failure path" >&2
    exit 1
fi
if [[ "$json_sha_before" != "$json_sha_after" ]]; then
    echo "clients.json changed after rollback failure path" >&2
    exit 1
fi

after_count="$(run_root jq '.inbounds | length' /etc/xray/config.json)"
if ((after_count != before_count)); then
    echo "Inbound count mismatch after rollback: before=${before_count}, after=${after_count}" >&2
    exit 1
fi

assert_service_active xray

for port in "${baseline_ports[@]}"; do
    assert_port_listening "$port"
done

echo "==> uninstall"
run_root bash "$SCRIPT_PATH" uninstall --yes --non-interactive

trap - EXIT
echo "e2e forced restart rollback check passed."
