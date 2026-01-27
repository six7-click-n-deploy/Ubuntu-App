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

############################
# APP-DEFAULTS (vom App-Entwickler vorgegeben)
############################

locals {
  # Diese Werte sind App-spezifisch und werden vom App-Entwickler definiert
  app_name           = "ubuntu-user"
  flavor             = "gp1.small"
  key_pair           = "" # Leer = nur Passwort-Auth
  enable_floating_ip = true
  ssh_cidr           = "0.0.0.0/0" # SSH-Zugriff von überall erlauben
  allow_icmp         = true
  allowed_tcp_ports  = [] # Leer = nur SSH
  metadata           = {}
}

############################
# USER MANAGEMENT (CONTRACT)
############################

# Flatten users from teams - EXAKT wie im Contract vorgegeben
locals {
  all_users = flatten([
    for team, members in var.users : [
      for member in members : {
        id       = "${team}-${replace(split("@", member.email)[0], ".", "-")}"
        team     = team
        email    = member.email
        username = replace(split("@", member.email)[0], ".", "")
      }
    ]
  ])

  # VM-Anzahl = Anzahl aller User (unabhängig von Teams)
  vm_count = length(local.all_users)

  # Liste aller Usernamen und E-Mails
  usernames = [for user in local.all_users : user.username]
  emails    = [for user in local.all_users : user.email]
  user_ids  = [for user in local.all_users : user.id]
}

# Passwörter für jeden User generieren
resource "random_password" "user_passwords" {
  count   = local.vm_count
  length  = 16
  special = true
  # Mindestens: 1 Uppercase, 1 Lowercase, 1 Zahl, 1 Sonderzeichen
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
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
  name        = "${local.app_name}-sg-${random_id.suffix.hex}"
  description = "Security group for clean Ubuntu VM"
}

#tfsec:ignore:openstack-networking-no-public-ingress
resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = local.ssh_cidr # User-konfigurierbar: In Produktion auf eigene IP beschränken
  security_group_id = openstack_networking_secgroup_v2.app_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "tcp" {
  for_each          = toset([for p in local.allowed_tcp_ports : tostring(p)])
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = each.value
  port_range_max    = each.value
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.app_sg.id
}

#tfsec:ignore:openstack-networking-no-public-ingress
resource "openstack_networking_secgroup_rule_v2" "icmp" {
  count             = local.allow_icmp ? 1 : 0
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0" # ICMP (Ping) von überall für Netzwerk-Diagnose
  security_group_id = openstack_networking_secgroup_v2.app_sg.id
}



# -----------------------------------------------------------------------------
# Multiple Instances (eine pro User)
# -----------------------------------------------------------------------------
resource "openstack_compute_instance_v2" "student_vms" {
  count       = local.vm_count
  name        = "${local.app_name}-${local.usernames[count.index]}"
  image_id    = data.openstack_images_image_v2.image.id
  flavor_name = local.flavor
  key_pair    = local.key_pair != "" ? local.key_pair : null

  security_groups = [openstack_networking_secgroup_v2.app_sg.name]

  timeouts {
    create = "15m"
    delete = "15m"
  }

  network {
    uuid = var.network_uuid
  }

  user_data = templatefile("${path.module}/cloud-init-user.yml.tpl", {
    username = local.usernames[count.index]
    password = random_password.user_passwords[count.index].result
  })

  metadata = merge(local.metadata, {
    student = local.usernames[count.index]
    email   = local.emails[count.index]
    team    = local.all_users[count.index].team
  })
}

# -----------------------------------------------------------------------------
# Optional Floating IPs (eine pro VM)
# -----------------------------------------------------------------------------
resource "openstack_networking_floatingip_v2" "fip" {
  count = local.enable_floating_ip ? local.vm_count : 0
  pool  = data.openstack_networking_network_v2.external.name
}

# Warten bis VMs vollständig gebootet sind
resource "time_sleep" "wait_for_vm" {
  count           = local.enable_floating_ip ? local.vm_count : 0
  depends_on      = [openstack_compute_instance_v2.student_vms]
  create_duration = "60s"
}

# Port-IDs der VMs finden
data "openstack_networking_port_v2" "vm_port" {
  count     = local.enable_floating_ip ? local.vm_count : 0
  device_id = openstack_compute_instance_v2.student_vms[count.index].id
  depends_on = [
    openstack_compute_instance_v2.student_vms,
    time_sleep.wait_for_vm
  ]
}

# Floating IP Association mit data-basierter Port-ID
resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
  count       = local.enable_floating_ip ? local.vm_count : 0
  floating_ip = openstack_networking_floatingip_v2.fip[count.index].address
  port_id     = data.openstack_networking_port_v2.vm_port[count.index].id

  depends_on = [
    data.openstack_networking_port_v2.vm_port,
    time_sleep.wait_for_vm
  ]
}
