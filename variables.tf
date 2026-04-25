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

variable "bucket_name" {
  type        = string
  default     = ""
  description = "Name for the Object Storage bucket. Empty string skips creation."
}

# --- Tags ---

variable "project_name" {
  type        = string
  default     = "app"
  description = "Project name used in resource display names"
}
