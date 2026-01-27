terraform {
  required_version = ">= 1.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.10"
    }
  }
}

provider "openstack" {
  cloud = "openstack"
  # Auth via OS_CLOUD + clouds.yaml (oder OS_* env vars)
}

# Automatische Berechnung der VM-Anzahl und Benutzernamen aus users Variable
locals {
  # VM-Anzahl = Anzahl User-E-Mails
  vm_count = length(var.users)

  # Erstelle Benutzernamen aus E-Mail-Adressen (Teil vor @, ohne Punkte/Sonderzeichen)
  usernames = [for email in var.users : replace(split("@", email)[0], ".", "")]
}

# Packer-built image lookup by name (keine IDs hardcoden)
data "openstack_images_image_v2" "image" {
  name        = var.image_name
  most_recent = true
}

# External network nur nötig, wenn Floating IP aktiviert ist
data "openstack_networking_network_v2" "external" {
  name = var.floating_ip_pool
}

resource "random_id" "suffix" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# Security Group: templatefähig über Variablen
# - SSH auf ssh_cidr
# - Weitere TCP Ports über allowed_tcp_ports
# - ICMP optional
# -----------------------------------------------------------------------------
resource "openstack_networking_secgroup_v2" "app_sg" {
  name        = "${var.instance_name}-sg-${random_id.suffix.hex}"
  description = "Security group for clean Ubuntu VM"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.ssh_cidr
  security_group_id = openstack_networking_secgroup_v2.app_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "tcp" {
  for_each          = toset(var.allowed_tcp_ports)
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = each.value
  port_range_max    = each.value
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.app_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  count             = var.allow_icmp ? 1 : 0
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.app_sg.id
}



# -----------------------------------------------------------------------------
# Multiple Instances (eine pro User)
# -----------------------------------------------------------------------------
resource "openstack_compute_instance_v2" "student_vms" {
  count       = local.vm_count
  name        = "${var.instance_name}-${local.usernames[count.index]}"
  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = var.flavor
  key_pair    = var.key_pair

  security_groups = [openstack_networking_secgroup_v2.app_sg.name]

  network {
    uuid = var.network_uuid
  }

  user_data = templatefile("cloud-init.yml", {
    user_prefix     = local.usernames[count.index]
    ubuntu_password = var.ubuntu_password
  })

  metadata = merge(var.metadata, {
    student = local.usernames[count.index]
    email   = var.users[count.index]
  })
}

# -----------------------------------------------------------------------------
# Optional Floating IPs (eine pro VM)
# -----------------------------------------------------------------------------
resource "openstack_networking_floatingip_v2" "fip" {
  count = var.enable_floating_ip ? local.vm_count : 0
  pool  = data.openstack_networking_network_v2.external.name
}

# Warten bis VMs vollständig gebootet sind
resource "time_sleep" "wait_for_vm" {
  count           = var.enable_floating_ip ? local.vm_count : 0
  depends_on      = [openstack_compute_instance_v2.student_vms]
  create_duration = "60s"
}

# Port-IDs der VMs finden
data "openstack_networking_port_v2" "vm_port" {
  count     = var.enable_floating_ip ? local.vm_count : 0
  device_id = openstack_compute_instance_v2.student_vms[count.index].id
  depends_on = [
    openstack_compute_instance_v2.student_vms,
    time_sleep.wait_for_vm
  ]
}

# Floating IP Association mit data-basierter Port-ID
resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
  count       = var.enable_floating_ip ? local.vm_count : 0
  floating_ip = openstack_networking_floatingip_v2.fip[count.index].address
  port_id     = data.openstack_networking_port_v2.vm_port[count.index].id

  depends_on = [
    data.openstack_networking_port_v2.vm_port,
    time_sleep.wait_for_vm
  ]
}
