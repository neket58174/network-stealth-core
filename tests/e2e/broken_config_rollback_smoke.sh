#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="$ROOT_DIR/xray-reality.sh"
# shellcheck source=tests/e2e/lib.sh
source "$ROOT_DIR/tests/e2e/lib.sh"

START_PORT="${START_PORT:-24640}"
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

config_sha_before="$(hash_as_root /etc/xray/config.json)"
keys_sha_before="$(hash_as_root /etc/xray/private/keys/keys.txt)"
clients_sha_before="$(hash_as_root /etc/xray/private/keys/clients.txt)"
json_sha_before="$(hash_as_root /etc/xray/private/keys/clients.json)"

mapfile -t baseline_ports < <(collect_ports_from_config /etc/xray/config.json)
if [[ ${#baseline_ports[@]} -eq 0 ]]; then
    echo "No baseline ports found in /etc/xray/config.json" >&2
    exit 1
fi

echo "==> force add-clients failure with intentionally broken config.json"
log_file="/tmp/xru-broken-config-rollback.log"
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
apply_validated_config() {
    local candidate_file="$1"
    log ERROR "intentional broken config for rollback smoke"
    printf "{broken-json" > "$XRAY_CONFIG"
    chmod 640 "$XRAY_CONFIG" 2> /dev/null || true
    chown "root:${XRAY_GROUP}" "$XRAY_CONFIG" 2> /dev/null || true
    rm -f "$candidate_file" 2> /dev/null || true
    return 1
}
add_clients_flow
' | tee "$log_file" > /dev/null
rc=${PIPESTATUS[0]}
set -e

if ((rc == 0)); then
    echo "Expected add-clients to fail on intentionally broken config path" >&2
    cat "$log_file" >&2 || true
    exit 1
fi
if ! grep -q "intentional broken config for rollback smoke" "$log_file"; then
    echo "Expected forced broken-config marker in add-clients log" >&2
    cat "$log_file" >&2 || true
    exit 1
fi

echo "==> verify rollback restored original artifacts"
config_sha_after="$(hash_as_root /etc/xray/config.json)"
keys_sha_after="$(hash_as_root /etc/xray/private/keys/keys.txt)"
clients_sha_after="$(hash_as_root /etc/xray/private/keys/clients.txt)"
json_sha_after="$(hash_as_root /etc/xray/private/keys/clients.json)"

if [[ "$config_sha_before" != "$config_sha_after" ]]; then
    echo "config.json changed after rollback recovery" >&2
    exit 1
fi
if [[ "$keys_sha_before" != "$keys_sha_after" ]]; then
    echo "keys.txt changed after rollback recovery" >&2
    exit 1
fi
if [[ "$clients_sha_before" != "$clients_sha_after" ]]; then
    echo "clients.txt changed after rollback recovery" >&2
    exit 1
fi
if [[ "$json_sha_before" != "$json_sha_after" ]]; then
    echo "clients.json changed after rollback recovery" >&2
    exit 1
fi

run_root jq empty /etc/xray/config.json > /dev/null
assert_service_active xray

for port in "${baseline_ports[@]}"; do
    assert_port_listening "$port"
done

echo "==> uninstall"
run_root bash "$SCRIPT_PATH" uninstall --yes --non-interactive

trap - EXIT
echo "e2e broken-config rollback smoke passed."
