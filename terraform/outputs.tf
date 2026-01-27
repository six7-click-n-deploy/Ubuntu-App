
############################
# [CONTRACT] User Accounts Output
############################

output "user_accounts" {
  description = "[CONTRACT] User accounts mit Login-Informationen"
  sensitive   = true # Enthält Passwörter
  value = local.vm_count > 0 ? {
    for i in range(local.vm_count) : local.user_ids[i] => {
      type     = "password"
      ip       = local.enable_floating_ip ? openstack_networking_floatingip_v2.fip[i].address : openstack_compute_instance_v2.student_vms[i].network[0].fixed_ip_v4
      port     = 22
      username = local.usernames[i]
      auth     = random_password.user_passwords[i].result
      email    = local.emails[i]
      team     = local.all_users[i].team
    }
  } : {}
}

############################
# VM Details
############################

output "vm_details" {
  description = "Details aller User-VMs"
  value = local.vm_count > 0 ? {
    for i in range(local.vm_count) : local.user_ids[i] => {
      instance_id   = openstack_compute_instance_v2.student_vms[i].id
      instance_name = openstack_compute_instance_v2.student_vms[i].name
      fixed_ip      = openstack_compute_instance_v2.student_vms[i].network[0].fixed_ip_v4
      floating_ip   = local.enable_floating_ip ? openstack_networking_floatingip_v2.fip[i].address : null
      ssh_command   = local.enable_floating_ip ? "ssh ${local.usernames[i]}@${openstack_networking_floatingip_v2.fip[i].address}" : "ssh ${local.usernames[i]}@${openstack_compute_instance_v2.student_vms[i].network[0].fixed_ip_v4}"
      team          = local.all_users[i].team
    }
  } : {}
}

output "users_summary" {
  description = "Übersicht: Anzahl VMs und User"
  value = {
    vm_count  = local.vm_count
    usernames = local.usernames
    emails    = local.emails
    teams     = distinct([for user in local.all_users : user.team])
  }
}

