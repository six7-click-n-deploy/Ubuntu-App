
output "instance_id" {
  value = openstack_compute_instance_v2.app.id
}

output "floating_ip" {
  value = var.enable_floating_ip ? openstack_networking_floatingip_v2.fip[0].address : null
}

