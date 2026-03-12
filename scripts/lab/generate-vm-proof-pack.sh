#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lab/common.sh
source "$SCRIPT_DIR/common.sh"

usage() {
    cat << 'EOF'
usage:
  bash scripts/lab/generate-vm-proof-pack.sh [--timestamp <ts>]

environment:
  LAB_HOST_ROOT   host directory for vm-lab state
EOF
}

timestamp=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --timestamp)
            timestamp="${2:-}"
            shift 2
            ;;
        --help | -h)
            usage
            exit 0
            ;;
        *)
            echo "unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

lab_prepare_vm_dirs

latest_env="$(lab_vm_workspace_dir)/latest-vm-run.env"
if [[ -f "$latest_env" ]]; then
    # shellcheck disable=SC1090
    source "$latest_env"
    [[ -n "$timestamp" ]] || timestamp="${LAB_VM_TIMESTAMP:-}"
fi

[[ -n "$timestamp" ]] || {
    echo "vm proof-pack requires a vm-lab run; no timestamp found" >&2
    exit 1
}

summary_json="$(lab_vm_workspace_dir)/lab-vm-summary-${timestamp}.json"
proof_src="${LAB_VM_PROOF_DIR:-$(lab_vm_artifacts_dir)/proof-${timestamp}}"
run_log="$(lab_vm_logs_dir)/vm-smoke-${timestamp}.log"
xray_install_log="$(lab_vm_logs_dir)/xray-install-${timestamp}.log"
journal_xray_log="$(lab_vm_logs_dir)/journal-xray-${timestamp}.log"
journal_health_log="$(lab_vm_logs_dir)/journal-xray-health-${timestamp}.log"
serial_log="$(lab_vm_serial_log)"

if [[ ! -d "$proof_src" ]]; then
    echo "vm proof-pack source not found: ${proof_src}" >&2
    exit 1
fi
if [[ ! -f "${proof_src}/lifecycle.json" ]]; then
    echo "vm proof-pack source is incomplete: ${proof_src}/lifecycle.json is missing" >&2
    exit 1
fi

proof_root="$(lab_vm_proof_dir)/${timestamp}"
bundle_dir="${proof_root}/bundle"
archive_path="${proof_root}/proof-pack-${timestamp}.tar.gz"
manifest_path="${proof_root}/manifest.json"
latest_proof_env="$(lab_vm_latest_proof_env)"

rm -rf "$proof_root"
mkdir -p "$bundle_dir/logs" "$bundle_dir/evidence"

sanitize_copy() {
    local src="$1"
    local dst="$2"
    [[ -f "$src" ]] || return 0

    python3 - "$src" "$dst" << 'PY'
import re
import sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
text = src.read_text(encoding="utf-8", errors="replace")

patterns = [
    (re.compile(r"vless://\S+", re.IGNORECASE), "VLESS-REDACTED"),
    (re.compile(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"), "UUID-REDACTED"),
    (re.compile(r'("privateKey"\s*:\s*")[^"]+', re.IGNORECASE), r"\1***REDACTED***"),
    (re.compile(r'("password"\s*:\s*")[^"]+', re.IGNORECASE), r"\1***REDACTED***"),
    (re.compile(r"(Private Key:\s*)\S+", re.IGNORECASE), r"\1***REDACTED***"),
    (re.compile(r"([?&](?:pbk|sid|password|token|privateKey)=)[^&#\s]+", re.IGNORECASE), r"\1***REDACTED***"),
    (re.compile(r"(password\s*[:=]\s*)\S+", re.IGNORECASE), r"\1***REDACTED***"),
    (re.compile(r'("shortId"\s*:\s*")[^"]+', re.IGNORECASE), r"\1***REDACTED***"),
    (re.compile(r'("publicKey"\s*:\s*")[^"]+', re.IGNORECASE), r"\1***REDACTED***"),
]

for pattern, replacement in patterns:
    text = pattern.sub(replacement, text)

dst.write_text(text, encoding="utf-8")
PY
}

copy_file() {
    local src="$1"
    local dst="$2"
    [[ -f "$src" ]] || return 0
    install -D -m 0644 "$src" "$dst"
}

sanitize_copy "$run_log" "${bundle_dir}/logs/vm-smoke.log"
sanitize_copy "$xray_install_log" "${bundle_dir}/logs/xray-install.log"
sanitize_copy "$journal_xray_log" "${bundle_dir}/logs/journal-xray.log"
sanitize_copy "$journal_health_log" "${bundle_dir}/logs/journal-xray-health.log"
sanitize_copy "$serial_log" "${bundle_dir}/logs/vm-console.log"

copy_file "${proof_src}/lifecycle.json" "${bundle_dir}/evidence/lifecycle.json"
copy_file "${proof_src}/artifact-inventory.json" "${bundle_dir}/evidence/artifact-inventory.json"
copy_file "${proof_src}/capabilities.json" "${bundle_dir}/evidence/capabilities.json"
copy_file "${proof_src}/canary-manifest.json" "${bundle_dir}/evidence/canary-manifest.json"
copy_file "${proof_src}/self-check.json" "${bundle_dir}/evidence/self-check.json"
copy_file "${proof_src}/measurement-summary.json" "${bundle_dir}/evidence/measurement-summary.json"
sanitize_copy "${proof_src}/status-verbose.txt" "${bundle_dir}/evidence/status-verbose.txt"
sanitize_copy "${proof_src}/diagnose.txt" "${bundle_dir}/evidence/diagnose.txt"
copy_file "$summary_json" "${bundle_dir}/evidence/vm-summary.json"

python3 - "$bundle_dir" "$manifest_path" "$timestamp" << 'PY'
import hashlib
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

bundle_dir = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
timestamp = sys.argv[3]

def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def git_output(args):
    try:
        return subprocess.check_output(args, text=True).strip()
    except Exception:
        return ""

files = []
for path in sorted(bundle_dir.rglob("*")):
    if not path.is_file():
        continue
    rel = path.relative_to(bundle_dir).as_posix()
    files.append(
        {
            "path": rel,
            "size_bytes": path.stat().st_size,
            "sha256": sha256_file(path),
        }
    )

manifest = {
    "schema_version": 1,
    "timestamp": timestamp,
    "generated_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "repo_branch": git_output(["git", "branch", "--show-current"]),
    "repo_commit": git_output(["git", "rev-parse", "HEAD"]),
    "bundle_root": bundle_dir.name,
    "files": files,
}

manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

tar -C "$proof_root" -czf "$archive_path" bundle manifest.json

cat > "$latest_proof_env" << EOF
LAB_VM_PROOF_PACK_TIMESTAMP=${timestamp}
LAB_VM_PROOF_PACK_DIR=${proof_root}
LAB_VM_PROOF_PACK_TAR=${archive_path}
LAB_VM_PROOF_PACK_MANIFEST=${manifest_path}
EOF

printf '%s\n' "$archive_path"
