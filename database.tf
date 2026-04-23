# --- Passwords ---

resource "random_password" "db_admin" {
  for_each         = var.databases
  length           = 24
  special          = true
  override_special = "#-_"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "random_password" "db_wallet" {
  for_each         = var.databases
  length           = 24
  special          = true
  override_special = "#-_"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

# --- Autonomous Transaction Processing (ATP) ---

resource "oci_database_autonomous_database" "db" {
  for_each                    = var.databases
  compartment_id              = var.tenancy_ocid
  display_name                = each.value.display_name
  db_name                     = each.value.db_name
  db_workload                 = "OLTP"
  db_version                  = "23ai"
  is_free_tier                = true
  cpu_core_count              = 1
  data_storage_size_in_gb     = 20
  admin_password              = random_password.db_admin[each.key].result
  is_auto_scaling_enabled     = false
  is_mtls_connection_required = true

  lifecycle {
    ignore_changes = [
      admin_password,
      db_version,
      cpu_core_count,
      data_storage_size_in_gb,
      is_mtls_connection_required,
      is_auto_scaling_enabled,
    ]
  }
}
