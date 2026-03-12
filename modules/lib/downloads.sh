#!/usr/bin/env bash
# shellcheck shell=bash

: "${XRAY_GEO_DIR:=}"
: "${XRAY_BIN:=/usr/local/bin/xray}"
: "${DOWNLOAD_HOST_ALLOWLIST:=github.com,api.github.com,objects.githubusercontent.com,raw.githubusercontent.com,release-assets.githubusercontent.com,ghproxy.com}"
: "${CONNECTION_TIMEOUT:=15}"
: "${DOWNLOAD_TIMEOUT:=900}"
: "${DOWNLOAD_RETRIES:=3}"
: "${DOWNLOAD_RETRY_DELAY:=2}"

resolve_mirror_base() {
    local base="$1"
    local version="$2"
    base=$(trim_ws "$base")
    base="${base//\{\{version\}\}/$version}"
    base="${base//\{version\}/$version}"
    base="${base//\$version/$version}"
    printf '%s' "${base%/}"
}

build_mirror_list() {
    local default_base="$1"
    local extra="$2"
    local version="$3"
    local -a mirrors=()
    local item
    if [[ -n "$default_base" ]]; then
        mirrors+=("$(resolve_mirror_base "$default_base" "$version")")
    fi
    while read -r item; do
        item=$(trim_ws "$item")
        [[ -z "$item" ]] && continue
        mirrors+=("$(resolve_mirror_base "$item" "$version")")
    done < <(split_list "$extra")
    printf '%s\n' "${mirrors[@]}"
}

xray_geo_dir() {
    if [[ -n "${XRAY_GEO_DIR:-}" ]]; then
        printf '%s\n' "$XRAY_GEO_DIR"
        return 0
    fi
    printf '%s\n' "$(dirname "$XRAY_BIN")"
}

url_host_from_https() {
    local url="$1"
    local rest="${url#https://}"
    rest="${rest%%/*}"
    rest="${rest%%\?*}"
    rest="${rest%%#*}"
    rest="${rest%%:*}"
    printf '%s' "${rest,,}"
}

is_valid_https_url() {
    local url="$1"
    [[ -n "$url" ]] || return 1
    [[ "$url" == https://* ]] || return 1
    [[ "$url" != *$'\n'* && "$url" != *$'\r'* ]] || return 1
    [[ ! "$url" =~ [[:cntrl:][:space:]] ]] || return 1

    local host
    host=$(url_host_from_https "$url")
    [[ -n "$host" ]] || return 1
    [[ "$host" =~ ^[a-z0-9.-]+$ ]] || return 1
    [[ "$host" != .* && "$host" != *..* && "$host" != *- && "$host" != -* ]] || return 1
    return 0
}

is_allowlisted_download_host() {
    local host="${1,,}"
    local entry
    while read -r entry; do
        entry=$(trim_ws "${entry,,}")
        [[ -n "$entry" ]] || continue
        if [[ "$host" == "$entry" || "$host" == *".${entry}" ]]; then
            return 0
        fi
    done < <(split_list "$DOWNLOAD_HOST_ALLOWLIST")
    return 1
}

validate_curl_target() {
    local url="$1"
    local require_allowlist="${2:-false}"

    if ! is_valid_https_url "$url"; then
        log ERROR "Невалидный URL для загрузки: $url"
        return 1
    fi

    if [[ "$require_allowlist" == "true" ]]; then
        local host
        host=$(url_host_from_https "$url")
        if ! is_allowlisted_download_host "$host"; then
            log ERROR "Хост не в DOWNLOAD_HOST_ALLOWLIST: $host"
            return 1
        fi
    fi
    return 0
}

resolve_effective_https_url() {
    local url="$1"
    local effective_url
    effective_url=$(curl --fail --show-error --silent --location \
        --proto '=https' --proto-redir '=https' \
        --output /dev/null --write-out '%{url_effective}' "$url")
    effective_url=$(trim_ws "$effective_url")
    if [[ -z "$effective_url" ]]; then
        log ERROR "Не удалось определить конечный redirect URL: $url"
        return 1
    fi
    if ! is_valid_https_url "$effective_url"; then
        log ERROR "Невалидный конечный redirect URL: $effective_url"
        return 1
    fi
    printf '%s\n' "$effective_url"
}

resolve_allowlisted_effective_url() {
    local url="$1"
    validate_curl_target "$url" true || return 1
    local effective_url
    if ! effective_url=$(resolve_effective_https_url "$url"); then
        return 1
    fi
    if ! validate_curl_target "$effective_url" true; then
        log ERROR "Конечный redirect URL вне allowlist: $effective_url"
        return 1
    fi
    printf '%s\n' "$effective_url"
}

curl_fetch_text() {
    local url="$1"
    shift
    validate_curl_target "$url" false || return 1
    curl --fail --show-error --silent --location \
        --proto '=https' --proto-redir '=https' --tlsv1.2 \
        "$@" "$url"
}

curl_fetch_text_allowlist() {
    local url="$1"
    shift
    local effective_url
    effective_url=$(resolve_allowlisted_effective_url "$url") || return 1
    curl --fail --show-error --silent \
        --proto '=https' --proto-redir '=https' --tlsv1.2 \
        "$@" "$effective_url"
}

download_file_allowlist() {
    if (($# < 2 || $# > 3)); then
        log ERROR "download_file_allowlist: usage: <url> <out_file> [description]"
        return 1
    fi

    local url="$1"
    local out_file="$2"
    local description="${3:-}"

    if [[ -n "$description" ]]; then
        debug "$description"
    fi

    local effective_url
    effective_url=$(resolve_allowlisted_effective_url "$url") || return 1

    local attempts="${DOWNLOAD_RETRIES:-3}"
    local delay="${DOWNLOAD_RETRY_DELAY:-2}"
    local i rc=1
    local tmp_dir
    tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/xray-dl.XXXXXX") || {
        log ERROR "Не удалось создать временную директорию для загрузки"
        return 1
    }
    local tmp_file=""

    if [[ ! "$attempts" =~ ^[0-9]+$ ]] || ((attempts < 1)); then
        attempts=1
    fi
    if [[ ! "$delay" =~ ^[0-9]+$ ]] || ((delay < 0)); then
        delay=0
    fi

    (
        trap 'rm -f "${tmp_file:-}"; rm -rf "${tmp_dir:-}"' EXIT INT TERM
        for ((i = 1; i <= attempts; i++)); do
            rm -f "${tmp_file:-}"
            tmp_file=$(mktemp "${tmp_dir}/part.XXXXXX") || {
                rc=1
                break
            }
            if curl --fail --show-error --silent \
                --proto '=https' --proto-redir '=https' --tlsv1.2 \
                --connect-timeout "$CONNECTION_TIMEOUT" \
                --max-time "$DOWNLOAD_TIMEOUT" \
                --output "$tmp_file" \
                "$effective_url"; then
                if [[ -s "$tmp_file" ]]; then
                    if mv -f "$tmp_file" "$out_file"; then
                        rc=0
                        break
                    fi
                    rc=1
                fi
            else
                rc=$?
            fi
            rm -f "$tmp_file"
            if ((i < attempts && delay > 0)); then
                sleep "$delay"
            fi
        done
        exit "$rc"
    )
}
