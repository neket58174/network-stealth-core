#!/usr/bin/env bash
# shellcheck shell=bash

GLOBAL_CONTRACT_MODULE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../lib" && pwd)/globals_contract.sh"
if [[ ! -f "$GLOBAL_CONTRACT_MODULE" && -n "${XRAY_DATA_DIR:-}" ]]; then
    GLOBAL_CONTRACT_MODULE="$XRAY_DATA_DIR/modules/lib/globals_contract.sh"
fi
if [[ ! -f "$GLOBAL_CONTRACT_MODULE" ]]; then
    echo "ERROR: не найден модуль global contract: $GLOBAL_CONTRACT_MODULE" >&2
    exit 1
fi
# shellcheck source=modules/lib/globals_contract.sh
source "$GLOBAL_CONTRACT_MODULE"

detect_distro() {
    log STEP "Определяем операционную систему..."

    if [[ ! -f /etc/os-release ]]; then
        log ERROR "Не удалось определить дистрибутив"
        exit 1
    fi

    # shellcheck source=/etc/os-release
    # shellcheck disable=SC1091
    . /etc/os-release

    case "$ID" in
        ubuntu | debian)
            if [[ "$ID" == "ubuntu" ]] && version_lt "$VERSION_ID" "20.04"; then
                log WARN "Рекомендуется Ubuntu 20.04+"
            fi
            PKG_TYPE="deb"
            PKG_MANAGER="apt-get"
            PKG_UPDATE="apt-get update -qq"
            PKG_INSTALL="apt-get install -y -qq"
            export DEBIAN_FRONTEND=noninteractive
            ;;
        fedora)
            PKG_TYPE="rpm"
            PKG_MANAGER="dnf"
            PKG_UPDATE="dnf -y makecache"
            PKG_INSTALL="dnf -y install"
            ;;
        centos | rhel | almalinux | rocky)
            PKG_TYPE="rpm"
            if command -v dnf > /dev/null 2>&1; then
                PKG_MANAGER="dnf"
                PKG_UPDATE="dnf -y makecache"
                PKG_INSTALL="dnf -y install"
            elif command -v yum > /dev/null 2>&1; then
                PKG_MANAGER="yum"
                PKG_UPDATE="yum -y makecache"
                PKG_INSTALL="yum -y install"
            else
                log ERROR "Не найден пакетный менеджер dnf/yum"
                exit 1
            fi
            ;;
        *)
            if [[ "${ID_LIKE:-}" == *"debian"* ]]; then
                PKG_TYPE="deb"
                PKG_MANAGER="apt-get"
                PKG_UPDATE="apt-get update -qq"
                PKG_INSTALL="apt-get install -y -qq"
                export DEBIAN_FRONTEND=noninteractive
            elif [[ "${ID_LIKE:-}" == *"rhel"* || "${ID_LIKE:-}" == *"fedora"* ]]; then
                PKG_TYPE="rpm"
                if command -v dnf > /dev/null 2>&1; then
                    PKG_MANAGER="dnf"
                    PKG_UPDATE="dnf -y makecache"
                    PKG_INSTALL="dnf -y install"
                elif command -v yum > /dev/null 2>&1; then
                    PKG_MANAGER="yum"
                    PKG_UPDATE="yum -y makecache"
                    PKG_INSTALL="yum -y install"
                else
                    log ERROR "Не найден пакетный менеджер dnf/yum"
                    exit 1
                fi
            else
                log ERROR "Поддерживаются только Ubuntu/Debian/Fedora/RHEL-based (обнаружено: $ID)"
                exit 1
            fi
            ;;
    esac

    log OK "Система: ${BOLD}$PRETTY_NAME${NC}"
    log INFO "Пакетный менеджер: ${PKG_MANAGER}"
}

check_disk_space() {
    log STEP "Проверяем свободное место на диске..."

    local min_mb=100 # минимум 100 MB для установки
    local -a check_dirs=(/var /etc /usr /tmp)
    local dir avail_mb

    for dir in "${check_dirs[@]}"; do
        [[ -d "$dir" ]] || continue
        avail_mb=$(df -m "$dir" 2> /dev/null | awk 'NR==2 {print $4}')
        if [[ -n "$avail_mb" && "$avail_mb" =~ ^[0-9]+$ ]] && ((avail_mb < min_mb)); then
            log ERROR "Недостаточно места в ${dir}: ${avail_mb}MB (нужно минимум ${min_mb}MB)"
            hint "Освободите место: apt-get clean, docker system prune, или удалите ненужные файлы"
            exit 1
        fi
    done

    log OK "Свободного места достаточно"
}

