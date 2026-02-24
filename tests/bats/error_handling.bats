#!/usr/bin/env bats

@test "cleanup_on_error restores local backup" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    local target="${tmpdir}/target.txt"
    local log_file="${tmpdir}/install.log"

    printf '%s' "orig" > "$target"
    cp "$target" "${target}.backup"

    run env TARGET="$target" LOG_FILE="$log_file" bash -c '
    source ./lib.sh
    INSTALL_LOG="$LOG_FILE"
    BACKUP_STACK=("$TARGET")
    declare -A LOCAL_BACKUP_MAP=()
    LOCAL_BACKUP_MAP["$TARGET"]=1
    printf "%s" "new" > "$TARGET"
    false
  '

    [ "$status" -ne 0 ]
    [ "$(cat "$target")" = "orig" ]
    [ ! -f "${target}.backup" ]
}

@test "cleanup_on_error restores from session backup" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    local target="${tmpdir}/target.txt"
    local session_dir="${tmpdir}/backup-session"
    local log_file="${tmpdir}/install.log"

    mkdir -p "${session_dir}${tmpdir}"
    printf '%s' "orig" > "$target"
    cp "$target" "${session_dir}${target}"
    printf '%s' "modified" > "$target"

    run env TARGET="$target" SESSION="$session_dir" LOG_FILE="$log_file" bash -c '
    source ./lib.sh
    INSTALL_LOG="$LOG_FILE"
    BACKUP_STACK=("$TARGET")
    declare -A LOCAL_BACKUP_MAP=()
    BACKUP_SESSION_DIR="$SESSION"
    false
  '

    [ "$status" -ne 0 ]
    [ "$(cat "$target")" = "orig" ]
}

@test "cleanup_on_error handles empty backup stack" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    local log_file="${tmpdir}/install.log"

    run env LOG_FILE="$log_file" bash -c '
    source ./lib.sh
    INSTALL_LOG="$LOG_FILE"
    BACKUP_STACK=()
    declare -A LOCAL_BACKUP_MAP=()
    false
  '

    [ "$status" -ne 0 ]
}

@test "cleanup_on_error rolls back firewall changes" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    local log_file="${tmpdir}/install.log"

    run env LOG_FILE="$log_file" bash -c '
    source ./lib.sh
    INSTALL_LOG="$LOG_FILE"
    BACKUP_STACK=()
    declare -A LOCAL_BACKUP_MAP=()
    FIREWALL_ROLLBACK_ENTRIES=("iptables|444|v4")
    FIREWALL_FIREWALLD_DIRTY=false
    rollback_firewall_changes() {
      echo "firewall_rollback_called"
      FIREWALL_ROLLBACK_ENTRIES=()
      FIREWALL_FIREWALLD_DIRTY=false
      return 0
    }
    false
  '

    [ "$status" -ne 0 ]
    [[ "$output" == *"firewall_rollback_called"* ]]
}

@test "cleanup_on_error removes files created in failed session" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    local created="${tmpdir}/created.txt"
    local log_file="${tmpdir}/install.log"

    run env CREATED="$created" LOG_FILE="$log_file" bash -c '
    source ./lib.sh
    INSTALL_LOG="$LOG_FILE"
    BACKUP_STACK=()
    declare -A LOCAL_BACKUP_MAP=()
    CREATED_PATHS=("$CREATED")
    declare -A CREATED_PATH_SET=()
    CREATED_PATH_SET["$CREATED"]=1
    printf "%s" "temporary" > "$CREATED"
    false
  '

    [ "$status" -ne 0 ]
    [ ! -e "$created" ]
}

@test "cleanup_on_error reconciles runtime after restoring critical files" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    local target="${tmpdir}/config.json"
    local log_file="${tmpdir}/install.log"

    printf '%s' "orig" > "$target"
    cp "$target" "${target}.backup"

    run env TARGET="$target" LOG_FILE="$log_file" bash -c '
    source ./lib.sh
    INSTALL_LOG="$LOG_FILE"
    XRAY_CONFIG="$TARGET"
    BACKUP_STACK=("$TARGET")
    declare -A LOCAL_BACKUP_MAP=()
    LOCAL_BACKUP_MAP["$TARGET"]=1
    reconcile_runtime_after_restore() {
      echo "runtime_reconcile_called"
      return 0
    }
    printf "%s" "broken" > "$TARGET"
    false
  '

    [ "$status" -ne 0 ]
    [[ "$output" == *"runtime_reconcile_called"* ]]
    [ "$(cat "$target")" = "orig" ]
}

@test "atomic_write creates file atomically" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    local target="${tmpdir}/atomic-test.txt"

    run env TMPDIR="$tmpdir" bash -c '
    source ./lib.sh
    # Patch safe_prefixes for test environment
    atomic_write_test() {
      local target="$1"
      local mode="${2:-}"
      local tmp
      tmp=$(mktemp "${target}.tmp.XXXXXX")
      cat > "$tmp"
      [[ -n "$mode" ]] && chmod "$mode" "$tmp"
      mkdir -p "$(dirname "$target")"
      mv "$tmp" "$target"
    }
    echo "test content" | atomic_write_test "'"$target"'" 0644
    cat "'"$target"'"
  '
    rm -rf "$tmpdir"

    [ "$status" -eq 0 ]
    [ "$output" = "test content" ]
}

@test "atomic_write creates parent directories" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    local target="${tmpdir}/sub/dir/test.txt"

    run bash -c '
    source ./lib.sh
    atomic_write_test() {
      local target="$1"
      local mode="${2:-}"
      local dir
      dir=$(dirname "$target")
      mkdir -p "$dir"
      local tmp
      tmp=$(mktemp "${target}.tmp.XXXXXX")
      cat > "$tmp"
      [[ -n "$mode" ]] && chmod "$mode" "$tmp"
      mv "$tmp" "$target"
    }
    echo "nested" | atomic_write_test "'"$target"'" 0644
    cat "'"$target"'"
  '
    rm -rf "$tmpdir"

    [ "$status" -eq 0 ]
    [ "$output" = "nested" ]
}

@test "atomic_write rejects /tmp paths" {
    run bash -c '
    source ./lib.sh
    echo "test" | atomic_write "/tmp/should-fail.txt" 0644
  '
    [ "$status" -ne 0 ]
}

@test "atomic_write rejects path traversal" {
    run bash -c '
    source ./lib.sh
    echo "test" | atomic_write "/var/log/../etc/passwd" 0644
  '
    [ "$status" -ne 0 ]
}
