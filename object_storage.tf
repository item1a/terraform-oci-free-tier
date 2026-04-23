resource "oci_objectstorage_bucket" "backups" {
  count          = var.backup_bucket_name != "" ? 1 : 0
  compartment_id = var.tenancy_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = var.backup_bucket_name
  access_type    = "NoPublicAccess"

  lifecycle {
    prevent_destroy = true
  }
}
