#!/usr/bin/env bats

@test "parse_bool handles true-ish values" {
    local value
    for value in 1 true yes y on; do
        run bash -c "source ./lib.sh; parse_bool \"$value\" false"
        [ "$status" -eq 0 ]
        [ "$output" = "true" ]
    done
}

@test "parse_bool handles false-ish values" {
    local value
    for value in 0 false no n off; do
        run bash -c "source ./lib.sh; parse_bool \"$value\" true"
        [ "$status" -eq 0 ]
        [ "$output" = "false" ]
    done
}

@test "normalize_domain_tier accepts underscore alias and canonicalizes value" {
    run bash -c 'source ./lib.sh; normalize_domain_tier "tier_global_ms10"'
    [ "$status" -eq 0 ]
    [ "$output" = "tier_global_ms10" ]
}

@test "normalize_domain_tier accepts ru-auto alias" {
    run bash -c 'source ./lib.sh; normalize_domain_tier "ru-auto"'
    [ "$status" -eq 0 ]
    [ "$output" = "tier_ru" ]
}

@test "normalize_domain_tier accepts global-ms10-auto alias" {
    run bash -c 'source ./lib.sh; normalize_domain_tier "global-ms10-auto"'
    [ "$status" -eq 0 ]
    [ "$output" = "tier_global_ms10" ]
}

@test "default runtime flags require explicit non-interactive confirmation" {
    run bash -c 'source ./lib.sh; echo "${ASSUME_YES}:${NON_INTERACTIVE}"'
    [ "$status" -eq 0 ]
    [ "$output" = "false:false" ]
}

@test "parse_args --yes enables non-interactive confirmation mode" {
    run bash -c '
    source ./lib.sh
    parse_args --yes uninstall
    echo "${ASSUME_YES}:${NON_INTERACTIVE}:${ACTION}"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "true:true:uninstall" ]
}

@test "parse_args --non-interactive enables non-interactive confirmation mode" {
    run bash -c '
    source ./lib.sh
    parse_args --non-interactive uninstall
    echo "${ASSUME_YES}:${NON_INTERACTIVE}:${ACTION}"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "true:true:uninstall" ]
}

@test "parse_args accepts --domain-check-parallelism" {
    run bash -c '
    source ./lib.sh
    parse_args install --domain-check-parallelism=24
    echo "${ACTION}:${DOMAIN_CHECK_PARALLELISM}"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "install:24" ]
}

@test "trim_ws strips leading and trailing spaces" {
    run bash -c 'source ./lib.sh; trim_ws "  hello world  "'
    [ "$status" -eq 0 ]
    [ "$output" = "hello world" ]
}

@test "split_list splits comma-separated values" {
    run bash -c 'source ./lib.sh; split_list "a,b"'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "a" ]
    [ "${lines[1]}" = "b" ]
}

@test "split_list splits space-separated values" {
    run bash -c 'source ./lib.sh; split_list "a b"'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "a" ]
    [ "${lines[1]}" = "b" ]
}

@test "split_list splits mixed comma and space separators" {
    run bash -c 'source ./lib.sh; split_list "a, b c"'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "a" ]
    [ "${lines[1]}" = "b" ]
    [ "${lines[2]}" = "c" ]
}

@test "get_query_param extracts value by key" {
    run bash -c 'source ./lib.sh; get_query_param "a=1&b=2" "b"'
    [ "$status" -eq 0 ]
    [ "$output" = "2" ]
}

@test "get_query_param decodes url-encoded value" {
    run bash -c 'source ./lib.sh; get_query_param "a=1&pbk=abc%2B123%2F%3D&sid=s%23id" "pbk"'
    [ "$status" -eq 0 ]
    [ "$output" = "abc+123/=" ]
}

