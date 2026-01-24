
output "instance_id" {
  value = openstack_compute_instance_v2.app.id
}

output "internal_ip" {
  value = openstack_compute_instance_v2.app.network[0].fixed_ip_v4
}

output "floating_ip" {
  value = var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[0].address : null
}

# Debug output für Troubleshooting
output "port_id" {
  value = var.enable_floating_ip ? data.openstack_networking_port_v2.vm_port[0].id : null
}

