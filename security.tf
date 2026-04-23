locals {
  # Collect unique app ports across all instances
  app_ports = toset([for k, v in var.instances : v.app_port])
}

resource "oci_core_security_list" "public" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "Public Security List"

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  dynamic "ingress_security_rules" {
    for_each = local.app_ports
    content {
      protocol = "6"
      source   = "10.0.0.0/16"
      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_security_list" "private" {
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "Private Security List"

  dynamic "ingress_security_rules" {
    for_each = local.app_ports
    content {
      protocol = "6"
      source   = oci_core_subnet.public.cidr_block
      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = oci_core_subnet.public.cidr_block
    tcp_options {
      min = 22
      max = 22
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

# --- Load Balancer NSG (Cloudflare IPs only) ---

resource "oci_core_network_security_group" "lb_nsg" {
  count          = var.enable_cloudflare ? 1 : 0
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "LB Network Security Group"
}

resource "oci_core_network_security_group_security_rule" "cf_ipv4" {
  for_each                  = var.enable_cloudflare ? toset(var.cloudflare_ipv4) : toset([])
  network_security_group_id = oci_core_network_security_group.lb_nsg[0].id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "cf_ipv6" {
  for_each                  = var.enable_cloudflare ? toset(var.cloudflare_ipv6) : toset([])
  network_security_group_id = oci_core_network_security_group.lb_nsg[0].id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}
