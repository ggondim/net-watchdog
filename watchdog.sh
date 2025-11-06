#!/usr/bin/env bash
# watchdog.sh
# Monitors network connectivity and reboots when connectivity returns after a prolonged outage.

set -euo pipefail

PREFIX="/opt/net-watchdog"
CONFIG_FILE="$PREFIX/config.env"
LOGFILE="/var/log/net-watchdog.log"
PIDFILE="/var/run/net-watchdog.pid"

# defaults
CHECK_HOST="8.8.8.8"
CHECK_INTERVAL=5
DOWN_THRESHOLD=12
DRY_RUN=${DRY_RUN:-0}

# load config if present
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

log() {
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "${ts} - $*" | tee -a "$LOGFILE"
}

check() {
  if ping -c1 -W1 "$CHECK_HOST" > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

cleanup() {
  rm -f "$PIDFILE" || true
}

ensure_singleton() {
  if [ -f "$PIDFILE" ]; then
    local p
    p=$(cat "$PIDFILE" 2>/dev/null || true)
    if [ -n "$p" ] && kill -0 "$p" > /dev/null 2>&1; then
      echo "net-watchdog already running (PID $p). Exiting." >&2
      exit 0
    else
      echo "Found stale PID file, removing." >&2
      rm -f "$PIDFILE"
    fi
  fi
  echo $$ > "$PIDFILE"
  trap cleanup EXIT INT TERM
}

main() {
  ensure_singleton
  local down_count=0
  log "net-watchdog started. Checking $CHECK_HOST every ${CHECK_INTERVAL}s. DRY_RUN=${DRY_RUN}"

  while true; do
    if check; then
      if [ "$down_count" -ge 1 ]; then
        log "Connectivity restored after ${down_count} failures."
        if [ "$DRY_RUN" -eq 1 ]; then
          log "DRY_RUN=1 -> not rebooting (log only)."
        else
          log "Waiting a moment to stabilize and rebooting..."
          sleep 5
          log "Rebooting now..."
          /sbin/shutdown -r now "net-watchdog: rebooting after network restoration"
        fi
      fi
      down_count=0
    else
      down_count=$((down_count+1))
      log "Check failed (#${down_count})."
      if [ "$down_count" -ge "$DOWN_THRESHOLD" ]; then
        log "Network seems down for >= ${DOWN_THRESHOLD} checks (~${DOWN_THRESHOLD}*${CHECK_INTERVAL}s). Waiting for restoration..."
        while ! check; do
          sleep "$CHECK_INTERVAL"
        done
        log "Network restored."
        if [ "$DRY_RUN" -eq 1 ]; then
          log "DRY_RUN=1 -> not rebooting (log only)."
        else
          log "Waiting a moment to stabilize and rebooting..."
          sleep 5
          log "Rebooting now..."
          /sbin/shutdown -r now "net-watchdog: rebooting after network restoration"
        fi
      fi
    fi
    sleep "$CHECK_INTERVAL"
  done
}

main
