#!/usr/bin/env bash

setup_mock_bin() {
    local base="${BATS_TEST_TMPDIR:-}"
    if [[ -z "$base" ]]; then
        base="$(mktemp -d 2> /dev/null || mktemp -d -t bats-tmp)"
    fi
    MOCK_BIN="${base}/mockbin"
    mkdir -p "$MOCK_BIN"
    PATH="$MOCK_BIN:$PATH"
    export PATH
}

mock_curl() {
    cat > "$MOCK_BIN/curl" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

out=""
write_out=""
url=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output)
      out="$2"
      shift 2
      ;;
    -w|--write-out)
      write_out="$2"
      shift 2
      ;;
    https://*|http://*)
      url="$1"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [[ "${MOCK_CURL_EXIT:-0}" != "0" ]]; then
  exit "${MOCK_CURL_EXIT}"
fi

if [[ -n "$out" && "$out" != "/dev/null" ]]; then
  printf '%s' "${MOCK_CURL_BODY:-mock}" > "$out"
elif [[ -z "$out" ]]; then
  printf '%s' "${MOCK_CURL_BODY:-mock}"
fi

if [[ -n "$write_out" ]]; then
  effective_url="${MOCK_CURL_EFFECTIVE_URL:-$url}"
  write_rendered="${write_out//\%\{url_effective\}/$effective_url}"
  printf '%s' "$write_rendered"
fi

exit 0
EOF
    chmod +x "$MOCK_BIN/curl"
}
