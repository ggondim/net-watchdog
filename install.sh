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

# Create safe defaults file
cat > "$DEFAULTS_FILE" <<'EOF'
# /etc/default/net-watchdog
# DRY_RUN=1 prevents the script from rebooting the system (safe default)
DRY_RUN=1
EOF

# Install systemd unit
cp "$PREFIX/net-watchdog.service" "$SERVICE_DST"
chmod 644 "$SERVICE_DST"

systemctl daemon-reload
systemctl enable --now net-watchdog.service

echo "Installation complete. Service enabled and started in DRY_RUN mode."
echo "To enable real reboot: edit $DEFAULTS_FILE and set DRY_RUN=0, then 'systemctl restart net-watchdog.service'"