install_dependencies() {
    log STEP "Проверяем зависимости..."

    local deps=()
    local missing=()

    if [[ "${PKG_TYPE:-}" == "rpm" ]]; then
        deps=(curl jq openssl unzip ca-certificates util-linux iproute procps-ng libcap logrotate policycoreutils)
        for dep in "${deps[@]}"; do
            if [[ "$dep" == "curl" ]]; then
                if command -v curl > /dev/null 2>&1 || rpm -q curl-minimal > /dev/null 2>&1; then
                    continue
                fi
            fi
            if ! rpm -q "$dep" > /dev/null 2>&1; then
                missing+=("$dep")
            fi
        done
    else
        deps=(curl jq openssl unzip ca-certificates uuid-runtime iproute2 libcap2-bin logrotate procps)
        for dep in "${deps[@]}"; do
            if ! dpkg -s "$dep" > /dev/null 2>&1; then
                missing+=("$dep")
            fi
        done
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log INFO "Устанавливаем: ${missing[*]}"
        # shellcheck disable=SC2086 # PKG_UPDATE/PKG_INSTALL contain intentional word splitting
        $PKG_UPDATE > /dev/null 2>&1 || true
        # shellcheck disable=SC2086
        $PKG_INSTALL "${missing[@]}" > /dev/null 2>&1 || {
            log ERROR "Не удалось установить пакеты: ${missing[*]}"
            exit 1
        }
    fi

    log OK "Все зависимости установлены"
}

install_self() {
    log STEP "Устанавливаем скрипт управления..."

    if [[ -n "$XRAY_DATA_DIR" ]]; then
        mkdir -p "$XRAY_DATA_DIR"
        if [[ -d "$SCRIPT_DIR/modules" ]]; then
            local modules_tmp modules_backup
            modules_tmp=$(mktemp -d "${XRAY_DATA_DIR}/.modules.new.XXXXXX")
            if ! cp -a "$SCRIPT_DIR/modules/." "$modules_tmp/"; then
                rm -rf "$modules_tmp"
                log ERROR "Не удалось скопировать modules в временную директорию"
                exit 1
            fi

            modules_backup=""
            if [[ -d "$XRAY_DATA_DIR/modules" ]]; then
                modules_backup=$(mktemp -d "${XRAY_DATA_DIR}/.modules.backup.XXXXXX")
                if ! mv "$XRAY_DATA_DIR/modules" "$modules_backup/modules"; then
                    rm -rf "$modules_tmp" "$modules_backup"
                    log ERROR "Не удалось подготовить backup текущих modules"
                    exit 1
                fi
            fi

            if ! mv "$modules_tmp" "$XRAY_DATA_DIR/modules"; then
                rm -rf "$XRAY_DATA_DIR/modules" "$modules_tmp"
                if [[ -n "$modules_backup" && -d "$modules_backup/modules" ]]; then
                    mv "$modules_backup/modules" "$XRAY_DATA_DIR/modules" || true
                fi
                rm -rf "$modules_backup"
                log ERROR "Не удалось обновить modules в $XRAY_DATA_DIR"
                exit 1
            fi
            rm -rf "$modules_backup"
        fi
        local f
        for f in domains.tiers sni_pools.map grpc_services.map lib.sh install.sh config.sh service.sh health.sh export.sh; do
            local src_path="$SCRIPT_DIR/$f"
            local dest_path="$XRAY_DATA_DIR/$f"
            if [[ -f "$src_path" && "$src_path" != "$dest_path" ]]; then
                cp -a "$src_path" "$dest_path"
            fi
        done
        log OK "Данные установлены в $XRAY_DATA_DIR"
    fi

    local src
    src=$(readlink -f "$0" 2> /dev/null || realpath "$0" 2> /dev/null || echo "$0")
    if [[ ! -f "$src" ]]; then
        log WARN "Не удалось определить путь скрипта (curl pipe); используйте $XRAY_DATA_DIR/xray-reality.sh"
        if [[ -f "$SCRIPT_DIR/xray-reality.sh" ]]; then
            backup_file "$XRAY_SCRIPT_PATH"
            local tmp
            tmp=$(mktemp "${XRAY_SCRIPT_PATH}.tmp.XXXXXX")
            cp -a "$SCRIPT_DIR/xray-reality.sh" "$tmp"
            mv "$tmp" "$XRAY_SCRIPT_PATH"
            chmod +x "$XRAY_SCRIPT_PATH"
            log OK "Скрипт установлен: $XRAY_SCRIPT_PATH"
        fi
        return 0
    fi
    backup_file "$XRAY_SCRIPT_PATH"
    local tmp
    tmp=$(mktemp "${XRAY_SCRIPT_PATH}.tmp.XXXXXX")
    cp -a "$src" "$tmp"
    mv "$tmp" "$XRAY_SCRIPT_PATH"
    chmod +x "$XRAY_SCRIPT_PATH"
    log OK "Скрипт установлен: $XRAY_SCRIPT_PATH"
}

