#!/usr/bin/env bash
# uninstall.sh - stops and removes net-watchdog and its systemd unit
set -euo pipefail

PREFIX="/opt/net-watchdog"
SERVICE_DST="/etc/systemd/system/net-watchdog.service"
DEFAULTS_FILE="/etc/default/net-watchdog"
LOGROTATE_FILE="/etc/logrotate.d/net-watchdog"

if [ "$EUID" -ne 0 ]; then
  echo "Run as root (or via sudo)." >&2
  exit 1
fi

echo "Stopping and disabling service..."
systemctl stop net-watchdog.service || true
systemctl disable net-watchdog.service || true

echo "Removing files..."
rm -f "$SERVICE_DST" || true
rm -f "$DEFAULTS_FILE" || true
rm -rf "$PREFIX" || true
rm -f "$LOGROTATE_FILE" || true

systemctl daemon-reload

echo "Uninstalled net-watchdog."