@test "sanitize_log_message redacts VLESS links and identifiers" {
    run bash -c '
    source ./lib.sh
    secret_uuid="110fdea4-ddfe-4f83-bc44-ca4a63b9079a"
    input="vless://${secret_uuid}@1.1.1.1:444?pbk=abc123&sid=deadbeef#cfg uuid=${secret_uuid}"
    out=$(sanitize_log_message "$input")

    [[ "$out" == *"VLESS-REDACTED"* ]]
    [[ "$out" == *"UUID-REDACTED"* ]]
    [[ "$out" != *"vless://"* ]]
    [[ "$out" != *"$secret_uuid"* ]]
    [[ "$out" != *"pbk=abc123"* ]]
    [[ "$out" != *"sid=deadbeef"* ]]
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "debug_file writes sanitized content into install log" {
    run bash -c '
    source ./lib.sh
    tmp=$(mktemp)
    trap "rm -f \"$tmp\"" EXIT
    INSTALL_LOG="$tmp"
    secret_uuid="110fdea4-ddfe-4f83-bc44-ca4a63b9079a"
    debug_file "leak-test vless://${secret_uuid}@1.1.1.1:444?pbk=abc123&sid=deadbeef"

    grep -q "VLESS-REDACTED" "$tmp"
    ! grep -q "vless://" "$tmp"
    ! grep -q "$secret_uuid" "$tmp"
    ! grep -q "pbk=abc123" "$tmp"
    ! grep -q "sid=deadbeef" "$tmp"
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "print_secret_file_to_tty degrades gracefully without tty" {
    run bash -c '
    source ./lib.sh
    can_write_dev_tty() { return 1; }
    tmp=$(mktemp)
    trap "rm -f \"$tmp\"" EXIT
    echo "secret-value" > "$tmp"
    if print_secret_file_to_tty "$tmp" "Клиентские ссылки"; then
      echo "unexpected-success"
      exit 1
    fi
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
    [[ "$output" == *"Клиентские ссылки"* ]]
}

@test "setup_logging avoids mktemp -u race pattern" {
    run bash -c '
    ! grep -q "mktemp -u .*xray-log" ./lib.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "install sysctl profile sets bbr congestion control" {
    run bash -c '
    grep -q "^net\\.ipv4\\.tcp_congestion_control = bbr$" ./install.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "yaml_escape always returns quoted safe scalar" {
    run bash -c 'source ./lib.sh; source ./export.sh; yaml_escape "a:b # test"'
    [ "$status" -eq 0 ]
    [ "$output" = "\"a:b # test\"" ]
}

@test "resolve_mirror_base replaces version placeholders" {
    local pattern
    for pattern in "https://x/{{version}}" "https://x/{version}" "https://x/\$version"; do
        run bash -c 'source ./lib.sh; resolve_mirror_base "$1" "$2"' -- "$pattern" "1.2.3"
        [ "$status" -eq 0 ]
        [ "$output" = "https://x/1.2.3" ]
    done
}

@test "build_mirror_list outputs default and extra mirrors" {
    run bash -c 'source ./lib.sh; build_mirror_list "https://a/{version}" '\''https://b/{version},https://c/$version'\'' "1.0"'
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "https://a/1.0" ]
    [ "${lines[1]}" = "https://b/1.0" ]
    [ "${lines[2]}" = "https://c/1.0" ]
}

@test "xray_geo_dir falls back to XRAY_BIN directory" {
    run bash -c 'source ./lib.sh; XRAY_BIN="/opt/xray/bin/xray"; XRAY_GEO_DIR=""; xray_geo_dir'
    [ "$status" -eq 0 ]
    [ "$output" = "/opt/xray/bin" ]
}

@test "xray_geo_dir prefers explicit XRAY_GEO_DIR" {
    run bash -c 'source ./lib.sh; XRAY_BIN="/opt/xray/bin/xray"; XRAY_GEO_DIR="/srv/xray/geo"; xray_geo_dir'
    [ "$status" -eq 0 ]
    [ "$output" = "/srv/xray/geo" ]
}

@test "validate_curl_target rejects non-https url" {
    run bash -c 'source ./lib.sh; validate_curl_target "http://example.com/a" true'
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects control chars in path vars" {
    run bash -c 'source ./lib.sh; XRAY_SCRIPT_PATH=$'\''/usr/local/bin/xray-reality.sh\nbad'\''; strict_validate_runtime_inputs install'
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs accepts valid update inputs" {
    run bash -c '
    source ./lib.sh
    XRAY_MIRRORS="https://github.com/XTLS/Xray-core/releases/download/v1.0.0"
    MINISIGN_MIRRORS="https://github.com/jedisct1/minisign/releases/download/0.11"
    DOWNLOAD_HOST_ALLOWLIST="github.com,api.github.com"
    strict_validate_runtime_inputs update
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "strict_validate_runtime_inputs rejects dangerous XRAY_LOGS for uninstall" {
    run bash -c '
    source ./lib.sh
    XRAY_LOGS="/etc"
    strict_validate_runtime_inputs uninstall
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects dangerous XRAY_LOGS for repair" {
    run bash -c '
    source ./lib.sh
    XRAY_LOGS="/etc"
    strict_validate_runtime_inputs repair
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects dangerous XRAY_LOGS for diagnose" {
    run bash -c '
    source ./lib.sh
    XRAY_LOGS="/etc"
    strict_validate_runtime_inputs diagnose
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects dangerous XRAY_LOGS for rollback" {
    run bash -c '
    source ./lib.sh
    XRAY_LOGS="/etc"
    strict_validate_runtime_inputs rollback
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs accepts safe nested custom paths for uninstall" {
    run bash -c '
    source ./lib.sh
    base="$(mktemp -d)"
    XRAY_KEYS="$base/etc/xray/private/keys"
    XRAY_BACKUP="$base/var/backups/xray"
    XRAY_LOGS="$base/var/log/xray"
    XRAY_HOME="$base/var/lib/xray"
    XRAY_DATA_DIR="$base/usr/local/share/xray-reality"
    XRAY_GEO_DIR="$base/usr/local/share/xray"
    XRAY_BIN="$base/usr/local/bin/xray"
    XRAY_CONFIG="$base/etc/xray/config.json"
    XRAY_ENV="$base/etc/xray-reality/config.env"
    XRAY_SCRIPT_PATH="$base/usr/local/bin/xray-reality.sh"
    XRAY_UPDATE_SCRIPT="$base/usr/local/bin/xray-reality-update.sh"
    MINISIGN_KEY="$base/etc/xray/minisign.pub"
    strict_validate_runtime_inputs uninstall
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "uninstall_is_allowed_file_path allows known xray logs in /var/log" {
    run bash -c '
    source ./lib.sh
    source ./service.sh
    uninstall_is_allowed_file_path /var/log/xray-install.log
    uninstall_is_allowed_file_path /var/log/xray-update.log
    uninstall_is_allowed_file_path /var/log/xray-diagnose.log
    uninstall_is_allowed_file_path /var/log/xray-repair.log
    uninstall_is_allowed_file_path /var/log/xray-health.log
    echo ok
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "uninstall_is_allowed_file_path rejects unrelated /var/log targets" {
    run bash -c '
    source ./lib.sh
    source ./service.sh
    uninstall_is_allowed_file_path /var/log/syslog
  '
    [ "$status" -ne 0 ]
}

@test "uninstall_is_allowed_file_path rejects unrelated file in allowed dirname" {
    run bash -c '
    source ./lib.sh
    source ./service.sh
    uninstall_is_allowed_file_path /usr/local/bin/sudo
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects invalid primary domain mode" {
    run bash -c '
    source ./lib.sh
    PRIMARY_DOMAIN_MODE="broken"
    strict_validate_runtime_inputs update
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs accepts quarantine and primary controls" {
    run bash -c '
    source ./lib.sh
    PRIMARY_DOMAIN_MODE="pinned"
    PRIMARY_PIN_DOMAIN="yandex.ru"
    PRIMARY_ADAPTIVE_TOP_N=10
    DOMAIN_QUARANTINE_FAIL_STREAK=5
    DOMAIN_QUARANTINE_COOLDOWN_MIN=180
    strict_validate_runtime_inputs update
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "strict_validate_runtime_inputs rejects invalid DOWNLOAD_HOST_ALLOWLIST host" {
    run bash -c '
    source ./lib.sh
    DOWNLOAD_HOST_ALLOWLIST="github.com,bad/host"
    strict_validate_runtime_inputs update
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects invalid GH_PROXY_BASE url" {
    run bash -c '
    source ./lib.sh
    GH_PROXY_BASE="http://ghproxy.com/https://github.com"
    strict_validate_runtime_inputs update
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects invalid PROGRESS_MODE" {
    run bash -c '
    source ./lib.sh
    PROGRESS_MODE="broken"
    strict_validate_runtime_inputs update
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects invalid HEALTH_CHECK_INTERVAL" {
    run bash -c '
    source ./lib.sh
    HEALTH_CHECK_INTERVAL="120
ExecStart=/tmp/pwn"
    strict_validate_runtime_inputs update
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects invalid LOG_MAX_SIZE_MB" {
    run bash -c '
    source ./lib.sh
    LOG_MAX_SIZE_MB="abc"
    strict_validate_runtime_inputs update
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects invalid DOMAIN_CHECK_PARALLELISM" {
    run bash -c '
    source ./lib.sh
    DOMAIN_CHECK_PARALLELISM=0
    strict_validate_runtime_inputs update
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects invalid AUTO_UPDATE_RANDOM_DELAY" {
    run bash -c '
    source ./lib.sh
    AUTO_UPDATE_RANDOM_DELAY="1h;touch /tmp/pwn"
    strict_validate_runtime_inputs update
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects invalid AUTO_UPDATE_ONCALENDAR" {
    run bash -c '
    source ./lib.sh
    AUTO_UPDATE_ONCALENDAR="weekly;touch /tmp/pwn"
    strict_validate_runtime_inputs update
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs accepts XRAY_DOMAIN_PROFILE global-ms10" {
    run bash -c '
    source ./lib.sh
    XRAY_DOMAIN_PROFILE="global-ms10"
    strict_validate_runtime_inputs install
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "strict_validate_runtime_inputs rejects invalid XRAY_DOMAIN_PROFILE" {
    run bash -c '
    source ./lib.sh
    XRAY_DOMAIN_PROFILE="global-ms999"
    strict_validate_runtime_inputs install
  '
    [ "$status" -ne 0 ]
}

@test "apply_runtime_overrides keeps installed tier for add-clients" {
    run bash -c '
    source ./lib.sh
    ACTION="add-clients"
    DOMAIN_TIER="tier_ru"
    XRAY_DOMAIN_PROFILE="global-ms10"
    apply_runtime_overrides
    echo "$DOMAIN_TIER"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"tier_ru"* ]]
}

@test "apply_runtime_overrides applies XRAY_DOMAIN_PROFILE for install" {
    run bash -c '
    source ./lib.sh
    ACTION="install"
    DOMAIN_TIER="tier_ru"
    XRAY_DOMAIN_PROFILE="global-ms10"
    apply_runtime_overrides
    echo "$DOMAIN_TIER"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "tier_global_ms10" ]
}

@test "strict_validate_runtime_inputs rejects invalid XRAY_DOMAINS_FILE domain" {
    run bash -c '
    source ./lib.sh
    tmp=$(mktemp)
    trap "rm -f \"$tmp\"" EXIT
    cat > "$tmp" <<EOF
yandex.ru
bad_domain
EOF
    XRAY_CUSTOM_DOMAINS=""
    XRAY_DOMAINS_FILE="$tmp"
    strict_validate_runtime_inputs install
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects empty XRAY_DOMAINS_FILE" {
    run bash -c '
    source ./lib.sh
    tmp=$(mktemp)
    trap "rm -f \"$tmp\"" EXIT
    XRAY_CUSTOM_DOMAINS=""
    XRAY_DOMAINS_FILE="$tmp"
    strict_validate_runtime_inputs install
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs accepts valid XRAY_DOMAINS_FILE" {
    run bash -c '
    source ./lib.sh
    tmp=$(mktemp)
    trap "rm -f \"$tmp\"" EXIT
    cat > "$tmp" <<EOF
yandex.ru
vk.com
EOF
    XRAY_CUSTOM_DOMAINS=""
    XRAY_DOMAINS_FILE="$tmp"
    strict_validate_runtime_inputs install
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "strict_validate_runtime_inputs rejects invalid REALITY_TEST_PORTS values" {
    run bash -c '
    source ./lib.sh
    REALITY_TEST_PORTS="443,70000"
    strict_validate_runtime_inputs update
  '
    [ "$status" -ne 0 ]
}

@test "strict_validate_runtime_inputs rejects invalid PRIMARY_PIN_DOMAIN" {
    run bash -c '
    source ./lib.sh
    PRIMARY_DOMAIN_MODE="pinned"
    PRIMARY_PIN_DOMAIN="bad_domain"
    strict_validate_runtime_inputs update
  '
    [ "$status" -ne 0 ]
}

@test "validate_export_json_schema accepts minimal singbox shape" {
    run bash -c '
    source ./lib.sh
    source ./export.sh
    tmp=$(mktemp)
    cat > "$tmp" <<EOF
{"dns":{"servers":[{"tag":"d1"}]},"inbounds":[{"type":"mixed"}],"outbounds":[{"type":"vless"},{"type":"direct"},{"type":"block"}]}
EOF
    validate_export_json_schema "$tmp" "singbox"
    echo ok
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "validate_export_json_schema rejects invalid v2rayn shape" {
    run bash -c '
    source ./lib.sh
    source ./export.sh
    tmp=$(mktemp)
    echo "{\"profiles\":[{\"name\":\"x\"}]}" > "$tmp"
    validate_export_json_schema "$tmp" "v2rayn"
  '
    [ "$status" -ne 0 ]
}

@test "auto-update template supports GEO_VERIFY_STRICT fail-closed mode" {
    run bash -c '
    block="$(awk '\''/echo "Updating Geo files..."/,/UPDATEEOF/'\'' ./modules/install/bootstrap.sh)"
    echo "$block" | grep -q "GEO_VERIFY_STRICT"
    echo "$block" | grep -q "if \\[\\[ \"\\$GEO_VERIFY_STRICT\" == \"true\" \\]\\]"
    echo "$block" | grep -q "download_geo_with_verify \"geoip.dat\" \"\\$GEOIP_URL\" \"\\$GEOIP_SHA256_URL\"$"
    echo "$block" | grep -q "download_geo_with_verify \"geosite.dat\" \"\\$GEOSITE_URL\" \"\\$GEOSITE_SHA256_URL\"$"
    echo "$block" | grep -q "download_geo_with_verify \"geoip.dat\" \"\\$GEOIP_URL\" \"\\$GEOIP_SHA256_URL\" || true"
    echo "$block" | grep -q "download_geo_with_verify \"geosite.dat\" \"\\$GEOSITE_URL\" \"\\$GEOSITE_SHA256_URL\" || true"
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "auto-update template escapes XRAY_SCRIPT_PATH in exec line" {
    run bash -c '
    grep -q "printf '\''exec %q update --non-interactive" ./modules/install/bootstrap.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "setup_logrotate uses runtime log path variables" {
    run bash -c '
    grep -q '\''safe_logs_dir='\'' ./modules/install/bootstrap.sh
    grep -q '\''safe_health_log='\'' ./modules/install/bootstrap.sh
    grep -q '\''\${safe_logs_dir%/}/\\*\\.log \${safe_health_log}'\'' ./modules/install/bootstrap.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "temp xray config files use hardened permissions helper" {
    run bash -c '
    grep -q '\''set_temp_xray_config_permissions "\$tmp_config"'\'' ./config.sh
    ! grep -q '\''chmod 644 "\$tmp_config"'\'' ./config.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "create_temp_xray_config_file uses TMPDIR and json suffix" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    tmpdir=$(mktemp -d)
    TMPDIR="$tmpdir"
    tmp_config=$(create_temp_xray_config_file)
    [[ -f "$tmp_config" ]]
    [[ "$tmp_config" == "$tmpdir"/xray-config.*.json ]]
    rm -f "$tmp_config"
    rmdir "$tmpdir"
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "rpm dependency check accepts curl provider even without curl package" {
    run bash -c '
    source ./modules/install/bootstrap.sh
    log() { :; }
    PKG_TYPE="rpm"
    PKG_UPDATE=":"
    PKG_INSTALL="false"
    rpm() {
      [[ "$1" == "-q" ]] || return 1
      case "$2" in
        curl) return 1 ;;
        curl-minimal|jq|openssl|unzip|ca-certificates|util-linux|iproute|procps-ng|libcap|logrotate|policycoreutils) return 0 ;;
        *) return 1 ;;
      esac
    }
    install_dependencies
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "e2e run_root prefers direct execution as root and falls back to sudo -n" {
    run bash -c '
    grep -q '\''EUID'\'' ./tests/e2e/lib.sh
    grep -q '\''sudo -n true'\'' ./tests/e2e/lib.sh
    grep -q '\''sudo -n "\$@"'\'' ./tests/e2e/lib.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "derive_public_key_from_private_key uses strict x25519 -i flow" {
    run bash -c '
    grep -q '\''x25519 -i "\$private_key"'\'' ./config.sh
    ! grep -q '\''x25519 "\$private_key"'\'' ./config.sh
    grep -q '\''xray x25519 -i failed while deriving public key'\'' ./config.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "build_config validates IPv6 port presence before jq tonumber" {
    run bash -c '
    grep -q '\''if \[\[ -z "\${PORTS_V6\[\$i\]:-}" \]\]'\'' ./config.sh
    grep -q '\''HAS_IPV6=true, но IPv6 порт для конфига'\'' ./config.sh
    grep -q '\''Ошибка генерации IPv6 inbound для конфига'\'' ./config.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "update_xray backs up config and client artifacts before update" {
    run bash -c '
    grep -q '\''backup_file "\$XRAY_CONFIG"'\'' ./service.sh
    grep -q '\''backup_file "\$XRAY_KEYS/keys.txt"'\'' ./service.sh
    grep -q '\''backup_file "\$XRAY_KEYS/clients.txt"'\'' ./service.sh
    grep -q '\''backup_file "\$XRAY_KEYS/clients.json"'\'' ./service.sh
    grep -q '\''backup_file "\$XRAY_BIN"'\'' ./service.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "release policy gate accepts valid checksum matrix and sbom" {
    run bash -c '
    tmpdir=$(mktemp -d)
    trap "rm -rf \"$tmpdir\"" EXIT
    archive="$tmpdir/xray-reality-v0.0.1.tar.gz"
    checksum="$tmpdir/xray-reality-v0.0.1.sha256"
    matrix="$tmpdir/matrix-result.json"
    sbom="$tmpdir/xray-reality-v0.0.1.spdx.json"
    printf "release-asset" > "$archive"
    sha256sum "$archive" > "$checksum"
    cat > "$matrix" <<EOF
[{"name":"ubuntu-24.04","status":"success"}]
EOF
    cat > "$sbom" <<EOF
{"spdxVersion":"SPDX-2.3","SPDXID":"SPDXRef-DOCUMENT","creationInfo":{"created":"2026-02-19T00:00:00Z"},"packages":[],"files":[]}
EOF
    bash ./scripts/release-policy-gate.sh \
      --tag v0.0.1 \
      --archive "$archive" \
      --checksum "$checksum" \
      --matrix "$matrix" \
      --sbom "$sbom"
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "release policy gate rejects failed matrix entries" {
    run bash -c '
    tmpdir=$(mktemp -d)
    trap "rm -rf \"$tmpdir\"" EXIT
    archive="$tmpdir/xray-reality-v0.0.1.tar.gz"
    checksum="$tmpdir/xray-reality-v0.0.1.sha256"
    matrix="$tmpdir/matrix-result.json"
    sbom="$tmpdir/xray-reality-v0.0.1.spdx.json"
    printf "release-asset" > "$archive"
    sha256sum "$archive" > "$checksum"
    cat > "$matrix" <<EOF
[{"name":"ubuntu-24.04","status":"failure"}]
EOF
    cat > "$sbom" <<EOF
{"spdxVersion":"SPDX-2.3","SPDXID":"SPDXRef-DOCUMENT","creationInfo":{"created":"2026-02-19T00:00:00Z"},"packages":[],"files":[]}
EOF
    if bash ./scripts/release-policy-gate.sh \
      --tag v0.0.1 \
      --archive "$archive" \
      --checksum "$checksum" \
      --matrix "$matrix" \
      --sbom "$sbom"; then
      echo "unexpected-success"
      exit 1
    fi
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "apply_validated_config accepts successful xray test without marker string" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    tmp=$(mktemp)
    target=$(mktemp)
    trap "rm -f \"$tmp\" \"$target\"" EXIT
    echo "{\"inbounds\":[]}" > "$tmp"
    XRAY_CONFIG="$target"
    XRAY_GROUP="xray"
    xray_config_test_file() { echo "ok-without-marker"; return 0; }
    chown() { :; }

    apply_validated_config "$tmp"
    [[ -f "$XRAY_CONFIG" ]]
    grep -q "\"inbounds\"" "$XRAY_CONFIG"
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "apply_validated_config rejects non-zero xray test even with marker text" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    tmp=$(mktemp)
    target=$(mktemp)
    trap "rm -f \"$tmp\" \"$target\"" EXIT
    echo "{\"inbounds\":[]}" > "$tmp"
    XRAY_CONFIG="$target"
    XRAY_GROUP="xray"
    xray_config_test_file() { echo "Configuration OK"; return 1; }
    chown() { :; }

    if apply_validated_config "$tmp"; then
      echo "unexpected-success"
      exit 1
    fi
    [[ ! -f "$tmp" ]]
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "runtime flows use exit-code config check helper instead of marker grep" {
    run bash -c '
    ! grep -q '\''xray_config_test 2>&1 | grep -q "Configuration OK"'\'' ./install.sh
    ! grep -q '\''xray_config_test 2>&1 | grep -q "Configuration OK"'\'' ./service.sh
    ! grep -q '\''xray_config_test 2>&1 | grep -q "Configuration OK"'\'' ./health.sh
    ! grep -q '\''xray_config_test 2>&1 | grep -q "Configuration OK"'\'' ./lib.sh
    grep -q '\''^xray_config_test_ok() {'\'' ./config.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "xray_config_test_file falls back to sudo when runuser fails" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    XRAY_USER="xray"
    XRAY_BIN="/usr/local/bin/xray"
    runuser() { return 1; }
    sudo() { echo "sudo-called:$*"; return 0; }
    su() { echo "su-called:$*"; return 99; }
    xray_config_test_file "/tmp/xray-config.json"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"sudo-called:-n -u xray -- /usr/local/bin/xray -test -c /tmp/xray-config.json"* ]]
}

@test "xray_config_test_file falls back to su when runuser and sudo fail" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    XRAY_USER="xray"
    XRAY_BIN="/usr/local/bin/xray"
    runuser() { return 1; }
    sudo() { return 1; }
    su() { echo "su-called:$*"; return 0; }
    xray_config_test_file "/tmp/xray-config.json"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"su-called:-s /bin/sh xray -c \"\$0\" -test -c \"\$1\" /usr/local/bin/xray /tmp/xray-config.json"* ]]
}

@test "xray_config_test_file falls back to root execution when user switches fail" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    XRAY_USER="xray"
    runuser() { return 1; }
    sudo() { return 1; }
    su() { return 1; }
    tmpbin=$(mktemp)
    trap "rm -f \"$tmpbin\"" EXIT
    cat > "$tmpbin" <<'\''EOF'\''
#!/usr/bin/env bash
echo "root-fallback:$*"
exit 0
EOF
    chmod +x "$tmpbin"
    XRAY_BIN="$tmpbin"
    xray_config_test_file "/tmp/xray-config.json"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"root-fallback:-test -c /tmp/xray-config.json"* ]]
}

@test "install_xray trap restore does not use eval" {
    run bash -c '
    ! grep -q '\''eval "\${_prev_return_trap}"'\'' ./install.sh
    grep -q '\''trap -- "\$_prev_return_trap_cmd" RETURN'\'' ./install.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "install_minisign supports MINISIGN_BIN override path" {
    run bash -c '
    grep -q '\''local minisign_bin="\${MINISIGN_BIN:-/usr/local/bin/minisign}"'\'' ./install.sh
    grep -q '\''install -m 755 "\$bin_path" "\$minisign_bin"'\'' ./install.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "install_xray can use MINISIGN_BIN for signature verification" {
    run bash -c '
    grep -q '\''local minisign_cmd="minisign"'\'' ./install.sh
    grep -q '\''if \[\[ -n "\${MINISIGN_BIN:-}" && -x "\${MINISIGN_BIN}" \]\]'\'' ./install.sh
    grep -q '\''if "\$minisign_cmd" -Vm "\$zip_file" -p "\$MINISIGN_KEY" -x "\$sig_file"'\'' ./install.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "install_xray suppresses noisy curl 404 lines for optional minisign lookup" {
    run bash -c '
    grep -q "sig_err_file=.*\\.sigerr" ./install.sh
    grep -q "download_file_allowlist .*\\.zip\\.minisig.*2> \"\\$sig_err_file\"" ./install.sh
    grep -q "minisign signature missing at \\${base} (404)" ./install.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "detect_ips ignores invalid auto-detected ipv6" {
    run bash -c '
    source ./lib.sh
    source ./install.sh
    log() { :; }
    fetch_ip() {
      if [[ "$1" == "4" ]]; then
        echo "1.2.3.4"
      else
        echo "bad-ip"
      fi
    }
    SERVER_IP=""
    SERVER_IP6=""
    detect_ips > /dev/null
    echo "${HAS_IPV6}:${SERVER_IP6:-empty}"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "false:empty" ]
}

@test "validate_clients_json_file accepts object with configs array" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    tmp=$(mktemp)
    trap "rm -f \"$tmp\"" EXIT
    cat > "$tmp" <<EOF
{"configs":[]}
EOF
    validate_clients_json_file "$tmp"
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "validate_clients_json_file reinitializes invalid clients.json shape" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    atomic_write() {
      local target="$1"
      local mode="${2:-}"
      cat > "$target"
      if [[ -n "$mode" ]]; then
        chmod "$mode" "$target"
      fi
    }
    tmp=$(mktemp)
    trap "rm -f \"$tmp\"" EXIT
    cat > "$tmp" <<EOF
{"profiles":{}}
EOF
    validate_clients_json_file "$tmp"
    jq -e '\''type=="object" and (.configs|type=="array") and (.configs|length==0)'\'' "$tmp" > /dev/null
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "validate_clients_json_file normalizes legacy array format" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    atomic_write() {
      local target="$1"
      local mode="${2:-}"
      cat > "$target"
      if [[ -n "$mode" ]]; then
        chmod "$mode" "$target"
      fi
    }
    tmp=$(mktemp)
    trap "rm -f \"$tmp\"" EXIT
    cat > "$tmp" <<EOF
[{"name":"Config 1"}]
EOF
    validate_clients_json_file "$tmp"
    jq -e '\''type=="object" and (.configs|type=="array") and (.configs|length==1)'\'' "$tmp" > /dev/null
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "validate_clients_json_file normalizes legacy profiles format" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    atomic_write() {
      local target="$1"
      local mode="${2:-}"
      cat > "$target"
      if [[ -n "$mode" ]]; then
        chmod "$mode" "$target"
      fi
    }
    tmp=$(mktemp)
    trap "rm -f \"$tmp\"" EXIT
    cat > "$tmp" <<EOF
{"profiles":[{"name":"Config 1"}]}
EOF
    validate_clients_json_file "$tmp"
    jq -e '\''type=="object" and (.configs|type=="array") and (.configs|length==1) and (has("profiles")|not)'\'' "$tmp" > /dev/null
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "secure_clients_json_permissions enforces mode 640" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    tmp=$(mktemp)
    trap "rm -f \"$tmp\"" EXIT

    chmod 600 "$tmp" 2> /dev/null || { echo "skip-perms"; exit 0; }
    probe_600=$(stat -c "%a" "$tmp" 2> /dev/null || true)
    chmod 644 "$tmp" 2> /dev/null || { echo "skip-perms"; exit 0; }
    probe_644=$(stat -c "%a" "$tmp" 2> /dev/null || true)
    if [[ "$probe_600" != "600" || "$probe_644" != "644" ]]; then
      echo "skip-perms"
      exit 0
    fi

    chmod 644 "$tmp"
    secure_clients_json_permissions "$tmp"
    mode=$(stat -c "%a" "$tmp")
    [[ "$mode" == "640" ]]
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == "ok" || "$output" == "skip-perms" ]]
}

@test "validate_clients_json_file keeps normalized file mode 640" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    atomic_write() {
      local target="$1"
      local mode="${2:-}"
      cat > "$target"
      if [[ -n "$mode" ]]; then
        chmod "$mode" "$target"
      fi
    }
    tmp=$(mktemp)
    trap "rm -f \"$tmp\"" EXIT

    chmod 600 "$tmp" 2> /dev/null || { echo "skip-perms"; exit 0; }
    probe_600=$(stat -c "%a" "$tmp" 2> /dev/null || true)
    chmod 644 "$tmp" 2> /dev/null || { echo "skip-perms"; exit 0; }
    probe_644=$(stat -c "%a" "$tmp" 2> /dev/null || true)
    if [[ "$probe_600" != "600" || "$probe_644" != "644" ]]; then
      echo "skip-perms"
      exit 0
    fi

    cat > "$tmp" <<EOF
{"profiles":[{"name":"Config 1"}]}
EOF
    chmod 666 "$tmp"
    validate_clients_json_file "$tmp"
    mode=$(stat -c "%a" "$tmp")
    [[ "$mode" == "640" ]]
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* || "$output" == "skip-perms" ]]
}

@test "ufw delete operations are non-interactive" {
    run bash -c '
    grep -q "ufw --force delete allow" ./lib.sh
    grep -q "ufw --force delete allow" ./service.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "add_clients_flow backs up artifacts before write" {
    run bash -c '
    grep -q '\''backup_file "\$keys_file"'\'' ./config.sh
    grep -q '\''backup_file "\$client_file"'\'' ./config.sh
    grep -q '\''backup_file "\$json_file"'\'' ./config.sh
    grep -q '\''validate_clients_json_file "\$json_file"'\'' ./config.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "firewall helper records v6 rules with correct family tags" {
    run bash -c '
    grep -q '\''record_firewall_rule_add "ufw" "\$port" "v6"'\'' ./lib.sh
    grep -q '\''record_firewall_rule_add "firewalld" "\$port" "v6"'\'' ./lib.sh
    grep -q '\''record_firewall_rule_add "ip6tables" "\$port" "v6"'\'' ./lib.sh
    grep -q '\''open_firewall_ports'\'' ./config.sh
    grep -q '\''open_firewall_ports'\'' ./service.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "add_clients_flow validates SERVER_IP before link generation" {
    run bash -c '
    grep -q '\''is_valid_ipv4 "\$SERVER_IP"'\'' ./config.sh
    grep -q '\''не удалось определить корректный ipv4 для add-clients/add-keys'\'' ./config.sh -i
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "client_artifacts_missing detects absent files" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    tmp=$(mktemp -d)
    trap "rm -rf \"$tmp\"" EXIT
    XRAY_KEYS="$tmp"
    mkdir -p "$XRAY_KEYS"
    touch "$XRAY_KEYS/keys.txt" "$XRAY_KEYS/clients.txt"
    if client_artifacts_missing; then
      echo "missing"
    else
      echo "complete"
    fi
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"missing"* ]]
}

@test "client_artifacts_missing returns false when all files exist" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    tmp=$(mktemp -d)
    trap "rm -rf \"$tmp\"" EXIT
    XRAY_KEYS="$tmp"
    mkdir -p "$XRAY_KEYS"
    touch "$XRAY_KEYS/keys.txt" "$XRAY_KEYS/clients.txt" "$XRAY_KEYS/clients.json"
    if client_artifacts_missing; then
      echo "missing"
    else
      echo "complete"
    fi
  '
    [ "$status" -eq 0 ]
    [ "$output" = "complete" ]
}

@test "client_artifacts_inconsistent detects mismatched counts" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    tmp=$(mktemp -d)
    trap "rm -rf \"$tmp\"" EXIT
    XRAY_KEYS="$tmp"
    cat > "$XRAY_KEYS/keys.txt" <<EOF
Private Key: p1
EOF
    cat > "$XRAY_KEYS/clients.txt" <<EOF
vless://u1@1.1.1.1:444?pbk=pk1#cfg1
EOF
    cat > "$XRAY_KEYS/clients.json" <<EOF
{"configs":[{"name":"Config 1"}]}
EOF
    if client_artifacts_inconsistent 2; then
      echo "inconsistent"
    else
      echo "consistent"
    fi
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"inconsistent"* ]]
}

@test "client_artifacts_inconsistent returns false for aligned artifacts" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    tmp=$(mktemp -d)
    trap "rm -rf \"$tmp\"" EXIT
    XRAY_KEYS="$tmp"
    cat > "$XRAY_KEYS/keys.txt" <<EOF
Private Key: p1
Private Key: p2
EOF
    cat > "$XRAY_KEYS/clients.txt" <<EOF
vless://u1@1.1.1.1:444?pbk=pk1#cfg1
vless://u2@1.1.1.1:445?pbk=pk2#cfg2
vless://u2@[2001:db8::1]:1445?pbk=pk2#cfg2-v6
EOF
    cat > "$XRAY_KEYS/clients.json" <<EOF
{"configs":[{"name":"Config 1"},{"name":"Config 2"}]}
EOF
    if client_artifacts_inconsistent 2; then
      echo "inconsistent"
    else
      echo "consistent"
    fi
  '
    [ "$status" -eq 0 ]
    [ "$output" = "consistent" ]
}

@test "add_clients_flow checks missing and inconsistent artifacts before finalize" {
    run bash -c '
    grep -q '\''client_artifacts_missing || client_artifacts_inconsistent "\$new_total"'\'' ./config.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "save_client_configs renders clients.txt from clients.json source" {
    run bash -c '
    grep -q '\''render_clients_txt_from_json "\$json_file" "\$client_file"'\'' ./config.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "save_client_configs keeps json entries when ipv6 is disabled" {
    run bash -c '
    source ./lib.sh
    source ./config.sh

    chown() { :; }
    backup_file() { :; }
    atomic_write() {
      local target="$1"
      local mode="${2:-}"
      cat > "$target"
      if [[ -n "$mode" ]]; then
        chmod "$mode" "$target"
      fi
    }

    XRAY_KEYS="$(mktemp -d)"
    trap "rm -rf \"$XRAY_KEYS\"" EXIT

    XRAY_GROUP="xray"
    SERVER_IP="1.1.1.1"
    SERVER_IP6=""
    HAS_IPV6=false
    TRANSPORT="grpc"
    SPIDER_MODE=false
    MUX_ENABLED=false
    MUX_CONCURRENCY=0
    QR_ENABLED=false

    NUM_CONFIGS=2
    PORTS=(443 444)
    PORTS_V6=()
    UUIDS=(u1 u2)
    SHORT_IDS=(s1 s2)
    PRIVATE_KEYS=(priv1 priv2)
    PUBLIC_KEYS=(pub1 pub2)
    CONFIG_DOMAINS=(example.com example.org)
    CONFIG_SNIS=(example.com example.org)
    CONFIG_FPS=(chrome firefox)
    CONFIG_GRPC_SERVICES=(svc.one svc.two)

    save_client_configs

    count=$(jq -r ".configs | length" "$XRAY_KEYS/clients.json")
    [[ "$count" == "2" ]]
    jq -e ".configs[] | .vless_v4 | select(type == \"string\" and length > 0)" "$XRAY_KEYS/clients.json" > /dev/null
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "add_clients_flow re-renders clients.txt from clients.json after append" {
    run bash -c '
    grep -q '\''jq --argjson new "\$new_json_configs"'\'' ./config.sh
    grep -q '\''\.configs += \$new'\'' ./config.sh
    grep -q '\''render_clients_txt_from_json "\$json_file" "\$client_file"'\'' ./config.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "rebuild_client_artifacts_from_config rebuilds via stubs" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    load_existing_ports_from_config() { PORTS=(444); PORTS_V6=(); HAS_IPV6=false; }
    load_existing_metadata_from_config() { CONFIG_DOMAINS=(yandex.ru); CONFIG_SNIS=(yandex.ru); CONFIG_FPS=(chrome); CONFIG_GRPC_SERVICES=(svc.Test); }
    load_keys_from_config() { UUIDS=(u1); SHORT_IDS=(abcd1234); PRIVATE_KEYS=(priv1); }
    build_public_keys_for_current_config() { PUBLIC_KEYS=(pub1); return 0; }
    save_client_configs() { echo "saved"; return 0; }
    export_all_configs() { echo "exported"; return 0; }
    XRAY_KEYS="$(mktemp -d)"
    SERVER_IP="127.0.0.1"
    SERVER_IP6=""
    TRANSPORT="grpc"
    SPIDER_MODE=true
    MUX_ENABLED=false
    MUX_CONCURRENCY=0
    XRAY_GROUP="xray"
    if rebuild_client_artifacts_from_config; then
      echo "ok"
    else
      echo "fail"
      exit 1
    fi
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"saved"* ]]
    [[ "$output" == *"exported"* ]]
    [[ "$output" == *"ok"* ]]
}

@test "load_existing_* supports explicit ipv4 listen and filters non-reality inbounds" {
    run bash -c '
    source ./lib.sh
    tmp=$(mktemp)
    trap "rm -f \"$tmp\"" EXIT
    cat > "$tmp" <<EOF
{
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 444,
      "settings": {"clients": [{"id": "uuid-v4"}]},
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {"serviceName": "svc.v4"},
        "realitySettings": {
          "dest": "yandex.ru:443",
          "serverNames": ["music.yandex.ru"],
          "fingerprint": "chrome",
          "shortIds": ["abcd1234"],
          "privateKey": "priv-v4"
        }
      }
    },
    {
      "listen": "::1",
      "port": 445,
      "settings": {"clients": [{"id": "uuid-v6"}]},
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {"serviceName": "svc.v6"},
        "realitySettings": {
          "dest": "vk.com:443",
          "serverNames": ["vk.com"],
          "fingerprint": "firefox",
          "shortIds": ["efgh5678"],
          "privateKey": "priv-v6"
        }
      }
    },
    {
      "listen": "0.0.0.0",
      "port": 1080,
      "settings": {},
      "streamSettings": {"network": "tcp"}
    }
  ]
}
EOF
    XRAY_CONFIG="$tmp"
    load_existing_ports_from_config
    load_existing_metadata_from_config
    load_keys_from_config
    echo "PORTS=${PORTS[*]}"
    echo "PORTS_V6=${PORTS_V6[*]}"
    echo "UUIDS=${UUIDS[*]}"
    echo "DOMAINS=${CONFIG_DOMAINS[*]}"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"PORTS=444"* ]]
    [[ "$output" == *"PORTS_V6=445"* ]]
    [[ "$output" == *"UUIDS=uuid-v4"* ]]
    [[ "$output" == *"DOMAINS=yandex.ru"* ]]
}

