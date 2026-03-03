#!/bin/bash
# =============================================================================
# Common utilities for publish-from-notion wrapper scripts
# =============================================================================
# Source this at the top of each wrapper script:
#   source "$(dirname "$0")/common.sh"
#
# Provides:
#   acquire_lock "name"     — PID-based lock with stale detection
#   activate_venv           — Activate Python venv if present
#   notify_webhook "msg"    — Send notification via webhook (optional)
#   run_with_notify "name" cmd args...  — Run command, notify on failure
# =============================================================================

# Auto-detect project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Ensure required directories exist
mkdir -p "$PROJECT_DIR/locks"
mkdir -p "$PROJECT_DIR/logs"

# =============================================================================
# Lock management (PID-based, stale detection)
# =============================================================================
# Prevents multiple instances of the same script from running concurrently.
# If a previous instance crashed, the stale lock is detected and cleaned up.
#
# Usage:
#   acquire_lock "my_script"
#   # ... rest of your script
#   # Lock is automatically released on exit (EXIT, INT, TERM)
# =============================================================================

acquire_lock() {
    local lock_name="$1"
    LOCKFILE="$PROJECT_DIR/locks/${lock_name}.lock"

    # Check for existing lock
    if [ -f "$LOCKFILE" ]; then
        local old_pid
        old_pid=$(cat "$LOCKFILE" 2>/dev/null)

        if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
            # PID is alive — legitimate lock, exit gracefully
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Already running (PID $old_pid), skipping."
            exit 0
        else
            # PID is dead — stale lock, clean up
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Stale lock detected (PID $old_pid dead), cleaning up."
            rm -f "$LOCKFILE"
        fi
    fi

    # Create lock with our PID
    echo $$ > "$LOCKFILE"

    # Auto-cleanup on exit (EXIT, INT, TERM — not KILL)
    trap "rm -f '$LOCKFILE'" EXIT INT TERM
}

# =============================================================================
# Virtual environment activation
# =============================================================================

activate_venv() {
    if [ -f "$PROJECT_DIR/venv/bin/activate" ]; then
        source "$PROJECT_DIR/venv/bin/activate"
    elif [ -f "$PROJECT_DIR/.venv/bin/activate" ]; then
        source "$PROJECT_DIR/.venv/bin/activate"
    fi
}

# =============================================================================
# Webhook notifications (optional)
# =============================================================================
# Set MONITORING_WEBHOOK_URL in your .env to receive failure alerts.
# Compatible with Slack (incoming webhooks) or any JSON POST endpoint.
# =============================================================================

_load_webhook() {
    if [ -z "$MONITORING_WEBHOOK_URL" ] && [ -f "$PROJECT_DIR/.env" ]; then
        MONITORING_WEBHOOK_URL=$(grep '^MONITORING_WEBHOOK_URL=' "$PROJECT_DIR/.env" | cut -d'=' -f2-)
    fi
}

notify_webhook() {
    local message="$1"

    _load_webhook
    [ -z "$MONITORING_WEBHOOK_URL" ] && return 0

    curl -sf -X POST "$MONITORING_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"$message\"}" \
        >/dev/null 2>&1
}

# =============================================================================
# Run with failure notification
# =============================================================================
# Executes a command and sends a webhook alert if it fails.
# Includes anti-spam: won't alert more than once per 15 minutes per script.
#
# Usage:
#   run_with_notify "ghost-sync" python3 src/sync_ghost.py
# =============================================================================

run_with_notify() {
    local script_name="$1"
    shift

    # Execute the command
    "$@" 2>&1
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        # Anti-spam: skip alert if already alerted within 15 minutes
        local alert_file="$PROJECT_DIR/locks/.alert_${script_name}"
        if [ -f "$alert_file" ]; then
            local last_alert
            last_alert=$(cat "$alert_file" 2>/dev/null)
            local now
            now=$(date +%s)
            if [ $((now - last_alert)) -lt 900 ]; then
                return $exit_code
            fi
        fi

        date +%s > "$alert_file"
        notify_webhook "**${script_name}** failed (exit code: ${exit_code})"
    fi

    return $exit_code
}
