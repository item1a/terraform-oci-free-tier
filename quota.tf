resource "oci_limits_quota" "free_tier" {
  depends_on     = [oci_core_instance.instance]
  compartment_id = var.tenancy_ocid
  name           = "${var.project_name}-free-tier-quota"
  description    = "Enforce free tier resource limits"

  statements = [
    "set compute-core quota standard-a1-core-count to 4 in tenancy",
    "set compute-core quota standard-e2-micro-core-count to 2 in tenancy",
    "set block-storage quota total-storage-gb to 200 in tenancy",
  ]
}
