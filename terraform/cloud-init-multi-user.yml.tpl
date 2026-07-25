#cloud-config

ssh_pwauth: true

packages:
  - curl
  - wget
  - git
  - htop
  - nano
  - vim
  - openssl
  - net-tools

# Create one group per team
groups:
%{ for team in unique_teams ~}
  - ${team}
%{ endfor ~}

users:
%{ for idx, user in all_users ~}
  - name: ${user.username}
    shell: /bin/bash
    sudo: ['ALL=(ALL) ALL']
    groups: ${user.team}
    lock_passwd: false
%{ endfor ~}

# SSH config overrides via drop-in file
write_files:
  - path: /etc/ssh/sshd_config.d/99-custom.conf
    content: |
      PasswordAuthentication yes
      PubkeyAuthentication yes
      PermitRootLogin no
      UsePAM yes
    permissions: '0644'

chpasswd:
  expire: false
  users:
%{ for idx, user in all_users ~}
    - name: ${user.username}
      password: ${passwords[idx]}
      type: text
%{ endfor ~}

runcmd:
  - systemctl restart sshd

  # Optional: firewall
  - ufw --force enable
  - ufw allow OpenSSH

  # Setup log — passwords intentionally omitted for security
  - |
    cat >> /var/log/setup-complete.log <<EOF
    ================================================
    Setup completed: $(date)
    ================================================
    Teams: ${join(", ", unique_teams)}
    Users created: ${length(all_users)}
    ================================================
    EOF

final_message: |
  ================================================
  Ubuntu Multi-User System ready!
  ================================================
  Teams: ${join(", ", unique_teams)}
  Users: ${length(all_users)}

  SSH login: ssh <username>@<vm-ip>
  ================================================
