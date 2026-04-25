# --- Repo identity ---

variable "github_owner" {
  type        = string
  description = "GitHub username or org that owns the repo"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
}

variable "extra_secrets" {
  type        = map(string)
  default     = {}
  sensitive   = true
  description = "Additional Actions secrets to set on top of the auto-derived ones. Keys become secret names verbatim."
}

# --- OCI auth (synced as secrets) ---

variable "oci_user_ocid" {
  type      = string
  default   = ""
  sensitive = true
}

variable "oci_fingerprint" {
  type      = string
  default   = ""
  sensitive = true
}

variable "oci_private_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "ssh_private_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "ssh_public_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "ip_address" {
  type    = string
  default = ""
}

# --- Cloudflare credentials (passed through, synced as secrets) ---
# Empty strings mean "skip" — the github module doesn't itself enable cloudflare.

variable "cloudflare_api_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "cloudflare_zone_id" {
  type    = string
  default = ""
}

variable "domain_name" {
  type    = string
  default = ""
}

# --- Auth0 credentials (passed through, synced as secrets) ---

variable "auth0_domain" {
  type    = string
  default = ""
}

variable "auth0_client_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "auth0_client_secret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "auth0_m2m_client_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "auth0_m2m_client_secret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "auth0_admin_user_id" {
  type    = string
  default = ""
}

# --- Module-derived values from root (synced as secrets) ---

variable "tenancy_ocid" {
  type = string
}

variable "region" {
  type = string
}

variable "vault_ocid" {
  type = string
}

variable "vault_key_id" {
  type = string
}

variable "vault_crypto_endpoint" {
  type = string
}

variable "os_namespace" {
  type = string
}

variable "instance_public_ips" {
  type        = map(string)
  default     = {}
  description = "Map of instance key to public IP. Synced as <UPPERCASE_KEY>_IP."
}

variable "database_ids" {
  type        = map(string)
  default     = {}
  description = "Map of database key to OCID. Synced as <UPPERCASE_KEY>_DB_OCID."
}
