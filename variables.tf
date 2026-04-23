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

variable "instances" {
  type = map(object({
    ocpus            = number
    memory_gb        = number
    boot_volume_gb   = optional(number, 50)
    block_volume_gb  = optional(number, 0)
    app_port         = optional(number, 8080)
    app_user         = optional(string, "opc")
    workspace_path   = optional(string, "/var/workspace")
    extra_packages   = optional(list(string), [])
    extra_cloud_init = optional(string, "")
    behind_lb        = optional(bool, true)
  }))
  default = {
    app = {
      ocpus     = 4
      memory_gb = 24
    }
  }
  description = "Map of ARM instances to create. Total OCPUs must not exceed 4, total memory must not exceed 24GB."
}

variable "arm_shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key content for instance access"
}

# --- Databases ---

variable "databases" {
  type = map(object({
    display_name = string
    db_name      = string
  }))
  default     = {}
  description = "Map of ATP databases to create. Key is used for resource naming."
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
