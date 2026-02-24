#!/usr/bin/env bats

@test "setup_health_monitoring handles unset PORTS_V6 when HAS_IPV6=true" {
    run bash -eo pipefail -c '
    source ./lib.sh
    source ./health.sh

    tmp_dir=$(mktemp -d)
    trap "rm -rf \"$tmp_dir\"" EXIT
    HEALTH_SCRIPT_OUT="$tmp_dir/xray-health.sh"
    HEALTH_SERVICE_OUT="$tmp_dir/xray-health.service"
    HEALTH_TIMER_OUT="$tmp_dir/xray-health.timer"

    log() { :; }
    backup_file() { :; }
    systemctl_available() { return 0; }
    systemd_running() { return 0; }
    systemctl() { return 0; }
    atomic_write() {
      local target="$1"
      local mode="${2:-}"
      local out="$target"
      case "$target" in
        /usr/local/bin/xray-health.sh) out="$HEALTH_SCRIPT_OUT" ;;
        /etc/systemd/system/xray-health.service) out="$HEALTH_SERVICE_OUT" ;;
        /etc/systemd/system/xray-health.timer) out="$HEALTH_TIMER_OUT" ;;
      esac
      cat > "$out"
      [[ -n "$mode" ]] && chmod "$mode" "$out"
    }

    PORTS=(443 444)
    HAS_IPV6=true
    unset -v PORTS_V6
    LOG_RETENTION_DAYS=30
    LOG_MAX_SIZE_MB=10
    HEALTH_CHECK_INTERVAL=120
    DOMAIN_HEALTH_FILE=""
    REALITY_TEST_PORTS="443,8443"
    DOMAIN_HEALTH_PROBE_TIMEOUT=2
    DOMAIN_HEALTH_RATE_LIMIT_MS=250
    DOMAIN_HEALTH_MAX_PROBES=20

    setup_health_monitoring
    grep -q "^PORTS_V6=()$" "$HEALTH_SCRIPT_OUT"
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "setup_health_monitoring applies safe fallback values for invalid inputs" {
    run bash -eo pipefail -c '
    source ./lib.sh
    source ./health.sh

    tmp_dir=$(mktemp -d)
    trap "rm -rf \"$tmp_dir\"" EXIT
    HEALTH_SCRIPT_OUT="$tmp_dir/xray-health.sh"
    HEALTH_SERVICE_OUT="$tmp_dir/xray-health.service"
    HEALTH_TIMER_OUT="$tmp_dir/xray-health.timer"

    log() { :; }
    backup_file() { :; }
    systemctl_available() { return 0; }
    systemd_running() { return 0; }
    systemctl() { return 0; }
    atomic_write() {
      local target="$1"
      local mode="${2:-}"
      local out="$target"
      case "$target" in
        /usr/local/bin/xray-health.sh) out="$HEALTH_SCRIPT_OUT" ;;
        /etc/systemd/system/xray-health.service) out="$HEALTH_SERVICE_OUT" ;;
        /etc/systemd/system/xray-health.timer) out="$HEALTH_TIMER_OUT" ;;
      esac
      cat > "$out"
      [[ -n "$mode" ]] && chmod "$mode" "$out"
    }

    PORTS=(443)
    HAS_IPV6=false
    LOG_RETENTION_DAYS="broken"
    LOG_MAX_SIZE_MB="0"
    HEALTH_CHECK_INTERVAL="100000"
    DOMAIN_HEALTH_FILE=""
    REALITY_TEST_PORTS="@@@"
    DOMAIN_HEALTH_PROBE_TIMEOUT=99
    DOMAIN_HEALTH_RATE_LIMIT_MS=-1
    DOMAIN_HEALTH_MAX_PROBES=999

    setup_health_monitoring
    grep -q "^set -euo pipefail$" "$HEALTH_SCRIPT_OUT"
    grep -q "^LOG_RETENTION_DAYS=30$" "$HEALTH_SCRIPT_OUT"
    grep -q "^LOG_MAX_SIZE_BYTES=10485760$" "$HEALTH_SCRIPT_OUT"
    grep -q "^DOMAIN_HEALTH_PROBE_TIMEOUT=2$" "$HEALTH_SCRIPT_OUT"
    grep -q "^DOMAIN_HEALTH_RATE_LIMIT_MS=250$" "$HEALTH_SCRIPT_OUT"
    grep -q "^DOMAIN_HEALTH_MAX_PROBES=20$" "$HEALTH_SCRIPT_OUT"
    ! grep -q "split_list" "$HEALTH_SCRIPT_OUT"
    grep -q "^OnUnitActiveSec=120s$" "$HEALTH_TIMER_OUT"
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "setup_health_monitoring uses configured health log paths" {
    run bash -eo pipefail -c '
    source ./lib.sh
    source ./health.sh

    tmp_dir=$(mktemp -d)
    trap "rm -rf \"$tmp_dir\"" EXIT
    HEALTH_SCRIPT_OUT="$tmp_dir/xray-health.sh"
    HEALTH_SERVICE_OUT="$tmp_dir/xray-health.service"
    HEALTH_TIMER_OUT="$tmp_dir/xray-health.timer"

    log() { :; }
    backup_file() { :; }
    systemctl_available() { return 0; }
    systemd_running() { return 0; }
    systemctl() { return 0; }
    atomic_write() {
      local target="$1"
      local mode="${2:-}"
      local out="$target"
      case "$target" in
        /usr/local/bin/xray-health.sh) out="$HEALTH_SCRIPT_OUT" ;;
        /etc/systemd/system/xray-health.service) out="$HEALTH_SERVICE_OUT" ;;
        /etc/systemd/system/xray-health.timer) out="$HEALTH_TIMER_OUT" ;;
      esac
      cat > "$out"
      [[ -n "$mode" ]] && chmod "$mode" "$out"
    }

    PORTS=(443)
    HAS_IPV6=false
    LOG_RETENTION_DAYS=30
    LOG_MAX_SIZE_MB=10
    HEALTH_CHECK_INTERVAL=120
    DOMAIN_HEALTH_FILE="/var/lib/xray/domain-health.json"
    REALITY_TEST_PORTS="443,8443"
    DOMAIN_HEALTH_PROBE_TIMEOUT=2
    DOMAIN_HEALTH_RATE_LIMIT_MS=250
    DOMAIN_HEALTH_MAX_PROBES=20
    XRAY_LOGS="/opt/xray/log"
    HEALTH_LOG="/opt/xray/log/custom-health.log"

    setup_health_monitoring
    grep -q "^LOG=/opt/xray/log/custom-health.log$" "$HEALTH_SCRIPT_OUT"
    grep -q "^LOG_DIR=/opt/xray/log$" "$HEALTH_SCRIPT_OUT"
    grep -Fq "find \"\$LOG_DIR\" -maxdepth 1 -name \"*.log\"" "$HEALTH_SCRIPT_OUT"
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "setup_health_monitoring embeds runtime xray config path into health script" {
    run bash -eo pipefail -c '
    source ./lib.sh
    source ./health.sh

    tmp_dir=$(mktemp -d)
    trap "rm -rf \"$tmp_dir\"" EXIT
    HEALTH_SCRIPT_OUT="$tmp_dir/xray-health.sh"
    HEALTH_SERVICE_OUT="$tmp_dir/xray-health.service"
    HEALTH_TIMER_OUT="$tmp_dir/xray-health.timer"

    log() { :; }
    backup_file() { :; }
    systemctl_available() { return 0; }
    systemd_running() { return 0; }
    systemctl() { return 0; }
    atomic_write() {
      local target="$1"
      local mode="${2:-}"
      local out="$target"
      case "$target" in
        /usr/local/bin/xray-health.sh) out="$HEALTH_SCRIPT_OUT" ;;
        /etc/systemd/system/xray-health.service) out="$HEALTH_SERVICE_OUT" ;;
        /etc/systemd/system/xray-health.timer) out="$HEALTH_TIMER_OUT" ;;
      esac
      cat > "$out"
      [[ -n "$mode" ]] && chmod "$mode" "$out"
    }

    PORTS=(443)
    HAS_IPV6=false
    LOG_RETENTION_DAYS=30
    LOG_MAX_SIZE_MB=10
    HEALTH_CHECK_INTERVAL=120
    DOMAIN_HEALTH_FILE="/var/lib/xray/domain-health.json"
    REALITY_TEST_PORTS="443,8443"
    DOMAIN_HEALTH_PROBE_TIMEOUT=2
    DOMAIN_HEALTH_RATE_LIMIT_MS=250
    DOMAIN_HEALTH_MAX_PROBES=20
    XRAY_CONFIG="/opt/xray/etc/custom-config.json"

    setup_health_monitoring
    grep -q "^XRAY_CONFIG_PATH=/opt/xray/etc/custom-config.json$" "$HEALTH_SCRIPT_OUT"
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "diagnose writes collected output to DIAG_LOG" {
    run bash -eo pipefail -c '
    source ./lib.sh
    source ./health.sh

    tmp_log=$(mktemp)
    trap "rm -f \"$tmp_log\"" EXIT

    DIAG_LOG="$tmp_log"
    XRAY_BIN="/nonexistent/xray"
    XRAY_CONFIG="/nonexistent/config.json"

    log() { :; }
    systemctl() { return 0; }
    journalctl() { return 0; }
    ss() { return 0; }
    df() { return 0; }
    free() { return 0; }

    diagnose
    test -s "$DIAG_LOG"
    grep -q "===== CONTEXT =====" "$DIAG_LOG"
    grep -q "===== XRAY =====" "$DIAG_LOG"
    echo "ok"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}
