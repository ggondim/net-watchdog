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
- `install.sh` — installer script (copies files to /opt, creates /etc/default/net-watchdog with safe defaults, installs the unit and starts it in DRY_RUN mode).
- `uninstall.sh` — uninstaller script (stops service, disables and removes files).
- `LICENSE` — MIT license.
- `.gitignore` — ignores logs and system files.

Usage (install)
```bash
# IMPORTANT: installer requires root privileges and will enable automatic reboot by default.
# Run with sudo or as root. This will install files under /opt and register a systemd service.
sudo bash install.sh
```

The installer will place files under `/opt/net-watchdog` and enable the `net-watchdog.service`. By default the service starts with `DRY_RUN=1` to avoid accidental reboots.

Enable real reboot (read carefully!)
1. Edit `/etc/default/net-watchdog` and set `DRY_RUN=0`.
2. Reload systemd and restart the service:
```bash
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
