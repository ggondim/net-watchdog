#!/usr/bin/env bash
# install.sh - installs net-watchdog into /opt and enables systemd service
set -euo pipefail

PREFIX="/opt/net-watchdog"
SERVICE_DST="/etc/systemd/system/net-watchdog.service"
DEFAULTS_FILE="/etc/default/net-watchdog"

if [ "$EUID" -ne 0 ]; then
  echo "This installer must be run as root (or via sudo)." >&2
  exit 1
fi

echo "Installing net-watchdog to $PREFIX ..."
mkdir -p "$PREFIX"
cp -r ./* "$PREFIX/"
chown -R root:root "$PREFIX"
chmod +x "$PREFIX"/*.sh

# Create defaults file (WARNING: enables real reboot)
cat > "$DEFAULTS_FILE" <<'EOF'
# /etc/default/net-watchdog
# DRY_RUN=0 enables real reboot when the watchdog detects restoration after outage.
# Be sure you understand the risk: the system will reboot automatically when network
# is restored after a prolonged outage. Installer sets DRY_RUN=0 as requested.
DRY_RUN=0
EOF

# Install systemd unit
cp "$PREFIX/net-watchdog.service" "$SERVICE_DST"
chmod 644 "$SERVICE_DST"

systemctl daemon-reload
systemctl enable --now net-watchdog.service

echo "Installation complete. Service enabled and started with DRY_RUN=0 (real reboot enabled)."
echo "WARNING: the service will reboot the system automatically when network restoration is detected."
echo "If you want to disable automatic reboot, set DRY_RUN=1 in $DEFAULTS_FILE and restart the service."