setup_logrotate() {
    log STEP "Настраиваем logrotate..."
    local safe_logs_dir safe_health_log safe_install_log safe_update_log safe_diag_log safe_repair_log
    safe_logs_dir=$(printf '%s' "${XRAY_LOGS:-/var/log/xray}" | tr -d '\000-\037\177')
    if [[ -z "$safe_logs_dir" || "$safe_logs_dir" != /* ]]; then
        safe_logs_dir="/var/log/xray"
    fi
    safe_health_log=$(printf '%s' "${HEALTH_LOG:-${safe_logs_dir%/}/xray-health.log}" | tr -d '\000-\037\177')
    if [[ -z "$safe_health_log" || "$safe_health_log" != /* ]]; then
        safe_health_log="${safe_logs_dir%/}/xray-health.log"
    fi
    safe_install_log=$(printf '%s' "${INSTALL_LOG:-/var/log/xray-install.log}" | tr -d '\000-\037\177')
    safe_update_log=$(printf '%s' "${UPDATE_LOG:-/var/log/xray-update.log}" | tr -d '\000-\037\177')
    safe_diag_log=$(printf '%s' "${DIAG_LOG:-/var/log/xray-diagnose.log}" | tr -d '\000-\037\177')
    safe_repair_log="/var/log/xray-repair.log"

    backup_file /etc/logrotate.d/xray
    atomic_write /etc/logrotate.d/xray 0644 << EOF
${safe_logs_dir%/}/*.log ${safe_health_log} ${safe_install_log} ${safe_update_log} ${safe_diag_log} ${safe_repair_log} {
    daily
    rotate 14
    missingok
    notifempty
    compress
    delaycompress
    copytruncate
    create 0640 root root
}
EOF
    log OK "logrotate настроен"
}

setup_auto_update() {
    log STEP "Настраиваем авто-обновления..."

    if ! systemctl_available; then
        log WARN "systemctl не найден; авто-обновления пропущены"
        return 0
    fi

    if [[ "$AUTO_UPDATE_ONCALENDAR" == *$'\n'* ]] || [[ "$AUTO_UPDATE_ONCALENDAR" =~ [[:cntrl:]] ]]; then
        log ERROR "AUTO_UPDATE_ONCALENDAR содержит недопустимые символы"
        return 1
    fi
    if [[ "$AUTO_UPDATE_RANDOM_DELAY" == *$'\n'* ]] || [[ "$AUTO_UPDATE_RANDOM_DELAY" =~ [[:cntrl:]] ]]; then
        log ERROR "AUTO_UPDATE_RANDOM_DELAY содержит недопустимые символы"
        return 1
    fi
    if ! validate_safe_executable_path "XRAY_SCRIPT_PATH" "$XRAY_SCRIPT_PATH"; then
        return 1
    fi
    if ! validate_safe_executable_path "XRAY_UPDATE_SCRIPT" "$XRAY_UPDATE_SCRIPT"; then
        return 1
    fi

    backup_file "$XRAY_UPDATE_SCRIPT"
    {
        # shellcheck disable=SC2016 # Intentional: vars expand at runtime, not build time
        cat << 'UPDATEEOF'
set -euo pipefail

XRAY_BIN_PATH="${XRAY_BIN_PATH:-}"
if [[ -z "$XRAY_BIN_PATH" ]]; then
    XRAY_BIN_PATH="$(command -v xray 2>/dev/null || echo /usr/local/bin/xray)"
fi
GEO_DIR="${XRAY_GEO_DIR:-$(dirname "$XRAY_BIN_PATH")}"
GEOIP_URL="${XRAY_GEOIP_URL:-https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat}"
GEOSITE_URL="${XRAY_GEOSITE_URL:-https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat}"
GEOIP_SHA256_URL="${XRAY_GEOIP_SHA256_URL:-https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat.sha256sum}"
GEOSITE_SHA256_URL="${XRAY_GEOSITE_SHA256_URL:-https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat.sha256sum}"
GEO_VERIFY_HASH="${GEO_VERIFY_HASH:-true}"
GEO_VERIFY_STRICT="${GEO_VERIFY_STRICT:-false}"

mkdir -p "$GEO_DIR"

download_geo_with_verify() {
    local name="$1"
    local url="$2"
    local sha_url="$3"
    local dest="$GEO_DIR/$name"
    local tmp_file
    tmp_file=$(mktemp)
    local tmp_sha
    tmp_sha=$(mktemp)

    echo "Downloading $name..."
    if [[ "$url" != https://* ]] || [[ "$sha_url" != https://* ]]; then
        echo "WARN: Insecure URL blocked for $name" >&2
        rm -f "$tmp_file" "$tmp_sha"
        return 1
    fi

    if ! curl --fail --show-error --silent --location \
        --proto '=https' --tlsv1.2 \
        --retry 3 --retry-delay 1 -o "$tmp_file" "$url"; then
        echo "WARN: Failed to download $name" >&2
        rm -f "$tmp_file" "$tmp_sha"
        return 1
    fi

    if [[ "$GEO_VERIFY_HASH" == "true" ]]; then
        echo "Verifying $name checksum..."
        if ! curl --fail --show-error --silent --location \
            --proto '=https' --tlsv1.2 \
            --retry 3 --retry-delay 1 -o "$tmp_sha" "$sha_url"; then
            if [[ "$GEO_VERIFY_STRICT" == "true" ]]; then
                echo "ERROR: Failed to download $name checksum and GEO_VERIFY_STRICT=true" >&2
                rm -f "$tmp_file" "$tmp_sha"
                return 1
            fi
            echo "WARN: Failed to download $name checksum, skipping verification" >&2
        else
            local expected_hash
            expected_hash=$(sed -n '1{s/[[:space:]].*$//;p;}' "$tmp_sha")
            local actual_hash
            actual_hash=$(sha256sum "$tmp_file" | awk '{print $1}')

            if [[ "$expected_hash" != "$actual_hash" ]]; then
                echo "ERROR: $name checksum mismatch!" >&2
                echo "  Expected: $expected_hash" >&2
                echo "  Actual:   $actual_hash" >&2
                rm -f "$tmp_file" "$tmp_sha"
                return 1
            fi
            echo "$name checksum verified OK"
        fi
    fi

    mv -f "$tmp_file" "$dest"
    chmod 644 "$dest"
    rm -f "$tmp_sha"
    echo "$name updated successfully"
    return 0
}

echo "Updating Geo files..."
if [[ "$GEO_VERIFY_STRICT" == "true" ]]; then
    download_geo_with_verify "geoip.dat" "$GEOIP_URL" "$GEOIP_SHA256_URL"
    download_geo_with_verify "geosite.dat" "$GEOSITE_URL" "$GEOSITE_SHA256_URL"
else
    download_geo_with_verify "geoip.dat" "$GEOIP_URL" "$GEOIP_SHA256_URL" || true
    download_geo_with_verify "geosite.dat" "$GEOSITE_URL" "$GEOSITE_SHA256_URL" || true
fi
UPDATEEOF
        printf 'exec %q update --non-interactive\n' "$XRAY_SCRIPT_PATH"
    } | atomic_write "$XRAY_UPDATE_SCRIPT" 0755

    local _safe_update_script
    _safe_update_script=$(realpath -m "$XRAY_UPDATE_SCRIPT" 2> /dev/null || echo "$XRAY_UPDATE_SCRIPT")

    backup_file /etc/systemd/system/xray-auto-update.service
    atomic_write /etc/systemd/system/xray-auto-update.service 0644 << EOF
[Unit]
Description=Xray Auto Update
After=network.target

[Service]
Type=oneshot
ExecStart=${_safe_update_script}
EOF

    backup_file /etc/systemd/system/xray-auto-update.timer
    atomic_write /etc/systemd/system/xray-auto-update.timer 0644 << EOF
[Unit]
Description=Xray Auto Update Time

[Timer]
OnCalendar=${AUTO_UPDATE_ONCALENDAR}
RandomizedDelaySec=${AUTO_UPDATE_RANDOM_DELAY}
Persistent=true

[Install]
WantedBy=timers.target
EOF

    if ! systemd_running; then
        log WARN "systemd не запущен; авто-обновления пропущены"
        return 0
    fi
    if ! systemctl daemon-reload > /dev/null 2>&1; then
        log WARN "systemd недоступен; авто-обновления пропущены"
        return 0
    fi
    if [[ "$AUTO_UPDATE" == true ]]; then
        if systemctl enable --now xray-auto-update.timer > /dev/null 2>&1; then
            log OK "Авто-обновления включены (${AUTO_UPDATE_ONCALENDAR})"
        else
            log WARN "Не удалось включить авто-обновления"
        fi
    else
        systemctl disable --now xray-auto-update.timer > /dev/null 2>&1 || true
        log INFO "Авто-обновления отключены"
    fi
}
