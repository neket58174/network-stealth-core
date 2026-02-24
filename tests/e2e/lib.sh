#!/usr/bin/env bash
set -Eeuo pipefail

run_root() {
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        "$@"
        return $?
    fi

    if command -v sudo > /dev/null 2>&1; then
        if sudo -n true > /dev/null 2>&1; then
            sudo -n "$@"
            return $?
        fi
        sudo "$@"
        return $?
    fi
    "$@"
}

cleanup_installation() {
    local script_path="$1"
    run_root bash "$script_path" uninstall --yes --non-interactive > /dev/null 2>&1 || true
}

assert_service_active() {
    local unit="$1"
    if ! run_root systemctl is-active --quiet "$unit"; then
        echo "service is not active: $unit" >&2
        run_root systemctl status "$unit" --no-pager -l >&2 || true
        exit 1
    fi
}

assert_path_absent() {
    local path="$1"
    if [[ -e "$path" ]]; then
        echo "path still exists: $path" >&2
        exit 1
    fi
}

assert_port_not_listening() {
    local port="$1"
    if run_root ss -ltn "( sport = :${port} )" | tail -n +2 | grep -q .; then
        echo "port still listening: ${port}" >&2
        exit 1
    fi
}

assert_port_listening() {
    local port="$1"
    if ! run_root ss -ltn "( sport = :${port} )" | tail -n +2 | grep -q .; then
        echo "expected listening port: ${port}" >&2
        exit 1
    fi
}

assert_user_absent() {
    local user_name="$1"
    if id "$user_name" > /dev/null 2>&1; then
        echo "user still exists: ${user_name}" >&2
        exit 1
    fi
}

collect_ports_from_config() {
    local config_path="$1"
    run_root jq -r '.inbounds[].port // empty' "$config_path" | sort -n -u
}

hash_as_root() {
    local file="$1"
    run_root sha256sum "$file" | awk '{print $1}'
}
