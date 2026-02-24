#!/usr/bin/env bats

# By default transport is gRPC; optional HTTP/2 mode is supported.

@test "generate_inbound_json uses grpc network" {
    run bash -eo pipefail -c '
    source ./lib.sh
    source ./config.sh
    json=$(generate_inbound_json 443 "test-uuid" "yandex.ru:443" "yandex.ru" "privkey" "abcd" "chrome" "TestService" 30 60 20)
    echo "$json" | jq -r ".streamSettings.network"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "grpc" ]
}

@test "generate_inbound_json sets grpc serviceName" {
    run bash -eo pipefail -c '
    source ./lib.sh
    source ./config.sh
    json=$(generate_inbound_json 443 "test-uuid" "yandex.ru:443" "yandex.ru" "privkey" "abcd" "chrome" "my.api.v1.Service" 30 60 20)
    echo "$json" | jq -r ".streamSettings.grpcSettings.serviceName"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "my.api.v1.Service" ]
}

@test "generate_inbound_json enables multiMode" {
    run bash -eo pipefail -c '
    source ./lib.sh
    source ./config.sh
    json=$(generate_inbound_json 443 "test-uuid" "yandex.ru:443" "yandex.ru" "privkey" "abcd" "chrome" "TestService" 30 60 20)
    echo "$json" | jq -r ".streamSettings.grpcSettings.multiMode"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "generate_inbound_json supports http2 mode" {
    run bash -eo pipefail -c '
    source ./lib.sh
    source ./config.sh
    json=$(generate_inbound_json 443 "test-uuid" "yandex.ru:443" "[\"yandex.ru\"]" "privkey" "abcd" "chrome" "my.api.v1.Service" 30 60 20 "http2" "/my/api/v1/Service")
    net=$(echo "$json" | jq -r ".streamSettings.network")
    path=$(echo "$json" | jq -r ".streamSettings.httpSettings.path")
    echo "${net}:${path}"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "h2:/my/api/v1/Service" ]
}

@test "build_inbound_profile_for_domain derives http2 payload from grpc service" {
    run bash -eo pipefail -c '
    source ./lib.sh
    source ./config.sh
    TRANSPORT="http2"
    SKIP_REALITY_CHECK=true
    declare -A SNI_POOLS
    declare -A GRPC_SERVICES
    SNI_POOLS["yandex.ru"]="yandex.ru"
    GRPC_SERVICES["yandex.ru"]="my.api.v1.Service"
    declare -a fp_pool=("chrome")
    build_inbound_profile_for_domain "yandex.ru" fp_pool
    echo "${PROFILE_GRPC}|${PROFILE_TRANSPORT_PAYLOAD}|${PROFILE_FP}|${PROFILE_DEST}"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "my.api.v1.Service|/my/api/v1/Service|chrome|yandex.ru:443" ]
}

@test "generate_profile_inbound_json uses prepared profile fields" {
    run bash -eo pipefail -c '
    source ./lib.sh
    source ./config.sh
    TRANSPORT="http2"
    SKIP_REALITY_CHECK=true
    declare -A SNI_POOLS
    declare -A GRPC_SERVICES
    SNI_POOLS["yandex.ru"]="yandex.ru"
    GRPC_SERVICES["yandex.ru"]="my.api.v1.Service"
    declare -a fp_pool=("chrome")
    build_inbound_profile_for_domain "yandex.ru" fp_pool
    json=$(generate_profile_inbound_json 443 "test-uuid" "privkey" "abcd")
    net=$(echo "$json" | jq -r ".streamSettings.network")
    path=$(echo "$json" | jq -r ".streamSettings.httpSettings.path")
    echo "${net}:${path}"
  '
    [ "$status" -eq 0 ]
    [ "$output" = "h2:/my/api/v1/Service" ]
}