@test "save_environment escapes command substitution and keeps 0600 mode" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    log() { :; }
    backup_file() { :; }
    atomic_write() {
      local target="$1"
      local mode="${2:-}"
      cat > "$target"
      [[ -n "$mode" ]] && chmod "$mode" "$target"
    }

    rm -f /tmp/xray_env_injection_test
    tmp_env=$(mktemp)
    tmp_bin_dir=$(mktemp -d)
    trap "rm -f \"$tmp_env\" /tmp/xray_env_injection_test; rm -rf \"$tmp_bin_dir\"" EXIT

    cat > "${tmp_bin_dir}/xray" <<EOF
#!/usr/bin/env bash
echo "Xray 1.8.0"
EOF
    chmod +x "${tmp_bin_dir}/xray"

    XRAY_BIN="${tmp_bin_dir}/xray"
    XRAY_ENV="$tmp_env"
    SERVER_IP='\''1.2.3.4$(touch /tmp/xray_env_injection_test)'\''
    SERVER_IP6=""
    SPIDER_MODE="false"

    save_environment
    grep -q '\''atomic_write "\$XRAY_ENV" 0600'\'' ./config.sh
    source "$XRAY_ENV"

    [[ ! -e /tmp/xray_env_injection_test ]]
    [[ "$SERVER_IP" == '\''1.2.3.4$(touch /tmp/xray_env_injection_test)'\'' ]]
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "save_environment writes legacy aliases for env compatibility" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    log() { :; }
    backup_file() { :; }
    atomic_write() {
      local target="$1"
      local mode="${2:-}"
      cat > "$target"
      [[ -n "$mode" ]] && chmod "$mode" "$target"
    }

    tmp_env=$(mktemp)
    tmp_bin_dir=$(mktemp -d)
    trap "rm -f \"$tmp_env\"; rm -rf \"$tmp_bin_dir\"" EXIT

    cat > "${tmp_bin_dir}/xray" <<EOF
