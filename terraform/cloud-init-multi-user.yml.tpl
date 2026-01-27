#cloud-config
# Ubuntu-App Multi-User Setup

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

# Gruppen für jedes Team erstellen
groups:
%{ for team in unique_teams ~}
  - ${team}
%{ endfor ~}

# Benutzer erstellen (einer pro User)
users:
%{ for idx, user in all_users ~}
  - name: ${user.username}
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    passwd: ${passwords[idx]}
    home: /home/${user.username}
    groups: [${user.team}]
%{ endfor ~}

# SSH-Service neu starten und Konfiguration sicherstellen
runcmd:
  - sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/#ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/#UsePAM no/UsePAM yes/' /etc/ssh/sshd_config
  - sed -i 's/UsePAM no/UsePAM yes/' /etc/ssh/sshd_config
  - sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config
  - sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
  - grep -q "^PasswordAuthentication" /etc/ssh/sshd_config || echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
  - grep -q "^ChallengeResponseAuthentication" /etc/ssh/sshd_config || echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config
  - grep -q "^UsePAM" /etc/ssh/sshd_config || echo "UsePAM yes" >> /etc/ssh/sshd_config
  - systemctl restart ssh
  - echo "Ubuntu-App Multi-User Setup abgeschlossen" >> /var/log/cloud-init-output.log
%{ for idx, user in all_users ~}
  - echo "Benutzer: ${user.username}, Team: ${user.team}, Passwort: ${passwords[idx]}" >> /var/log/cloud-init-output.log
%{ endfor ~}

# Final message
final_message: |
  Ubuntu-App System ist bereit!

  Teams: ${join(", ", unique_teams)}
  Benutzer können sich mit SSH anmelden: ssh <username>@<vm-ip>
  Passwörter sind in /var/log/cloud-init-output.log gespeichert.