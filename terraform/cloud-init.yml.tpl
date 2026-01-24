#cloud-config
# Ubuntu-App Single-User Setup per VM

# System-Update beim ersten Start
package_update: true

# SSH-Konfiguration aktivieren  
ssh_pwauth: true

# Ubuntu user mit konfigurierbarem Passwort
users:
  - name: ubuntu
    plain_text_passwd: "${ubuntu_password}"
    lock_passwd: false
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
  - name: ubuntu
    plain_text_passwd: "admin"
    lock_passwd: false
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
  - name: ${student_name}
    lock_passwd: false
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash

# Script für zufälliges Student-Passwort
write_files:
  - path: /usr/local/bin/setup-student-password.sh
    permissions: '0755'
    owner: root:root
    content: |
      #!/usr/bin/env bash
      set -euo pipefail
      
      STUDENT_NAME="${student_name}"
      RANDOM_PASSWORD="$(openssl rand -base64 16 | tr -d '+/=' | cut -c1-12)$(date +%s | tail -c4)"
      
      # Passwort für Student setzen
      echo "$STUDENT_NAME:$RANDOM_PASSWORD" | chpasswd
      
      # Credentials in Datei speichern
      OUT_DIR="/var/lib/ubuntu-app"
      OUT_FILE="$OUT_DIR/student-credentials.txt"
      mkdir -p "$OUT_DIR"
      chmod 700 "$OUT_DIR"
      
      echo "ubuntu:admin" > "$OUT_FILE"
      echo "$STUDENT_NAME:$RANDOM_PASSWORD" >> "$OUT_FILE"
      chmod 600 "$OUT_FILE"
      
      echo "Student-Passwort gesetzt für: $STUDENT_NAME"
      echo "Credentials gespeichert in: $OUT_FILE"

# Pakete installieren
packages:
  - curl
  - wget
  - git
  - htop
  - nano
  - vim

# SSH-Service konfigurieren
runcmd:
  - sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - systemctl restart ssh
  - /usr/local/bin/setup-student-password.sh
  - echo "Student-VM Setup abgeschlossen für ${student_name}" >> /var/log/cloud-init-output.log
  
# Final message
final_message: |
  Student-VM ist bereit!
  
  Benutzer erstellt: ${student_name}
  
  Login-Optionen:
  - ssh ubuntu@<vm-ip> (Passwort: admin)
  - ssh ${student_name}@<vm-ip> (Passwort: siehe /var/lib/ubuntu-app/student-credentials.txt)