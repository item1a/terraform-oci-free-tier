# --- OCI Authentication ---
variable "TENANCY_OCID" { type = string }
variable "USER_OCID" { type = string }
variable "FINGERPRINT" { type = string }
variable "REGION" { type = string }
variable "IP_ADDRESS" {
  type        = string
  description = "Your public IP in CIDR form (e.g., 1.2.3.4/32)"
}

variable "OCI_PRIVATE_KEY_PATH" { type = string }
variable "SSH_PUBLIC_KEY_PATH" { type = string }
variable "SSH_PRIVATE_KEY_PATH" { type = string }

locals {
  oci_private_key = file(var.OCI_PRIVATE_KEY_PATH)
  ssh_public_key  = file(var.SSH_PUBLIC_KEY_PATH)
  ssh_private_key = file(var.SSH_PRIVATE_KEY_PATH)
}

# --- Cloudflare ---
variable "CLOUDFLARE_API_TOKEN" {
  type      = string
  sensitive = true
}
variable "CLOUDFLARE_ZONE_ID" { type = string }
variable "DOMAIN_NAME" {
  type        = string
  description = "Custom domain (e.g., example.com)"
}

# --- GitHub ---
variable "GITHUB_OWNER" { type = string }
variable "GITHUB_TOKEN" {
  type      = string
  sensitive = true
}
variable "GITHUB_REPO" { type = string }

# --- Auth0 ---
variable "AUTH0_DOMAIN" { type = string }

variable "AUTH0_CLIENT_ID" {
  type      = string
  sensitive = true
}

variable "AUTH0_CLIENT_SECRET" {
  type      = string
  sensitive = true
}

variable "AUTH0_M2M_CLIENT_ID" {
  type      = string
  sensitive = true
}

variable "AUTH0_M2M_CLIENT_SECRET" {
  type      = string
  sensitive = true
}

variable "AUTH0_API_AUDIENCE" {
  type        = string
  description = "Auth0 API identifier (e.g., https://api.example.com)"
}

variable "AUTH0_JWT_NAMESPACE" {
  type        = string
  description = "Custom-claim namespace prefix (e.g., https://app.example.com). Must match what your backend reads."
}

variable "AUTH0_CALLBACK_URLS" {
  type        = list(string)
  description = "Allowed callback URLs for the SPA (e.g., [\"https://app.example.com\", \"http://localhost:5173\"])"
}

variable "AUTH0_ADMIN_USER_ID" {
  type        = string
  default     = ""
  description = "Auth0 user_id (e.g., auth0|abc123) auto-assigned the admin role. Empty to skip."
}
