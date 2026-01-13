#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Minimal Provisioning Script für Golden Ubuntu 22.04 Image
# - Keine Applikationen, nur Basistools
# - Idempotent, reproduzierbar, CI/CD-tauglich
# -----------------------------------------------------------------------------

echo "Warte auf cloud-init (sofern vorhanden)..."
cloud-init status --wait || true

echo "System aktualisieren..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

echo "Installiere minimale Basis-Tools..."
sudo apt-get install -y --no-install-recommends curl ca-certificates

# Keine weiteren Applikationen oder Konfigurationen!

echo "Cleanup: apt-Cache & Listen entfernen..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "Setze machine-id zurück..."
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id || true

echo "Provisioning abgeschlossen."