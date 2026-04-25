# --- Inputs from root ---

variable "tenancy_ocid" {
  type        = string
  description = "OCI tenancy OCID — used as compartment_id"
}

variable "project_name" {
  type        = string
  description = "Project name used in resource display names"
}

variable "vcn_id" {
  type        = string
  description = "VCN OCID for the LB NSG"
}

variable "public_subnet_id" {
  type        = string
  description = "Public subnet OCID for the LB"
}

variable "instances" {
  type = map(object({
    app_port  = number
    behind_lb = bool
  }))
  description = "Subset of root var.instances — only fields needed for backend wiring"
}

variable "instance_private_ips" {
  type        = map(string)
  description = "Map of instance key to private IP, used for LB backends"
}

# --- Cloudflare configuration ---

variable "domain_name" {
  type        = string
  description = "Apex domain for the origin certificate (e.g., example.com)"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for DNS records"
}

variable "dns_records" {
  type        = list(string)
  default     = []
  description = "DNS records to create. Use the domain itself for root, or a subdomain name."
}

variable "cloudflare_ipv4" {
  description = "Cloudflare IPv4 ranges allowed to reach the LB on 443"
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
  description = "Cloudflare IPv6 ranges allowed to reach the LB on 443"
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