#!/usr/bin/env bash
echo "Xray 1.8.0"
EOF
    chmod +x "${tmp_bin_dir}/xray"

    XRAY_BIN="${tmp_bin_dir}/xray"
    XRAY_ENV="$tmp_env"
    DOMAIN_TIER="tier_global_ms10"
    NUM_CONFIGS=3
    START_PORT=24440
    SPIDER_MODE="true"
    TRANSPORT="http2"
    PROGRESS_MODE="plain"
    SERVER_IP="127.0.0.1"
    SERVER_IP6="::1"

    save_environment
    grep -q "^DOMAIN_TIER=" "$XRAY_ENV"
    grep -q "^XRAY_DOMAIN_TIER=" "$XRAY_ENV"
    grep -q "^NUM_CONFIGS=" "$XRAY_ENV"
    grep -q "^XRAY_NUM_CONFIGS=" "$XRAY_ENV"
    grep -q "^START_PORT=" "$XRAY_ENV"
    grep -q "^XRAY_START_PORT=" "$XRAY_ENV"
    grep -q "^SPIDER_MODE=" "$XRAY_ENV"
    grep -q "^XRAY_SPIDER_MODE=" "$XRAY_ENV"
    grep -q "^PROGRESS_MODE=" "$XRAY_ENV"
    grep -q "^XRAY_PROGRESS_MODE=" "$XRAY_ENV"
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "load_config_file keeps legacy key compatibility" {
    run bash -c '
    source ./lib.sh

    cfg=$(mktemp)
    trap "rm -f \"$cfg\"" EXIT
    cat > "$cfg" <<EOF
DOMAIN_TIER=tier_global_ms10
NUM_CONFIGS="4"
SPIDER_MODE=true
START_PORT=25555
HEALTH_LOG="/var/log/xray/custom-health.log"
GH_PROXY_BASE="https://ghproxy.com/https://github.com"
PROGRESS_MODE=plain
UNKNOWN_KEY=ignored
EOF

    DOMAIN_TIER=tier_ru
    NUM_CONFIGS=1
    SPIDER_MODE=false
    START_PORT=443
    HEALTH_LOG=""
    GH_PROXY_BASE=""
    PROGRESS_MODE="auto"

    load_config_file "$cfg"
    [[ "$DOMAIN_TIER" == "tier_global_ms10" ]]
    [[ "$NUM_CONFIGS" == "4" ]]
    [[ "$SPIDER_MODE" == "true" ]]
    [[ "$START_PORT" == "25555" ]]
    [[ "$HEALTH_LOG" == "/var/log/xray/custom-health.log" ]]
    [[ "$GH_PROXY_BASE" == "https://ghproxy.com/https://github.com" ]]
    [[ "$PROGRESS_MODE" == "plain" ]]
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "load_config_file strips matching single quotes" {
    run bash -c "
    source ./lib.sh

    cfg=\$(mktemp)
    trap 'rm -f \"\$cfg\"' EXIT
    cat > \"\$cfg\" <<'EOF'
PRIMARY_PIN_DOMAIN='example.com'
HEALTH_LOG='/var/log/xray/custom-health.log'
EOF

    PRIMARY_PIN_DOMAIN=''
    HEALTH_LOG=''

    load_config_file \"\$cfg\"
    [[ \"\$PRIMARY_PIN_DOMAIN\" == 'example.com' ]]
    [[ \"\$HEALTH_LOG\" == '/var/log/xray/custom-health.log' ]]
    echo ok
  "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "build_vless_query_params URL-encodes special characters" {
    run bash -c '
    source ./lib.sh
    source ./config.sh
    params=$(build_vless_query_params "exa&mple.com" "fire fox" "abc+123" "s#id" "grpc" "svc/one?x=1")
    [[ "$params" == *"sni=exa%26mple.com"* ]]
    [[ "$params" == *"fp=fire%20fox"* ]]
    [[ "$params" == *"pbk=abc%2B123"* ]]
    [[ "$params" == *"sid=s%23id"* ]]
    [[ "$params" == *"serviceName=svc%2Fone%3Fx%3D1"* ]]
    [[ "$params" != *"sni=exa&mple.com"* ]]
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "generate_uuid falls back when uuidgen output is invalid" {
    run bash -c '
    source ./lib.sh
    source ./modules/config/domain_planner.sh
    uuidgen() { echo "broken"; return 0; }
    uuid=$(generate_uuid)
    [[ "$uuid" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]
    [[ "${uuid:14:1}" == "4" ]]
    [[ "${uuid:19:1}" =~ ^[89aAbB]$ ]]
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "service unit helpers reject unsafe systemd values" {
    run bash -c '
    source ./lib.sh
    source ./service.sh
    sanitize_systemd_value cleaned $'\''xray\r\n\t'\''
    sanitize_systemd_value_into cleaned_into $'\''xray\r\n\t'\''
    [[ "$cleaned" == "xray" ]]
    [[ "$cleaned_into" == "xray" ]]
    validate_systemd_path_value "/usr/local/bin/xray" "XRAY_BIN"
    if validate_systemd_path_value "xray;/bin/sh" "XRAY_BIN"; then
      exit 1
    fi
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}

@test "create_systemd_service handles missing systemd dir in non-systemd mode" {
    run bash -c '
    grep -q '\''local systemd_dir="/etc/systemd/system"'\'' ./service.sh
    grep -q '\''install -d -m 755 "\$systemd_dir"'\'' ./service.sh
    grep -q '\''создание unit-файла пропущено'\'' ./service.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "service systemd flows degrade on nonfatal systemctl errors" {
    run bash -c '
    grep -q '\''is_nonfatal_systemctl_error()'\'' ./service.sh
    grep -q '\''local daemon_reload_rc=0'\'' ./service.sh
    grep -q '\''local enable_rc=0'\'' ./service.sh
    grep -q '\''local restart_rc=0'\'' ./service.sh
    grep -q '\''if ((daemon_reload_rc != 0)); then'\'' ./service.sh
    grep -q '\''if ((enable_rc != 0)); then'\'' ./service.sh
    grep -q '\''if ((restart_rc != 0)); then'\'' ./service.sh
    grep -q '\''SYSTEMD_MANAGEMENT_DISABLED=true'\'' ./service.sh
    grep -q '\''systemd недоступен для активации unit; продолжаем без enable'\'' ./service.sh
    grep -q '\''systemd недоступен для restart xray; запуск сервисов пропущен'\'' ./service.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "systemd_running disables service management in isolated root contexts" {
    run bash -c '
    grep -q '\''running_in_isolated_root_context'\'' ./lib.sh
    grep -q '\''/proc/1/root/'\'' ./lib.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "atomic_write allows canonical systemd unit directories" {
    run bash -c '
    grep -q '\''"/usr/lib/systemd"'\'' ./lib.sh
    grep -q '\''"/lib/systemd"'\'' ./lib.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "status_flow verbose degrades gracefully when free/df are unavailable" {
    run bash -c '
    source ./lib.sh
    source ./service.sh
    grep -q '\''mem_info=$(free -m .*|| true)'\'' ./service.sh
    grep -q '\''disk_info=$(df -h / .*|| true)'\'' ./service.sh
    grep -q '\''Память: n/a'\'' ./service.sh
    grep -q '\''Диск:   n/a'\'' ./service.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "release workflow avoids curl pipe sh and unpinned release action" {
    run bash -c '
    grep -q '\''gh release create'\'' ./.github/workflows/release.yml
    ! grep -Eq '\''curl[[:space:]]+-sSfL[[:space:]]+https://raw.githubusercontent.com/anchore/syft/main/install.sh[[:space:]]*\\|[[:space:]]*sudo[[:space:]]+sh'\'' ./.github/workflows/release.yml
    ! grep -q '\''softprops/action-gh-release'\'' ./.github/workflows/release.yml
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "release script pushes current branch instead of hardcoded main" {
    run bash -c '
    grep -q '\''git push origin "\$push_branch"'\'' ./scripts/release.sh
    ! grep -q '\''git push origin main'\'' ./scripts/release.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "release script uses portable replacements instead of sed -i" {
    run bash -c '
    grep -q '\''replace_with_sed()'\'' ./scripts/release.sh
    ! grep -q '\''sed -i'\'' ./scripts/release.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "os matrix workflow tracks supported fedora image" {
    run bash -c '
    grep -q '\''name: fedora-41'\'' ./.github/workflows/os-matrix-smoke.yml
    grep -q '\''image: fedora:41'\'' ./.github/workflows/os-matrix-smoke.yml
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "os matrix workflow includes almalinux image" {
    run bash -c '
    grep -q '\''name: almalinux-9'\'' ./.github/workflows/os-matrix-smoke.yml
    grep -q '\''image: almalinux:9'\'' ./.github/workflows/os-matrix-smoke.yml
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "ci workflow includes stability and audit gates" {
    run bash -c '
    grep -q '\''name: stability smoke (double bats)'\'' ./.github/workflows/ci.yml
    grep -q '\''bash scripts/check-workflow-pinning.sh'\'' ./.github/workflows/ci.yml
    grep -q '\''bash scripts/check-security-baseline.sh'\'' ./.github/workflows/ci.yml
    grep -q '\''bash scripts/check-docs-commands.sh'\'' ./.github/workflows/ci.yml
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "audit scripts exist and are wired into lint pipeline" {
    run bash -c '
    test -f ./scripts/check-workflow-pinning.sh
    test -f ./scripts/check-security-baseline.sh
    test -f ./scripts/check-docs-commands.sh
    grep -q '\''check-workflow-pinning.sh'\'' ./tests/lint.sh
    grep -q '\''check-security-baseline.sh'\'' ./tests/lint.sh
    grep -q '\''check-docs-commands.sh'\'' ./tests/lint.sh
    grep -q '\''check-workflow-pinning.sh'\'' ./Makefile
    grep -q '\''check-security-baseline.sh'\'' ./Makefile
    grep -q '\''check-docs-commands.sh'\'' ./Makefile
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "dockerfile runs non-root and defines healthcheck" {
    run bash -c '
    grep -q '\''^FROM debian:bookworm-20260112-slim$'\'' ./Dockerfile
    grep -q '\''^HEALTHCHECK '\'' ./Dockerfile
    grep -q '\''^USER xray$'\'' ./Dockerfile
    grep -q '\''logrotate'\'' ./Dockerfile
    grep -q '\''unzip'\'' ./Dockerfile
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "uninstall_flow exits early when managed artifacts are already absent" {
    run bash -c '
    grep -q '\''if ! uninstall_has_managed_artifacts; then'\'' ./install.sh
    grep -q '\''управляемые артефакты не обнаружены'\'' ./install.sh
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}
