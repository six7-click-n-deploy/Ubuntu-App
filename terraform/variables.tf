############################
# Frontend-Variablen
############################

########################################
# Custom-Variablen (Frontend) - Multi-VM Setup
########################################

variable "users" {
  description = "[CONTRACT] User-Emails (vom Dozenten übermittelt) - eine VM pro E-Mail"
  type        = list(string)
  default     = ["student@dhbw.de"]
}

variable "ubuntu_password" {
  description = "[ADMIN] Ubuntu admin user password"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "instance_name" {
  type        = string
  description = "Basis-Name der Instanz(en), z.B. 'webserver'"
  default     = "ubuntu-user"
}

variable "image_name" {
  type        = string
  description = "Name des Packer-Images, das deployed werden soll"
  default     = "ubuntu-v1"
}

variable "flavor" {
  type        = string
  description = "OpenStack Flavor (CPU/RAM/Disk-Größe)"
  default     = "gp1.small"
}

variable "enable_floating_ip" {
  type        = bool
  default     = true
  description = "Für jede VM eine Floating IP anlegen und assoziieren"
}

variable "allowed_tcp_ports" {
  type        = list(number)
  default     = []
  description = "Zusätzliche öffentliche TCP-Ports (z.B. [80, 443]). Leer = nur SSH (und optional ICMP)."
}

variable "allow_icmp" {
  type        = bool
  default     = true
  description = "Ping (ICMP) erlauben"
}

############################
# Backend-Defaults
############################

variable "key_pair" {
  type        = string
  description = "OpenStack Keypair Name (für SSH, meist fix pro Projekt)"
  default     = "test-key-pair"
}

variable "network_uuid" {
  description = "UUID of the internal network to attach the instance to (NOT the external network)"
  type        = string
  default     = "34a00b87-57ce-42c4-8e1b-9ea8a657ec2e"
}

variable "floating_ip_pool" {
  description = "Name of the floating IP pool (external network). Leave empty to use default."
  type        = string
  default     = "DHBW"
}

variable "ssh_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR für SSH-Zugriff. WARNUNG: 0.0.0.0/0 erlaubt globalen Zugriff! In Produktion auf eigene IP beschränken (z.B. 203.0.113.5/32)"
}

variable "metadata" {
  type        = map(string)
  default     = {}
  description = "Zusätzliche Metadata für die Instanzen"
}
