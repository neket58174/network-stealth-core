#!/usr/bin/env bash
# shellcheck shell=bash

GLOBAL_CONTRACT_MODULE="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}/modules/lib/globals_contract.sh"
if [[ ! -f "$GLOBAL_CONTRACT_MODULE" && -n "${XRAY_DATA_DIR:-}" ]]; then
    GLOBAL_CONTRACT_MODULE="$XRAY_DATA_DIR/modules/lib/globals_contract.sh"
fi
if [[ ! -f "$GLOBAL_CONTRACT_MODULE" ]]; then
    echo "ERROR: не найден модуль global contract: $GLOBAL_CONTRACT_MODULE" >&2
    exit 1
fi
# shellcheck source=modules/lib/globals_contract.sh
source "$GLOBAL_CONTRACT_MODULE"

yaml_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\n'/\\n}"
    printf '"%s"' "$str"
}

transport_endpoint_for_service() {
    local service="$1"
    if [[ "$TRANSPORT" == "http2" ]]; then
        if declare -F grpc_service_to_http2_path > /dev/null 2>&1; then
            grpc_service_to_http2_path "$service"
            return 0
        fi
        printf '/%s' "${service//./\/}"
        return 0
    fi
    printf '%s' "$service"
}

validate_export_json_schema() {
    local file="$1"
    local kind="$2"

    if [[ ! -f "$file" ]]; then
        log ERROR "Файл экспорта не найден: $file"
        return 1
    fi
    if ! jq empty "$file" > /dev/null 2>&1; then
        log ERROR "Некорректный JSON в экспорте: $file"
        return 1
    fi

    local schema_ok=false
    case "$kind" in
        singbox)
            if jq -e '
                (.inbounds | type == "array" and length >= 1) and
                (.outbounds | type == "array" and length >= 3) and
                (.dns.servers | type == "array" and length >= 1) and
                (([.outbounds[] | select(.type == "vless")] | length) >= 1)
            ' "$file" > /dev/null 2>&1; then
                schema_ok=true
            fi
            ;;
        v2rayn)
            if jq -e '
                (.profiles | type == "array" and length >= 1) and
                ([.profiles[] |
                    (has("name") and has("server") and has("port") and has("uuid") and has("vless_link"))
                ] | all)
            ' "$file" > /dev/null 2>&1; then
                schema_ok=true
            fi
            ;;
        nekoray)
            if jq -e '
                (.profiles | type == "array" and length >= 1) and
                ([.profiles[] |
                    (has("name") and has("server") and has("server_port") and has("uuid") and
                     (.tls.reality.enabled == true))
                ] | all)
            ' "$file" > /dev/null 2>&1; then
                schema_ok=true
            fi
            ;;
        *)
            log ERROR "Неизвестный тип JSON-schema проверки: $kind"
            return 1
            ;;
    esac

    if [[ "$schema_ok" != true ]]; then
        log ERROR "JSON-schema проверка не пройдена (${kind}): ${file}"
        return 1
    fi

    log OK "JSON-schema проверка пройдена (${kind})"
    return 0
}

