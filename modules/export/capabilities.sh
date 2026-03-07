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

export_capabilities_json() {
    local export_dir="$1"
    local out_file="$2"
    local tmp_out
    tmp_out=$(mktemp "${out_file}.tmp.XXXXXX")

    jq -n \
        --arg generated "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        --arg transport "${TRANSPORT:-xhttp}" \
        --arg clients_txt "${XRAY_KEYS}/clients.txt" \
        --arg clients_json "${XRAY_KEYS}/clients.json" \
        --arg raw_xray_dir "${export_dir}/raw-xray" \
        --arg raw_xray_index "${export_dir}/raw-xray-index.json" \
        --arg v2rayn "${export_dir}/v2rayn-links.json" \
        --arg nekoray "${export_dir}/nekoray-template.json" \
        '{
            generated: $generated,
            transport: $transport,
            formats: [
                {
                    name: "clients.txt",
                    status: "native",
                    artifact: $clients_txt,
                    reason: "human-readable server-managed client inventory"
                },
                {
                    name: "clients.json",
                    status: "native",
                    artifact: $clients_json,
                    reason: "schema v2 source of truth for generated variants"
                },
                {
                    name: "raw-xray",
                    status: "native",
                    artifact: $raw_xray_dir,
                    index: $raw_xray_index,
                    reason: "per-variant xray client json for xhttp self-check and direct import"
                },
                {
                    name: "v2rayn-links",
                    status: "link-only",
                    artifact: $v2rayn,
                    reason: "vless links only; raw xray json remains the canonical xhttp artifact"
                },
                {
                    name: "nekoray-template",
                    status: "link-only",
                    artifact: $nekoray,
                    reason: "template contains links and references to raw xray json"
                },
                {
                    name: "sing-box",
                    status: "unsupported",
                    artifact: null,
                    reason: "not generated in xhttp-only mode to avoid misleading degraded templates"
                },
                {
                    name: "clash-meta",
                    status: "unsupported",
                    artifact: null,
                    reason: "not generated in xhttp-only mode to avoid misleading degraded templates"
                }
            ]
        }' > "$tmp_out"

    mv "$tmp_out" "$out_file"
}

export_capabilities_notes_from_json() {
    local capabilities_file="$1"
    local out_file="$2"
    local tmp_out
    tmp_out=$(mktemp "${out_file}.tmp.XXXXXX")

    {
        printf 'network stealth core export notes\n'
        printf '===============================\n\n'
        printf 'transport: %s\n\n' "${TRANSPORT:-xhttp}"
        printf 'capabilities:\n'
        jq -r '.formats[]
            | "- " + .name + ": " + .status + (if (.artifact // "") != "" then " -> " + .artifact else "" end) + "\n  reason: " + (.reason // "n/a")
        ' "$capabilities_file"
    } > "$tmp_out"

    mv "$tmp_out" "$out_file"
}
