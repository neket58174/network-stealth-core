#!/usr/bin/env bash
# shellcheck shell=bash

: "${XRAY_KEYS:=/etc/xray/private/keys}"
: "${XRAY_CONFIG:=/etc/xray/config.json}"
: "${XRAY_ENV:=/etc/xray-reality/config.env}"
: "${SERVER_IP:=}"
: "${SERVER_IP6:=}"
: "${ALLOW_NO_SYSTEMD:=false}"
: "${INSTALL_START_TIME:=}"
: "${BOLD:=}"
: "${DIM:=}"
: "${GREEN:=}"
: "${YELLOW:=}"
: "${NC:=}"

show_install_result() {
    local duration=""
    if [[ -n "${INSTALL_START_TIME:-}" ]]; then
        local elapsed=$(($(date +%s) - INSTALL_START_TIME))
        duration=" за ${elapsed}s"
    fi

    echo ""
    local title="УСТАНОВКА УСПЕШНО ЗАВЕРШЕНА${duration}"
    local box_width box_top box_line box_bottom
    box_width=$(ui_box_width_for_lines 60 90 "$title")
    box_top=$(ui_box_border_string top "$box_width")
    box_line=$(ui_box_line_string "$title" "$box_width")
    box_bottom=$(ui_box_border_string bottom "$box_width")
    echo -e "${BOLD}${GREEN}${box_top}${NC}"
    echo -e "${BOLD}${GREEN}${box_line}${NC}"
    echo -e "${BOLD}${GREEN}${box_bottom}${NC}"
    echo ""

    print_install_runtime_mode_notice
    echo ""

    local client_file="${XRAY_KEYS}/clients.txt"
    local client_links_file="${XRAY_KEYS}/clients-links.txt"
    if [[ -f "$client_links_file" ]]; then
        if print_install_links_summary "$client_links_file"; then
            echo ""
        else
            echo -e "  ${DIM}🔗 VLESS-ссылки сохранены: ${client_links_file}${NC}"
            echo ""
        fi
    elif [[ -f "$client_file" ]]; then
        echo -e "  ${DIM}💡 Клиентские конфиги сохранены: ${client_file}${NC}"
        echo ""
    fi

    echo -e "${BOLD}📁 Файлы:${NC}"
    echo -e "  Клиентские конфиги: ${XRAY_KEYS}/clients.txt"
    if [[ -f "$client_links_file" ]]; then
        echo -e "  Быстрые VLESS-ссылки: ${client_links_file}"
    fi
    echo -e "  Клиентские конфиги (JSON): ${XRAY_KEYS}/clients.json"
    if [[ -d "${XRAY_KEYS}/qr" ]]; then
        echo -e "  QR-коды: ${XRAY_KEYS}/qr/"
    fi
    if [[ -d "${XRAY_KEYS}/export" ]]; then
        echo -e "  Экспорт: ${XRAY_KEYS}/export/ (raw xray, шаблоны клиентов, canary)"
    fi
    echo -e "  Конфигурация Xray: ${XRAY_CONFIG}"
    echo -e "  Окружение: ${XRAY_ENV}"
    echo ""
    echo -e "${BOLD}🔧 Управление:${NC}"
    echo -e "  Статус:    ${YELLOW}xray-reality.sh status${NC}"
    echo -e "  Логи:      ${YELLOW}xray-reality.sh logs${NC}"
    echo -e "  Обновить:  ${YELLOW}xray-reality.sh update${NC}"
    echo -e "  Удалить:   ${YELLOW}xray-reality.sh uninstall${NC}"
    echo ""

}

install_is_loopback_lab_mode() {
    if declare -F self_check_is_loopback_runtime > /dev/null 2>&1 && self_check_is_loopback_runtime; then
        return 0
    fi

    case "${SERVER_IP:-}" in
        127.0.0.1 | localhost) return 0 ;;
        *) ;;
    esac
    case "${SERVER_IP6:-}" in
        ::1 | "[::1]" | localhost) return 0 ;;
        *) return 1 ;;
    esac
}

install_is_compat_no_systemd_mode() {
    [[ "${ALLOW_NO_SYSTEMD:-false}" == "true" ]] || return 1
    if ! declare -F systemctl_available > /dev/null 2>&1; then
        return 0
    fi
    if ! systemctl_available; then
        return 0
    fi
    if declare -F systemd_running > /dev/null 2>&1 && ! systemd_running; then
        return 0
    fi
    return 1
}

install_is_nonprod_runtime_mode() {
    install_is_loopback_lab_mode || install_is_compat_no_systemd_mode
}

install_runtime_mode_title() {
    if install_is_nonprod_runtime_mode; then
        printf '%s' "РЕЖИМ: СТЕНД / COMPAT"
    else
        printf '%s' "РЕЖИМ: БОЕВОЙ СЕРВЕР"
    fi
}

install_runtime_mode_color() {
    if install_is_nonprod_runtime_mode; then
        printf '%s' "$YELLOW"
    else
        printf '%s' "$GREEN"
    fi
}

install_runtime_mode_lines() {
    if install_is_nonprod_runtime_mode; then
        printf '%s\n' "это не боевой install path"
        if install_is_loopback_lab_mode; then
            printf '%s\n' "loopback-адрес обнаружен: ссылки работают только внутри текущего стенда"
        fi
        if install_is_compat_no_systemd_mode; then
            printf '%s\n' "compat-режим без systemd: сервисы, таймеры и автообновления не активированы"
        fi
        printf '%s\n' "для реального сервера используй внешний ip/домен и обычный install path с systemd"
    else
        printf '%s\n' "это полноценный install path для реального сервера"
        printf '%s\n' "основная ссылка ниже — стартовый рекомендуемый вариант"
        printf '%s\n' "запасную ссылку используй только если сеть режет основной вариант"
    fi
}

