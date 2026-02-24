#!/usr/bin/env bats

load 'helpers/mocks'

@test "curl_fetch_text returns body via mocked curl" {
    setup_mock_bin
    mock_curl

    run env MOCK_CURL_BODY="ok" MOCK_BIN="$MOCK_BIN" PATH="$MOCK_BIN:$PATH" bash -c '
    set -euo pipefail
    source ./lib.sh
    if ! command -v curl >/dev/null 2>&1; then
      exit 11
    fi
    curl_fetch_text "https://example.test/file"
  '

    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "curl_fetch_text returns non-zero when curl fails" {
    setup_mock_bin
    mock_curl

    run env MOCK_CURL_EXIT=22 MOCK_BIN="$MOCK_BIN" PATH="$MOCK_BIN:$PATH" bash -c '
    set -euo pipefail
    source ./lib.sh
    if ! command -v curl >/dev/null 2>&1; then
      exit 11
    fi
    curl_fetch_text "https://example.test/file"
  '

    [ "$status" -ne 0 ]
}

@test "curl_fetch_text_allowlist rejects host outside allowlist" {
    run bash -eo pipefail -c '
    set -euo pipefail
    source ./lib.sh
    DOWNLOAD_HOST_ALLOWLIST="github.com,api.github.com"
    curl_fetch_text_allowlist "https://example.test/file"
  '

    [ "$status" -ne 0 ]
}

@test "curl_fetch_text_allowlist allows host in allowlist" {
    setup_mock_bin
    mock_curl

    run env MOCK_CURL_BODY="ok" MOCK_BIN="$MOCK_BIN" PATH="$MOCK_BIN:$PATH" bash -c '
    set -euo pipefail
    source ./lib.sh
    DOWNLOAD_HOST_ALLOWLIST="example.test,github.com"
    if ! command -v curl >/dev/null 2>&1; then
      exit 11
    fi
    curl_fetch_text_allowlist "https://example.test/file"
  '

    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "curl_fetch_text_allowlist rejects redirect target outside allowlist" {
    setup_mock_bin
    mock_curl

    run env MOCK_CURL_BODY="ok" MOCK_CURL_EFFECTIVE_URL="https://evil.test/file" MOCK_BIN="$MOCK_BIN" PATH="$MOCK_BIN:$PATH" bash -c '
    set -euo pipefail
    source ./lib.sh
    DOWNLOAD_HOST_ALLOWLIST="example.test,github.com"
    curl_fetch_text_allowlist "https://example.test/file"
  '

    [ "$status" -ne 0 ]
}

@test "curl_fetch_text_allowlist accepts allowlisted redirect target" {
    setup_mock_bin
    mock_curl

    run env MOCK_CURL_BODY="ok" MOCK_CURL_EFFECTIVE_URL="https://release-assets.githubusercontent.com/file" MOCK_BIN="$MOCK_BIN" PATH="$MOCK_BIN:$PATH" bash -c '
    set -euo pipefail
    source ./lib.sh
    DOWNLOAD_HOST_ALLOWLIST="example.test,release-assets.githubusercontent.com"
    curl_fetch_text_allowlist "https://example.test/file"
  '

    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "download_file_allowlist stores file for allowlisted host" {
    setup_mock_bin
    mock_curl

    run env MOCK_CURL_BODY="payload" MOCK_BIN="$MOCK_BIN" PATH="$MOCK_BIN:$PATH" bash -c '
    set -euo pipefail
    source ./lib.sh
    DOWNLOAD_HOST_ALLOWLIST="example.test,github.com"
    out_file="$(mktemp)"
    download_file_allowlist "https://example.test/file" "$out_file" "download test"
    cat "$out_file"
  '

    [ "$status" -eq 0 ]
    [ "$output" = "payload" ]
}

@test "download_file_allowlist works without description argument" {
    setup_mock_bin
    mock_curl

    run env MOCK_CURL_BODY="payload2" MOCK_BIN="$MOCK_BIN" PATH="$MOCK_BIN:$PATH" bash -c '
    set -euo pipefail
    source ./lib.sh
    DOWNLOAD_HOST_ALLOWLIST="example.test,github.com"
    out_file="$(mktemp)"
    download_file_allowlist "https://example.test/file" "$out_file"
    cat "$out_file"
  '

    [ "$status" -eq 0 ]
    [ "$output" = "payload2" ]
}

@test "download_file_allowlist rejects extra unexpected arguments" {
    run bash -eo pipefail -c '
    set -euo pipefail
    source ./lib.sh
    out_file="$(mktemp)"
    download_file_allowlist "https://example.test/file" "$out_file" "desc" "extra"
  '

    [ "$status" -ne 0 ]
}

@test "download_file_allowlist rejects host outside allowlist" {
    run bash -eo pipefail -c '
    set -euo pipefail
    source ./lib.sh
    DOWNLOAD_HOST_ALLOWLIST="github.com,api.github.com"
    out_file="$(mktemp)"
    download_file_allowlist "https://example.test/file" "$out_file" "download test"
  '

    [ "$status" -ne 0 ]
}

@test "download_file_allowlist uses randomized temp files" {
    run bash -eo pipefail -c '
    grep -Fq '\''mktemp -d "${TMPDIR:-/tmp}/xray-dl.XXXXXX"'\'' ./lib.sh
    ! grep -Fq '\''tmp_file="${out_file}.part.$$"'\'' ./lib.sh
    echo "ok"
  '

    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

@test "download_file_allowlist cleans temp files on interrupts" {
    run bash -eo pipefail -c '
    grep -Fq "trap '\''rm -f \"\${tmp_file:-}\"; rm -rf \"\${tmp_dir:-}\"'\'' EXIT INT TERM" ./lib.sh
    echo "ok"
  '

    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}
