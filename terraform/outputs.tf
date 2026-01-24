# ===============================================
# 🚀 UBUNTU-APP TERRAFORM OUTPUTS - SIMPLIFIED
# ===============================================

# 1. 📋 HAUPT-OUTPUT: VM-Übersicht (das Wichtigste!)
output "vms" {
  description = "🖥️  Alle VMs mit SSH-Commands"
  value = [
    for i in range(var.vm_count) : {
      name        = "${var.user_prefix}${i + 1}"
      ip          = var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[i].address : openstack_compute_instance_v2.student_vms[i].network[0].fixed_ip_v4
      admin_ssh   = "ssh ubuntu@${var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[i].address : openstack_compute_instance_v2.student_vms[i].network[0].fixed_ip_v4}"
      student_ssh = "ssh ${var.user_prefix}${i + 1}@${var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[i].address : openstack_compute_instance_v2.student_vms[i].network[0].fixed_ip_v4}"
      fix_ssh_key = "ssh-keygen -R ${var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[i].address : openstack_compute_instance_v2.student_vms[i].network[0].fixed_ip_v4}"
    }
  ]
}

# 2. 🔑 PASSWORT-INFO: Wo sind die Passwörter?
output "passwords" {
  description = "🔐 Passwort-Informationen"
  value = {
    admin_password     = "Gesetzt via --var ubuntu_password (Standard: 'admin')"
    student_passwords  = "Auf jeder VM: sudo cat /var/lib/ubuntu-app/student-credentials.txt"
    admin_pw_anzeigen  = "terraform output admin_credentials"
  }
}

# 3. ⚡ QUICK-COMMANDS: Copy-Paste ready!
output "commands" {
  description = "📋 Copy-Paste Commands"
  value = var.vm_count > 0 ? {
    ssh_first_vm      = "ssh ubuntu@${var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[0].address : openstack_compute_instance_v2.student_vms[0].network[0].fixed_ip_v4}"
    get_student_pws   = "ssh ubuntu@${var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[0].address : openstack_compute_instance_v2.student_vms[0].network[0].fixed_ip_v4} 'sudo cat /var/lib/ubuntu-app/student-credentials.txt'"
    fix_ssh_keys      = "ssh-keygen -R ${var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[0].address : openstack_compute_instance_v2.student_vms[0].network[0].fixed_ip_v4}"
    show_admin_pw     = "terraform output admin_credentials"
  } : {
    info = "Keine VMs vorhanden - erst 'terraform apply' ausführen"
  }
}

# 4. 📊 DEPLOYMENT-INFO: Was wurde erstellt?
output "deployment" {
  description = "📈 Deployment-Details"
  value = {
    vm_count      = var.vm_count
    user_prefix   = var.user_prefix  
    floating_ips  = var.enable_floating_ip ? "✅ Aktiviert" : "❌ Deaktiviert"
    students      = [for i in range(var.vm_count) : "${var.user_prefix}${i + 1}"]
    admin_user    = "ubuntu"
  }
}

# 5. 🔐 ADMIN-CREDENTIALS (sensitive)
output "admin_credentials" {
  description = "🔑 Admin-Passwort (nur bei explizitem Abruf sichtbar)"
  sensitive = true
  value = {
    username = "ubuntu"
    password = var.ubuntu_password
  }
}

# 6. 🔄 LEGACY SUPPORT: Für bestehende Scripts
output "floating_ip" {
  description = "IP der ersten VM (Legacy)"
  value = var.vm_count > 0 && var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[0].address : null
}

output "instance_id" {
  description = "ID der ersten VM (Legacy)"  
  value = var.vm_count > 0 ? openstack_compute_instance_v2.student_vms[0].id : null
}

