#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$ROOT_DIR"
MODULE_DIR="$ROOT_DIR"
DEFAULT_CLIENTS_JSON="/etc/xray/private/keys/clients.json"
DEFAULT_VARIANTS="recommended,rescue"

# shellcheck source=lib.sh
source "$ROOT_DIR/lib.sh"
# shellcheck source=config.sh
source "$ROOT_DIR/config.sh"
# shellcheck source=health.sh
source "$ROOT_DIR/health.sh"

measure_usage() {
    cat << 'EOF'
usage: scripts/measure-stealth.sh [options]

options:
  --clients-json <file>   clients.json path (default: /etc/xray/private/keys/clients.json)
  --variants <list>       comma/space-separated variant keys (default: recommended,rescue)
  --output <file>         write json report to file
  --help                  show help
EOF
}

MEASURE_CLIENTS_JSON="$DEFAULT_CLIENTS_JSON"
MEASURE_VARIANTS="$DEFAULT_VARIANTS"
MEASURE_OUTPUT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --clients-json)
            MEASURE_CLIENTS_JSON="${2:-}"
            shift 2
            ;;
        --variants)
            MEASURE_VARIANTS="${2:-}"
            shift 2
            ;;
        --output)
            MEASURE_OUTPUT="${2:-}"
            shift 2
            ;;
        --help)
            measure_usage
            exit 0
            ;;
        *)
            echo "unknown option: $1" >&2
            measure_usage >&2
            exit 1
            ;;
    esac
done

[[ -n "$MEASURE_CLIENTS_JSON" ]] || {
    echo "clients.json path is required" >&2
    exit 1
}
[[ -f "$MEASURE_CLIENTS_JSON" ]] || {
    echo "clients.json not found: $MEASURE_CLIENTS_JSON" >&2
    exit 1
}
if ! jq -e 'type == "object" and (.configs | type == "array")' "$MEASURE_CLIENTS_JSON" > /dev/null 2>&1; then
    echo "clients.json has invalid schema: $MEASURE_CLIENTS_JSON" >&2
    exit 1
fi

SELF_CHECK_ENABLED=true

report_results='[]'
config_summary='[]'
requested_variants_json=$(printf '%s\n' "$MEASURE_VARIANTS" | tr ', ' '\n\n' | sed '/^$/d' | jq -R . | jq -s .)

while IFS= read -r config_name; do
    config_name=${config_name//$'\r'/}
    config_name=$(self_check_trim_ws "$config_name")
    [[ -n "$config_name" ]] || continue
    config_success=false

    while IFS= read -r variant_key; do
        variant_key=${variant_key//$'\r'/}
        variant_key=$(self_check_trim_ws "$variant_key")
        [[ -n "$variant_key" ]] || continue
        job_json=$(jq -c \
            --arg config_name "$config_name" \
            --arg variant_key "$variant_key" '
                .configs[]
                | select(.name == $config_name)
                | . as $cfg
                | ($cfg.variants[] | select(.key == $variant_key) | {
                    config_name: $cfg.name,
                    variant_key: .key,
                    mode: (.mode // ""),
                    raw_v4: (.xray_client_file_v4 // ""),
                    raw_v6: (.xray_client_file_v6 // "")
                })
            ' "$MEASURE_CLIENTS_JSON" 2> /dev/null | head -n 1 || true)
        [[ -n "$job_json" ]] || continue

        for family in ipv4 ipv6; do
            raw_file=""
            case "$family" in
                ipv4) raw_file=$(jq -r '.raw_v4 // empty' <<< "$job_json") ;;
                ipv6) raw_file=$(jq -r '.raw_v6 // empty' <<< "$job_json") ;;
            esac
            [[ -n "$raw_file" ]] || continue

            probe_result=$(self_check_run_variant_probe \
                "measure-stealth" \
                "$config_name" \
                "$variant_key" \
                "$(jq -r '.mode // ""' <<< "$job_json")" \
                "$family" \
                "$raw_file")
            report_results=$(jq --argjson item "$probe_result" '. + [$item]' <<< "$report_results")

            if jq -e '.success == true' <<< "$probe_result" > /dev/null 2>&1; then
                config_success=true
            fi
        done
    done < <(split_list "$MEASURE_VARIANTS")

    config_summary=$(jq \
        --arg config_name "$config_name" \
        --argjson config_success "$config_success" \
        --argjson requested_variants "$requested_variants_json" \
        --argjson results "$report_results" '
            . + [{
                config_name: $config_name,
                requested_variants: $requested_variants,
                success: $config_success,
                successful_results: (
                    $results
                    | map(select(.config_name == $config_name and .success == true))
                    | length
                )
            }]
        ' <<< "$config_summary")
done < <(jq -r '.configs[]?.name // empty' "$MEASURE_CLIENTS_JSON")

final_report=$(jq -n \
    --arg generated "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    --arg clients_json "$MEASURE_CLIENTS_JSON" \
    --argjson requested_variants "$requested_variants_json" \
    --argjson probe_urls "$(self_check_urls_json)" \
    --argjson results "$report_results" \
    --argjson configs "$config_summary" \
    '{
        generated: $generated,
        clients_json: $clients_json,
        requested_variants: $requested_variants,
        probe_urls: $probe_urls,
        configs: $configs,
        results: $results
    }')

if [[ -n "$MEASURE_OUTPUT" ]]; then
    mkdir -p "$(dirname "$MEASURE_OUTPUT")"
    printf '%s\n' "$final_report" > "$MEASURE_OUTPUT"
fi

printf '%s\n' "$final_report"

if jq -e 'all(.configs[]?; .success == true)' <<< "$final_report" > /dev/null 2>&1; then
    exit 0
fi
exit 1
