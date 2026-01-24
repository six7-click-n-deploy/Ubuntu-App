# Ubuntu-App Admin Guide 📚

Diese Anleitung beschreibt die Administration des Ubuntu-App Systems mit dynamischer VM-Erstellung für Studenten.

---

## Das Wichtigste 

terraform apply -var="vm_count=3" -var="user_prefix=student" -var="ubuntu_password=123" -auto-approve

ssh ubuntu@<vm-ip>


User Passwörter: sudo cat /var/lib/ubuntu-app/student-credentials.txt


ssh-keygen -R <vm-ip>

---


## 🚀 System Overview

Das System erstellt automatisch **individuelle Ubuntu VMs für jeden Student**:
- ✅ **Eine VM pro Student** (nicht mehrere User pro VM)
- ✅ **Automatische Passwort-Generierung** für Student-Accounts
- ✅ **Flexibles Admin-Passwort** (Standard: "admin")
- ✅ **SSH-Zugang** für alle VMs aktiviert

---

## 🔑 1. Admin-Login (Quick Start)

### VM IPs herausfinden
```bash
# Im terraform/ Verzeichnis
terraform output vm_list
```

### Als Admin einloggen
```bash
# Standard Admin-Login (Passwort: "admin")
ssh ubuntu@<vm-ip>

# Beispiel:
ssh ubuntu@141.72.13.246
# Bei Prompt: admin
```

### Admin-Passwort prüfen
```bash
# Sensitive Info anzeigen
terraform output admin_info
```

---

## 👨‍🎓 2. Student-Passwörter abrufen

### Einzelne VM prüfen
```bash
# Nach Admin-Login auf der VM:
sudo cat /var/lib/ubuntu-app/student-credentials.txt
```

**Ausgabe-Format:**
```
Student Credentials for VM: student1
Username: student1  
Password: Xy9#mK2$pL8@
Login: ssh student1@141.72.13.246
```

### Alle VMs auf einmal prüfen
```bash
# Script für alle Student-Passwörter
for vm in student1 student2 student3; do
    echo "=== $vm ==="
    ip=$(terraform output -json vm_list | jq -r ".[] | select(.name==\"$vm\") | .ip")
    echo "IP: $ip"
    ssh ubuntu@$ip "sudo cat /var/lib/ubuntu-app/student-credentials.txt"
    echo
done
```

---

## 🔧 3. SSH Troubleshooting

### Host Key Konflikte (häufiges Problem)
```bash
# Nach VM-Neustart: "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED"
ssh-keygen -R <vm-ip>

# Beispiel:
ssh-keygen -R 141.72.13.246
```

### Alle VM Host Keys entfernen
```bash
# Bei kompletter Neu-Deployment
terraform output -json vm_list | jq -r '.[].ip' | xargs -I {} ssh-keygen -R {}
```

### SSH Debug Mode
```bash
# Bei Verbindungsproblemen
ssh -v ubuntu@<vm-ip>

# Passwort-Auth erzwingen
ssh -o PreferredAuthentications=password ubuntu@<vm-ip>
```

---

## 🛠 4. VM Management

### VM Status prüfen
```bash
# Alle VMs und ihre IPs
terraform output vm_list

# Sensitive Admin-Infos
terraform output admin_info

# OpenStack Status (falls verfügbar)
openstack server list
```

### Health Check alle VMs
```bash
#!/bin/bash
echo "=== Ubuntu-App VM Health Check ==="
terraform output -json vm_list | jq -r '.[] | "\(.name): \(.ip)"' | while IFS=': ' read name ip; do
    echo -n "Testing $name ($ip)... "
    if timeout 5 ssh -o ConnectTimeout=3 -o BatchMode=yes ubuntu@$ip "echo OK" 2>/dev/null; then
        echo "✅ Online"
    else
        echo "❌ Offline"
    fi
done
```

### VM neu starten
```bash
# Via SSH auf der VM
ssh ubuntu@<vm-ip>
sudo reboot

# Via OpenStack (falls verfügbar)
openstack server reboot student1
```

---

## 👥 5. Student Account Management

### Student-Account Details prüfen
```bash
# Nach SSH-Login auf VM als ubuntu:
sudo cat /etc/passwd | grep student
sudo passwd -S student1  # Account Status
```

### Student-Passwort ändern
```bash
# Neues Passwort setzen
sudo passwd student1

# Zufälliges Passwort generieren
new_pw=$(openssl rand -base64 12)
echo "student1:$new_pw" | sudo chpasswd
echo "Neues Passwort für student1: $new_pw"
```

### Student-Account sperren/entsperren
```bash
sudo usermod -L student1  # Sperren
sudo usermod -U student1  # Entsperren
```

---