print_install_runtime_mode_notice() {
    local title color
    title=$(install_runtime_mode_title)
    color=$(install_runtime_mode_color)
    local -a lines=()
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        lines+=("$line")
    done < <(install_runtime_mode_lines)

    local box_width top header bottom line
    box_width=$(ui_box_width_for_lines 60 90 "$title" "${lines[@]}")
    top=$(ui_box_border_string top "$box_width")
    header=$(ui_box_line_string "$title" "$box_width")
    bottom=$(ui_box_border_string bottom "$box_width")

    echo -e "${BOLD}${color}${top}${NC}"
    echo -e "${BOLD}${color}${header}${NC}"
    for line in "${lines[@]}"; do
        echo -e "${color}$(ui_box_line_string "$line" "$box_width")${NC}"
    done
    echo -e "${BOLD}${color}${bottom}${NC}"
}

build_install_quick_start_file() {
    local json_file="$1"
    local output_file="$2"

    [[ -f "$json_file" ]] || return 1
    if ! jq -e 'type == "object" and (.configs | type == "array") and ((.configs | length) > 0)' "$json_file" > /dev/null 2>&1; then
        return 1
    fi

    local summary_json
    summary_json=$(jq -c '
        .configs[0] as $cfg |
        {
            name: ($cfg.name // "Config 1"),
            domain: ($cfg.domain // "unknown"),
            recommended_link: ([$cfg.variants[]? | select(.key == ($cfg.recommended_variant // "recommended")) | (.vless_v4 // .vless_v6 // "")] | .[0] // ""),
            rescue_link: ([$cfg.variants[]? | select(.key == "rescue") | (.vless_v4 // .vless_v6 // "")] | .[0] // ""),
            emergency_raw: ([$cfg.variants[]? | select(.key == "emergency") | (.xray_client_file_v4 // .xray_client_file_v6 // "")] | .[0] // "")
        }
    ' "$json_file" 2> /dev/null) || return 1

    local config_name domain recommended_link rescue_link emergency_raw config_label
    config_name=$(jq -r '.name // "Config 1"' <<< "$summary_json")
    domain=$(jq -r '.domain // "unknown"' <<< "$summary_json")
    recommended_link=$(jq -r '.recommended_link // empty' <<< "$summary_json")
    rescue_link=$(jq -r '.rescue_link // empty' <<< "$summary_json")
    emergency_raw=$(jq -r '.emergency_raw // empty' <<< "$summary_json")
    config_label="$domain"
    [[ -n "$config_label" && "$config_label" != "unknown" ]] || config_label="$config_name"
    if [[ -n "$config_name" && "$config_name" != "$config_label" && "$config_name" != "Config 1" ]]; then
        config_label="${config_label} (${config_name})"
    fi

    [[ -n "$recommended_link" || -n "$rescue_link" || -n "$emergency_raw" ]] || return 1

    {
        echo "что делать сейчас:"
        echo "1. импортируй основную ссылку"
        echo "2. если сеть её режет — попробуй запасную"
        echo ""
        echo "основной конфиг: ${config_label}"
        echo ""
        if [[ -n "$recommended_link" ]]; then
            echo "основная ссылка:"
            printf '%s\n' "$recommended_link"
            echo ""
        fi
        if [[ -n "$rescue_link" ]]; then
            echo "запасная ссылка:"
            printf '%s\n' "$rescue_link"
            echo ""
        fi
        if [[ -n "$emergency_raw" ]]; then
            echo "аварийный режим:"
            echo "raw xray json: ${emergency_raw}"
            echo "нужен только если основная и запасная не помогли"
            echo ""
        fi
        echo "все ссылки: ${XRAY_KEYS}/clients-links.txt"
        echo "подробная сводка: ${XRAY_KEYS}/clients.txt"
    } > "$output_file"
}

print_install_links_summary() {
    local client_links_file="$1"
    local clients_json="${XRAY_KEYS}/clients.json"
    local summary_file=""

    if [[ -f "$clients_json" ]]; then
        summary_file=$(mktemp "${XRAY_KEYS}/install-quick-start.XXXXXX")
        if ! build_install_quick_start_file "$clients_json" "$summary_file"; then
            rm -f "$summary_file"
            summary_file=""
        fi
    fi

    local target_file="$client_links_file"
    local header_text="🔗 что использовать сейчас:"
    if [[ -n "$summary_file" ]]; then
        target_file="$summary_file"
    else
        header_text="🔗 быстрые ссылки:"
    fi

    if [[ -t 1 ]]; then
        echo -e "${BOLD}${header_text}${NC}"
        cat "$target_file"
        [[ -n "$summary_file" ]] && rm -f "$summary_file"
        return 0
    fi

    local tty_fd=""
    if ! open_interactive_tty_fd tty_fd; then
        [[ -n "$summary_file" ]] && rm -f "$summary_file"
        return 1
    fi

    tty_printf "$tty_fd" '%b%s%b\n' "$BOLD" "$header_text" "$NC" || {
        exec {tty_fd}>&-
        [[ -n "$summary_file" ]] && rm -f "$summary_file"
        return 1
    }
    if ! cat "$target_file" >&"$tty_fd"; then
        exec {tty_fd}>&-
        [[ -n "$summary_file" ]] && rm -f "$summary_file"
        return 1
    fi
    exec {tty_fd}>&-
    [[ -n "$summary_file" ]] && rm -f "$summary_file"
    return 0
}