export_clashmeta_config() {
    local out_file="$1"
    log STEP "Экспортируем конфигурацию в формате ClashMeta (Mihomo)..."
    local tmp_out
    tmp_out=$(mktemp "${out_file}.tmp.XXXXXX")

    local proxies=""
    local proxy_names=""

    for ((i = 0; i < NUM_CONFIGS; i++)); do
        local name="Reality-$((i + 1))"
        local server="$SERVER_IP"
        local port="${PORTS[$i]}"
        local uuid="${UUIDS[$i]}"
        local sni="${CONFIG_SNIS[$i]:-${CONFIG_DOMAINS[$i]:-unknown}}"
        local fp="${CONFIG_FPS[$i]:-chrome}"
        local pbk="${PUBLIC_KEYS[$i]}"
        local sid="${SHORT_IDS[$i]}"
        local grpc="${CONFIG_GRPC_SERVICES[$i]:-}"
        local endpoint
        endpoint=$(transport_endpoint_for_service "$grpc")

        local esc_server esc_uuid esc_sni esc_pbk esc_sid esc_fp esc_grpc esc_endpoint
        esc_server=$(yaml_escape "$server")
        esc_uuid=$(yaml_escape "$uuid")
        esc_sni=$(yaml_escape "$sni")
        esc_pbk=$(yaml_escape "$pbk")
        esc_sid=$(yaml_escape "$sid")
        esc_fp=$(yaml_escape "$fp")
        esc_grpc=$(yaml_escape "$grpc")
        esc_endpoint=$(yaml_escape "$endpoint")

        local transport_block=""
        if [[ "$TRANSPORT" == "http2" ]]; then
            transport_block="    network: http
    alpn:
      - h2
    http-opts:
      path: [${esc_endpoint}]
      headers:
        Host: [${esc_sni}]"
        else
            transport_block="    network: grpc
    grpc-opts:
      grpc-service-name: ${esc_grpc}"
        fi

        proxies+="  - name: \"${name}\"
    type: vless
    server: ${esc_server}
    port: ${port}
    uuid: ${esc_uuid}
    tls: true
    udp: true
    servername: ${esc_sni}
    reality-opts:
      public-key: ${esc_pbk}
      short-id: ${esc_sid}
    client-fingerprint: ${esc_fp}
${transport_block}

"

        if [[ -n "$proxy_names" ]]; then
            proxy_names+=", "
        fi
        proxy_names+="\"${name}\""
    done

    cat > "$tmp_out" << EOF

mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
unified-delay: true
tcp-concurrent: true
find-process-mode: strict

dns:
  enable: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  nameserver:
    - https://1.1.1.1/dns-query
    - https://8.8.8.8/dns-query
  fallback:
    - https://1.0.0.1/dns-query
    - https://9.9.9.9/dns-query
  fallback-filter:
    geoip: true
    geoip-code: RU

sniffer:
  enable: true
  sniff:
    HTTP:
      ports: [80, 8080-8880]
    TLS:
      ports: [443, 8443]

proxies:
${proxies}
proxy-groups:
  - name: "Reality"
    type: select
    proxies: [${proxy_names}, "Auto"]

  - name: "Auto"
    type: url-test
    proxies: [${proxy_names}]
    url: "https://www.gstatic.com/generate_204"
    interval: 300
    tolerance: 50

rules:
  - GEOIP,PRIVATE,DIRECT
  - GEOSITE,category-ads-all,REJECT
  - MATCH,Reality
EOF

    mv "$tmp_out" "$out_file"

    log OK "ClashMeta конфиг сохранён: $out_file"
}

export_singbox_config() {
    local out_file="$1"
    log STEP "Экспортируем конфигурацию в формате SingBox..."
    local tmp_out
    tmp_out=$(mktemp "${out_file}.tmp.XXXXXX")

    local outbounds_json='[]'
    local outbounds_tmp
    outbounds_tmp=$(mktemp "${TMPDIR:-/tmp}/xray-export-singbox.XXXXXX")

    for ((i = 0; i < NUM_CONFIGS; i++)); do
        local tag="reality-$((i + 1))"
        local server="$SERVER_IP"
        local port="${PORTS[$i]}"
        local uuid="${UUIDS[$i]}"
        local sni="${CONFIG_SNIS[$i]:-${CONFIG_DOMAINS[$i]:-unknown}}"
        local fp="${CONFIG_FPS[$i]:-chrome}"
        local pbk="${PUBLIC_KEYS[$i]}"
        local sid="${SHORT_IDS[$i]}"
        local grpc="${CONFIG_GRPC_SERVICES[$i]:-}"
        local endpoint
        endpoint=$(transport_endpoint_for_service "$grpc")

        local transport_json
        if [[ "$TRANSPORT" == "http2" ]]; then
            transport_json=$(jq -n --arg path "$endpoint" --arg host "$sni" '{type: "http", path: $path, host: [$host]}')
        else
            transport_json=$(jq -n --arg sn "$grpc" '{type: "grpc", service_name: $sn}')
        fi

        local ob
        ob=$(jq -n \
            --arg tag "$tag" \
            --arg server "$server" \
            --argjson port "$port" \
            --arg uuid "$uuid" \
            --arg sni "$sni" \
            --arg fp "$fp" \
            --arg pbk "$pbk" \
            --arg sid "$sid" \
            --arg transport "$TRANSPORT" \
            --argjson transport_obj "$transport_json" \
            '{
                type: "vless",
                tag: $tag,
                server: $server,
                server_port: $port,
                uuid: $uuid,
                tls: {
                    enabled: true,
                    server_name: $sni,
                    alpn: (if $transport == "http2" then ["h2"] else ["h2", "http/1.1"] end),
                    utls: {
                        enabled: true,
                        fingerprint: $fp
                    },
                    reality: {
                        enabled: true,
                        public_key: $pbk,
                        short_id: $sid
                    }
                },
                transport: $transport_obj,
                packet_encoding: "xudp"
            }')

        printf '%s\n' "$ob" >> "$outbounds_tmp"
    done
    if [[ -s "$outbounds_tmp" ]]; then
        outbounds_json=$(jq -s '.' "$outbounds_tmp")
    fi
    rm -f "$outbounds_tmp"

    local tags_json
    tags_json=$(echo "$outbounds_json" | jq '[.[].tag]')

    local full_config
    full_config=$(jq -n \
        --argjson outbounds "$outbounds_json" \
        --argjson tags "$tags_json" \
        '{
            log: {level: "info"},
            dns: {
                servers: [
                    {tag: "cloudflare-doh", address: "https://1.1.1.1/dns-query", detour: "proxy"},
                    {tag: "google-doh", address: "https://8.8.8.8/dns-query", detour: "proxy"},
                    {tag: "local", address: "https://1.0.0.1/dns-query", detour: "direct"}
                ],
                rules: [{outbound: "any", server: "local"}],
                strategy: "prefer_ipv4"
            },
            inbounds: [
                {
                    type: "mixed",
                    tag: "mixed-in",
                    listen: "127.0.0.1",
                    listen_port: 7890
                }
            ],
            outbounds: (
                [{type: "selector", tag: "proxy", outbounds: ($tags + ["auto", "direct"])}]
                + [{type: "urltest", tag: "auto", outbounds: $tags, url: "https://www.gstatic.com/generate_204", interval: "3m"}]
                + $outbounds
                + [{type: "direct", tag: "direct"}, {type: "block", tag: "block"}]
            ),
            route: {
                rule_set: [
                    {
                        tag: "geoip-private",
                        type: "remote",
                        format: "binary",
                        url: "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-private.srs"
                    }
                ],
                rules: [
                    {rule_set: "geoip-private", outbound: "direct"}
                ],
                final: "proxy",
                auto_detect_interface: true
            }
        }')

    if ! printf '%s\n' "$full_config" | jq '.' > "$tmp_out"; then
        rm -f "$tmp_out"
        return 1
    fi
    if ! validate_export_json_schema "$tmp_out" "singbox"; then
        rm -f "$tmp_out"
        return 1
    fi
    mv "$tmp_out" "$out_file"
    log OK "SingBox конфиг сохранён: $out_file"
}