## 🔐 6. Security & Best Practices

### Passwort-Policy
- **Admin-Passwort:** Variable `ubuntu_password`, Standard "admin"
- **Student-Passwörter:** Auto-generiert, 12 Zeichen mit Sonderzeichen
- **SSH:** Passwort-Auth für Development aktiviert

### Für Production Setup
```bash
# SSH Keys statt Passwörter
ssh-keygen -t ed25519 -f ~/.ssh/ubuntu-app-key
ssh-copy-id -i ~/.ssh/ubuntu-app-key ubuntu@<vm-ip>

# Dann in Terraform: disable password auth
```

### Firewall Check
```bash
# SSH Port 22 prüfen
sudo ufw status
sudo netstat -tlnp | grep :22
```

---

## 📊 7. Logs & Debugging

### Cloud-init Logs (VM Setup)
```bash
# Auf der VM:
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log

# Cloud-init Status
cloud-init status
```

### System Logs
```bash
# Allgemeine System-Logs
sudo journalctl -xe

# SSH Service
sudo journalctl -u ssh

# Cloud-init Debugging
sudo cloud-init logs
```

### Terraform Debugging
```bash
# Terraform Logs
export TF_LOG=DEBUG
terraform apply -var="vm_count=3"

# State prüfen
terraform show
terraform refresh
```

---

## 🚀 8. Deployment Commands

### Standard Deployment
```bash
cd terraform/
terraform apply -var="vm_count=3" -var="user_prefix=student"
```

### Mit custom Admin-Passwort
```bash
terraform apply \
  -var="vm_count=5" \
  -var="user_prefix=demo" \
  -var="ubuntu_password=mein-sicheres-passwort"
```

### VMs erweitern/reduzieren
```bash
# Von 3 auf 5 VMs
terraform apply -var="vm_count=5"

# Komplett löschen
terraform destroy
```

---

## ❌ 9. Common Problems & Solutions

### Problem: "Permission denied (publickey)"
```bash
# Lösung: Passwort-Auth explizit verwenden
ssh -o PreferredAuthentications=password ubuntu@<vm-ip>
```

### Problem: "Connection timeout"
```bash
# 1. VM Status prüfen
openstack server show student1

# 2. Security Groups prüfen
openstack security group list

# 3. Ping Test
ping <vm-ip>
```

### Problem: Student kann sich nicht einloggen
```bash
# 1. Auf VM als admin
ssh ubuntu@<vm-ip>

# 2. Student-Account prüfen
sudo passwd -S student1
sudo cat /var/lib/ubuntu-app/student-credentials.txt

# 3. SSH Test für Student
sudo su - student1
ssh localhost  # Loopback test
```

### Problem: Cloud-init Failed
```bash
# Cloud-init Status und Logs
cloud-init status
sudo cat /var/log/cloud-init-output.log | grep -i error

# Cloud-init neu ausführen (VORSICHT)
sudo cloud-init clean
sudo cloud-init init
```

---

## 📋 10. Quick Reference

### Wichtige Files
```
terraform/variables.tf     # Konfiguration
terraform/main.tf         # VM-Definition  
terraform/outputs.tf      # Terraform Outputs
terraform/cloud-init.yml.tpl  # VM Setup Template
```

### Wichtige Commands
```bash
# Status
terraform output vm_list
terraform output admin_info

# SSH
ssh ubuntu@<vm-ip>  # Admin
ssh student1@<vm-ip>  # Student

# Troubleshooting  
ssh-keygen -R <vm-ip>  # Host Key fix
sudo cat /var/lib/ubuntu-app/student-credentials.txt  # Passwörter
```

### Default Credentials
```
Admin User: ubuntu
Admin Password: admin (oder custom via ubuntu_password Variable)
Student User: student1, student2, etc.
Student Password: siehe /var/lib/ubuntu-app/student-credentials.txt
```

---

## 📞 Support

Bei Problemen diese Schritte befolgen:
1. **Terraform Outputs prüfen:** `terraform output`
2. **VM-Status checken:** `openstack server list`  
3. **SSH Debug:** `ssh -v ubuntu@<vm-ip>`
4. **VM-Logs analysieren:** SSH + `sudo journalctl -xe`
5. **OpenStack Console** falls SSH nicht funktioniert
6. **Im Notfall:** `terraform destroy` + `terraform apply`

### **Student-Login testen:**
```bash
# Mit dem gefundenen Passwort
ssh student1@<vm-ip>
# Passwort: ABC123DEF456
```

---

## 🌐 **3. VM-Übersicht abrufen**

### **Alle VMs und IPs anzeigen:**
```bash
# Im Terraform-Verzeichnis
cd ~/Documents/DHBW/5.\ Semester/six7/Ubuntu-App/terraform

# Alle VM-Infos
terraform output all_student_accounts

# Nur IP-Liste
terraform output vm_list
```

