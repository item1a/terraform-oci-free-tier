resource "oci_core_instance" "arm" {
  compartment_id      = var.tenancy_ocid
  availability_domain = local.availability_domain
  display_name        = "${var.project_name} ARM Instance"

  shape = var.arm_shape
  shape_config {
    ocpus         = var.arm_ocpus
    memory_in_gbs = var.arm_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = local.arm_image_id
    boot_volume_size_in_gbs = var.boot_volume_size_gb
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
    ignore_changes = [metadata, defined_tags, freeform_tags]
  }

  metadata = {
    ssh_authorized_keys = trimspace(var.ssh_public_key)
    user_data           = base64encode(local.cloud_init_script)
  }
}

# --- Block Volume (optional) ---

resource "oci_core_volume" "block" {
  count               = var.block_volume_size_gb > 0 ? 1 : 0
  compartment_id      = var.tenancy_ocid
  display_name        = "${var.project_name} Block Volume"
  availability_domain = local.availability_domain
  size_in_gbs         = var.block_volume_size_gb
}

resource "oci_core_volume_attachment" "block" {
  count           = var.block_volume_size_gb > 0 ? 1 : 0
  instance_id     = oci_core_instance.arm.id
  volume_id       = oci_core_volume.block[0].id
  attachment_type = "paravirtualized"
}
