variable "auth0_api_audience" {
  type        = string
  description = "Auth0 API identifier (audience claim) — e.g., https://api.example.com"
}

variable "auth0_jwt_namespace" {
  type        = string
  description = "Custom-claim namespace prefix injected into JWTs by the post-login action — e.g., https://app.example.com. Must match what your backend reads."
}

variable "auth0_callback_urls" {
  type        = list(string)
  default     = []
  description = "Allowed callback / logout / web-origin URLs for the SPA client"
}

variable "auth0_admin_user_id" {
  type        = string
  default     = ""
  description = "Auth0 user_id (e.g., auth0|abc123) auto-assigned the admin role. Empty to skip."
}

variable "auth0_spa_name" {
  type        = string
  default     = "SPA"
  description = "Display name for the Auth0 SPA client"
}

variable "auth0_m2m_name" {
  type        = string
  default     = "Terraform (M2M)"
  description = "Display name for the Auth0 M2M client"
}

variable "auth0_api_name" {
  type        = string
  default     = "API"
  description = "Display name for the Auth0 API resource server"
}
