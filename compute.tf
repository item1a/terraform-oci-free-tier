resource "oci_core_instance" "instance" {
  for_each            = var.instances
  compartment_id      = var.tenancy_ocid
  availability_domain = local.availability_domain
  display_name        = "${var.project_name}-${each.key}"

  shape = var.arm_shape
  shape_config {
    ocpus         = each.value.ocpus
    memory_in_gbs = each.value.memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = local.arm_image_id
    boot_volume_size_in_gbs = each.value.boot_volume_gb
  }
  preserve_boot_volume = false

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
  }

  agent_config {
    is_management_disabled = false
    is_monitoring_disabled = false
    plugins_config {
      name          = "Bastion"
      desired_state = "ENABLED"
    }
  }

  lifecycle {
    # source_details intentionally NOT in this list — Oracle refreshes
    # the OL9 ARM image periodically and we want plans against running
    # instances to propose a rebuild against the newer image. Operators
    # need to provide free-tier quota headroom (≤ 150 GB existing total
    # so the swap can hold a transient second boot volume) before the
    # apply will succeed.
    ignore_changes = [metadata, defined_tags, freeform_tags]
  }

  metadata = {
    ssh_authorized_keys = trimspace(var.ssh_public_key)
    user_data           = base64encode(local.cloud_init_scripts[each.key])
  }
}

# --- Block Volumes (per-instance, optional) ---

resource "oci_core_volume" "block" {
  for_each            = { for k, v in var.instances : k => v if v.block_volume_gb > 0 }
  compartment_id      = var.tenancy_ocid
  display_name        = "${var.project_name}-${each.key}-block"
  availability_domain = local.availability_domain
  size_in_gbs         = each.value.block_volume_gb
}

resource "oci_core_volume_attachment" "block" {
  for_each        = oci_core_volume.block
  instance_id     = oci_core_instance.instance[each.key].id
  volume_id       = each.value.id
  attachment_type = "paravirtualized"
}
