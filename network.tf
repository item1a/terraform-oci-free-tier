resource "oci_core_vcn" "vcn" {
  compartment_id = var.tenancy_ocid
  display_name   = "${var.project_name} VCN"
  dns_label      = "vcn"
  cidr_blocks    = ["10.0.0.0/16"]
  is_ipv6enabled = true
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "Internet Gateway"
}

resource "oci_core_service_gateway" "sgw" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "Service Gateway"
  services {
    service_id = local.all_services.id
  }
}

resource "oci_core_route_table" "public" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "Public Route Table"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "Private Route Table"
  route_rules {
    network_entity_id = oci_core_service_gateway.sgw.id
    destination       = local.all_services.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "public" {
  compartment_id    = var.tenancy_ocid
  vcn_id            = oci_core_vcn.vcn.id
  route_table_id    = oci_core_route_table.public.id
  security_list_ids = [oci_core_security_list.public.id]
  display_name      = "Public Subnet"
  dns_label         = "public"
  cidr_block        = "10.0.2.0/24"
}

resource "oci_core_subnet" "private" {
  compartment_id             = var.tenancy_ocid
  vcn_id                     = oci_core_vcn.vcn.id
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.private.id]
  display_name               = "Private Subnet"
  dns_label                  = "private"
  cidr_block                 = "10.0.1.0/24"
  prohibit_public_ip_on_vnic = true
}
