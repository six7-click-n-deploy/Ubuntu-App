
# Multi-VM Outputs
output "vm_details" {
  description = "Details aller erstellten VMs"
  value = local.vm_count > 0 ? {
    for i in range(local.vm_count) : "vm${i + 1}" => {
      vm_name     = openstack_compute_instance_v2.student_vms[i].name
      internal_ip = openstack_compute_instance_v2.student_vms[i].network[0].fixed_ip_v4
      floating_ip = var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[i].address : null
      username    = local.usernames[i]
      email       = var.users[i]
      instance_id = openstack_compute_instance_v2.student_vms[i].id
      port_id     = var.enable_floating_ip ? data.openstack_networking_port_v2.vm_port[i].id : null
    }
  } : {}
}

# Summary Output
output "deployment_summary" {
  description = "Zusammenfassung der Deployment"
  value = local.vm_count > 0 ? {
    vm_count     = local.vm_count
    users        = [for email in var.users : { email = email }]
    usernames    = local.usernames
    floating_ips = var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[*].address : []
    internal_ips = openstack_compute_instance_v2.student_vms[*].network[0].fixed_ip_v4
  } : null
}

# Convenience Outputs (für Backward Compatibility)
output "instance_id" {
  description = "ID der ersten VM (für Backward Compatibility)"
  value       = local.vm_count > 0 ? openstack_compute_instance_v2.student_vms[0].id : null
}

output "internal_ip" {
  description = "Interne IP der ersten VM (für Backward Compatibility)"
  value       = local.vm_count > 0 ? openstack_compute_instance_v2.student_vms[0].network[0].fixed_ip_v4 : null
}

output "floating_ip" {
  description = "Floating IP der ersten VM (für Backward Compatibility)"
  value       = local.vm_count > 0 && var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[0].address : null
}

# Debug outputs für Troubleshooting
output "port_id" {
  description = "Port ID der ersten VM (für Backward Compatibility)"
  value       = local.vm_count > 0 && var.enable_floating_ip ? data.openstack_networking_port_v2.vm_port[0].id : null
}

