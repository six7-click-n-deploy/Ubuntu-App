#!/bin/bash
# Script für sauberes VM Re-Deployment

set -e

echo "🗑️  Lösche alte VM..."
terraform destroy -auto-approve

echo "🧹 Entferne alte SSH Host Keys..."
# Entferne bekannte DHBW IPs
ssh-keygen -R 141.72.13.246 2>/dev/null || true
ssh-keygen -R 141.72.12.205 2>/dev/null || true
ssh-keygen -R 141.72.13.187 2>/dev/null || true

echo "🚀 Deploye neue VM..."
terraform apply -auto-approve

echo "📋 Hole neue IP..."
NEW_IP=$(terraform output -raw floating_ip)

echo "🔑 Entferne Host Key für neue IP (falls vorhanden)..."
ssh-keygen -R $NEW_IP 2>/dev/null || true

echo ""
echo "✅ Deployment fertig!"
echo "🌐 Neue IP: $NEW_IP"
echo ""
echo "📡 SSH-Verbindung testen:"
echo "ssh alice@$NEW_IP    (Passwort: hallo123)"
echo "ssh clara@$NEW_IP    (Passwort: test123)"  
echo "ssh bob@$NEW_IP      (Passwort: einfach123)"
echo "ssh diana@$NEW_IP    (Passwort: ubuntu123)"
echo ""
echo "💡 Beim ersten SSH-Login: 'yes' eingeben!"
