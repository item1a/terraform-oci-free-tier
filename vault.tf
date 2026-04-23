resource "oci_kms_vault" "vault" {
  compartment_id = var.tenancy_ocid
  display_name   = "${var.project_name} Vault"
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "master_key" {
  compartment_id      = var.tenancy_ocid
  display_name        = "${var.project_name} Master Key"
  management_endpoint = oci_kms_vault.vault.management_endpoint

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}

# --- Dynamic Group for Instance Principal Auth ---

resource "oci_identity_dynamic_group" "instance_group" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-instance-group"
  description    = "Dynamic group for ${var.project_name} compute instances"
  matching_rule  = join(" || ", [
    for k, inst in oci_core_instance.instance :
    "instance.id = '${inst.id}'"
  ])
}

# --- IAM Policies ---

resource "oci_identity_policy" "vault_policy" {
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-vault-policy"
  description    = "Allow instances to use vault secrets and keys"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.instance_group.name} to use secret-family in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.instance_group.name} to read vaults in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.instance_group.name} to use keys in tenancy",
  ]
}

resource "oci_identity_policy" "db_policy" {
  count          = length(var.databases) > 0 ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-db-policy"
  description    = "Allow instances to download DB wallets"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.instance_group.name} to read autonomous-databases in tenancy",
  ]
}

resource "oci_identity_policy" "object_storage_policy" {
  count          = var.bucket_name != "" ? 1 : 0
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-object-storage-policy"
  description    = "Allow instances to read/write Object Storage bucket"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.instance_group.name} to manage objects in tenancy where target.bucket.name = '${var.bucket_name}'",
    "Allow dynamic-group ${oci_identity_dynamic_group.instance_group.name} to read buckets in tenancy",
  ]
}

# --- DB Secrets in Vault ---

resource "oci_vault_secret" "db_admin_password" {
  for_each       = var.databases
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.vault.id
  key_id         = oci_kms_key.master_key.id
  secret_name    = "${each.key}-db-admin-password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(random_password.db_admin[each.key].result)
  }

  lifecycle {
    ignore_changes = [secret_content]
  }
}

resource "oci_vault_secret" "db_wallet_password" {
  for_each       = var.databases
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.vault.id
  key_id         = oci_kms_key.master_key.id
  secret_name    = "${each.key}-db-wallet-password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(random_password.db_wallet[each.key].result)
  }

  lifecycle {
    ignore_changes = [secret_content]
  }
}
