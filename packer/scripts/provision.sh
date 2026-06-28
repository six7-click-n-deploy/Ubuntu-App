#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Minimal Provisioning Script für Golden Ubuntu 22.04 Image
# - Basistools + Python + Node.js
# - Idempotent, reproduzierbar, CI/CD-tauglich
# -----------------------------------------------------------------------------

NODE_MAJOR=24

echo "Warte auf cloud-init (sofern vorhanden)..."
cloud-init status --wait || true

echo "System aktualisieren..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade

echo "Installiere minimale Basis-Tools..."
sudo apt-get install -y --no-install-recommends \
  curl \
  ca-certificates \
  gnupg

echo "Installiere Python..."
sudo apt-get install -y --no-install-recommends \
  python3 \
  python3-pip \
  python3-venv \
  python-is-python3

echo "Füge NodeSource Repository für Node.js ${NODE_MAJOR}.x hinzu..."
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg

echo "Types: deb
URIs: https://deb.nodesource.com/node_${NODE_MAJOR}.x/
Suites: nodistro
Components: main
Signed-By: /etc/apt/keyrings/nodesource.gpg" \
  | sudo tee /etc/apt/sources.list.d/nodesource.sources > /dev/null

echo "Installiere Node.js..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends nodejs

# Optional, aber sinnvoll für npm-Pakete mit nativen Addons:
# sudo apt-get install -y --no-install-recommends build-essential

# SSH-Passwort-Authentifizierung vorbereiten (für cloud-init)
echo "Bereite SSH für Passwort-Auth vor..."
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

echo "Prüfe Versionen..."
python3 --version
pip3 --version
node --version
npm --version

echo "Cleanup: apt-Cache & Listen entfernen..."
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "Setze machine-id zurück..."
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id || true

echo "Provisioning abgeschlossen."