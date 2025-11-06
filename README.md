# net-watchdog

A small system watchdog that monitors network connectivity and reboots the system when connectivity returns after a prolonged outage.

This repository contains the monitoring scripts, a systemd unit, and simple installer and uninstaller scripts so you can deploy the watchdog on a Linux host.

Quick overview
- The watchdog periodically pings a host (default: 8.8.8.8).
- If the host is unreachable for a configured number of attempts (default: 12 attempts × 5s = ~60s), the watchdog waits until connectivity returns.
- When connectivity returns, the watchdog optionally reboots the system (controlled by `DRY_RUN`).

Files included
- `watchdog.sh` — main script (supports config and DRY_RUN). 
- `watchdog_dry.sh` — test script (never reboots).
- `net-watchdog.service` — systemd unit file.
- `config.env` — example configuration file.
- `install.sh` — installer script (copies files to /opt, creates `/etc/default/net-watchdog` and installs the systemd unit). NOTE: installer now enables `DRY_RUN=0` by default (real reboot enabled).
- `uninstall.sh` — uninstaller script (stops service, disables and removes files).
- `LICENSE` — MIT license.
- `.gitignore` — ignores logs and system files.

Usage (install)
```bash
# IMPORTANT: installer requires root privileges and will enable automatic reboot by default.
# Run with sudo or as root. This will install files under /opt and register a systemd service.
sudo bash install.sh
```

The installer will place files under `/opt/net-watchdog` and enable the `net-watchdog.service`.

IMPORTANT: the installer now configures `/etc/default/net-watchdog` with `DRY_RUN=0` by default — that means the service will perform a real reboot when it detects network restoration after a prolonged outage. Be sure you want that behavior before running the installer.

If you want to keep the service from rebooting automatically after installation, disable it by setting `DRY_RUN=1` and restarting the service:

```bash
echo 'DRY_RUN=1' | sudo tee /etc/default/net-watchdog
sudo systemctl daemon-reload
sudo systemctl restart net-watchdog.service
```

Test safely
- Use `./watchdog_dry.sh` to test behavior locally without risking a reboot.
- To simulate loss of connectivity to the configured check host:
```bash
sudo ip route add 8.8.8.8/32 via 127.0.0.1 dev lo
# run tests and watch logs, then restore
sudo ip route del 8.8.8.8/32
```

Uninstall
```bash
sudo bash uninstall.sh
```

Security and recommendations
- Consider checking multiple hosts and using TCP connect checks in production.
- Add alerting (email, Slack) before performing an automatic reboot.
- Ensure you have console access before enabling real reboot on a critical machine.

License: MIT

_This tested repository was made 100% by GitHub Copilot (GPT-5-mini)_
