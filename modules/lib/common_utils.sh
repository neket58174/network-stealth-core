#!/usr/bin/env bash
# shellcheck shell=bash

parse_bool() {
    local value="${1:-}"
    local default="${2:-false}"
    case "${value,,}" in
        1 | true | yes | y | on) echo "true" ;;
        0 | false | no | n | off) echo "false" ;;
        *) echo "$default" ;;
    esac
}

split_list() {
    local list="${1:-}"
    [[ -n "$list" ]] || return 0
    tr ',[:space:]' '\n' <<< "$list" | awk 'NF'
}
