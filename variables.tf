# --- OCI Authentication ---

variable "tenancy_ocid" {
  type        = string
  description = "OCI tenancy OCID"
}

variable "region" {
  type        = string
  description = "OCI region (e.g., us-ashburn-1)"
}

# --- Compute ---

variable "arm_shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}

variable "arm_ocpus" {
  type    = number
  default = 4
}

variable "arm_memory_gb" {
  type    = number
  default = 24
}

variable "boot_volume_size_gb" {
  type    = number
  default = 50
}

variable "block_volume_size_gb" {
  type        = number
  default     = 50
  description = "Block volume size in GB. Set to 0 to skip block volume creation."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key content for instance access"
}

# --- Cloud Init ---

variable "extra_packages" {
  type        = list(string)
  default     = []
  description = "Additional dnf packages/modules to install (e.g., [\"nodejs:20\", \"python3\"])"
}

variable "extra_cloud_init" {
  type        = string
  default     = ""
  description = "Additional shell commands to run at end of cloud-init"
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "app_user" {
  type    = string
  default = "opc"
}

variable "workspace_path" {
  type    = string
  default = "/var/workspace"
}

# --- Databases ---

variable "databases" {
  type = map(object({
    display_name = string
    db_name      = string
  }))
  default = {}
  description = "Map of ATP databases to create. Key is used for resource naming. Example: { main = { display_name = \"MainDB\", db_name = \"MAINDB\" } }"
}

# --- Object Storage ---

variable "backup_bucket_name" {
  type        = string
  default     = ""
  description = "Name for the backup bucket. Empty string skips creation."
}

# --- Cloudflare (optional) ---

variable "enable_cloudflare" {
  type    = bool
  default = false
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
  default   = ""
}

variable "cloudflare_zone_id" {
  type    = string
  default = ""
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "dns_records" {
  type        = list(string)
  default     = []
  description = "DNS records to create. Use the domain itself for root, or a subdomain name (e.g., [\"example.com\", \"app\"])"
}

variable "cloudflare_ipv4" {
  description = "Cloudflare IPv4 ranges for NSG rules"
  default = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/12",
    "172.64.0.0/13",
    "131.0.72.0/22",
  ]
}

variable "cloudflare_ipv6" {
  description = "Cloudflare IPv6 ranges for NSG rules"
  default = [
    "2400:cb00::/32",
    "2606:4700::/32",
    "2803:f800::/32",
    "2405:b500::/32",
    "2405:8100::/32",
    "2a06:98c0::/29",
    "2c0f:f248::/32",
  ]
}

# --- Tags ---

variable "project_name" {
  type        = string
  default     = "app"
  description = "Project name used in resource display names"
}