export_v2rayn_fragment_template() {
    local out_file="$1"
    log STEP "Экспортируем шаблон v2rayN с фрагментацией..."
    local tmp_out
    tmp_out=$(mktemp "${out_file}.tmp.XXXXXX")

    local profiles='[]'
    local profiles_tmp
    profiles_tmp=$(mktemp "${TMPDIR:-/tmp}/xray-export-v2rayn.XXXXXX")
    local i
    for ((i = 0; i < NUM_CONFIGS; i++)); do
        local domain="${CONFIG_DOMAINS[$i]:-unknown}"
        local sni="${CONFIG_SNIS[$i]:-$domain}"
        local fp="${CONFIG_FPS[$i]:-chrome}"
        local grpc="${CONFIG_GRPC_SERVICES[$i]:-GunService}"
        local endpoint
        endpoint=$(transport_endpoint_for_service "$grpc")

        local params
        if declare -F build_vless_query_params > /dev/null 2>&1; then
            params=$(build_vless_query_params "$sni" "$fp" "${PUBLIC_KEYS[$i]}" "${SHORT_IDS[$i]}" "$TRANSPORT" "$endpoint")
        elif [[ "$TRANSPORT" == "http2" ]]; then
            params="encryption=none&security=reality&sni=${sni}&fp=${fp}&pbk=${PUBLIC_KEYS[$i]}&sid=${SHORT_IDS[$i]}&type=http&host=${sni}&path=${endpoint}&alpn=h2"
        else
            params="encryption=none&security=reality&sni=${sni}&fp=${fp}&pbk=${PUBLIC_KEYS[$i]}&sid=${SHORT_IDS[$i]}&type=grpc&serviceName=${grpc}&mode=multi"
        fi
        local vless="vless://${UUIDS[$i]}@${SERVER_IP}:${PORTS[$i]}?${params}#Reality-$((i + 1))"

        local item
        item=$(jq -n \
            --arg name "Reality-$((i + 1))" \
            --arg server "$SERVER_IP" \
            --argjson port "${PORTS[$i]}" \
            --arg uuid "${UUIDS[$i]}" \
            --arg sni "$sni" \
            --arg fp "$fp" \
            --arg pbk "${PUBLIC_KEYS[$i]}" \
            --arg sid "${SHORT_IDS[$i]}" \
            --arg transport "$TRANSPORT" \
            --arg endpoint "$endpoint" \
            --arg vless "$vless" \
            '{
                name: $name,
                server: $server,
                port: $port,
                uuid: $uuid,
                sni: $sni,
                fingerprint: $fp,
                public_key: $pbk,
                short_id: $sid,
                transport: $transport,
                transport_endpoint: $endpoint,
                vless_link: $vless
            }')
        printf '%s\n' "$item" >> "$profiles_tmp"
    done
    if [[ -s "$profiles_tmp" ]]; then
        profiles=$(jq -s '.' "$profiles_tmp")
    fi
    rm -f "$profiles_tmp"

    if ! jq -n \
        --arg generated "$(date)" \
        --arg transport "$TRANSPORT" \
        --argjson profiles "$profiles" \
        '{
            generated: $generated,
            transport: $transport,
            fragment_recommendation: {
                packets: "tlshello",
                length: "100-200",
                interval: "10-20",
                randomize: true
            },
            profiles: $profiles
        }' > "$tmp_out"; then
        rm -f "$tmp_out"
        return 1
    fi
    if ! validate_export_json_schema "$tmp_out" "v2rayn"; then
        rm -f "$tmp_out"
        return 1
    fi
    mv "$tmp_out" "$out_file"
    log OK "v2rayN шаблон сохранён: $out_file"
}

