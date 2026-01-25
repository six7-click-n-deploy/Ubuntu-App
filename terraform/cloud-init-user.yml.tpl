#cloud-config
# Ubuntu-App Per-User Setup

# System-Update beim ersten Start
package_update: true

# SSH-Konfiguration aktivieren  
ssh_pwauth: true

# Pakete installieren
packages:
  - curl
  - wget
  - git
  - htop
  - nano
  - vim
  - openssl

# User erstellen (einer pro VM)
users:
  - name: ${username}
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    plain_text_passwd: ${password}
    home: /home/${username}
    
# SSH-Service neu starten und Konfiguration sicherstellen
runcmd:
  - sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - systemctl restart ssh
  - echo "Ubuntu-App User Setup abgeschlossen für: ${username}" >> /var/log/cloud-init-output.log
  
# Final message
final_message: |
  Ubuntu-App System ist bereit!
  
  Benutzer: ${username}
  SSH-Login: ssh ${username}@<vm-ip>
  Passwort: ${password}