**Beispiel-Output:**
```json
{
  "accounts" = [
    {
      "ip_address" = "141.72.13.246"
      "student_name" = "student1"
      "ubuntu_login" = {
        "command" = "ssh ubuntu@141.72.13.246"
        "password" = "siehe Variable ubuntu_password"
      }
      "student_login" = {
        "command" = "ssh student1@141.72.13.246"
        "password" = "siehe /var/lib/ubuntu-app/student-credentials.txt"
      }
    },
    ...
  ]
}
```

---

## 🔧 **4. SSH-Troubleshooting**

### **Host Key Verification Failed:**
```bash
# Problem: "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"
# Lösung: Alten SSH Key entfernen
ssh-keygen -R <vm-ip>

# Beispiele:
ssh-keygen -R 141.72.13.246
ssh-keygen -R 141.72.12.248
ssh-keygen -R 141.72.12.119

# Dann neu verbinden
ssh ubuntu@<vm-ip>
```

### **Alle bekannten Hosts löschen:**
```bash
# VORSICHT: Löscht alle SSH Host Keys
rm ~/.ssh/known_hosts
```

### **SSH mit Passwort erzwingen:**
```bash
# Falls nur SSH Keys probiert werden
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no ubuntu@<vm-ip>
```

### **SSH Verbindung testen:**
```bash
# Ping-Test
ping <vm-ip>

# SSH Verbose Mode
ssh -v ubuntu@<vm-ip>
```

---

## 📋 **5. Cloud-init Debugging**

### **Cloud-init Status prüfen:**
```bash
# Nach Login auf der VM
cloud-init status

# Vollständige Logs
sudo cat /var/log/cloud-init-output.log

# Setup-Script Logs
sudo journalctl -u cloud-final | grep setup-student
```

### **VM Console Logs (von außen):**
```bash
# OpenStack Console Logs
openstack console log show ubuntu-user-student1 | tail -50
```

---

## 🚀 **6. Neue VMs erstellen**

### **Anzahl VMs ändern:**
```bash
cd ~/Documents/DHBW/5.\ Semester/six7/Ubuntu-App/terraform

# 5 VMs erstellen
terraform apply -var="vm_count=5" -var="user_prefix=student"

# Mit custom Admin-Passwort
terraform apply -var="vm_count=3" -var="user_prefix=demo" -var="ubuntu_password=geheim123"
```

### **VMs löschen:**
```bash
# Alle VMs zerstören
terraform destroy

# Nur bestimmte VMs
terraform destroy -target=openstack_compute_instance_v2.student_vms[2]
```

---

## 📝 **7. Tipps & Best Practices**

### **Session Management:**
```bash
# Aus SSH-Session raus
exit
# oder Ctrl+D

# SSH-Session beenden (falls hängend)
~.
```

### **Mehrere VMs gleichzeitig:**
```bash
# Terminal Tabs/Windows nutzen für mehrere VMs
# Tab 1: ssh ubuntu@141.72.13.246
# Tab 2: ssh ubuntu@141.72.12.248
# Tab 3: ssh ubuntu@141.72.12.119
```

### **Password-Manager Integration:**
```bash
# Alle Passwörter sammeln (Script-Beispiel)
for vm in student1 student2 student3; do
  echo "=== $vm ==="
  ssh ubuntu@$(terraform output -json vm_list | jq -r ".[] | select(.student_name==\"$vm\") | .ip_address") "sudo cat /var/lib/ubuntu-app/student-credentials.txt"
  echo ""
done
```

---

## ⚠️ **8. Sicherheitshinweise**

1. **Admin-Passwort nicht in Logs/Git:** Nutze `-var` statt tfvars-Dateien für Passwörter
2. **Student-Passwörter sind zufällig:** 16 Zeichen mit Zahlen/Buchstaben
3. **SSH Keys empfohlen:** Für Produktion besser als Passwörter
4. **Firewall:** SSH nur von bekannten IPs erlauben (`ssh_cidr` Variable)

---

## 📞 **9. Support**

**Terraform-Verzeichnis:**
```
~/Documents/DHBW/5. Semester/six7/Ubuntu-App/terraform/
```

**Wichtige Dateien:**
- `variables.tf` - Konfiguration
- `cloud-init.yml.tpl` - VM Setup Template
- `outputs.tf` - Terraform Outputs

**Commands Cheat Sheet:**
```bash
# Status
terraform output
terraform show

# Logs
terraform apply -var="vm_count=3" 2>&1 | tee deploy.log

# Debug
export TF_LOG=DEBUG
terraform apply
```