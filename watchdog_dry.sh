#!/usr/bin/env bash
# watchdog_dry.sh - dry-run version that never reboots
set -eu
CHECK_HOST="8.8.8.8"
CHECK_INTERVAL=2
DOWN_THRESHOLD=3
LOGFILE="/tmp/net-watchdog-dry.log"

log(){
  echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ") - $*" | tee -a "$LOGFILE"
}

check(){
  if ping -c1 -W1 "$CHECK_HOST" > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

main(){
  local down_count=0
  log "dry-watchdog started"
  local end=$((SECONDS+30))
  while [ "$SECONDS" -lt "$end" ]; do
    if check; then
      if [ "$down_count" -ge 1 ]; then
        log "(DRY) Connectivity restored after $down_count failures. (not rebooting)"
      fi
      down_count=0
    else
      down_count=$((down_count+1))
      log "(DRY) Check failed (#$down_count)"
      if [ "$down_count" -ge "$DOWN_THRESHOLD" ]; then
        log "(DRY) Network looks down for >= $DOWN_THRESHOLD checks. Waiting for restoration..."
        while ! check; do
          sleep "$CHECK_INTERVAL"
        done
        log "(DRY) Network restored. (not rebooting)"
      fi
    fi
    sleep "$CHECK_INTERVAL"
  done
  log "dry-watchdog finished"
}

main