export_nekoray_fragment_template() {
    local out_file="$1"
    log STEP "Экспортируем шаблон Nekoray с фрагментацией..."
    local tmp_out
    tmp_out=$(mktemp "${out_file}.tmp.XXXXXX")

    local profiles='[]'
    local profiles_tmp
    profiles_tmp=$(mktemp "${TMPDIR:-/tmp}/xray-export-nekoray.XXXXXX")
    local i
    for ((i = 0; i < NUM_CONFIGS; i++)); do
        local domain="${CONFIG_DOMAINS[$i]:-unknown}"
        local sni="${CONFIG_SNIS[$i]:-$domain}"
        local fp="${CONFIG_FPS[$i]:-chrome}"
        local grpc="${CONFIG_GRPC_SERVICES[$i]:-GunService}"
        local endpoint
        endpoint=$(transport_endpoint_for_service "$grpc")

        local item
        item=$(jq -n \
            --arg name "Reality-$((i + 1))" \
            --arg server "$SERVER_IP" \
            --argjson port "${PORTS[$i]}" \
            --arg uuid "${UUIDS[$i]}" \
            --arg sni "$sni" \
            --arg fp "$fp" \
            --arg pbk "${PUBLIC_KEYS[$i]}" \
            --arg sid "${SHORT_IDS[$i]}" \
            --arg transport "$TRANSPORT" \
            --arg endpoint "$endpoint" \
            '{
                name: $name,
                type: "vless",
                server: $server,
                server_port: $port,
                uuid: $uuid,
                tls: {
                    enabled: true,
                    server_name: $sni,
                    reality: {
                        enabled: true,
                        public_key: $pbk,
                        short_id: $sid
                    },
                    utls: {
                        enabled: true,
                        fingerprint: $fp
                    }
                },
                transport: {
                    type: $transport,
                    endpoint: $endpoint
                },
                fragment: {
                    enabled: true,
                    packets: "tlshello",
                    length: "100-200",
                    interval: "10-20"
                }
            }')
        printf '%s\n' "$item" >> "$profiles_tmp"
    done
    if [[ -s "$profiles_tmp" ]]; then
        profiles=$(jq -s '.' "$profiles_tmp")
    fi
    rm -f "$profiles_tmp"

    if ! jq -n \
        --arg generated "$(date)" \
        --argjson profiles "$profiles" \
        '{
            generated: $generated,
            note: "Nekoray template with recommended fragmentation parameters",
            profiles: $profiles
        }' > "$tmp_out"; then
        rm -f "$tmp_out"
        return 1
    fi
    if ! validate_export_json_schema "$tmp_out" "nekoray"; then
        rm -f "$tmp_out"
        return 1
    fi
    mv "$tmp_out" "$out_file"
    log OK "Nekoray шаблон сохранён: $out_file"
}

export_all_configs() {
    local export_dir="${XRAY_KEYS}/export"
    mkdir -p "$export_dir"

    export_clashmeta_config "${export_dir}/clashmeta.yaml"
    export_singbox_config "${export_dir}/singbox.json"
    export_nekoray_fragment_template "${export_dir}/nekoray-fragment.json"
    export_v2rayn_fragment_template "${export_dir}/v2rayn-fragment.json"

    local -a artifacts=()
    mapfile -t artifacts < <(find "$export_dir" -mindepth 1 -maxdepth 1 -type f)
    if ((${#artifacts[@]} > 0)); then
        chmod 640 "${artifacts[@]}"
        chown "root:${XRAY_GROUP}" "${artifacts[@]}" 2> /dev/null || true
    fi
    log OK "Все форматы экспортированы в ${export_dir}/"
}
